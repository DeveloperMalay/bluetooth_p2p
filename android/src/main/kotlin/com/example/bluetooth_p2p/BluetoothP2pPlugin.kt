package com.example.bluetooth_p2p

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID

/** BluetoothP2pPlugin */
class BluetoothP2pPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var discoveredDevices: MutableList<BluetoothDevice> = mutableListOf()
    private var isDiscovering = false
    private val MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private var connectedSockets: MutableMap<String, BluetoothSocket> = mutableMapOf()
    private var messageListeners: MutableMap<String, Thread> = mutableMapOf()
    
    private val discoveryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    device?.let {
                        if (!discoveredDevices.contains(it)) {
                            discoveredDevices.add(it)
                            notifyDeviceFound(it)
                        }
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    isDiscovering = false
                    notifyDiscoveryFinished()
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bluetooth_p2p")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "isBluetoothEnabled" -> {
                result.success(bluetoothAdapter?.isEnabled ?: false)
            }
            "startDiscovery" -> {
                startBluetoothDiscovery(result)
            }
            "stopDiscovery" -> {
                stopBluetoothDiscovery(result)
            }
            "getDiscoveredDevices" -> {
                getDiscoveredDevices(result)
            }
            "connectToDevice" -> {
                val deviceAddress = call.argument<String>("deviceAddress")
                if (deviceAddress != null) {
                    connectToDevice(deviceAddress, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Device address is required", null)
                }
            }
            "getPairedDevices" -> {
                getPairedDevices(result)
            }
            "sendMessage" -> {
                val message = call.argument<String>("message")
                val deviceAddress = call.argument<String>("deviceAddress")
                if (message != null && deviceAddress != null) {
                    sendMessage(message, deviceAddress, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Message and device address are required", null)
                }
            }
            "disconnect" -> {
                val deviceAddress = call.argument<String>("deviceAddress")
                if (deviceAddress != null) {
                    disconnect(deviceAddress, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Device address is required", null)
                }
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
        // Activity binding if needed for permissions
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

    @SuppressLint("MissingPermission")
    private fun startBluetoothDiscovery(result: Result) {
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

        discoveredDevices.clear()
        
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }
        
        context?.registerReceiver(discoveryReceiver, filter)
        
        if (bluetoothAdapter!!.isDiscovering) {
            bluetoothAdapter!!.cancelDiscovery()
        }
        
        isDiscovering = bluetoothAdapter!!.startDiscovery()
        
        if (isDiscovering) {
            result.success("Discovery started successfully")
        } else {
            result.error("DISCOVERY_FAILED", "Failed to start device discovery", null)
        }
    }

    @SuppressLint("MissingPermission")
    private fun stopBluetoothDiscovery(result: Result) {
        if (bluetoothAdapter?.isDiscovering == true) {
            bluetoothAdapter!!.cancelDiscovery()
        }
        isDiscovering = false
        
        try {
            context?.unregisterReceiver(discoveryReceiver)
        } catch (e: IllegalArgumentException) {
            // Receiver was not registered
        }
        
        result.success("Discovery stopped successfully")
    }

    @SuppressLint("MissingPermission")
    private fun getDiscoveredDevices(result: Result) {
        val deviceList = discoveredDevices.map { device ->
            mapOf(
                "name" to (device.name ?: "Unknown Device"),
                "address" to device.address,
                "type" to device.type,
                "bondState" to device.bondState
            )
        }
        result.success(deviceList)
    }

    @SuppressLint("MissingPermission")
    private fun getPairedDevices(result: Result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_NOT_AVAILABLE", "Bluetooth is not available on this device", null)
            return
        }

        if (!hasBluetoothPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions are not granted", null)
            return
        }

        val pairedDevices = bluetoothAdapter!!.bondedDevices
        val deviceList = pairedDevices.map { device ->
            mapOf(
                "name" to (device.name ?: "Unknown Device"),
                "address" to device.address,
                "type" to device.type,
                "bondState" to device.bondState
            )
        }
        result.success(deviceList)
    }

    @SuppressLint("MissingPermission")
    private fun connectToDevice(deviceAddress: String, result: Result) {
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

        try {
            val device = bluetoothAdapter!!.getRemoteDevice(deviceAddress)
            
            // Cancel discovery to improve connection performance
            if (bluetoothAdapter!!.isDiscovering) {
                bluetoothAdapter!!.cancelDiscovery()
            }
            
            // Create a socket connection in a separate thread
            Thread {
                var socket: BluetoothSocket? = null
                try {
                    socket = device.createRfcommSocketToServiceRecord(MY_UUID)
                    socket.connect()
                    
                    // Store the connected socket
                    connectedSockets[deviceAddress] = socket
                    
                    // Start listening for messages
                    startMessageListener(socket, deviceAddress)
                    
                    // Connection successful
                    notifyConnectionResult(true, "Connected to ${device.name ?: device.address}", deviceAddress)
                    
                } catch (e: IOException) {
                    try {
                        // Try alternative connection method
                        val fallbackSocket = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                            .invoke(device, 1) as BluetoothSocket
                        fallbackSocket.connect()
                        socket = fallbackSocket
                        
                        // Store the connected socket
                        connectedSockets[deviceAddress] = fallbackSocket
                        
                        // Start listening for messages
                        startMessageListener(fallbackSocket, deviceAddress)
                        
                        notifyConnectionResult(true, "Connected to ${device.name ?: device.address}", deviceAddress)
                        
                    } catch (e2: Exception) {
                        socket?.close()
                        notifyConnectionResult(false, "Failed to connect: ${e2.message}", deviceAddress)
                    }
                }
            }.start()
            
            result.success("Connection attempt started")
            
        } catch (e: Exception) {
            result.error("CONNECTION_ERROR", "Error initiating connection: ${e.message}", null)
        }
    }

    private fun hasBluetoothPermissions(): Boolean {
        val context = this.context ?: return false
        
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    @SuppressLint("MissingPermission")
    private fun notifyDeviceFound(device: BluetoothDevice) {
        val deviceMap = mapOf(
            "name" to (device.name ?: "Unknown Device"),
            "address" to device.address,
            "type" to device.type,
            "bondState" to device.bondState
        )
        channel.invokeMethod("onDeviceFound", deviceMap)
    }

    private fun notifyDiscoveryFinished() {
        channel.invokeMethod("onDiscoveryFinished", null)
    }

    private fun notifyConnectionResult(success: Boolean, message: String, deviceAddress: String) {
        val result = mapOf(
            "success" to success,
            "message" to message,
            "deviceAddress" to deviceAddress
        )
        channel.invokeMethod("onConnectionResult", result)
    }

    private fun sendMessage(message: String, deviceAddress: String, result: Result) {
        val socket = connectedSockets[deviceAddress]
        if (socket == null) {
            result.error("NOT_CONNECTED", "No active connection to device $deviceAddress", null)
            return
        }

        Thread {
            try {
                val outputStream: OutputStream = socket.outputStream
                outputStream.write(message.toByteArray())
                outputStream.flush()
                result.success(true)
            } catch (e: IOException) {
                result.error("SEND_ERROR", "Failed to send message: ${e.message}", null)
            }
        }.start()
    }

    private fun disconnect(deviceAddress: String, result: Result) {
        val socket = connectedSockets[deviceAddress]
        val listener = messageListeners[deviceAddress]
        
        try {
            listener?.interrupt()
            socket?.close()
            connectedSockets.remove(deviceAddress)
            messageListeners.remove(deviceAddress)
            result.success(true)
        } catch (e: IOException) {
            result.error("DISCONNECT_ERROR", "Failed to disconnect: ${e.message}", null)
        }
    }

    private fun startMessageListener(socket: BluetoothSocket, deviceAddress: String) {
        val listenerThread = Thread {
            try {
                val inputStream: InputStream = socket.inputStream
                val buffer = ByteArray(1024)
                
                while (!Thread.currentThread().isInterrupted) {
                    try {
                        val bytesRead = inputStream.read(buffer)
                        if (bytesRead > 0) {
                            val message = String(buffer, 0, bytesRead)
                            notifyMessageReceived(message, deviceAddress)
                        }
                    } catch (e: IOException) {
                        break
                    }
                }
            } catch (e: IOException) {
                // Connection lost
            }
        }
        
        messageListeners[deviceAddress] = listenerThread
        listenerThread.start()
    }

    private fun notifyMessageReceived(message: String, deviceAddress: String) {
        val result = mapOf(
            "message" to message,
            "deviceAddress" to deviceAddress
        )
        channel.invokeMethod("onMessageReceived", result)
    }
}
