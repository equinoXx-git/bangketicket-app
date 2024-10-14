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
  String fullName = '';  // Vendor full name

  @override
  void initState() {
    super.initState();
    debugPrint("Collector ID at QRResultPage: ${widget.collector_id}"); // Debug print
    _parseQRCode();
    _fetchVendorDetails();  // Fetch vendor details when the page loads
  }

  void _parseQRCode() {
    // Extract Vendor ID from the QR text
    final lines = widget.qrText.split('\n');

    // Loop through the lines to find "Vendor ID:"
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
            fullName = data['full_name'];  // Set vendor full name from the response
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
        title: const Text('QR Code Result'),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Add back button icon
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Vendor Details Display (Vendor ID and Full Name)
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Vendor Details:\n',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'Vendor ID: $vendorID\n',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'Vendor Full Name: $fullName\n',  // Display vendor full name
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Market Stall Fee',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
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
                  debugPrint("Collector ID at ReceiptPage transition: ${widget.collector_id}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptPage(
                        amount: amountController.text,
                        vendorID: vendorID,
                        fullName: fullName,  // Pass the fetched full name
                        collectorName: widget.collectorName,
                        collector_id: widget.collector_id
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 13, 41, 88),  // Blue button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
