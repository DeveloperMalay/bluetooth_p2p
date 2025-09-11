
import 'bluetooth_p2p_platform_interface.dart';

class BluetoothP2p {
  Future<String?> getPlatformVersion() {
    return BluetoothP2pPlatform.instance.getPlatformVersion();
  }
}
