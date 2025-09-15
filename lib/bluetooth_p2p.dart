
import 'package:flutter/services.dart';
import 'bluetooth_p2p_platform_interface.dart';

class BluetoothDevice {
  final String name;
  final String address;
  final int type;
  final int bondState;
  final String rssi;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.type,
    required this.bondState,
    this.rssi = 'Unknown',
  });

  factory BluetoothDevice.fromMap(Map<String, dynamic> map) {
    return BluetoothDevice(
      name: map['name'] ?? 'Unknown Device',
      address: map['address'] ?? '',
      type: map['type'] ?? 0,
      bondState: map['bondState'] ?? 0,
      rssi: map['rssi']?.toString() ?? 'Unknown',
    );
  }

  bool get isPaired => bondState == 12; // BluetoothDevice.BOND_BONDED = 12
  
  String get deviceTypeString {
    switch (type) {
      case 1:
        return 'Classic';
      case 2:
        return 'LE';
      case 3:
        return 'Dual';
      default:
        return 'Unknown';
    }
  }
}

class BluetoothP2p {
  static const MethodChannel _channel = MethodChannel('bluetooth_p2p');
  
  // Callback functions
  Function(BluetoothDevice)? onDeviceFound;
  Function()? onDiscoveryFinished;
  Function(bool success, String message, String deviceAddress)? onConnectionResult;

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
    }
  }

  Future<String?> getPlatformVersion() {
    return BluetoothP2pPlatform.instance.getPlatformVersion();
  }

  Future<int> getBatteryPercentage() {
    return BluetoothP2pPlatform.instance.getBatteryPercentage();
  }

  Future<bool> isBluetoothEnabled() {
    return BluetoothP2pPlatform.instance.isBluetoothEnabled();
  }

  Future<String> startDiscovery() {
    return BluetoothP2pPlatform.instance.startBluetoothScan();
  }

  Future<String> stopDiscovery() {
    return BluetoothP2pPlatform.instance.stopBluetoothScan();
  }

  Future<List<BluetoothDevice>> getDiscoveredDevices() async {
    final devices = await BluetoothP2pPlatform.instance.getDiscoveredDevices();
    return devices.map((device) => BluetoothDevice.fromMap(device)).toList();
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    final devices = await BluetoothP2pPlatform.instance.getPairedDevices();
    return devices.map((device) => BluetoothDevice.fromMap(device)).toList();
  }

  Future<String> connectToDevice(String deviceAddress) {
    return BluetoothP2pPlatform.instance.connectToDevice(deviceAddress);
  }
}
