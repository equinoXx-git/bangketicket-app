import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON decoding
import 'printer_scan_page.dart';
import 'dart:async'; // Needed for periodic checks
import 'dart:ui'; // Import for BackdropFilter
import 'qr_result_page.dart'; // Import the result page
import 'login.dart'; // Import your LoginPage here

void main() => runApp(const QRCodeScannerApp());

class QRCodeScannerApp extends StatelessWidget {
  const QRCodeScannerApp({super.key});

  // Mock method to check if user is logged in
  // You should replace this with your actual authentication check
  bool isLoggedIn() {
    // Replace with your actual authentication logic
    return false; // Set this to true if the user is already logged in
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Show LoginPage if the user is not logged in, otherwise show PermissionAndPrinterCheck
      home: isLoggedIn() ? const PermissionAndPrinterCheck(collectorName: 'Default Collector', collector_id: 'Default',) : const LoginPage(),
    );
  }
}

class PermissionAndPrinterCheck extends StatefulWidget {
  final String collectorName; // Add this parameter
  final String collector_id; 

  const PermissionAndPrinterCheck({super.key, required this.collectorName, required this.collector_id,});

  @override
  _PermissionAndPrinterCheckState createState() => _PermissionAndPrinterCheckState();
}

class _PermissionAndPrinterCheckState extends State<PermissionAndPrinterCheck> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {

    debugPrint('Collector ID at Permission Check: ${widget.collector_id}'); // Debug

    await Permission.camera.request();
    await Permission.location.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterScanPage(collectorName: widget.collectorName, collector_id: widget.collector_id), // Pass collectorName
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class QRViewExample extends StatefulWidget {
  final String collectorName; // Add this parameter
  final String collector_id;

  const QRViewExample({super.key, required this.collectorName, required this.collector_id,});
  
  @override
  _QRViewExampleState createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final double cutOutSize = 300;
  final double lineThickness = 2;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation =
        Tween<double>(begin: 0, end: cutOutSize - 2).animate(_animationController);

        debugPrint('Collector ID at QRView: ${widget.collector_id}'); // Debug
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Add back button icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth), // Bluetooth icon
            tooltip: 'Connect to Printer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrinterScanPage(collectorName: widget.collectorName, collector_id: widget.collector_id,)), // Pass collectorName
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          buildBackdropFilter(), // Apply blur effect to background
          buildQRView(context),
          buildScannerOverlay(context),
          if (isScanning) buildScanningLine(),
          buildToggleButton(),
        ],
      ),
    );
  }

  Widget buildQRView(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.transparent, // Hide border
        borderRadius: 0,
        borderLength: 0,
        borderWidth: 0,
        cutOutSize: cutOutSize,
        cutOutBottomOffset: 0, // No bottom offset
        overlayColor: Colors.transparent, // Ensure the overlay is transparent
      ),
    );
  }

  Future<void> validateQRCode(String qrCode) async {
    final lines = qrCode.split('\n');
    String vendorID = '';

    for (String line in lines) {
      if (line.startsWith('Vendor ID:')) {
        vendorID = line.replaceFirst('Vendor ID:', '').trim(); // Extract the vendorID value
        break;
      }
    }

    if (vendorID.isNotEmpty) {
      final url = 'http://192.168.100.37/bangketicket_api/validate_qr.php?vendorID=$vendorID';
      print("Validation URL: $url"); // Debugging

      try {
        final response = await http.get(Uri.parse(url));
        final data = jsonDecode(response.body);

        if (data['status'] == 'valid') {
          debugPrint("Collector ID at QRResultPage transition: ${widget.collector_id}"); // Debug print
          String collectorId = widget.collector_id; // Extract collector_id from the response
          debugPrint('Collector ID after QR validation: $collectorId'); // Debug
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRResultPage(qrText: qrCode, collectorName: widget.collectorName, collector_id: collectorId,), // Pass collectorName
            ),
          );
        } else {
          String errorMessage = data['message'] ?? 'Invalid QR Code. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
          controller?.resumeCamera(); // Resume scanning if invalid
          setState(() {
            isScanning = true;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
        controller?.resumeCamera(); // Resume scanning on error
        setState(() {
          isScanning = true;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code format: Vendor ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      controller?.resumeCamera();
      setState(() {
        isScanning = true;
      });
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanning) {
        setState(() {
          isScanning = false;
        });
        controller.pauseCamera();
        validateQRCode(scanData.code ?? ''); // Validate QR code
      }
    });
  }

  Widget buildBackdropFilter() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget buildScannerOverlay(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topOffset = (screenSize.height - cutOutSize) / 2;
    final leftOffset = (screenSize.width - cutOutSize) / 2;

    return Positioned(
      top: topOffset - 60,
      left: leftOffset,
      width: cutOutSize,
      child: Column(
        children: [
          const Text(
            'Place the QR Code inside the area',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: cutOutSize,
            height: cutOutSize,
            child: CustomPaint(
              painter: QRScannerOverlayPainter(
                borderColor: Colors.blue,
                borderWidth: 4,
                cornerLength: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildScanningLine() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final topOffset = (screenSize.height - cutOutSize) / 2;
        final leftOffset = (screenSize.width - cutOutSize) / 2;

        return Positioned(
          top: topOffset + _animation.value,
          left: leftOffset,
          width: cutOutSize,
          child: Container(
            color: const Color.fromARGB(255, 255, 0, 0).withOpacity(0.5),
            height: lineThickness,
          ),
        );
      },
    );
  }

  Widget buildToggleButton() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: ElevatedButton(
        onPressed: _toggleScanning,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 13, 41, 88),
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isScanning ? 'Stop Scanning' : 'Start Scanning',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _toggleScanning() {
    setState(() {
      if (isScanning) {
        controller?.pauseCamera();
      } else {
        controller?.resumeCamera();
      }
      isScanning = !isScanning;
    });
  }
}

class QRScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double cornerLength;

  QRScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final double cutOutSize = size.width;
    final double cutOutOffset = (size.height - cutOutSize) / 2;

    canvas.drawLine(Offset(0, cutOutOffset), Offset(cornerLength, cutOutOffset), paint);
    canvas.drawLine(Offset(0, cutOutOffset), Offset(0, cutOutOffset + cornerLength), paint);
    canvas.drawLine(Offset(size.width, cutOutOffset),
        Offset(size.width - cornerLength, cutOutOffset), paint);
    canvas.drawLine(Offset(size.width, cutOutOffset),
        Offset(size.width, cutOutOffset + cornerLength), paint);
    canvas.drawLine(Offset(0, cutOutOffset + cutOutSize),
        Offset(cornerLength, cutOutOffset + cutOutSize), paint);
    canvas.drawLine(Offset(0, cutOutOffset + cutOutSize),
        Offset(0, cutOutOffset + cutOutSize - cornerLength), paint);
    canvas.drawLine(Offset(size.width, cutOutOffset + cutOutSize),
        Offset(size.width - cornerLength, cutOutOffset + cutOutSize), paint);
    canvas.drawLine(Offset(size.width, cutOutOffset + cutOutSize),
        Offset(size.width, cutOutOffset + cutOutSize - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
