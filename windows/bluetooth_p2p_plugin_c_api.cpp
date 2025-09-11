#include "include/bluetooth_p2p/bluetooth_p2p_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "bluetooth_p2p_plugin.h"

void BluetoothP2pPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  bluetooth_p2p::BluetoothP2pPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
