#ifndef FLUTTER_PLUGIN_BLUETOOTH_P2P_PLUGIN_H_
#define FLUTTER_PLUGIN_BLUETOOTH_P2P_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace bluetooth_p2p {

class BluetoothP2pPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  BluetoothP2pPlugin();

  virtual ~BluetoothP2pPlugin();

  // Disallow copy and assign.
  BluetoothP2pPlugin(const BluetoothP2pPlugin&) = delete;
  BluetoothP2pPlugin& operator=(const BluetoothP2pPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace bluetooth_p2p

#endif  // FLUTTER_PLUGIN_BLUETOOTH_P2P_PLUGIN_H_
