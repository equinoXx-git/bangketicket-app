import 'dart:async';

import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'main.dart';
import 'login.dart'; // Import the LoginPage


class PrinterScanPage extends StatefulWidget {
  final String collectorName; // Add this parameter
  final String collector_id; // Add this parameter

  const PrinterScanPage({super.key, required this.collectorName, required this.collector_id});

  @override
  _PrinterScanPageState createState() => _PrinterScanPageState();
}

class _PrinterScanPageState extends State<PrinterScanPage> {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _pairedDevices = [];
  List<BluetoothDevice> _availableDevices = [];
  BluetoothDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isDialogShown = false; // Ensure dialog is shown only once
  StreamSubscription? _stateSubscription; 

  @override
  void initState() {
    super.initState();
    _checkBluetoothAndScan();
    _listenToBluetoothState(); // Start listening for Bluetooth state changes
  }
  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _stateSubscription?.cancel();
    super.dispose();
  }
  Future<void> _checkBluetoothAndScan() async {
    const intent = AndroidIntent(
      action: 'android.bluetooth.adapter.action.REQUEST_ENABLE',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();

    bool? isOn = await bluetooth.isOn;
  if (isOn == null || !isOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please turn on Bluetooth to proceed.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent, // Modern style for snackbar
        ),
      );
      return;
    }

    _startScanning();
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _pairedDevices = [];
      _availableDevices = [];
    });

    try {
      List<BluetoothDevice> pairedDevices = await bluetooth.getBondedDevices();
      setState(() {
        _pairedDevices = pairedDevices;
        _isScanning = false;
      });

      // Instead of scanning, we only check for paired devices
      if (_pairedDevices.isEmpty) {
        _showManualPairingPrompt();
      }
    } catch (e) {
      print('Error during scanning: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error scanning for devices. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _isScanning = false;
      });
    }
  }

// Add this method to listen to Bluetooth state changes
  void _listenToBluetoothState() {
     _stateSubscription = bluetooth.onStateChanged().listen((dynamic state) {
      if (state == BlueThermalPrinter.DISCONNECTED && !_isDialogShown) {
        _isDialogShown = true; // Ensure only one dialog shows
        _showDisconnectedPrompt(); // Prompt user when disconnected
        setState(() {
          _selectedDevice = null; // Printer is no longer connected
        });
      }
    });
  }
  // Show dialog if no devices are paired or available
  void _showManualPairingPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Bluetooth Pairing Required', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'No paired devices found. Please manually pair your printer via Bluetooth settings to connect.',
          ),
          actions: [
            TextButton(
              child: const Text('Open Bluetooth Settings'),
              onPressed: () {
                // Open Bluetooth settings
                const intent = AndroidIntent(
                  action: 'android.settings.BLUETOOTH_SETTINGS',
                  flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                );
                intent.launch();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _showConnectingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing the dialog
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
              const CircularProgressIndicator(
                color: Color.fromARGB(255, 13, 41, 88), // Customize progress color
              ),
              const SizedBox(height: 20),
              const Text(
                'Connecting to the printer...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 13, 41, 88),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
void _showSuccessDialog(BluetoothDevice device) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing the dialog
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
              Icon(
                Icons.check_circle_outline,
                size: 60,
                color: Colors.green, // Success icon color
              ),
              const SizedBox(height: 20),
              Text(
                'Connected to ${device.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 13, 41, 88),
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 10),
              const Text(
                'You are now connected to the printer.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 13, 41, 88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _connectToDevice(BluetoothDevice device) async {
  _showConnectingDialog(); // Show the connecting dialog

  bool isConnected = false;
  int retryCount = 0;
  const int maxRetries = 5;

  DateTime connectionStartTime = DateTime.now(); // Track when the connection starts

  while (!isConnected && retryCount < maxRetries) {
    try {
      if (!(await bluetooth.isOn)!) {
        throw Exception('Bluetooth is turned off');
      }

      isConnected = (await bluetooth.connect(device))!;

      if (isConnected) {
        Navigator.of(context).pop(); // Close the connecting dialog
        _showSuccessDialog(device); // Show success dialog
        setState(() {
          _selectedDevice = device; // Update the selected device
        });

        // Listen for state changes and handle disconnection immediately
        bluetooth.onStateChanged().listen((state) {
          if (state == BlueThermalPrinter.DISCONNECTED && !_isDialogShown) {
            // Show disconnected message and prompt immediately
            _isDialogShown = true; // Prevent showing multiple dialogs
            _showDisconnectedPrompt(); // Prompt user when disconnected
            setState(() {
              _selectedDevice = null; // Printer is no longer connected
            });
          }
        });

        return;
      }
    } catch (e) {
      print('Connection attempt ${retryCount + 1} failed: $e');
    }

    retryCount++;

    // If the connection time exceeds 5 seconds, show the reconnect prompt
    if (DateTime.now().difference(connectionStartTime).inSeconds > 5) {
      Navigator.of(context).pop(); // Close the connecting dialog
      _showReconnectDialog(device); // Show the reconnect prompt dialog
      return; // Exit the loop after showing the dialog
    }

    if (retryCount < maxRetries) {
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  if (!isConnected) {
    Navigator.of(context).pop(); // Close the connecting dialog if it fails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to connect to ${device.name} after $maxRetries attempts.')),
    );
  }

  setState(() {
    _isConnecting = false;
  });
}

// Function to show disconnect prompt with updated design
void _showDisconnectedPrompt() {

  _isDialogShown = true; // Set the flag to true

  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing the dialog
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content
            children: [
              Icon(
                Icons.bluetooth_disabled, // Bluetooth disabled icon
                size: 60,
                color: Colors.redAccent, // Icon color for disconnected state
              ),
              const SizedBox(height: 20),
              const Text(
                'Printer Disconnected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 13, 41, 88), // Title color
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 10),
              const Text(
                'The printer has been disconnected. Would you like to reconnect?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // White background for cancel button
                      side: const BorderSide(
                        color: Color.fromARGB(255, 13, 41, 88),
                      ), // Outline border with matching color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color.fromARGB(255, 13, 41, 88), // Text color matching palette
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      setState(() {
                        _isDialogShown = false; // Reset the flag
                        _isConnecting = false; // Reset the connection state
                        _selectedDevice = null; // Reset selected device
                      });
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 13, 41, 88), // Reconnect button background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      'Reconnect',
                      style: TextStyle(color: Colors.white), // White text
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      setState(() {
                          _isDialogShown = false; // Reset the flag
                        });
                      if (_selectedDevice != null) {
                        _connectToDevice(_selectedDevice!); // Retry connecting
                      }
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

// Function to show reconnect dialog with updated design
void _showReconnectDialog(BluetoothDevice device) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content
            children: [
              Icon(
                Icons.error_outline, // Error icon
                size: 60,
                color: Colors.orangeAccent, // Icon color for failure state
              ),
              const SizedBox(height: 20),
              const Text(
                'Connection Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 13, 41, 88), // Title color
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 10),
              const Text(
                'Unable to connect to the printer. Would you like to try again?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // White background for cancel button
                      side: const BorderSide(
                        color: Color.fromARGB(255, 13, 41, 88),
                      ), // Outline border with matching color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color.fromARGB(255, 13, 41, 88), // Text color matching palette
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      setState(() {
                        _isConnecting = false; // Reset the connection state
                        _selectedDevice = null; // Reset selected device
                      });
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 13, 41, 88), // Retry button background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white), // White text
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      _connectToDevice(device); // Retry connecting
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

  // Modernized Logout Confirmation Dialog
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white, // Dialog background color
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  size: 40,
                  color: const Color.fromARGB(255, 13, 41, 88), // Icon color
                ),
                const SizedBox(height: 20),
                const Text(
                  'Logout Confirmation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 13, 41, 88), // Title color
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey, // Subtitle color
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // White background for cancel button
                        side: const BorderSide(
                          color: Color.fromARGB(255, 13, 41, 88),
                        ), // Outline border with matching color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color.fromARGB(255, 13, 41, 88), // Text color matching palette
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 13, 41, 88), // Background color matching "Proceed"
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white), // White text
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _logout(); // Call the logout function
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

  void _logout() {
    // Navigate back to the login page, effectively logging the user out
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  // Redesigned paired devices with modern Card UI
Widget _buildPairedDevicesList() {
  return _pairedDevices.isEmpty
      ? const Center(
          child: Text(
            'No paired devices found.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        )
      : ListView.builder(
          itemCount: _pairedDevices.length,
          itemBuilder: (context, index) {
            final device = _pairedDevices[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Icon(Icons.devices, color: const Color.fromARGB(255, 13, 41, 88)),
                title: Text(device.name ?? "Unknown Device"),
                subtitle: Text(device.address!),
                trailing: SizedBox(
                  width: 48, // Ensure the same width for the icon
                  height: 48, // Ensure the same height for the icon
                  child: Center(
                    child: _isConnecting && _selectedDevice == device
                        ? const CircularProgressIndicator()  // Show loading while connecting
                        : _selectedDevice == device
                            ? const Icon(Icons.check_circle, color: Colors.green) // Show check icon when connected
                            : IconButton(
                                icon: const Icon(Icons.print, color: Color.fromARGB(255, 13, 41, 88)),
                                onPressed: () => _connectToDevice(device),
                              ),
                  ),
                ),
              ),
            );
          },
        );
}

  Widget _buildAvailableDevicesList() {
    return _availableDevices.isEmpty
        ? const Center(
            child: Text(
              'No available devices found.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          )
        : ListView.builder(
            itemCount: _availableDevices.length,
            itemBuilder: (context, index) {
              final device = _availableDevices[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(Icons.devices, color: const Color.fromARGB(255, 13, 41, 88)),
                  title: Text(device.name ?? "Unknown Device"),
                  subtitle: Text(device.address!),
                  trailing: IconButton(
                    icon: const Icon(Icons.print, color: Color.fromARGB(255, 13, 41, 88)),
                    onPressed: () => _connectToDevice(device),
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text(
    'Select Printer',
    style: TextStyle(color: Color.fromARGB(255, 13, 41, 88)),
  ),
  backgroundColor: Colors.white,
  elevation: 0,
  automaticallyImplyLeading: false, // Disable the back button
  iconTheme: const IconThemeData(color: Color.fromARGB(255, 13, 41, 88)),
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _startScanning,
      tooltip: 'Re-scan',
    ),
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: _showLogoutConfirmation,
      tooltip: 'Logout',
    ),
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _isScanning
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paired Devices',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 13, 41, 88)),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildPairedDevicesList()),
                  const Divider(),
                  const Text(
                    'Available Devices',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 13, 41, 88)),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildAvailableDevicesList()),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          debugPrint("Collector ID: ${widget.collector_id}");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRViewExample(collectorName: widget.collectorName, collector_id: widget.collector_id),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          'Proceed',
          style: TextStyle(color: Color.fromARGB(255, 13, 41, 88)),
        ),
      ),
    );
  }
}
