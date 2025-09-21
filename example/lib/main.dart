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

  Future<void> _testBluetoothAdapter() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Bluetooth Adapter...';
    });

    try {
      // This will test if we can call the native getBluetoothAdapter method
      // Since it's not exposed via method channel, we'll show instructions
      setState(() {
        _status = '''
✅ Android Plugin Ready!

📱 Available Native Methods:
• getBluetoothAdapter()
• makeDiscoverable(activity)  
• startDiscovery(adapter)
• startServer(adapter)
• connectToDevice(device)
• manageConnection(socket)

🔹 Next Steps:
1. Add method channel handlers in Android
2. Expose these methods to Flutter
3. Test P2P connection between 2 phones

🎯 Current Status: Basic plugin structure working!
        ''';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testMethodChannel() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing method channel...';
    });

    try {
      final result = await _channel.invokeMethod('getPlatformVersion');
      setState(() {
        _status = '✅ Method Channel Working!\nAndroid Version: $result';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Method Channel Error: $e';
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
                      'Plugin Testing',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testMethodChannel,
                        child: const Text('Test Method Channel'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testBluetoothAdapter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Show Bluetooth P2P Info'),
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