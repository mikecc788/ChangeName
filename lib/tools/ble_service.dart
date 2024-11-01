import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lfs_rename/tools/ble_communication_service.dart';

class BleService implements CommunicationService{
  final List<BluetoothDevice> devicesList =  <BluetoothDevice>[];
  final Guid serviceCharacteristic =
  Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
  final Guid writecharacteristic = Guid("6e400002-b5a3-f393-e0a9-e50e24dcca9e");
  final Guid readcharacteristic = Guid("6e400003-b5a3-f393-e0a9-e50e24dcca9e");

  List<BluetoothService>? _services;
  StreamController<BluetoothDevice>? _scanController;

  @override
  Stream<BluetoothDevice> get bleDeviceStream => _scanController!.stream;
  StreamController<List<int>> ? _rxController;

  @override
  Stream<List<int>> get dispatchStream => _rxController!.stream;
  StreamSubscription? _readDataSubscription;
  StreamSubscription?_scanDevicesSubscription;

  @override
  Future<bool> connectDevice(Object device) async{
    BluetoothDevice bleDevice;
    _isBleConnected = false;
    try {
      bleDevice = device as BluetoothDevice;
    } catch (e) {
      throw 'Invalid Bluetooth device';
    }

    try {
      _isBleConnected = await _connectToDevice(bleDevice, 5);
          if (!_isBleConnected) {
        return false;
      }
    }catch(e){
      if (e.hashCode.toString() != 'already_connected') {
        await bleDevice.disconnect();
        print('Device Already connected : $e');
        return false;
      }
      print('Exception in connectDevice API : $e');
    }finally{
      if (_isBleConnected){
        _services = await bleDevice.discoverServices();
        for (BluetoothService service in _services!) {
          var characteristics = service.characteristics;
          for (BluetoothCharacteristic c in characteristics) {
            if (c.uuid == writecharacteristic) {
              //print('\nble data instance  Write Characteristic\n');
            }
            if (c.uuid == readcharacteristic) {
              _setNotifyforReadBleData(c);
            }
          }
        }
        activeDevice = bleDevice;
        _deviceName = bleDevice.platformName;
      }
    }
    return _isBleConnected;
  }

  Future<bool> _connectToDevice(BluetoothDevice device, int timeout) async {
    Future<bool> ? returnValue;
    await device.connect(autoConnect: false).timeout(Duration(seconds: timeout),
        onTimeout: () {
          print('timeout occured');
          returnValue = Future.value(false);
          device.disconnect();
        }).then((data) {
      if (returnValue == null) {
        print('connection successful');
        returnValue = Future.value(true);
      }
    });

    return returnValue!;
  }

  bool _isBleConnected = false;
  @override
  bool get deviceConnectionStatus => _isBleConnected;

  String _deviceName = "No device connected";
  @override
  String get deviceName => _deviceName;

  BluetoothDevice? activeDevice;
  @override
  void Function(BluetoothDevice p1)? scanResultCallback;


  @override
  Future<bool> disconnectDevice() async{
    if (activeDevice != null) {
      await activeDevice!.disconnect();
      deinitControllers();
      _isBleConnected = false;
      activeDevice = null;
      devicesList.clear();
      _deviceName = "No device connected";
    } else {
      print('activeDevice is null in bleService');
    }
    return true;
  }


  void initControllers(){
    _scanController =StreamController<BluetoothDevice>();
    _scanDevicesSubscription = _scanController!.stream.listen((event) {
      scanResultCallback!.call(event);
    },onError: (error){
      print('initControllers is $error');
    },onDone: ()async{
      print('OnDone called');
    });

    _rxController = StreamController<List<int>>.broadcast();
  }

  void deinitControllers() {
    FlutterBluePlus.stopScan();
    _scanController?.close();
    _scanController = null;
    _rxController?.close();
    _rxController = null;

    _scanDevicesSubscription?.cancel();
    _scanDevicesSubscription = null;
    _readDataSubscription?.cancel();
    _readDataSubscription = null;
  }


  @override
  Future scanDevices() async{
    if(!_isBleConnected){
      FlutterBluePlus.stopScan();
      devicesList.clear();

      initControllers();

      print('Listening devices...');
      _scanDevicesSubscription =
          FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
            for (ScanResult result in results) {
              _addDeviceTolist(result.device);
            }
          });
      debugPrint('Scanning...');
      FlutterBluePlus.startScan(withServices: [serviceCharacteristic]);
    }
  }


  void _addDeviceTolist(final BluetoothDevice device) {
    if (!devicesList.contains(device)) {
      if (_scanController?.hasListener == true) {
        if (device.name != '') {
          devicesList.add(device);
          _scanController!.add(device);
          debugPrint('Adding ${device.name}');
        } else {
          //print('device.name is empty');
        }
      } else {
        //print('_controller has no listener');
      }
    } else {
      debugPrint('${device.name} already in list');
    }
  }

  @override
  Future stopScanningDevices() async{
    print('stopping scan');
    await FlutterBluePlus.stopScan();
    devicesList.clear();
    _scanDevicesSubscription!.cancel();
    _scanDevicesSubscription = null;
  }

  void _setNotifyforReadBleData(BluetoothCharacteristic charc) async {
    await charc.setNotifyValue(true);
    _readDataSubscription = charc.value.listen((value) {
      print('r:$value');
      if (_rxController!.hasListener) {
        _rxController!.add(value);
      } else {
        //print('rxListner not registered');
      }
    });
  }

  @override
  Future writeData(List<int> data) async{
    for (BluetoothService service in _services!) {
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        if (c.uuid == writecharacteristic) {
          await c.write(data, withoutResponse: true);
        }
      }
    }
  }

}