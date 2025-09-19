package com.example.bluetooth_p2p

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** BluetoothP2pPlugin */
class BluetoothP2pPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var discoveredDevices: MutableList<BluetoothDevice> = mutableListOf()
    private var isScanning = false

    private val discoveryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(
                        BluetoothDevice.EXTRA_DEVICE, 
                        BluetoothDevice::class.java
                    )
                    device?.let {
                        if (!discoveredDevices.any { d -> d.address == it.address }) {
                            discoveredDevices.add(it)
                            notifyDeviceFound(it)
                        }
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    isScanning = false
                    notifyDiscoveryFinished()
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bluetooth_p2p")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        // Initialize Bluetooth adapter
        val bluetoothManager = context?.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        bluetoothAdapter = bluetoothManager?.adapter
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "getBatteryPercentage" -> {
                getBatteryPercentage(result)
            }
            "isBluetoothEnabled" -> {
                result.success(bluetoothAdapter?.isEnabled ?: false)
            }
            "startBluetoothScan" -> {
                startBluetoothScan(result)
            }
            "stopBluetoothScan" -> {
                stopBluetoothScan(result)
            }
            "getDiscoveredDevices" -> {
                getDiscoveredDevices(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        try {
            context?.unregisterReceiver(discoveryReceiver)
        } catch (e: IllegalArgumentException) {
            // Receiver was not registered
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        // Activity binding for permissions if needed
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // Handle configuration changes
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        // Handle configuration changes
    }

    override fun onDetachedFromActivity() {
        // Clean up activity binding
    }

    private fun getBatteryPercentage(result: Result) {
        try {
            val batteryIntent = context?.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            
            val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            
            if (level == -1 || scale == -1) {
                result.error("BATTERY_ERROR", "Unable to get battery information", null)
                return
            }
            
            val batteryPercentage = (level * 100 / scale.toFloat()).toInt()
            result.success(batteryPercentage)
            
        } catch (e: Exception) {
            result.error("BATTERY_ERROR", "Error getting battery percentage: ${e.message}", null)
        }
    }

    private fun startBluetoothScan(result: Result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_NOT_AVAILABLE", "Bluetooth is not available on this device", null)
            return
        }

        if (!bluetoothAdapter!!.isEnabled) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
            return
        }

        if (!hasBluetoothPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions are not granted", null)
            return
        }

        if (isScanning) {
            result.error("ALREADY_SCANNING", "Bluetooth scan is already in progress", null)
            return
        }

        try {
            // Clear previous results
            discoveredDevices.clear()
            
            // Register broadcast receiver for device discovery
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_FOUND)
                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            }
            context?.registerReceiver(discoveryReceiver, filter)
            
            // Double-check permissions before making Bluetooth calls
            if (hasBluetoothPermissions()) {
                // Cancel any ongoing discovery
                if (bluetoothAdapter!!.isDiscovering) {
                    bluetoothAdapter!!.cancelDiscovery()
                }
                
                // Start discovery
                isScanning = bluetoothAdapter!!.startDiscovery()
            } else {
                result.error("PERMISSION_DENIED", "Bluetooth permissions lost during execution", null)
                return
            }
            
            if (isScanning) {
                result.success("Bluetooth scan started successfully")
            } else {
                result.error("SCAN_FAILED", "Failed to start Bluetooth scan", null)
            }
            
        } catch (e: Exception) {
            result.error("SCAN_ERROR", "Error starting Bluetooth scan: ${e.message}", null)
        }
    }

    private fun stopBluetoothScan(result: Result) {
        try {
            if (hasBluetoothPermissions() && bluetoothAdapter?.isDiscovering == true) {
                bluetoothAdapter!!.cancelDiscovery()
            }
            
            isScanning = false
            
            try {
                context?.unregisterReceiver(discoveryReceiver)
            } catch (e: IllegalArgumentException) {
                // Receiver was not registered
            }
            
            result.success("Bluetooth scan stopped successfully")
            
        } catch (e: Exception) {
            result.error("STOP_SCAN_ERROR", "Error stopping Bluetooth scan: ${e.message}", null)
        }
    }

    private fun getDiscoveredDevices(result: Result) {
        if (!hasBluetoothPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions are not granted", null)
            return
        }
        
        try {
            val deviceList = discoveredDevices.map { device ->
                mapOf(
                    "name" to (if (hasBluetoothPermissions()) device.name ?: "Unknown Device" else "Permission Denied"),
                    "address" to device.address,
                    "type" to device.type,
                    "bondState" to device.bondState,
                    "rssi" to "Unknown" // RSSI would need additional implementation
                )
            }
            result.success(deviceList)
        } catch (e: Exception) {
            result.error("GET_DEVICES_ERROR", "Error getting discovered devices: ${e.message}", null)
        }
    }

    private fun hasBluetoothPermissions(): Boolean {
        val context = this.context ?: return false
        
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ permissions
            ActivityCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            // Pre-Android 12 permissions
            ActivityCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun notifyDeviceFound(device: BluetoothDevice) {
        if (!hasBluetoothPermissions()) return
        
        val deviceMap = mapOf(
            "name" to (if (hasBluetoothPermissions()) device.name ?: "Unknown Device" else "Permission Denied"),
            "address" to device.address,
            "type" to device.type,
            "bondState" to device.bondState
        )
        channel.invokeMethod("onDeviceFound", deviceMap)
    }

    private fun notifyDiscoveryFinished() {
        channel.invokeMethod("onDiscoveryFinished", mapOf(
            "totalDevicesFound" to discoveredDevices.size
        ))
    }
}