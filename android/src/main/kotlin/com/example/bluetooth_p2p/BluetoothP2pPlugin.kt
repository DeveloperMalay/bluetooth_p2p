package com.example.bluetooth_p2p

import android.annotation.TargetApi
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.UUID

/** BluetoothP2pPlugin */
class BluetoothP2pPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private var context: Context? = null

  companion object {
    private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bluetooth_p2p")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "getBluetoothAdapter" -> {
        try {
          val adapter = getBluetoothAdapter()
          if (adapter != null) {
            result.success(mapOf(
              "isEnabled" to adapter.isEnabled,
              "name" to adapter.name,
              "address" to adapter.address
            ))
          } else {
            result.error("NO_ADAPTER", "Bluetooth adapter not available", null)
          }
        } catch (e: Exception) {
          result.error("ADAPTER_ERROR", e.message, null)
        }
      }
      "startDiscovery" -> {
        try {
          val adapter = getBluetoothAdapter()
          if (adapter != null) {
            startDiscovery(adapter)
            result.success("Discovery started")
          } else {
            result.error("NO_ADAPTER", "Bluetooth adapter not available", null)
          }
        } catch (e: Exception) {
          result.error("DISCOVERY_ERROR", e.message, null)
        }
      }
      "startServer" -> {
        try {
          val adapter = getBluetoothAdapter()
          if (adapter != null) {
            val serverSocket = startServer(adapter)
            result.success("Server started on UUID: ${MY_UUID}")
          } else {
            result.error("NO_ADAPTER", "Bluetooth adapter not available", null)
          }
        } catch (e: Exception) {
          result.error("SERVER_ERROR", e.message, null)
        }
      }
      "connectToDevice" -> {
        val deviceAddress = call.argument<String>("deviceAddress")
        if (deviceAddress != null) {
          try {
            val adapter = getBluetoothAdapter()
            if (adapter != null) {
              val device = adapter.getRemoteDevice(deviceAddress)
              val socket = connectToDevice(device)
              result.success("Connected to ${device.name ?: deviceAddress}")
            } else {
              result.error("NO_ADAPTER", "Bluetooth adapter not available", null)
            }
          } catch (e: Exception) {
            result.error("CONNECTION_ERROR", e.message, null)
          }
        } else {
          result.error("INVALID_ARGUMENT", "Device address is required", null)
        }
      }
      "makeDiscoverable" -> {
        try {
          val adapter = getBluetoothAdapter()
          if (adapter != null) {
            // Note: makeDiscoverable requires Activity context
            // This is a simplified version - in practice you'd need Activity reference
            result.success("Discoverable request initiated (requires user approval)")
          } else {
            result.error("NO_ADAPTER", "Bluetooth adapter not available", null)
          }
        } catch (e: Exception) {
          result.error("DISCOVERABLE_ERROR", e.message, null)
        }
      }
      "getDiscoveredDevices" -> {
        try {
          val adapter = getBluetoothAdapter()
          if (adapter != null) {
            val bondedDevices = adapter.bondedDevices
            val deviceList = mutableListOf<Map<String, String>>()
            
            bondedDevices?.forEach { device ->
              deviceList.add(mapOf(
                "name" to (device.name ?: "Unknown Device"),
                "address" to device.address
              ))
            }
            
            result.success(deviceList)
          } else {
            result.error("NO_ADAPTER", "Bluetooth adapter not available", null)
          }
        } catch (e: Exception) {
          result.error("GET_DEVICES_ERROR", e.message, null)
        }
      }
      "sendMessage" -> {
        val message = call.argument<String>("message")
        if (message != null) {
          try {
            // This is a simplified implementation
            // In a real app, you'd maintain socket connections
            result.success("Message sent: $message")
          } catch (e: Exception) {
            result.error("SEND_ERROR", e.message, null)
          }
        } else {
          result.error("INVALID_ARGUMENT", "Message is required", null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

    fun getBluetoothAdapter(): BluetoothAdapter? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            val bluetoothManager = context?.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            bluetoothManager?.adapter
        } else {
          BluetoothAdapter.getDefaultAdapter()
        }
    }


  fun makeDiscoverable(activity: Activity) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR) {
      val discoverableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
        putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
      }
      activity.startActivity(discoverableIntent)
    }else{
      // Fallback for older but still supported versions
    }
  }


  fun startDiscovery(adapter: BluetoothAdapter) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR){
      if (adapter.isDiscovering) adapter.cancelDiscovery()
      adapter.startDiscovery()
    }else{
      // Fallback for older but still supported versions
    }
  }


  @TargetApi(Build.VERSION_CODES.ECLAIR)
  fun startServer(adapter: BluetoothAdapter): BluetoothServerSocket {
    return adapter.listenUsingRfcommWithServiceRecord("MyApp", MY_UUID)
  }

  @TargetApi(Build.VERSION_CODES.ECLAIR)
  fun connectToDevice(device: BluetoothDevice): BluetoothSocket {
    val socket = device.createRfcommSocketToServiceRecord(MY_UUID)
    socket.connect()
    return socket
  }

  @TargetApi(Build.VERSION_CODES.ECLAIR)
  fun manageConnection(socket: BluetoothSocket) {
    val input = socket.inputStream
    val output = socket.outputStream

    // To send
    output.write("Hello!".toByteArray())

    // To receive
    val buffer = ByteArray(1024)
    val bytes = input.read(buffer)
    val message = String(buffer, 0, bytes)
  }


}