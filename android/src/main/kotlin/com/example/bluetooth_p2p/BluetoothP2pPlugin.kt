package com.example.bluetooth_p2p

import android.content.Context
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Intent
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BluetoothP2pPlugin: FlutterPlugin, MethodCallHandler {

    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var bluetoothAdapter: BluetoothAdapter? = null

    companion object {
        private const val CHANNEL = "bluetooth_p2p"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        bluetoothAdapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            val bluetoothManager = context?.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            bluetoothManager?.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isBluetoothSupported" -> result.success(isBluetoothSupported())
            "isBluetoothEnabled" -> result.success(isBluetoothEnabled())
            "hasBluetoothPermissions" -> result.success(hasBluetoothPermissions())
            "getPairedDevices" -> result.success(getPairedDevices())
            "startDiscovery" -> result.success(startDiscovery())
            "stopDiscovery" -> result.success(stopDiscovery())
            "connectToDevice" -> {
                val address = call.argument<String>("address")
                if (address != null) {
                    result.success(connectToDevice(address))
                } else {
                    result.error("INVALID_ARGUMENT", "Device address is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun isBluetoothSupported(): Boolean {
        return bluetoothAdapter != null
    }

    fun isBluetoothEnabled(): Boolean {
        return try {
            bluetoothAdapter?.isEnabled == true
        } catch (e: SecurityException) {
            Log.e("BluetoothP2pPlugin", "Permission required: ${e.message}")
            false
        }
    }

    fun requestEnableBluetooth(): Intent? {
        return if (bluetoothAdapter?.isEnabled == false) {
            Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        } else null
    }

    fun hasBluetoothPermissions(): Boolean {
        context?.let { ctx ->
            val bluetoothPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                ctx.checkSelfPermission(Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED
            } else {
                true
            }

            val bluetoothAdminPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                ctx.checkSelfPermission(Manifest.permission.BLUETOOTH_ADMIN) == PackageManager.PERMISSION_GRANTED
            } else {
                true
            }

            val locationPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                ctx.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            } else {
                true
            }

            return bluetoothPermission && bluetoothAdminPermission && locationPermission
        }
        return false
    }

    fun getPairedDevices(): List<Map<String, String>> {
        val devices: MutableList<Map<String, String>> = mutableListOf()

        if (hasBluetoothPermissions() && bluetoothAdapter != null) {
            try {
                bluetoothAdapter!!.bondedDevices?.forEach { device ->
                    devices.add(mapOf(
                        "name" to (device.name ?: "Unknown"),
                        "address" to device.address
                    ))
                }
            } catch (e: SecurityException) {
                // Handle permission error
                Log.e("BluetoothP2pPlugin", "Security exception: ${e.message}")
            }
        }

        return devices.toList()
    }

    fun startDiscovery(): Boolean {
        return if (hasBluetoothPermissions() && bluetoothAdapter != null) {
            try {
                bluetoothAdapter!!.startDiscovery()
            } catch (e: SecurityException) {
                Log.e("BluetoothP2pPlugin", "Security exception: ${e.message}")
                false
            }
        } else false
    }

    fun stopDiscovery(): Boolean {
        return try {
            bluetoothAdapter?.let { adapter ->
                if (adapter.isDiscovering) {
                    adapter.cancelDiscovery()
                } else {
                    true
                }
            } ?: true
        } catch (e: SecurityException) {
            Log.e("BluetoothP2pPlugin", "Security exception: ${e.message}")
            false
        }
    }

    fun connectToDevice(address: String): Boolean {
        if (!hasBluetoothPermissions() || bluetoothAdapter == null) {
            return false
        }

        return try {
            val device = bluetoothAdapter!!.getRemoteDevice(address)
            // Add your connection logic here
            true
        } catch (e: Exception) {
            Log.e("BluetoothP2pPlugin", "Connection error: ${e.message}")
            false
        }
    }
}