import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'change_password.dart';  // Import for the ChangePasswordPage
import 'forgot_password_email.dart';  // Import the ForgotPasswordEmailPage
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPasswordVisible = false; // State to track if the password is visible
  bool _isRememberMeChecked = false;

  // Method to check for internet connection
  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      _showNoConnectionDialog();
      return false;
    }
    return true;
  }

// Method to show a modern "No Internet Connection" dialog
void _showNoConnectionDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
        ),
        elevation: 16,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content
            crossAxisAlignment: CrossAxisAlignment.center, // Center the content
            children: [
              const Icon(
                Icons.wifi_off, // No internet icon
                size: 60,
                color: Colors.redAccent, // Icon color for no internet state
              ),
              const SizedBox(height: 20),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 13, 41, 88), // Title color matching design
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 10),
              const Text(
                'Please check your internet connection and try again.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey, // Subtitle color
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 13, 41, 88), // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners for the button
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white), // White text
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Method to show a modern "Server Timeout" dialog
void _showTimeoutDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
        ),
        elevation: 16,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content
            crossAxisAlignment: CrossAxisAlignment.center, // Center the content
            children: [
              const Icon(
                Icons.access_time, // Timeout icon
                size: 60,
                color: Colors.orangeAccent, // Icon color for timeout
              ),
              const SizedBox(height: 20),
              const Text(
                'Server Timeout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 13, 41, 88), // Title color matching design
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 10),
              const Text(
                'The server is taking too long to respond. Please try again later.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey, // Subtitle color
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 13, 41, 88), // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners for the button
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white), // White text
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}


Future<void> _login() async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  String username = _usernameController.text.trim();
  String password = _passwordController.text.trim();

  if (username.isEmpty || password.isEmpty) {
    setState(() {
      _errorMessage = 'Please fill in both fields';
      _isLoading = false;
    });
    return;
  }

  var url = Uri.parse('https://bangketicket.online/bangketicket_api/validate_login.php');
  
  try {
    var response = await http.post(url, body: {
      'username': username,
      'password': password,
    })
    .timeout(
      const Duration(seconds: 10), 
      onTimeout: () {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Server is taking too long to respond. Please try again later.';
        });
        _showTimeoutDialog();
        // Return a dummy response with a timeout error code like 408 (Request Timeout)
        return http.Response('Error: Timeout', 408); 
      });

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print("Response from API: $data");

      if (data['success'] == true) {
        String collectorName = data['collector_details']['collectorName'];
        String collectorId = data['collector_details']['collector_id'];

        // Navigate based on login conditions
        if (data['first_login'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordPage(collectorId: collectorId),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PermissionAndPrinterCheck(
                collectorName: collectorName,
                collector_id: collectorId,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'];
        });
      }
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      setState(() {
        _errorMessage = 'Error connecting to the server. Status code: ${response.statusCode}';
      });
    }
  } catch (e) {
    print("Error during HTTP request: $e");
    _showNoConnectionDialog(); // Show the dialog if the connection fails during API call
    setState(() {
    });
  }

  setState(() {
    _isLoading = false;
  });
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
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/malolos.png',
                          height: 85,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Republika ng Pilipinas',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          height: 1,
                          width: 120,
                          color: Colors.black,
                        ),
                        const Text(
                          'Pamahalaang Lungsod ng Malolos',
                          style: TextStyle(
                            fontSize: 7,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  Center(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(seconds: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Center vertically inside the Column
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 75,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 5),
                          ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 13, 41, 88),
                                  Color.fromARGB(255, 30, 60, 120),
                                  Color.fromARGB(255, 0, 52, 128),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: const Text(
                              'BangkeTicket',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20), // More rounded corners
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                       prefixIcon: const Icon(Icons.person),
                        filled: true, // Add background color to TextFields
                        fillColor: Colors.white.withOpacity(0.8), // Semi-transparent background
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible, // Toggle password visibility
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20), // More rounded corners
                          borderSide: const BorderSide(color: Colors.grey, width: 1),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        filled: true, // Add background color to TextFields
                        fillColor: Colors.white.withOpacity(0.8), // Semi-transparent background
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.grey, width: 1),
                        ),
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
                // Remember Me checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between Remember Me and Forgot Password
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _isRememberMeChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              _isRememberMeChecked = value!;
                            });
                          },
                        ),
                        const Text("Remember Me"),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to Forgot Password Email Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordEmailPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color.fromARGB(255, 13, 41, 88), // Change color to match theme
                          fontSize: 14,
                          decoration: TextDecoration.underline, // Underline the text
                          fontWeight: FontWeight.bold, // Make it bold
                        ),
                      ),
                    ),
                  ],
                ),

                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 13, 41, 88),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
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
}