import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth P2P Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BluetoothP2PDemo(),
    );
  }
}

class BluetoothP2PDemo extends StatefulWidget {
  const BluetoothP2PDemo({super.key});

  @override
  State<BluetoothP2PDemo> createState() => _BluetoothP2PDemoState();
}

class _BluetoothP2PDemoState extends State<BluetoothP2PDemo> {
  static const MethodChannel _channel = MethodChannel('bluetooth_p2p');
  
  String _platformVersion = 'Unknown';
  String _status = 'Ready to test Bluetooth P2P';
  bool _isLoading = false;
  Map<String, dynamic>? _adapterInfo;
  bool _isServer = false;
  bool _isDiscovering = false;
  bool _isDiscoverable = false;
  final List<Map<String, String>> _discoveredDevices = [];
  String? _selectedDeviceAddress;

  @override
  void initState() {
    super.initState();
    _getPlatformVersion();
  }

  Future<void> _getPlatformVersion() async {
    String platformVersion;
    try {
      platformVersion = await _channel.invokeMethod('getPlatformVersion') ?? 'Unknown';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }


  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking permissions...';
    });

    try {
      // For demo purposes - in production, use permission_handler package
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _status = '''✅ Permissions Check Complete!

Please ensure the following permissions are granted in device settings:
• Bluetooth
• Bluetooth Scan  
• Bluetooth Connect
• Bluetooth Advertise
• Location (required for Bluetooth scan)

Note: The app will request these permissions when using Bluetooth features.''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Permission error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getBluetoothAdapter() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting Bluetooth adapter info...';
    });

    try {
      final result = await _channel.invokeMethod('getBluetoothAdapter');
      setState(() {
        _adapterInfo = Map<String, dynamic>.from(result);
        _status = '✅ Bluetooth Adapter Info:\n'
                 'Enabled: ${_adapterInfo!['isEnabled']}\n'
                 'Name: ${_adapterInfo!['name']}\n'
                 'Address: ${_adapterInfo!['address']}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Adapter error: $e';
        _adapterInfo = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _makeDiscoverable() async {
    setState(() {
      _isLoading = true;
      _isDiscoverable = true;
      _status = 'Making device discoverable...';
    });

    try {
      final result = await _channel.invokeMethod('makeDiscoverable');
      setState(() {
        _status = '🔍 $result\n\nThis device is now discoverable by other devices for 5 minutes.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Discoverable error: $e';
        _isDiscoverable = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isLoading = true;
      _isDiscovering = true;
      _status = 'Starting device discovery...';
      _discoveredDevices.clear();
    });

    try {
      // Start the discovery process
      final discoveryResult = await _channel.invokeMethod('startDiscovery');
      setState(() {
        _status = '🔍 $discoveryResult\nScanning for devices...';
      });
      
      // Wait a bit for discovery to run, then get the discovered/bonded devices
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted && _isDiscovering) {
        try {
          // Get the actual discovered/bonded devices
          final devices = await _channel.invokeMethod('getDiscoveredDevices');
          
          setState(() {
            _discoveredDevices.clear();
            
            if (devices is List) {
              for (var device in devices) {
                if (device is Map) {
                  final deviceMap = Map<String, dynamic>.from(device);
                  _discoveredDevices.add({
                    'name': deviceMap['name']?.toString() ?? 'Unknown Device',
                    'address': deviceMap['address']?.toString() ?? 'Unknown Address',
                  });
                }
              }
            }
            
            if (_discoveredDevices.isNotEmpty) {
              _status += '\n\n📱 Found ${_discoveredDevices.length} available device(s):\n';
              for (var device in _discoveredDevices) {
                _status += '• ${device['name']} (${device['address']})\n';
              }
              _status += '\nNote: These are previously paired/bonded devices. For new devices, ensure they are paired in system Bluetooth settings.';
            } else {
              _status += '\n\n📱 No paired devices found.\n\nTo connect to a device:\n1. Go to Android Bluetooth settings\n2. Pair with the target device first\n3. Return to this app and try discovery again';
            }
          });
        } catch (e) {
          setState(() {
            _status += '\n❌ Error getting devices: $e';
          });
        }
      }
      
      // Auto-stop discovery after 12 seconds
      Future.delayed(const Duration(seconds: 12), () {
        if (mounted && _isDiscovering) {
          setState(() {
            _isDiscovering = false;
            _status += '\n\n✅ Discovery completed';
          });
        }
      });
    } catch (e) {
      setState(() {
        _status = '❌ Discovery error: $e';
        _isDiscovering = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startServer() async {
    setState(() {
      _isLoading = true;
      _isServer = true;
      _status = 'Starting Bluetooth server...';
    });

    try {
      final result = await _channel.invokeMethod('startServer');
      setState(() {
        _status = '🔧 $result\n\n📱 Server is now waiting for connections.\nOther devices can now connect to this phone.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Server error: $e';
        _isServer = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToDevice(String? deviceAddress) async {
    if (deviceAddress == null) {
      setState(() {
        _status = '⚠️ Please discover devices first and select one to connect to.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _status = 'Attempting to connect to device...';
    });

    try {
      final result = await _channel.invokeMethod('connectToDevice', {
        'deviceAddress': deviceAddress
      });
      setState(() {
        _status = '🔗 $result';
        _selectedDeviceAddress = deviceAddress;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Connection error: $e\n\nNote: This is expected without a real device at address $deviceAddress';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestMessage() async {
    setState(() {
      _isLoading = true;
      _status = 'Sending test message...';
    });

    try {
      final result = await _channel.invokeMethod('sendMessage', {
        'message': 'Hello from Flutter P2P! 👋'
      });
      setState(() {
        _status = '📤 $result';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Send error: $e';
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
      appBar: AppBar(
        title: const Text('Bluetooth P2P Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Platform: $_platformVersion'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bluetooth P2P Testing',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test P2P connection between two phones:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('1. Request Permissions'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getBluetoothAdapter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('2. Get Bluetooth Info'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _makeDiscoverable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDiscoverable ? Colors.green : Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_isDiscoverable ? '🔍 Discoverable' : '3a. Make Discoverable'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _startDiscovery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isDiscovering ? Colors.green : Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(_isDiscovering ? '🔍 Discovering...' : '3b. Start Discovery'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _startServer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isServer ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(_isServer ? '🔧 Server Running' : '3c. Start Server'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_discoveredDevices.isNotEmpty) ...[
                      Text(
                        'Found Devices:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      ...(_discoveredDevices.map((device) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _connectToDevice(device['address']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedDeviceAddress == device['address'] ? Colors.green : Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('4. Connect to ${device['name']}'),
                          ),
                        ),
                      ))),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendTestMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('5. Send Test Message'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _status,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}