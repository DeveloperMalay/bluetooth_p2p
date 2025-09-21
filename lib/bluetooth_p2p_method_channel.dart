import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluetooth_p2p_platform_interface.dart';

/// An implementation of [BluetoothP2pPlatform] that uses method channels.
class MethodChannelBluetoothP2p extends BluetoothP2pPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bluetooth_p2p');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    final enabled = await methodChannel.invokeMethod<bool>('isBluetoothEnabled');
    return enabled ?? false;
  }

  @override
  Future<String> startDiscovery() async {
    final result = await methodChannel.invokeMethod<String>('startDiscovery');
    return result ?? 'Failed to start discovery';
  }

  @override
  Future<String> stopDiscovery() async {
    final result = await methodChannel.invokeMethod<String>('stopDiscovery');
    return result ?? 'Failed to stop discovery';
  }

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async {
    final result = await methodChannel.invokeMethod<List>('getDiscoveredDevices');
    return result?.cast<Map<String, dynamic>>() ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> getPairedDevices() async {
    final result = await methodChannel.invokeMethod<List>('getPairedDevices');
    return result?.cast<Map<String, dynamic>>() ?? [];
  }

  @override
  Future<String> connectToDevice(String deviceAddress) async {
    final result = await methodChannel.invokeMethod<String>('connectToDevice', {
      'deviceAddress': deviceAddress,
    });
    return result ?? 'Failed to connect to device';
  }

  @override
  Future<String> startServer() async {
    final result = await methodChannel.invokeMethod<String>('startServer');
    return result ?? 'Failed to start server';
  }

  @override
  Future<String> stopServer() async {
    final result = await methodChannel.invokeMethod<String>('stopServer');
    return result ?? 'Failed to stop server';
  }

  @override
  Future<String> makeDiscoverable() async {
    final result = await methodChannel.invokeMethod<String>('makeDiscoverable');
    return result ?? 'Failed to make discoverable';
  }
}
