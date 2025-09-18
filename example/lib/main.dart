import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:bluetooth_p2p/bluetooth_p2p.dart';
import 'package:permission_handler/permission_handler.dart';
import 'message_screen.dart';

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
  bool _bluetoothEnabled = false;
  bool _isDiscovering = false;
  final List<BluetoothDevice> _discoveredDevices = [];
  List<BluetoothDevice> _pairedDevices = [];
  String _statusMessage = '';
  String _connectionStatus = '';
  String? _connectedDeviceAddress;

  final _bluetoothP2pPlugin = BluetoothP2p();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _setupBluetoothCallbacks();
  }

  void _setupBluetoothCallbacks() {
    _bluetoothP2pPlugin.onDeviceFound = (BluetoothDevice device) {
      setState(() {
        if (!_discoveredDevices.any((d) => d.address == device.address)) {
          _discoveredDevices.add(device);
        }
      });
    };

    _bluetoothP2pPlugin.onDiscoveryFinished = () {
      setState(() {
        _isDiscovering = false;
        _statusMessage =
            'Discovery finished. Found ${_discoveredDevices.length} devices.';
      });
    };

    _bluetoothP2pPlugin.onConnectionResult =
        (bool success, String message, String deviceAddress) {
          setState(() {
            _connectionStatus = success
                ? 'Connected to $deviceAddress'
                : 'Failed: $message';
            if (success) {
              _connectedDeviceAddress = deviceAddress;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Connected successfully!'
                    : 'Connection failed: $message',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        };
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    bool bluetoothEnabled = false;

    try {
      platformVersion =
          await _bluetoothP2pPlugin.getPlatformVersion() ??
          'Unknown platform version';
      bluetoothEnabled = await _bluetoothP2pPlugin.isBluetoothEnabled();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _bluetoothEnabled = bluetoothEnabled;
    });

    await _loadPairedDevices();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every(
      (status) => status == PermissionStatus.granted,
    );

    if (!allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bluetooth permissions are required for this app to work properly.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _startDiscovery() async {
    await _requestPermissions();

    try {
      setState(() {
        _discoveredDevices.clear();
        _isDiscovering = true;
        _statusMessage = 'Starting discovery...';
      });

      final result = await _bluetoothP2pPlugin.startDiscovery();
      setState(() {
        _statusMessage = result;
      });
    } catch (e) {
      setState(() {
        _isDiscovering = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _stopDiscovery() async {
    try {
      final result = await _bluetoothP2pPlugin.stopDiscovery();
      setState(() {
        _isDiscovering = false;
        _statusMessage = result;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping discovery: $e';
      });
    }
  }

  Future<void> _loadPairedDevices() async {
    try {
      final devices = await _bluetoothP2pPlugin.getPairedDevices();
      setState(() {
        _pairedDevices = devices;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading paired devices: $e';
      });
    }
  }

  Future<void> _connectToDevice(String deviceAddress) async {
    try {
      setState(() {
        _connectionStatus = 'Connecting...';
      });

      final result = await _bluetoothP2pPlugin.connectToDevice(deviceAddress);
      setState(() {
        _connectionStatus = result;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: $e';
      });
    }
  }

  void _openMessageScreen(BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          deviceAddress: device.address,
          deviceName: device.name,
        ),
      ),
    );
  }

  Widget _buildDeviceList(String title, List<BluetoothDevice> devices) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (devices.isEmpty)
              const Text('No devices found')
            else
              ...devices.map(
                (device) => ListTile(
                  title: Text(device.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Address: ${device.address}'),
                      Text('Paired: ${device.isPaired ? 'Yes' : 'No'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _connectToDevice(device.address),
                        child: const Text('Connect'),
                      ),
                      const SizedBox(width: 8),
                      if (_connectedDeviceAddress == device.address)
                        ElevatedButton(
                          onPressed: () => _openMessageScreen(device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Message'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth P2P Example'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platform: $_platformVersion'),
                      Text('Bluetooth Enabled: $_bluetoothEnabled'),
                      Row(
                        children: [
                          Text(
                            'Discovery Status: ${_isDiscovering ? 'Discovering...' : 'Stopped'}',
                          ),
                          if (_isDiscovering) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_statusMessage.isNotEmpty)
                        Text('Status: $_statusMessage'),
                      if (_connectionStatus.isNotEmpty)
                        Text('Connection: $_connectionStatus'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isDiscovering ? null : _startDiscovery,
                      child: const Text('Start Discovery'),
                    ),
                    ElevatedButton(
                      onPressed: !_isDiscovering ? null : _stopDiscovery,
                      child: const Text('Stop Discovery'),
                    ),
                    ElevatedButton(
                      onPressed: _loadPairedDevices,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDeviceList('Paired Devices', _pairedDevices),
              _buildDeviceList('Discovered Devices', _discoveredDevices),
            ],
          ),
        ),
      ),
    );
  }
}
