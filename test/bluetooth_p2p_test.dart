import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_p2p/bluetooth_p2p_platform_interface.dart';
import 'package:bluetooth_p2p/bluetooth_p2p_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBluetoothP2pPlatform
    with MockPlatformInterfaceMixin
    implements BluetoothP2pPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String> connectToDevice(String deviceAddress) {
    // TODO: implement connectToDevice
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() {
    // TODO: implement getDiscoveredDevices
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getPairedDevices() {
    // TODO: implement getPairedDevices
    throw UnimplementedError();
  }

  @override
  Future<bool> isBluetoothEnabled() {
    // TODO: implement isBluetoothEnabled
    throw UnimplementedError();
  }

  @override
  Future<String> startDiscovery() {
    // TODO: implement startDiscovery
    throw UnimplementedError();
  }

  @override
  Future<String> stopDiscovery() {
    // TODO: implement stopDiscovery
    throw UnimplementedError();
  }

  @override
  Future<String> makeDiscoverable() {
    // TODO: implement makeDiscoverable
    throw UnimplementedError();
  }

  @override
  Future<String> startServer() {
    // TODO: implement startServer
    throw UnimplementedError();
  }

  @override
  Future<String> stopServer() {
    // TODO: implement stopServer
    throw UnimplementedError();
  }
}

void main() {
  final BluetoothP2pPlatform initialPlatform = BluetoothP2pPlatform.instance;

  test('$MethodChannelBluetoothP2p is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBluetoothP2p>());
  });

  // test('getPlatformVersion', () async {
  //   BluetoothP2p bluetoothP2pPlugin = BluetoothP2p();
  //   MockBluetoothP2pPlatform fakePlatform = MockBluetoothP2pPlatform();
  //   BluetoothP2pPlatform.instance = fakePlatform;

  //   expect(await bluetoothP2pPlugin.getPlatformVersion(), '42');
  // });
}
