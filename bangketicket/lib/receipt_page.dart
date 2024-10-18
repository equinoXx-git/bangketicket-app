import 'dart:async';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart'; // Ensure this is correctly imported for routing

class ReceiptPage extends StatelessWidget {
  final String amount;
  final String vendorID;
  final String fullName; // Vendor full name
  final String collectorName; // Collector name
  final String collector_id; // Collector ID
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // Constructor with all the required arguments
  ReceiptPage({
    super.key,
    required this.amount,
    required this.vendorID,
    required this.fullName,
    required this.collectorName,
    required this.collector_id,
  }) {
    debugPrint("Collector ID: $collector_id");
  }

  // Function to format vendor name as "LastName, F."
  String _formatVendorName(String fullName) {
    final nameParts = fullName.split(',');

    if (nameParts.length > 1) {
      final lastName = nameParts[0].trim(); 
      final firstAndMiddle = nameParts[1].trim(); 
      final firstNameInitial = firstAndMiddle.isNotEmpty ? firstAndMiddle[0] : ''; 
      return '$lastName, $firstNameInitial.'; 
    } else {
      return fullName; 
    }
  }

  Future<void> _selectAndConnectPrinter(BuildContext context) async {
    List<BluetoothDevice> pairedDevices = await bluetooth.getBondedDevices();

    if (pairedDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No paired devices found. Please pair your printer first.')),
      );
      return;
    }

    BluetoothDevice? selectedDevice = await showDialog<BluetoothDevice>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select Printer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pairedDevices.length,
                    itemBuilder: (context, index) {
                      final device = pairedDevices[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: const Icon(Icons.devices, color: Color.fromARGB(255, 13, 41, 88)),
                          title: Text(device.name ?? "Unknown Device"),
                          subtitle: Text(device.address!),
                          trailing: const Icon(Icons.arrow_forward, color: Color.fromARGB(255, 13, 41, 88)),
                          onTap: () {
                            Navigator.of(context).pop(pairedDevices[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No printer selected.')),
      );
      return;
    }

    _showConnectingDialog(context);
    await _connectToDevice(context, selectedDevice);
  }

  Future<void> _connectToDevice(BuildContext context, BluetoothDevice device) async {
    bool isConnected = false;
    int retryCount = 0;
    const int maxRetries = 5;

    DateTime connectionStartTime = DateTime.now();

    while (!isConnected && retryCount < maxRetries) {
      try {
        isConnected = (await bluetooth.connect(device))!;
        if (isConnected) {
          Navigator.of(context).pop(); 
          _showSuccessDialog(context, device);
          await _insertTransactionAndPrint(context);
          return;
        }
      } catch (e) {
        print('Connection attempt ${retryCount + 1} failed: $e');
      }

      retryCount++;

      if (DateTime.now().difference(connectionStartTime).inSeconds > 5) {
        Navigator.of(context).pop(); 
        _showReconnectDialog(context, device); 
        return; 
      }

      if (retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (!isConnected) {
      Navigator.of(context).pop(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device.name} after $maxRetries attempts.')),
      );
    }
  }

  // Function to show connecting dialog
  void _showConnectingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color.fromARGB(255, 13, 41, 88)),
                SizedBox(height: 20),
                Text('Connecting to the printer...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReconnectDialog(BuildContext context, BluetoothDevice device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.orangeAccent),
                const SizedBox(height: 20),
                const Text(
                  'Connection Failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 13, 41, 88)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unable to connect to the printer. Would you like to try again?',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color.fromARGB(255, 13, 41, 88)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color.fromARGB(255, 13, 41, 88))),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 13, 41, 88),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _connectToDevice(context, device); 
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to show success dialog after connecting
  void _showSuccessDialog(BuildContext context, BluetoothDevice device) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                const SizedBox(height: 20),
                Text('Connected to ${device.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('You are now connected to the printer.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 13, 41, 88),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _insertTransactionAndPrint(BuildContext context) async {
    debugPrint("Collector ID before transaction insertion: $collector_id");
    String transactionID = await _insertTransaction(vendorID, DateTime.now().toString(), amount);

    if (transactionID.isNotEmpty) {
      _printReceipt(context, transactionID);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to insert the transaction.')),
      );
    }
  }

  Future<void> _printReceipt(BuildContext context, String transactionID) async {
    bool? isConnected = await bluetooth.isConnected;

    if (isConnected == null || !isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected. Please connect to the printer first.')),
      );
      return;
    }

    ByteData malolosBytes = await rootBundle.load('assets/malolos-bw.png');
    Uint8List malolosImageBytes = malolosBytes.buffer.asUint8List();
    img.Image? malolosImage = img.decodeImage(malolosImageBytes);

    if (malolosImage != null) {
      img.Image resizedMalolosImage = img.copyResize(malolosImage, width: 400);
      Uint8List malolosPrintableBytes = Uint8List.fromList(img.encodePng(resizedMalolosImage));
      bluetooth.printImageBytes(malolosPrintableBytes);
    }

    String formattedDate = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    String formattedTime = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';
    String formattedVendorName = _formatVendorName(fullName); 

    bluetooth.printCustom("Official Receipt", 2, 1);
    bluetooth.printNewLine();
    bluetooth.printLeftRight("Transaction No:", transactionID, 1);
    bluetooth.printLeftRight("Date:", formattedDate, 1);
    bluetooth.printLeftRight("Time:", formattedTime, 1);
    bluetooth.printLeftRight("Vendor ID:", vendorID, 1);
    bluetooth.printLeftRight("Vendor Name:", formattedVendorName, 1);
    bluetooth.printLeftRight("Collector:", collectorName, 1);

    bluetooth.printCustom("--------------------------------", 0, 1);
    bluetooth.printLeftRight("Total Amount:", 'PHP $amount', 1);
    bluetooth.printCustom("--------------------------------", 0, 1);
    bluetooth.printCustom("Thank you for your payment!", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();

    _showPrintSuccessDialog(context);
  }

  Future<String> _insertTransaction(String vendorID, String date, String amount) async {
    try {
      DateTime currentDate = DateTime.now();
      String formattedDate = "${currentDate.toLocal()}".split('.')[0];

      final response = await http.post(
        Uri.parse('http://192.168.100.37/bangketicket_api/insert_transaction.php'),
        body: {
          'vendorID': vendorID,
          'date': formattedDate,
          'amount': amount,
          'collector_id': collector_id,
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          return result['transactionID'];
        } else {
          return '';
        }
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  void _showPrintSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 76, 175, 80),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Print Successful!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  "Your receipt has been printed successfully.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRViewExample(collectorName: collectorName, collector_id: collector_id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 13, 41, 88),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    String formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 20),
              const Text('Official Receipt', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(thickness: 2),
              const SizedBox(height: 20),
              Text('Date: $formattedDate', style: const TextStyle(fontSize: 16)),
              Text('Time: $formattedTime', style: const TextStyle(fontSize: 16)),
              Text('Vendor ID: $vendorID', style: const TextStyle(fontSize: 16)),
              Text('Vendor Name: ${_formatVendorName(fullName)}', style: const TextStyle(fontSize: 16)),
              Text('Collector ID: $collector_id', style: const TextStyle(fontSize: 16)),
              Text('Collector: $collectorName', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Text('Amount: ₱$amount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              SizedBox(
                width: 150,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    bool? isConnected = await bluetooth.isConnected;
                    if (isConnected == true) {
                      await _insertTransactionAndPrint(context);
                    } else {
                      _selectAndConnectPrinter(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 13, 41, 88),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Print Receipt', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 150,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 180, 19, 19),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
