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

  @override
  void initState() {
    super.initState();
    _checkBluetoothAndScan();
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
        const SnackBar(content: Text('Please turn on Bluetooth to proceed.')),
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
      });

      var timeout;
      bluetooth.startScan(timeout: timeout).listen((BluetoothDevice device) {
        if (!_availableDevices.contains(device) && !_pairedDevices.contains(device)) {
          setState(() {
            _availableDevices.add(device);
          });
        }
      });

      bluetooth.isScanning.listen((isScanning) {
        if (!isScanning) {
          setState(() {
            _isScanning = false;
          });

          // Check if there are no paired or available devices
          if (_pairedDevices.isEmpty && _availableDevices.isEmpty) {
            _showManualPairingPrompt();
          }
        }
      });
    } catch (e) {
      print('Error during scanning: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error scanning for devices. Please try again.')),
      );
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Show dialog if no devices are paired or available
  void _showManualPairingPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bluetooth Pairing Required'),
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

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _selectedDevice = device;
      _isConnecting = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to ${device.name}...')),
    );

    bool isConnected = false;
    int retryCount = 0;
    const int maxRetries = 5;

    while (!isConnected && retryCount < maxRetries) {
      try {
        if (!(await bluetooth.isOn)!) {
          throw Exception('Bluetooth is turned off');
        }

        isConnected = (await bluetooth.connect(device))!;

        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${device.name}')),
          );

          bluetooth.onStateChanged().listen((state) {
            if (state == BlueThermalPrinter.DISCONNECTED) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printer disconnected')),
              );
              setState(() {
                _selectedDevice = null;
              });
            }
          });

          return;
        }
      } catch (e) {
        print('Connection attempt ${retryCount + 1} failed: $e');
      }

      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device.name} after $maxRetries attempts.')),
      );
    }

    setState(() {
      _isConnecting = false;
    });
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _logout(); // Call the logout function
              },
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Printer'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
      body: _isScanning
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Paired Devices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _pairedDevices.isEmpty
                    ? const Center(child: Text('No paired devices found.'))
                    : Column(
                        children: _pairedDevices.map((device) {
                          return ListTile(
                            title: Text(device.name ?? "Unknown Device"),
                            subtitle: Text(device.address!),
                            trailing: _isConnecting && _selectedDevice == device
                                ? const CircularProgressIndicator()
                                : _selectedDevice == device
                                    ? const Icon(Icons.check_circle, color: Colors.green) // Icon indicating connection success
                                    : IconButton(
                                        icon: const Icon(Icons.print, color: Color.fromARGB(255, 13, 41, 88)),
                                        onPressed: () => _connectToDevice(device),
                                      ),
                          );
                        }).toList(),
                      ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Available Devices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _availableDevices.isEmpty
                    ? const Center(child: Text('No available devices found.'))
                    : Column(
                        children: _availableDevices.map((device) {
                          return ListTile(
                            title: Text(device.name ?? "Unknown Device"),
                            subtitle: Text(device.address!),
                            trailing: IconButton(
                              icon: const Icon(Icons.print, color: Color.fromARGB(255, 13, 41, 88)),
                              onPressed: () => _connectToDevice(device),
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          debugPrint("Collector ID: ${widget.collector_id}");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRViewExample(collectorName: widget.collectorName, collector_id: widget.collector_id), // Pass the collectorName correctly
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 13, 41, 88),
        label: const Text(
          'Proceed',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

extension on BlueThermalPrinter {
  get isScanning => null;

  startScan({required timeout}) {}
}
