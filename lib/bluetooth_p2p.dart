
import 'package:flutter/services.dart';

class BluetoothDevice {
  final String name;
  final String address;
  final int type;
  final int bondState;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.type,
    required this.bondState,
  });

  factory BluetoothDevice.fromMap(Map<String, dynamic> map) {
    return BluetoothDevice(
      name: map['name'] ?? 'Unknown Device',
      address: map['address'] ?? '',
      type: map['type'] ?? 0,
      bondState: map['bondState'] ?? 0,
    );
  }

  bool get isPaired => bondState == 12; // BluetoothDevice.BOND_BONDED = 12
}

class BluetoothP2p {
  static const MethodChannel _channel = MethodChannel('bluetooth_p2p');
  
  // Simple callbacks for P2P communication
  Function(BluetoothDevice)? onDeviceFound;
  Function()? onDiscoveryFinished;
  Function(bool success, String message, String deviceAddress)? onConnectionResult;
  Function(String message)? onMessageReceived;

  BluetoothP2p() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeviceFound':
        if (onDeviceFound != null) {
          final device = BluetoothDevice.fromMap(call.arguments);
          onDeviceFound!(device);
        }
        break;
      case 'onDiscoveryFinished':
        if (onDiscoveryFinished != null) {
          onDiscoveryFinished!();
        }
        break;
      case 'onConnectionResult':
        if (onConnectionResult != null) {
          final args = call.arguments as Map;
          onConnectionResult!(
            args['success'] ?? false,
            args['message'] ?? '',
            args['deviceAddress'] ?? '',
          );
        }
        break;
      case 'onMessageReceived':
        if (onMessageReceived != null) {
          final message = call.arguments as String;
          onMessageReceived!(message);
        }
        break;
    }
  }

  // Core P2P Methods
  
  Future<bool> isBluetoothEnabled() async {
    final result = await _channel.invokeMethod<bool>('isBluetoothEnabled');
    return result ?? false;
  }

  Future<String> startServer() async {
    final result = await _channel.invokeMethod<String>('startServer');
    return result ?? 'Failed to start server';
  }

  Future<String> stopServer() async {
    final result = await _channel.invokeMethod<String>('stopServer');
    return result ?? 'Failed to stop server';
  }

  Future<String> startDiscovery() async {
    final result = await _channel.invokeMethod<String>('startDiscovery');
    return result ?? 'Failed to start discovery';
  }

  Future<String> stopDiscovery() async {
    final result = await _channel.invokeMethod<String>('stopDiscovery');
    return result ?? 'Failed to stop discovery';
  }

  Future<String> connectToDevice(String deviceAddress) async {
    final result = await _channel.invokeMethod<String>('connectToDevice', {
      'deviceAddress': deviceAddress,
    });
    return result ?? 'Failed to connect';
  }

  Future<bool> sendMessage(String message) async {
    try {
      final result = await _channel.invokeMethod('sendMessage', {
        'message': message,
      });
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final result = await _channel.invokeMethod('disconnect');
      return result as bool;
    } catch (e) {
      return false;
    }
  }
}
