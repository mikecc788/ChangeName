import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';

typedef DisconnectedCallback = void Function();
typedef ConnectedCallback = void Function();

class LFSBleManager{
  // final BluetoothDevice device;
  // DisconnectedCallback disconnectedCallback;
  // LFSBleManager({required this.device,});

  Future<void> _setMTU(int value,BluetoothDevice device) async {
    final startMtu = await device.mtu.first;
    debugPrint('Default MTU $startMtu');
    await device.requestMtu(
        value).timeout(const Duration(seconds: 2)); // I would await this regardless, set a timeout if you are concerned
    var mtuChanged = Completer<void>();
    // await Future.delayed(const Duration(seconds: 1));
// mtu is of type 'int'
    var mtuStreamSubscription = device.mtu.listen((mtu) {
      if (mtu == value) {
        debugPrint('Current MTU: $mtu',);
        mtuChanged.complete();
      }
    });

    await mtuChanged.future; // set timeout and catch exception
    mtuStreamSubscription.cancel();
    // await mtuChanged.future.timeout(const Duration(seconds: 2)).catchError(
    //         (dynamic error) =>
    //         debugPrint(error.toString())); // set timeout and catch exception
    // mtuStreamSubscription.cancel();
  }

  connectBle(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: true).timeout(const Duration(seconds: 4));
      // await _setMTU(128, device);
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  listenBleConnect(DisconnectedCallback disconnectedCallback,ConnectedCallback connectedCallback,BluetoothDevice device){
    device.state.listen((event) {
      if(event == BluetoothDeviceState.disconnected){
        disconnectedCallback();
      }else if(event == BluetoothDeviceState.connected){
        connectedCallback();
      }
    });
  }

}