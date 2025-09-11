package com.example.bluetooth_p2p

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


/** BluetoothP2pPlugin */
class BluetoothP2pPlugin :
    FlutterPlugin,
    MethodCallHandler, StreamHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var eventSink: EventChannel.EventSink? = null
    private var socket: BluetoothSocket? = null
    private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB") // Standard SPP

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bluetooth_p2p")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "scanDevices" -> {
                val devices = bluetoothAdapter?.bondedDevices?.map { "${it.name} | ${it.address}" } ?: emptyList()
                result.success(devices)
            }
            "connect" -> {
                val deviceId = call.argument<String>("deviceId")
                val device = bluetoothAdapter?.getRemoteDevice(deviceId)
                Thread {
                    try {
                        socket = device?.createRfcommSocketToServiceRecord(MY_UUID)
                        bluetoothAdapter?.cancelDiscovery()
                        socket?.connect()
                        listenForMessages()
                        result.success(true)
                    } catch (e: IOException) {
                        Log.e("BluetoothP2P", "Connection failed", e)
                        result.success(false)
                    }
                }.start()
            }
            "sendMessage" -> {
                val message = call.argument<String>("message")
                Thread {
                    try {
                        socket?.outputStream?.write(message?.toByteArray())
                        result.success(true)
                    } catch (e: IOException) {
                        Log.e("BluetoothP2P", "Send failed", e)
                        result.success(false)
                    }
                }.start()
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
