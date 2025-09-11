import 'package:flutter/services.dart';

import 'bluetooth_p2p_platform_interface.dart';

class BluetoothP2p {
  static const MethodChannel _channel = MethodChannel('bluetooth_p2p');
  static const EventChannel _eventChannel = EventChannel(
    'bluetooth_p2p_events',
  );

  Future<String?> getPlatformVersion() {
    return BluetoothP2pPlatform.instance.getPlatformVersion();
  }

  static Future<List<String>> scanDevices() async {
    final devices = await _channel.invokeMethod<List>('scanDevices');
    return devices?.cast<String>() ?? [];
  }

  static Future<bool> connect(String deviceId) async {
    final result = await _channel.invokeMethod<bool>('connect', {
      'deviceId': deviceId,
    });
    return result ?? false;
  }

  static Future<bool> sendMessage(String deviceId, String message) async {
    final result = await _channel.invokeMethod<bool>('sendMessage', {
      'deviceId': deviceId,
      'message': message,
    });
    return result ?? false;
  }

  // Listen for incoming messages
  static Stream<String> get onMessageReceived =>
      _eventChannel.receiveBroadcastStream().cast<String>();
}
