import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class ReceiptPage extends StatelessWidget {
  final String amount;
  final String vendorID;
  final String fullName; // Vendor full name
  final String collectorName; // Collector name
  final String collector_id; // Collector name
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // Constructor with all the required arguments
  ReceiptPage({
    super.key,
    required this.amount,
    required this.vendorID,
    required this.fullName,
    required this.collectorName,
    required this.collector_id,
  })
  {
  // Debug prints to verify collector details
  debugPrint("Collector ID: $collector_id");
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
        return AlertDialog(
          title: const Text('Select Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pairedDevices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(pairedDevices[index].name ?? "Unknown Device"),
                  subtitle: Text(pairedDevices[index].address!),
                  onTap: () {
                    Navigator.of(context).pop(pairedDevices[index]);
                  },
                );
              },
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to ${selectedDevice.name}...')),
    );

    bool? connected = await bluetooth.connect(selectedDevice);

    if (connected == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${selectedDevice.name}')),
      );
      await _insertTransactionAndPrint(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to the printer. Please try again.')),
      );
    }
  }

  Future<void> _insertTransactionAndPrint(BuildContext context) async {
    debugPrint("Collector ID before transaction insertion: $collector_id"); // Debug print
    String transactionID = await _insertTransaction(vendorID, DateTime.now().toString(), amount);

    if (transactionID.isNotEmpty) {
      _printReceipt(context, transactionID); // Proceed to print with the actual transaction ID
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to insert the transaction.')),
      );
    }
  }

  Future<void> _printReceipt(BuildContext context, String transactionID) async {
    bool? isConnected = await bluetooth.isConnected;
    debugPrint("Printing receipt with Collector ID: $collector_id"); // Debug print

    if (isConnected == null || !isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected. Please connect to the printer first.')),
      );
      return;
    }

   // Load and trim the malolos-bw.png logo
ByteData malolosBytes = await rootBundle.load('assets/malolos-bw.png');
Uint8List malolosImageBytes = malolosBytes.buffer.asUint8List();
img.Image? malolosImage = img.decodeImage(malolosImageBytes);

if (malolosImage != null) {
    // Trim the image to remove any white space around the content
    img.Image trimmedMalolosImage = img.copyCrop(malolosImage, 0, 0, malolosImage.width, malolosImage.height);

    // Resize and print the trimmed image
    img.Image resizedMalolosImage = img.copyResize(trimmedMalolosImage, width: 400);
    Uint8List malolosPrintableBytes = Uint8List.fromList(img.encodePng(resizedMalolosImage));
    bluetooth.printImageBytes(malolosPrintableBytes);
}
    // Print some space
    // Formatting receipt for Malolos City
    bluetooth.printCustom("Republic of the Philippines", 1, 1);
    bluetooth.printCustom("Malolos City", 1, 1);


    // Load and print the logo-bw.png logo
    ByteData logoBytes = await rootBundle.load('assets/logo-bw.png');
    Uint8List logoImageBytes = logoBytes.buffer.asUint8List();
    img.Image? logoImage = img.decodeImage(logoImageBytes);

    if (logoImage != null) {
      img.Image resizedLogoImage = img.copyResize(logoImage, width: 100); // Make the logo smaller
      Uint8List logoPrintableBytes = Uint8List.fromList(img.encodePng(resizedLogoImage));
      bluetooth.printImageBytes(logoPrintableBytes);
    }

    String formattedDate = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    String formattedTime = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';


    bluetooth.printCustom("Official Receipt", 2, 1);
    bluetooth.printNewLine();

    bluetooth.printLeftRight("Transaction No:", transactionID, 1);
    bluetooth.printLeftRight("Date:", formattedDate, 1);
    bluetooth.printLeftRight("Time:", formattedTime, 1);
    bluetooth.printLeftRight("Vendor ID:", vendorID, 1);
    bluetooth.printLeftRight("Vendor Name:", fullName, 1);
    bluetooth.printLeftRight("Collector:", collectorName, 1); // Print the collector's name

    bluetooth.printNewLine();
    bluetooth.printCustom("--------------------------------", 0, 1);
    bluetooth.printLeftRight("Total Amount:", 'PHP $amount', 1);
    bluetooth.printCustom("--------------------------------", 0, 1);
    bluetooth.printNewLine();

    bluetooth.printCustom("Thank you for your payment!", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();

    _showPrintSuccessDialog(context);
  }

 Future<String> _insertTransaction(String vendorID, String date, String amount) async {
  try {
    DateTime currentDate = DateTime.now();
    String formattedDate = "${currentDate.toLocal()}".split('.')[0];

    debugPrint("Sending transaction data: Vendor ID: $vendorID, Date: $formattedDate, Amount: $amount, Collector ID: $collector_id");
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
        print('Transaction inserted successfully with ID: ${result['transactionID']}');
        return result['transactionID'];
      } else {
        print('Failed to insert transaction: ${result['message']}');
        return '';
      }
    } else {
      print('Failed to connect to server: ${response.statusCode}');
      return '';
    }
  } catch (e) {
    print('Error: $e');
    return '';
  }
}

  void _showPrintSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 10),
                const Text(
                  "Print Successful!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your receipt has been printed successfully.",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRViewExample(collectorName: collectorName, collector_id: collector_id,), // Navigate back to QRViewExample
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 13, 41, 88),
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
          icon: const Icon(Icons.arrow_back), // Add back button icon
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              Image.asset('assets/logo.png', height: 100),
            const SizedBox(height: 10),
            const Text(
              'Official Receipt',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text('Date: $formattedDate', style: const TextStyle(fontSize: 16)),
            Text('Time: $formattedTime', style: const TextStyle(fontSize: 16)),
            Text('Vendor ID: $vendorID', style: const TextStyle(fontSize: 16)),
            Text('Vendor Name: $fullName', style: const TextStyle(fontSize: 16)), // Display vendor name
            Text('Collector ID: $collector_id', style: const TextStyle(fontSize: 16)), // Display vendor name
            Text('Collector: $collectorName', style: const TextStyle(fontSize: 16)), // Display the collector's name
            const SizedBox(height: 10),
            Text('Amount: ₱$amount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Divider(),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
