import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lfs_rename/res/resources.dart';
import 'package:lfs_rename/tools/log.dart';
import 'package:lfs_rename/widgets/search_list_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'calibration.dart';

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  @override
  initState() {
    super.initState();
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Find Devices')),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBluePlus.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBluePlus.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => Padding(
                            padding: const EdgeInsets.all(22.0),
                            child: Container(
                              height: 120,
                              color: Colours.bar_color,
                              child: Column(
                                children: [
                                  Row(
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Text(d.platformName,
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                      StreamBuilder<BluetoothConnectionState>(
                                        stream: d.connectionState,
                                        initialData: BluetoothConnectionState
                                            .disconnected,
                                        builder: (c, snapshot) {
                                          if (snapshot.data ==
                                              BluetoothConnectionState
                                                  .connected) {
                                            return ElevatedButton(
                                              onPressed: () => d.disconnect(),
                                              child: const Text('断开',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            );
                                          }
                                          LogD(
                                              "msg=${snapshot.data.toString()}");
                                          return const SizedBox();
                                        },
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      d.platformName.contains('Air Smart')
                                          ? ElevatedButton(
                                              child: const Text('校准系数',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              onPressed: () =>
                                                  Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              AirSmartCalibra(
                                                                  device: d))),
                                            )
                                          : SizedBox(),
                                      Gaps.hGap32,
                                      ElevatedButton(
                                        child: const Text('改名',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        onPressed: () => Navigator.of(context)
                                            .push(MaterialPageRoute(
                                                builder: (context) =>
                                                    DeviceScreen(device: d))),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .where((element) => element.device.name.isNotEmpty)
                      .map(
                        (r) => ScanResultTile(
                          result: r,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            r.device.connect();
                            return DeviceScreen(device: r.device);
                          })),
                          onCal: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            r.device.connect();
                            return AirSmartCalibra(device: r.device);
                          })),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
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
                child: Icon(Icons.refresh),
                onPressed: () =>
                    FlutterBluePlus.startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  Widget build(BuildContext context) {
    List<int> bleData = [];
    BluetoothCharacteristic? mCharacteristic;
    bool isDiscoverSer = false;
    bool isSetMTu = false;
    int textLength = 0;
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: AutoSizeText(
          device.name,
          maxLines: 1,
        )),
        actions: <Widget>[
          StreamBuilder<BluetoothConnectionState>(
            stream: device.connectionState,
            initialData: BluetoothConnectionState.disconnected,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothConnectionState.connected:
                  onPressed = () => device.disconnect();
                  text = '断开连接';
                  break;
                case BluetoothConnectionState.disconnected:
                  onPressed = () => device.connect();
                  text = '连接中';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return ElevatedButton(
                onPressed: onPressed,
                child: Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.white),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothConnectionState>(
                stream: device.connectionState,
                initialData: BluetoothConnectionState.disconnected,
                builder: (c, snapshot) {
                  if (snapshot.data == BluetoothConnectionState.connected) {
                    return ListTile(
                      trailing: StreamBuilder<bool>(
                        stream: device.isDiscoveringServices,
                        initialData: false,
                        builder: (c, snapshot) {
                          debugPrint('snapshot=${snapshot.data}');
                          if (!snapshot.data!) {
                            if (!isDiscoverSer) {
                              isDiscoverSer = true;
                              debugPrint('discoverServices $device');
                              device.discoverServices();
                            }
                          }
                          return const SizedBox();
                        },
                      ),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(18.0),
                    child: Text('设备未连接'),
                  );
                }),
            StreamBuilder<int>(
                stream: device.mtu,
                initialData: 0,
                builder: (c, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  // if(snapshot.data!<21 && snapshot.data!>0){
                  //   Future.delayed(Duration(milliseconds:1200),(){
                  //     debugPrint('SET MTU OVER');
                  //     device.requestMtu(223);
                  //   });
                  // }
                  // device.requestMtu(223);
                  Future.delayed(const Duration(seconds: 2), () {
                    device.requestMtu(223);
                  });

                  if (snapshot.data! > 0) {
                    textLength = snapshot.data! - 5;
                  }
                  // debugPrint('textLength=$textLength');
                  return ListTile(
                    title: Text('可设置最大字符长度'),
                    subtitle: Text('当前可输入${snapshot.data! - 5}个字符'),
                    trailing: ElevatedButton(
                      child: Text('修改长度'),
                      onPressed: () => device.requestMtu(223),
                    ),
                  );
                }),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children:
                      _buildServiceTiles(snapshot.data!, context, textLength),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void writeData(List<int> tempList, BluetoothCharacteristic c) async {
    await c.write(tempList, withoutResponse: true);
  }

  void clearTextField(BuildContext context) {
    Navigator.pop(context);
  }

  List<Widget> _buildServiceTiles(
      List<BluetoothService> services, BuildContext context, int textLength) {
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().substring(4, 8) == "AE00") {
        List<BluetoothCharacteristic> characteristics = service.characteristics;
        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString().toUpperCase().substring(4, 8) ==
              "AE01") {
            debugPrint('write data');
          }
        }
      }
    }

    List<int> bleData = [];
    TextEditingController nameController = TextEditingController();
    FocusNode focusNode = FocusNode();
    return services
        .where((element) =>
            element.uuid.toString().toUpperCase().substring(4, 8) == "1000" ||
            element.uuid.toString().toUpperCase().substring(4, 8) == "AE00")
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .where((c) =>
                    c.uuid.toString().toUpperCase().substring(4, 8) == "1001" ||
                    c.uuid.toString().toUpperCase().substring(4, 8) == "AE01")
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () async {
                      nameController.text = device.name;
                      Alert(
                          context: context,
                          title: '输入设备名字',
                          content: TextField(
                              controller: nameController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: '名字',
                              )),
                          buttons: [
                            DialogButton(
                              onPressed: () {
                                List<int> sendData =
                                    utf8.encode('AT+BM${nameController.text}');
                                debugPrint('changeName=$sendData');
                                for (int i = 0; i < sendData.length; i++) {
                                  bleData.add(sendData[i]);
                                }
                                debugPrint(
                                    'insert=$bleData cha=${c.uuid.toString().toUpperCase().substring(4, 8)}');
                                // await c.write(bleData, withoutResponse: true);
                                writeData(bleData, c);
                                Future.delayed(
                                    const Duration(milliseconds: 400), () {
                                  debugPrint('SET OVER');
                                  bleData.clear();
                                  device.disconnect();
                                  Navigator.pop(context);
                                });
                                focusNode.unfocus();
                                nameController.clear();
                                clearTextField(context);
                              },
                              child: const Text(
                                "确认",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            )
                          ]).show();
                      // setDataToDevice(bleData,c);
                      await c.read();
                    },
                    onNotificationPressed: () async {
                      await c.setNotifyValue(!c.isNotifying);
                      await c.read();
                    },
                    descriptorTiles: c.descriptors
                        .map(
                          (d) => DescriptorTile(
                            descriptor: d,
                            onReadPressed: () => d.read(),
                            // onWritePressed: () => d.write(_getRandomBytes()),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }
}
