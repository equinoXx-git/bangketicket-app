import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For decoding JSON responses
import 'change_password.dart'; // Import the Change Password page

class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP';
        _isLoading = false;
      });
      return;
    }

 try {
  final response = await http.post(
    Uri.parse('http://192.168.100.37/bangketicket_api/verify_otp.php'),
    body: {
      'email': widget.email,
      'otp': otp,
    },
  );

  print("Response body: ${response.body}"); // Log the raw response body for debugging

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    if (data['success'] == true) {
      String collectorId = data['collector_id'];

      // OTP is verified, navigate to change password page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChangePasswordPage(collectorId: collectorId),
        ),
      );
    } else {
      setState(() {
        _errorMessage = data['message'];
      });
    }
  } else {
    setState(() {
      _errorMessage = 'Error: ' + response.statusCode.toString() + ' - ' + response.body;
    });
  }
} catch (error) {
  setState(() {
    _errorMessage = 'An unexpected error occurred: ' + error.toString();
  });
} finally {
  setState(() {
    _isLoading = false;
  });
}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Image.asset(
                      'assets/logo.png', // Adjust the logo path
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 20), // Reduced padding between logo and title
                  
                  const Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A one-time password (OTP) has been sent to your email. Please enter it below.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20), // Reduced padding between description and form
                  
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'OTP',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.security),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 13, 41, 88),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Verify OTP',
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
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
