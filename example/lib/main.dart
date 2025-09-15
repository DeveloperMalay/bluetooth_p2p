import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:bluetooth_p2p/bluetooth_p2p.dart';

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
  List<BluetoothDevice> _discoveredDevices = [];
  String _statusMessage = '';

  final _bluetoothPlugin = BluetoothP2p();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // Delay callback setup until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupBluetoothCallbacks();
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

    _bluetoothPlugin.onDiscoveryFinished = (int totalDevices) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan finished. Found $totalDevices devices.';
      });
    };
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
    try {
      setState(() {
        _discoveredDevices.clear();
        _isScanning = true;
        _statusMessage = 'Starting Bluetooth scan...';
      });

      final result = await _bluetoothPlugin.startBluetoothScan();
      setState(() {
        _statusMessage = result;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopBluetoothScan() async {
    try {
      final result = await _bluetoothPlugin.stopBluetoothScan();
      setState(() {
        _isScanning = false;
        _statusMessage = result;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping scan: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _refreshBluetoothStatus,
                            child: const Text('Check'),
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
                            onPressed: (_isScanning || !_bluetoothEnabled) ? null : _startBluetoothScan,
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
                        ..._discoveredDevices.map((device) => _buildDeviceCard(device)).toList(),
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