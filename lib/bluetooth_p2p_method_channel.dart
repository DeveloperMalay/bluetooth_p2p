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
}
