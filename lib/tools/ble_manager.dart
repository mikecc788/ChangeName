import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

typedef DisconnectedCallback = void Function();
typedef ConnectedCallback = void Function();

class LFSBleManager{

  connectBle(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: true).timeout(const Duration(seconds: 4));
      // await _setMTU(128, device);
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  listenBleConnect(DisconnectedCallback disconnectedCallback,ConnectedCallback connectedCallback,BluetoothDevice device){
    device.connectionState.listen((event) {
      if(event == BluetoothConnectionState.disconnected){
        disconnectedCallback();
      }else if(event == BluetoothConnectionState.connected){
        connectedCallback();
      }
    });
  }
}
