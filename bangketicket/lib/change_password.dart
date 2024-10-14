import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  // For decoding JSON responses
import 'login.dart';  // Import your login page

class ChangePasswordPage extends StatefulWidget {
  final String collectorId;

  const ChangePasswordPage({super.key, required this.collectorId});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPasswordVisible = false;  // Toggle password visibility for new password
  bool _isConfirmPasswordVisible = false;  // Toggle password visibility for confirm password

  bool _showPasswordError = false;  // Show error for password length
  bool _showPasswordMatchError = false;  // Show error for matching passwords

  void _validatePassword() {
    setState(() {
      _showPasswordError = _newPasswordController.text.length < 8;
    });
  }

  void _validatePasswordMatch() {
    setState(() {
      _showPasswordMatchError = _newPasswordController.text != _confirmPasswordController.text;
    });
  }

  Future<void> _submitNewPassword() async {
    _validatePassword();
    _validatePasswordMatch();

    if (_showPasswordError || _showPasswordMatchError) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.37/bangketicket_api/change_password.php'),
        body: {
          'collector_id': widget.collectorId,
          'new_password': _newPasswordController.text,
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully. Please log in again.')),
          );
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error changing password';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error connecting to the server. Please try again.';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,  // Prevent layout from adjusting when keyboard pops up
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,  // Align to the left
                children: [
                  // Adjust the top padding to move content upwards
                  const SizedBox(height: 40),
                  Center(
                    child: Image.asset(
                      'assets/logo.png',  // Adjust the logo path
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 20),  // Reduced padding between logo and title
                  
                  // Left-align the title and description
                  const Text(
                    'Create New Password',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your new password must be different from previous used passwords.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),  // Reduced padding between description and form
                  
                  // New Password Field
                  TextField(
                    controller: _newPasswordController,
                    onChanged: (_) => _validatePassword(),  // Validate as user types
                    obscureText: !_isPasswordVisible,  // Toggle password visibility
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  // Display password error if necessary
                  if (_showPasswordError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Must be at least 8 characters.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  
                  // Confirm Password Field
                  TextField(
                    controller: _confirmPasswordController,
                    onChanged: (_) => _validatePasswordMatch(),  // Validate as user types
                    obscureText: !_isConfirmPasswordVisible,  // Toggle confirm password visibility
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  // Display password match error if necessary
                  if (_showPasswordMatchError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Both passwords must match.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  
                  // Error Message
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  
                  // Submit Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitNewPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 13, 41, 88),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Reset Password',
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
