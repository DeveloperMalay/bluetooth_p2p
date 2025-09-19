import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:bluetooth_p2p/bluetooth_p2p.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  int _batteryPercentage = 0;
  bool _bluetoothEnabled = false;
  bool _isScanning = false;
  final List<BluetoothDevice> _discoveredDevices = [];
  String _statusMessage = '';
  bool _hasPermissions = false;
  int _permissionAttempts = 0;
  static const int maxPermissionAttempts = 3;

  final _bluetoothPlugin = BluetoothP2p();

  @override
  void initState() {
    super.initState();
    // Delay initialization until after first frame when MaterialApp is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupBluetoothCallbacks();
      _initializeApp();
    });
  }

  void _setupBluetoothCallbacks() {
    _bluetoothPlugin.onDeviceFound = (BluetoothDevice device) {
      setState(() {
        if (!_discoveredDevices.any((d) => d.address == device.address)) {
          _discoveredDevices.add(device);
        }
      });
    };

    _bluetoothPlugin.onDiscoveryFinished = () {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan finished. Found ${_discoveredDevices.length} devices.';
      });
    };
  }

  Future<void> _initializeApp() async {
    // First request permissions
    if (await _requestBluetoothPermissions()) {
      // Only initialize if permissions are granted
      initPlatformState();
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    _permissionAttempts++;
    
    List<Permission> permissions = [];
    
    if (Theme.of(context).platform == TargetPlatform.android) {
      // Android 12+ permissions
      if (await _isAndroid12OrHigher()) {
        permissions.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]);
      } else {
        // Pre-Android 12 permissions
        permissions.addAll([
          Permission.bluetooth,
          Permission.location,
        ]);
      }
    } else if (Theme.of(context).platform == TargetPlatform.iOS || 
               Theme.of(context).platform == TargetPlatform.macOS) {
      // iOS and macOS use the same Bluetooth permissions
      permissions.addAll([
        Permission.bluetooth,
      ]);
    }

    if (permissions.isEmpty) {
      setState(() {
        _hasPermissions = true;
        _statusMessage = 'Permissions granted (iOS/other platforms)';
      });
      return true;
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    setState(() {
      _hasPermissions = allGranted;
      if (allGranted) {
        _statusMessage = 'Bluetooth permissions granted';
      } else {
        _statusMessage = 'Some permissions denied (Attempt $_permissionAttempts/$maxPermissionAttempts)';
      }
    });

    if (!allGranted && _permissionAttempts < maxPermissionAttempts) {
      // Show dialog to explain why permissions are needed
      if (mounted) {
        await _showPermissionDialog();
      }
    } else if (!allGranted) {
      setState(() {
        _statusMessage = 'Permissions permanently denied. Please enable them in settings.';
      });
      if (mounted) {
        await _showSettingsDialog();
      }
    }

    return allGranted;
  }

  Future<bool> _isAndroid12OrHigher() async {
    try {
      return await Permission.bluetoothScan.isDenied;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showPermissionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bluetooth Permissions Required'),
          content: const Text(
            'This app needs Bluetooth permissions to scan for and connect to devices. '
            'Please grant the permissions to continue.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                Future.microtask(() => _requestBluetoothPermissions());
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSettingsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Bluetooth permissions are required for this app to function. '
            'Please enable them in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    int batteryPercentage = 0;
    bool bluetoothEnabled = false;

    try {
      platformVersion = await _bluetoothPlugin.getPlatformVersion() ?? 'Unknown platform version';
      batteryPercentage = await _bluetoothPlugin.getBatteryPercentage();
      bluetoothEnabled = await _bluetoothPlugin.isBluetoothEnabled();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
      batteryPercentage = 0;
      bluetoothEnabled = false;
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _batteryPercentage = batteryPercentage;
      _bluetoothEnabled = bluetoothEnabled;
    });
  }

  Future<void> _refreshBatteryPercentage() async {
    try {
      final percentage = await _bluetoothPlugin.getBatteryPercentage();
      setState(() {
        _batteryPercentage = percentage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting battery percentage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshBluetoothStatus() async {
    try {
      final enabled = await _bluetoothPlugin.isBluetoothEnabled();
      setState(() {
        _bluetoothEnabled = enabled;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking Bluetooth status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startBluetoothScan() async {
    // Check permissions first
    if (!_hasPermissions) {
      bool granted = await _requestBluetoothPermissions();
      if (!granted) {
        setState(() {
          _statusMessage = 'Permissions required to start scanning';
        });
        return;
      }
    }

    try {
      setState(() {
        _discoveredDevices.clear();
        _isScanning = true;
        _statusMessage = 'Starting Bluetooth scan...';
      });

      final result = await _bluetoothPlugin.startDiscovery();
      setState(() {
        _statusMessage = result;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error: $e';
      });
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error starting scan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (scaffoldError) {
          // ScaffoldMessenger not available yet, just update status
          setState(() {
            _statusMessage = 'Error starting scan: $e';
          });
        }
      }
    }
  }

  Future<void> _stopBluetoothScan() async {
    try {
      final result = await _bluetoothPlugin.stopDiscovery();
      setState(() {
        _isScanning = false;
        _statusMessage = result;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping scan: $e';
      });
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error stopping scan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (scaffoldError) {
          // ScaffoldMessenger not available yet, just update status
          setState(() {
            _statusMessage = 'Error stopping scan: $e';
          });
        }
      }
    }
  }

  Widget _buildDeviceCard(BluetoothDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        leading: Icon(
          device.isPaired ? Icons.bluetooth_connected : Icons.bluetooth,
          color: device.isPaired ? Colors.blue : Colors.grey,
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${device.address}'),
            Text('Type: ${device.deviceTypeString}'),
            Text('Paired: ${device.isPaired ? 'Yes' : 'No'}'),
            if (device.rssi != 'Unknown') Text('RSSI: ${device.rssi}'),
          ],
        ),
        trailing: device.isPaired 
          ? const Icon(Icons.verified, color: Colors.green)
          : const Icon(Icons.info_outline, color: Colors.orange),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth Scanner Example'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // System Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Platform: $_platformVersion'),
                      Row(
                        children: [
                          Text('Battery: $_batteryPercentage%'),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _refreshBatteryPercentage,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Bluetooth: ${_bluetoothEnabled ? 'Enabled' : 'Disabled'}'),
                          const SizedBox(width: 16),
                          Text('Permissions: ${_hasPermissions ? 'Granted' : 'Required'}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _refreshBluetoothStatus,
                            child: const Text('Check'),
                          ),
                          const SizedBox(width: 8),
                          if (!_hasPermissions)
                            ElevatedButton(
                              onPressed: _requestBluetoothPermissions,
                              child: const Text('Request Permissions'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bluetooth Scanning Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bluetooth Scanner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Status: ${_isScanning ? 'Scanning...' : 'Stopped'}'),
                      if (_statusMessage.isNotEmpty)
                        Text('Message: $_statusMessage'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: (_isScanning || !_bluetoothEnabled || !_hasPermissions) ? null : _startBluetoothScan,
                            child: const Text('Start Scan'),
                          ),
                          ElevatedButton(
                            onPressed: !_isScanning ? null : _stopBluetoothScan,
                            child: const Text('Stop Scan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Discovered Devices
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discovered Devices (${_discoveredDevices.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_discoveredDevices.isEmpty)
                        const Text('No devices found. Start a scan to discover Bluetooth devices.')
                      else
                        ..._discoveredDevices.map((device) => _buildDeviceCard(device)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}