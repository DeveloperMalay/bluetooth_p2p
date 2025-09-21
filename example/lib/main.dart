import 'package:flutter/material.dart';
import 'package:bluetooth_p2p/bluetooth_p2p.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth P2P Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const P2PChatScreen(),
    );
  }
}

class P2PChatScreen extends StatefulWidget {
  const P2PChatScreen({super.key});

  @override
  State<P2PChatScreen> createState() => _P2PChatScreenState();
}

class _P2PChatScreenState extends State<P2PChatScreen> {
  final BluetoothP2p _bluetooth = BluetoothP2p();
  final List<BluetoothDevice> _discoveredDevices = [];
  final List<String> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  
  bool _isServer = false;
  bool _isConnected = false;
  bool _isDiscovering = false;
  String _status = 'Choose your role';
  String? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _setupBluetoothCallbacks();
    _requestPermissions();
  }

  void _setupBluetoothCallbacks() {
    _bluetooth.onDeviceFound = (device) {
      setState(() {
        if (!_discoveredDevices.any((d) => d.address == device.address)) {
          _discoveredDevices.add(device);
        }
      });
    };

    _bluetooth.onDiscoveryFinished = () {
      setState(() {
        _isDiscovering = false;
        _status = 'Discovery finished. Found ${_discoveredDevices.length} devices.';
      });
    };

    _bluetooth.onConnectionResult = (success, message, deviceAddress) {
      setState(() {
        _isConnected = success;
        _connectedDevice = success ? deviceAddress : null;
        _status = message;
      });
      
      if (success) {
        _addMessage('📱 Connected to $deviceAddress');
      }
    };

    _bluetooth.onMessageReceived = (message) {
      _addMessage('📨 $message');
    };
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();
  }

  void _addMessage(String message) {
    setState(() {
      _messages.add(message);
    });
  }

  // Phone A (Server) - Opens server socket and waits
  Future<void> _startServer() async {
    setState(() {
      _status = 'Starting server...';
    });
    
    final result = await _bluetooth.startServer();
    setState(() {
      _isServer = true;
      _status = result;
    });
    _addMessage('🏠 Server started - waiting for connections');
  }

  // Phone B (Client) - Scans for devices
  Future<void> _startDiscovery() async {
    setState(() {
      _discoveredDevices.clear();
      _isDiscovering = true;
      _status = 'Scanning for devices...';
    });
    
    final result = await _bluetooth.startDiscovery();
    setState(() {
      _status = result;
    });
  }

  // Phone B connects to Phone A
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _status = 'Connecting to ${device.name}...';
    });
    
    final result = await _bluetooth.connectToDevice(device.address);
    setState(() {
      _status = result;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || !_isConnected) return;
    
    final message = _messageController.text;
    final success = await _bluetooth.sendMessage(message);
    
    if (success) {
      _addMessage('📤 You: $message');
      _messageController.clear();
    } else {
      _addMessage('❌ Failed to send message');
    }
  }

  Future<void> _disconnect() async {
    await _bluetooth.disconnect();
    await _bluetooth.stopServer();
    
    setState(() {
      _isConnected = false;
      _isServer = false;
      _connectedDevice = null;
      _status = 'Disconnected';
      _discoveredDevices.clear();
    });
    _addMessage('🔌 Disconnected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth P2P Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _disconnect,
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: $_status',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_connectedDevice != null)
                    Text('Connected to: $_connectedDevice'),
                  if (_isServer)
                    const Text('Role: Server (Phone A)', 
                      style: TextStyle(color: Colors.green)),
                  if (_isDiscovering)
                    const Text('Role: Client (Phone B)', 
                      style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
          ),
          
          // Action Buttons
          if (!_isConnected) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    '🔹 Phone A: Start Server',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isServer ? null : _startServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isServer ? 'Server Running' : 'Start Server'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '🔹 Phone B: Find & Connect',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isDiscovering ? null : _startDiscovery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isDiscovering ? 'Scanning...' : 'Scan for Devices'),
                    ),
                  ),
                ],
              ),
            ),
            
            // Device List
            if (_discoveredDevices.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Found Devices:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(device.name),
                        subtitle: Text(device.address),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(device),
                          child: const Text('Connect'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
          
          // Chat Interface
          if (_isConnected) ...[
            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(_messages[index]),
                  );
                },
              ),
            ),
            
            // Message Input
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}