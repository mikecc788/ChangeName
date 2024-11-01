import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:lfs_rename/res/resources.dart';
import 'package:lfs_rename/scan_device.dart';
import 'package:lfs_rename/tools/ble_manager.dart';
import 'package:lfs_rename/tools/ble_service.dart';
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
        // home: const MyHomePage(title: '设备'),
        home: StreamBuilder<BluetoothAdapterState>(
            stream: FlutterBluePlus.adapterState,
            initialData: BluetoothAdapterState.unknown,
            builder: (c, snapshot) {
              final state = snapshot.data;
              if (state == BluetoothAdapterState.on) {
                // return MyHomePage(title: '设备');
                return FindDevicesScreen();
              }
              return BluetoothOffScreen(state: state);
            }),
        builder: (context, child) {
          child = EasyLoading.init()(context, child);
          return child;
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BluetoothDevice> list = [];
  TextEditingController nameController = TextEditingController();
  FocusNode focusNode = FocusNode();

  // 蓝牙扫描的时长
  final Duration scanTimeout = const Duration(seconds: 4);
  BluetoothCharacteristic? mCharacteristic;
  var notifyStream;
  List<int> bleData = [];

  Future<void> _scanDevice() async {
    FlutterBluePlus.startScan(timeout: scanTimeout);
    List<BluetoothDevice> connectDevice =
        await FlutterBluePlus.connectedDevices;
    FlutterBluePlus.scanResults.listen((scanResult) {
      // do something with scan result
      if (scanResult.isNotEmpty) {
        var device = scanResult[0].device;

        if (mounted) {
          setState(() {
            scanResult.sort((left, right) => right.rssi.compareTo(left.rssi));
            list.clear();
            for (ScanResult result in scanResult) {
              if (result.rssi > 0) continue;
              if (result.device.name.isNotEmpty) {
                debugPrint('${device.name} found! id: ${device.id}');
                list.add(result.device);
              }
            }
            for (var element in connectDevice) {
              // LogD('name=${element.name}');
              if (!list.contains(element)) {
                list.add(element);
              }
            }
          });
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    FlutterBluePlus.startScan(timeout: scanTimeout);
    List<BluetoothDevice> connectDevice =
        await FlutterBluePlus.connectedDevices;
    FlutterBluePlus.scanResults.listen((scanResult) {
      // do something with scan result
      var device = scanResult[0].device;
      setState(() {
        scanResult.sort((left, right) => right.rssi.compareTo(left.rssi));
        list.clear();
        for (ScanResult result in scanResult) {
          if (result.rssi > 0) continue;
          if (result.device.name.isNotEmpty) {
            debugPrint('${device.name} found! id: ${device.id}');
            list.add(result.device);
          }
        }
        for (var element in connectDevice) {
          // LogD('name=${element.name}');
          if (!list.contains(element)) {
            list.add(element);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    cancelNotify();
    super.dispose();
  }

  cancelNotify() async {
    if (mCharacteristic != null) {
      await notifyStream.cancel();
    }
  }

  void setCharacteristicNotify(BluetoothCharacteristic c, bool notify) async {
    await c.setNotifyValue(notify);
    notifyStream = c.value.listen((value) {
      if (value.isNotEmpty) {
        List<String> data = [];
        for (var i = 0; i < value.length; i++) {
          String dataStr = value[i].toRadixString(16);
          if (dataStr.length < 2) {
            dataStr = "0$dataStr";
          }
          String dataEndStr = dataStr;
          data.add(dataEndStr);
        }
        debugPrint("我是蓝牙返回数据 - $data");
      }
    });
  }

  void setDataToDevice(List<int> datas) {
    debugPrint('sendData=$datas');
    int singleMax = 20;
    int tempCount = datas.length ~/ singleMax;
    int maxCount = datas.length % singleMax == 0 ? tempCount : tempCount + 1;
    List<int> tempList = [];
    for (int i = 0; i < maxCount; i++) {
      int start = i * singleMax;
      tempList =
          datas.sublist(start, i == maxCount - 1 ? datas.length : start + 20);
      debugPrint('tempList=$tempList');
      // Future.delayed(const Duration(milliseconds: 300), () {
      // });
      writeData(tempList);
      // mCharacteristic!.write(tempList);
      // Delay of 6800 milliseconds ,6500 is the best value for iOS native testing, which can ensure both data integrity and
      // the shortest time,  150k data takes about 59 seconds
      //  The Android interval needs to be set longer, and the same data 150K takes about 1 minute and 25 seconds
      //  sleep(Duration(microseconds: (Platform.isIOS ? 6800 : 10000)));
    }
  }

  void writeData(List<int> tempList) async {
    await mCharacteristic!.write(tempList, withoutResponse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colours.bar_color,
        title: Center(child: Text(widget.title)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(),
        child: list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Gaps.vGap32,
                    Text(
                      '没有搜索到设备',
                      style: TextStyle(color: Colours.bar_color, fontSize: 20),
                    ),
                  ],
                ),
              )
            : buildListView(),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBluePlus.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
              child: const Icon(Icons.refresh),
              onPressed: () => _onRefresh(),
            );
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _onRefresh,
      //   child: const Icon(Icons.refresh),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  ListView buildListView() {
    return ListView.builder(
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          return SearchListItem(
              index: index,
              list: list.cast<BluetoothDevice>(),
              clickItem: (index) async {
                nameController.text = list[index].name;
                //点击item就开始连接 发送数据
                LFSBleManager().connectBle(list[index]);
                Alert(
                    context: context,
                    title: '输入设备名字',
                    content: StreamBuilder<BluetoothConnectionState>(
                        stream: list[index].connectionState,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.data ==
                              BluetoothConnectionState.connected) {
                            list[index].requestMtu(223);

                            FutureBuilder<List<BluetoothService>>(
                              future: list[index].discoverServices(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                for (var service in snapshot.data!) {
                                  if (service.uuid
                                          .toString()
                                          .toUpperCase()
                                          .substring(4, 8) ==
                                      "1000") {
                                    List<BluetoothCharacteristic>
                                        characteristics =
                                        service.characteristics;

                                    for (var characteristic
                                        in characteristics) {
                                      if (characteristic.uuid
                                              .toString()
                                              .toUpperCase()
                                              .substring(4, 8) ==
                                          "1001") {
                                        //写数据
                                        debugPrint('write data');
                                        mCharacteristic = characteristic;
                                      } else if (characteristic.uuid
                                              .toString()
                                              .toUpperCase()
                                              .substring(4, 8) ==
                                          "1002") {
                                        //读数据
                                        if (characteristic.properties.notify) {
                                          setCharacteristicNotify(
                                              characteristic, true);
                                        }
                                      }
                                    }
                                  }
                                }

                                return TextField(
                                    controller: nameController,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: '名字',
                                    ));
                              },
                            );
                          }

                          return Center(child: CircularProgressIndicator());
                        }),
                    buttons: [
                      DialogButton(
                        onPressed: () async {
                          List<int> sendData =
                              utf8.encode('AT+BM${nameController.text}');
                          debugPrint('changeName=$sendData');
                          for (int i = 0; i < sendData.length; i++) {
                            bleData.add(sendData[i]);
                          }
                          // int tempCount =
                          //     ((bleData.length + 1) ~/ 20) + 1;
                          // bleData.insert(5, tempCount);
                          debugPrint(
                              'insert=$bleData state=${list[index].state}');
                          // setDataToDevice(bleData);
                          if (list[index].connectionState ==
                              BluetoothConnectionState.connected) {
                            // await mCharacteristic!.write(sendData, withoutResponse: true);
                          }

                          debugPrint('mCharacteristic=$mCharacteristic');

                          await mCharacteristic!.write(sendData);
                          sendData.clear();

                          // mCharacteristic!.write(sendData);
                          focusNode.unfocus();
                          bleData.clear();
                          nameController.clear();
                          // const timeout = Duration(milliseconds: 3000);
                          // Timer(timeout, () {
                          //   debugPrint('SET OVER');
                          //   cancelNotify();
                          //   list[index].disconnect();
                          // });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "确认",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      )
                    ]).show();
              });
        });
  }
}
