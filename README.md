# Bluetooth P2P Flutter Plugin

A Flutter plugin for peer-to-peer Bluetooth Classic communication between Android devices.

## Features

- 🔍 **Device Discovery**: Find nearby Bluetooth devices
- 🔧 **Server Mode**: Listen for incoming connections  
- 📱 **Client Mode**: Connect to server devices
- 💬 **Message Exchange**: Send and receive data between connected devices
- 🛡️ **Permission Handling**: Proper Android 12+ Bluetooth permissions

## Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  bluetooth_p2p:
    path: ../  # or your plugin path
  permission_handler: ^11.3.1
```

### 2. Request Permissions

```dart
await [
  Permission.bluetooth,
  Permission.bluetoothScan,
  Permission.bluetoothConnect,
  Permission.bluetoothAdvertise,
  Permission.location,
].request();
```

### 3. Basic Usage

```dart
import 'package:flutter/services.dart';

class BluetoothP2P {
  static const MethodChannel _channel = MethodChannel('bluetooth_p2p');

  // Get Bluetooth adapter info
  static Future<Map<String, dynamic>> getBluetoothInfo() async {
    return await _channel.invokeMethod('getBluetoothAdapter');
  }

  // Start discovering devices
  static Future<String> startDiscovery() async {
    return await _channel.invokeMethod('startDiscovery');
  }

  // Start server (Phone A)
  static Future<String> startServer() async {
    return await _channel.invokeMethod('startServer');
  }

  // Connect to device (Phone B)
  static Future<String> connectToDevice(String deviceAddress) async {
    return await _channel.invokeMethod('connectToDevice', {
      'deviceAddress': deviceAddress
    });
  }

  // Send message
  static Future<String> sendMessage(String message) async {
    return await _channel.invokeMethod('sendMessage', {
      'message': message
    });
  }
}
```

## Testing the Example App

### Setting up Two Phones

**Prerequisites:**
- Pair both phones in Android Bluetooth settings first
- Grant all Bluetooth permissions when prompted

**Phone A (Server):**
1. Install the example app
2. Tap "1. Request Permissions" 
3. Tap "2. Get Bluetooth Info"
4. Tap "3a. Make Discoverable" (makes device discoverable)
5. Tap "3c. Start Server" (starts listening for connections)

**Phone B (Client):**
1. Install the example app  
2. Tap "1. Request Permissions"
3. Tap "2. Get Bluetooth Info" 
4. Tap "3b. Start Discovery" (finds paired devices)
5. Tap "4. Connect to [Device Name]" (connect to Phone A)
6. Tap "5. Send Test Message"

### Available Methods

| Method | Description |
|--------|-------------|
| `getBluetoothAdapter()` | Get adapter info (enabled, name, address) |
| `makeDiscoverable()` | Make device discoverable for 5 minutes |
| `startDiscovery()` | Start scanning for nearby devices |
| `getDiscoveredDevices()` | Get list of paired/bonded devices |
| `startServer()` | Start listening for connections |
| `connectToDevice(address)` | Connect to a specific device |
| `sendMessage(message)` | Send text message to connected device |

## Technical Details

### Android Implementation

- **UUID**: `00001101-0000-1000-8000-00805F9B34FB` (Serial Port Profile)
- **Protocol**: Bluetooth Classic RFCOMM
- **API Level**: Minimum SDK 21 (Android 5.0)
- **Permissions**: Full Android 12+ Bluetooth permission support

### Architecture

```
Flutter App (Dart)
      ↕ Method Channel
Android Plugin (Kotlin)
      ↕ Bluetooth APIs
Android Bluetooth Stack
      ↕ RFCOMM
Bluetooth Hardware
```

## Known Limitations

- Android only (iOS has limited Bluetooth Classic support)
- Requires devices to be in close proximity (10-100m typical range)
- No automatic pairing - uses service discovery
- Single UUID for all connections

## Development

Run the example app:

```bash
cd example
flutter pub get
flutter run
```

Build plugin:

```bash
flutter pub get
flutter build apk --debug
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure all Bluetooth permissions are granted
2. **Discovery Not Working**: Check location permission (required for Bluetooth scan)
3. **Connection Failed**: Verify both devices have Bluetooth enabled and are discoverable
4. **Build Errors**: Update Android NDK to version 27.0.12077973

### Debug Steps

1. Check `flutter doctor` for Android setup
2. Verify device Bluetooth is enabled  
3. Test with two physical Android devices
4. Check Android logs: `flutter logs`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test on physical Android devices
4. Submit a pull request

## License

This project is licensed under the MIT License.