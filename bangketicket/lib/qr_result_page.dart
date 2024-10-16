import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'receipt_page.dart';

class QRResultPage extends StatefulWidget {
  final String qrText;
  final String collectorName;
  final String collector_id;

  const QRResultPage({super.key, required this.qrText, required this.collectorName, required this.collector_id});

  @override
  _QRResultPageState createState() => _QRResultPageState();
}

class _QRResultPageState extends State<QRResultPage> {
  final TextEditingController amountController = TextEditingController();
  String vendorID = '';
  String fullName = ''; // Vendor full name

  @override
  void initState() {
    super.initState();
    debugPrint("Collector ID at QRResultPage: ${widget.collector_id}");
    _parseQRCode();
    _fetchVendorDetails();
  }

  void _parseQRCode() {
    final lines = widget.qrText.split('\n');
    for (String line in lines) {
      if (line.startsWith('Vendor ID:')) {
        vendorID = line.replaceFirst('Vendor ID:', '').trim();
      }
    }
  }

  Future<void> _fetchVendorDetails() async {
    if (vendorID.isEmpty) return;

    var url = Uri.parse('http://192.168.100.37/bangketicket_api/get_vendor_details.php?vendorID=$vendorID');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            fullName = data['full_name']; // Set vendor full name from the response
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Vendor not found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching vendor details')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Code Result',
          style: TextStyle(color: Color.fromARGB(255, 13, 41, 88), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 13, 41, 88)), // Add back button icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,  // Make it stretch across the screen width
          children: [
            // Vendor Details Display (Vendor ID and Full Name)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,  // Center all the content
                children: [
                  const Text(
                    'Vendor Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 13, 41, 88),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Vendor ID:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    vendorID,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,  // Make the vendor ID bold
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Vendor Name:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,  // Make the full name bold
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Market Stall Fee Label
            const Text(
              'Market Stall Fee',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 13, 41, 88),
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 10),

            // Amount Text Field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.money, color: Color.fromARGB(255, 13, 41, 88)),
                labelStyle: const TextStyle(color: Colors.grey),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 13, 41, 88),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an amount.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptPage(
                        amount: amountController.text,
                        vendorID: vendorID,
                        fullName: fullName,  // Pass the fetched full name
                        collectorName: widget.collectorName,
                        collector_id: widget.collector_id,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 13, 41, 88), // Blue button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),  // Light background color for contrast
    );
  }
}
