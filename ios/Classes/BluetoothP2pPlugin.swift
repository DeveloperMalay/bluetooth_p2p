import Flutter
import UIKit
import CoreBluetooth

public class BluetoothP2pPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {
  private var channel: FlutterMethodChannel?
  private var centralManager: CBCentralManager?
  private var discoveredPeripherals: [CBPeripheral] = []
  private var isScanning: Bool = false
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "bluetooth_p2p", binaryMessenger: registrar.messenger())
    let instance = BluetoothP2pPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getBatteryPercentage":
      getBatteryPercentage(result: result)
    case "isBluetoothEnabled":
      result(centralManager?.state == .poweredOn)
    case "startBluetoothScan":
      startBluetoothScan(result: result)
    case "stopBluetoothScan":
      stopBluetoothScan(result: result)
    case "getDiscoveredDevices":
      getDiscoveredDevices(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func getBatteryPercentage(result: @escaping FlutterResult) {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let batteryLevel = UIDevice.current.batteryLevel
    UIDevice.current.isBatteryMonitoringEnabled = false
    
    if batteryLevel < 0 {
      result(FlutterError(code: "BATTERY_ERROR", message: "Unable to get battery information", details: nil))
    } else {
      result(Int(batteryLevel * 100))
    }
  }
  
  private func startBluetoothScan(result: @escaping FlutterResult) {
    guard let centralManager = centralManager else {
      result(FlutterError(code: "BLUETOOTH_NOT_AVAILABLE", message: "Bluetooth manager not available", details: nil))
      return
    }
    
    if centralManager.state != .poweredOn {
      result(FlutterError(code: "BLUETOOTH_DISABLED", message: "Bluetooth is not enabled", details: nil))
      return
    }
    
    if isScanning {
      result(FlutterError(code: "ALREADY_SCANNING", message: "Bluetooth scan is already in progress", details: nil))
      return
    }
    
    // Clear previous results
    discoveredPeripherals.removeAll()
    
    // Start scanning for peripherals
    centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    isScanning = true
    
    // Stop scanning after 10 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
      self.stopScanning()
    }
    
    result("Bluetooth scan started successfully")
  }
  
  private func stopBluetoothScan(result: @escaping FlutterResult) {
    stopScanning()
    result("Bluetooth scan stopped successfully")
  }
  
  private func stopScanning() {
    if isScanning {
      centralManager?.stopScan()
      isScanning = false
      notifyDiscoveryFinished()
    }
  }
  
  private func getDiscoveredDevices(result: @escaping FlutterResult) {
    let deviceList: [[String: Any]] = discoveredPeripherals.map { peripheral in
      return [
        "name": peripheral.name ?? "Unknown Device",
        "address": peripheral.identifier.uuidString,
        "type": getDeviceType(peripheral: peripheral),
        "bondState": getBondState(peripheral: peripheral),
        "rssi": "Unknown"
      ]
    }
    result(deviceList)
  }
  
  private func getDeviceType(peripheral: CBPeripheral) -> Int {
    // iOS doesn't provide classic Bluetooth type info, assume BLE
    return 2 // LE type
  }
  
  private func getBondState(peripheral: CBPeripheral) -> Int {
    // iOS doesn't expose bond state directly, return unpaired
    return 10 // BOND_NONE equivalent
  }
  
  private func notifyDeviceFound(peripheral: CBPeripheral) {
    let deviceMap: [String: Any] = [
      "name": peripheral.name ?? "Unknown Device",
      "address": peripheral.identifier.uuidString,
      "type": getDeviceType(peripheral: peripheral),
      "bondState": getBondState(peripheral: peripheral)
    ]
    channel?.invokeMethod("onDeviceFound", arguments: deviceMap)
  }
  
  private func notifyDiscoveryFinished() {
    let result: [String: Any] = [
      "totalDevicesFound": discoveredPeripherals.count
    ]
    channel?.invokeMethod("onDiscoveryFinished", arguments: result)
  }
  
  // MARK: - CBCentralManagerDelegate
  
  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
      print("Bluetooth is powered on")
    case .poweredOff:
      print("Bluetooth is powered off")
    case .resetting:
      print("Bluetooth is resetting")
    case .unauthorized:
      print("Bluetooth is unauthorized")
    case .unsupported:
      print("Bluetooth is unsupported")
    case .unknown:
      print("Bluetooth state is unknown")
    @unknown default:
      print("Unknown Bluetooth state")
    }
  }
  
  public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
    // Add to discovered peripherals if not already present
    if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
      discoveredPeripherals.append(peripheral)
      notifyDeviceFound(peripheral: peripheral)
    }
  }
}
