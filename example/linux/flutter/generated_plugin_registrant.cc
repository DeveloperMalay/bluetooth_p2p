//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <bluetooth_p2p/bluetooth_p2p_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) bluetooth_p2p_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "BluetoothP2pPlugin");
  bluetooth_p2p_plugin_register_with_registrar(bluetooth_p2p_registrar);
}
