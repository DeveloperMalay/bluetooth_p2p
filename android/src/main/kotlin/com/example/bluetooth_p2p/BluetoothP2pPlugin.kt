package com.example.bluetooth_p2p

import android.Manifest
import android.annotation.TargetApi
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.UUID

/** BluetoothP2pPlugin */
class BluetoothP2pPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  private lateinit var channel : MethodChannel
  private var context: Context? = null
  private var activity: Activity? = null
  private var pendingResult: Result? = null

  companion object {
    private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private const val BLUETOOTH_PERMISSION_REQUEST_CODE = 1001
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
      "requestBluetoothPermissions" -> {
        if (!hasBluetoothPermissions()) {
          requestBluetoothPermissions(result)
        } else {
          result.success("Permissions already granted")
        }
      }
      "getBluetoothAdapter" -> {
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
          return
        }
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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
          return
        }
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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
          return
        }
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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
          return
        }
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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
          return
        }
        try {
          val adapter = getBluetoothAdapter()
          if (adapter != null) {
            makeDiscoverable(activity!!)
            result.success("Discoverable request initiated (requires user approval)")
          } else {
            result.error("NO_ADAPTER", "Bluetooth adapter not available", null)
          }
        } catch (e: Exception) {
          result.error("DISCOVERABLE_ERROR", e.message, null)
        }
      }
      "getDiscoveredDevices" -> {
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
          return
        }
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

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
    if (requestCode == BLUETOOTH_PERMISSION_REQUEST_CODE) {
      val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
      if (allGranted) {
        pendingResult?.success("Permissions granted")
      } else {
        pendingResult?.error("PERMISSION_DENIED", "Bluetooth permissions are required", null)
      }
      pendingResult = null
      return true
    }
    return false
  }

  private fun hasBluetoothPermissions(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      ContextCompat.checkSelfPermission(context!!, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
      ContextCompat.checkSelfPermission(context!!, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
    } else {
      ContextCompat.checkSelfPermission(context!!, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED &&
      ContextCompat.checkSelfPermission(context!!, Manifest.permission.BLUETOOTH_ADMIN) == PackageManager.PERMISSION_GRANTED
    }
  }

  private fun requestBluetoothPermissions(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity not available for permission request", null)
      return
    }

    pendingResult = result
    val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      arrayOf(
        Manifest.permission.BLUETOOTH_CONNECT,
        Manifest.permission.BLUETOOTH_SCAN,
        Manifest.permission.BLUETOOTH_ADVERTISE
      )
    } else {
      arrayOf(
        Manifest.permission.BLUETOOTH,
        Manifest.permission.BLUETOOTH_ADMIN,
        Manifest.permission.ACCESS_FINE_LOCATION
      )
    }

    ActivityCompat.requestPermissions(activity!!, permissions, BLUETOOTH_PERMISSION_REQUEST_CODE)
  }

  private fun getBluetoothAdapter(): BluetoothAdapter? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            val bluetoothManager = context?.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            bluetoothManager?.adapter
        } else {
          BluetoothAdapter.getDefaultAdapter()
        }
    }


  private fun makeDiscoverable(activity: Activity) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR) {
      val discoverableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
        putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
      }
      activity.startActivity(discoverableIntent)
    }else{
      // Fallback for older but still supported versions
    }
  }


  private fun startDiscovery(adapter: BluetoothAdapter) {
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