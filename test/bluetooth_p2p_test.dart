import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_p2p/bluetooth_p2p.dart';
import 'package:bluetooth_p2p/bluetooth_p2p_platform_interface.dart';
import 'package:bluetooth_p2p/bluetooth_p2p_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBluetoothP2pPlatform
    with MockPlatformInterfaceMixin
    implements BluetoothP2pPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BluetoothP2pPlatform initialPlatform = BluetoothP2pPlatform.instance;

  test('$MethodChannelBluetoothP2p is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBluetoothP2p>());
  });

  test('getPlatformVersion', () async {
    BluetoothP2p bluetoothP2pPlugin = BluetoothP2p();
    MockBluetoothP2pPlatform fakePlatform = MockBluetoothP2pPlatform();
    BluetoothP2pPlatform.instance = fakePlatform;

    expect(await bluetoothP2pPlugin.getPlatformVersion(), '42');
  });
}
