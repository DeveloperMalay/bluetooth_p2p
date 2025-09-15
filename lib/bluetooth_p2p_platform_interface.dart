import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluetooth_p2p_method_channel.dart';

abstract class BluetoothP2pPlatform extends PlatformInterface {
  /// Constructs a BluetoothP2pPlatform.
  BluetoothP2pPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluetoothP2pPlatform _instance = MethodChannelBluetoothP2p();

  /// The default instance of [BluetoothP2pPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluetoothP2p].
  static BluetoothP2pPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluetoothP2pPlatform] when
  /// they register themselves.
  static set instance(BluetoothP2pPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<int> getBatteryPercentage() {
    throw UnimplementedError('getBatteryPercentage() has not been implemented.');
  }

  Future<bool> isBluetoothEnabled() {
    throw UnimplementedError('isBluetoothEnabled() has not been implemented.');
  }

  Future<String> startBluetoothScan() {
    throw UnimplementedError('startBluetoothScan() has not been implemented.');
  }

  Future<String> stopBluetoothScan() {
    throw UnimplementedError('stopBluetoothScan() has not been implemented.');
  }

  Future<List<Map<String, dynamic>>> getDiscoveredDevices() {
    throw UnimplementedError('getDiscoveredDevices() has not been implemented.');
  }

  Future<List<Map<String, dynamic>>> getPairedDevices() {
    throw UnimplementedError('getPairedDevices() has not been implemented.');
  }

  Future<String> connectToDevice(String deviceAddress) {
    throw UnimplementedError('connectToDevice() has not been implemented.');
  }
}
