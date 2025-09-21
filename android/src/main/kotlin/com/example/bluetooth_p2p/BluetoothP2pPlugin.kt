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
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
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