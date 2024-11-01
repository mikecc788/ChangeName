import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:lfs_rename/res/resources.dart';
import 'package:lfs_rename/scan_device.dart';
import 'package:lfs_rename/tools/ble_manager.dart';
import 'package:lfs_rename/widgets/search_list_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  void requestPermission() async {
    final status = await Permission.bluetooth.request();
    if (status.isGranted) {
      await Permission.bluetoothConnect.request();
      var status1 = await Permission.bluetoothScan.request();
      if (status1.isGranted) {
        await Permission.bluetoothAdvertise.request();
      }
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    requestPermission();
    return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: StreamBuilder<BluetoothAdapterState>(
            stream: FlutterBluePlus.adapterState,
            initialData: BluetoothAdapterState.unknown,
            builder: (c, snapshot) {
              final state = snapshot.data;
              if (state == BluetoothAdapterState.on) {
                return const FindDevicesScreen();
              }
              return BluetoothOffScreen(state: state);
            }),
        builder: (context, child) {
          child = EasyLoading.init()(context, child);
          return child;
        });
  }
}
