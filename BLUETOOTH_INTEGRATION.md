# Bluetooth P2P Integration Guide

This document explains how to use the Bluetooth device discovery and connection features in your Flutter app.

## Features

- **Device Discovery**: Search for nearby Bluetooth devices
- **Device Connection**: Connect to discovered or paired devices  
- **Paired Devices**: Get list of already paired devices
- **Real-time Callbacks**: Receive notifications about discovery events and connection results
- **Permission Management**: Automatic handling of Android 12+ and legacy Bluetooth permissions

## Usage Example

```dart
import 'package:bluetooth_p2p/bluetooth_p2p.dart';

class BluetoothManager {
  final BluetoothP2p _bluetooth = BluetoothP2p();
  
  void initializeBluetooth() {
    // Set up callbacks
    _bluetooth.onDeviceFound = (BluetoothDevice device) {
      print('Found device: ${device.name} (${device.address})');
    };
    
    _bluetooth.onDiscoveryFinished = () {
      print('Discovery completed');
    };
    
    _bluetooth.onConnectionResult = (bool success, String message, String deviceAddress) {
      if (success) {
        print('Connected to $deviceAddress');
      } else {
        print('Connection failed: $message');
      }
    };
  }
  
  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    return await _bluetooth.isBluetoothEnabled();
  }
  
  // Start device discovery
  Future<void> startDiscovery() async {
    try {
      final result = await _bluetooth.startDiscovery();
      print('Discovery started: $result');
    } catch (e) {
      print('Error starting discovery: $e');
    }
  }
  
  // Stop device discovery
  Future<void> stopDiscovery() async {
    try {
      final result = await _bluetooth.stopDiscovery();
      print('Discovery stopped: $result');
    } catch (e) {
      print('Error stopping discovery: $e');
    }
  }
  
  // Get discovered devices
  Future<List<BluetoothDevice>> getDiscoveredDevices() async {
    return await _bluetooth.getDiscoveredDevices();
  }
  
  // Get paired devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await _bluetooth.getPairedDevices();
  }
  
  // Connect to a device
  Future<void> connectToDevice(String deviceAddress) async {
    try {
      final result = await _bluetooth.connectToDevice(deviceAddress);
      print('Connection initiated: $result');
    } catch (e) {
      print('Error connecting: $e');
    }
  }
}
```

## BluetoothDevice Properties

```dart
class BluetoothDevice {
  final String name;        // Device name (e.g., "John's Phone")
  final String address;     // MAC address (e.g., "12:34:56:78:90:AB")  
  final int type;          // Device type (classic, BLE, etc.)
  final int bondState;     // Pairing state
  
  bool get isPaired => bondState == 12; // Helper to check if paired
}
```

## Required Permissions

The plugin handles permissions automatically, but you need to add them to your `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Bluetooth permissions for older Android versions -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Bluetooth permissions for Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />

<!-- Bluetooth feature requirement -->
<uses-feature 
    android:name="android.hardware.bluetooth" 
    android:required="true" />
```

## Permission Handling

Add `permission_handler` to your `pubspec.yaml`:

```yaml
dependencies:
  permission_handler: ^11.3.1
```

Then request permissions in your app:

```dart
Future<void> requestBluetoothPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.location,
  ].request();
  
  // Handle permission results
}
```

## Error Handling

Common error codes:
- `BLUETOOTH_NOT_AVAILABLE`: Device doesn't support Bluetooth
- `BLUETOOTH_DISABLED`: Bluetooth is turned off  
- `PERMISSION_DENIED`: Required permissions not granted
- `DISCOVERY_FAILED`: Failed to start device discovery
- `CONNECTION_ERROR`: Failed to connect to device

## Example App

Check the `example/` folder for a complete implementation showing:
- Device discovery UI
- Paired devices list
- Connection buttons
- Status indicators
- Permission management

Run the example with:
```bash
cd example
flutter run
```