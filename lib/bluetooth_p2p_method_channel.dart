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
  Future<int> getBatteryPercentage() async {
    final percentage = await methodChannel.invokeMethod<int>('getBatteryPercentage');
    return percentage ?? 0;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    final enabled = await methodChannel.invokeMethod<bool>('isBluetoothEnabled');
    return enabled ?? false;
  }

  @override
  Future<String> startBluetoothScan() async {
    final result = await methodChannel.invokeMethod<String>('startBluetoothScan');
    return result ?? 'Failed to start scan';
  }

  @override
  Future<String> stopBluetoothScan() async {
    final result = await methodChannel.invokeMethod<String>('stopBluetoothScan');
    return result ?? 'Failed to stop scan';
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
}
