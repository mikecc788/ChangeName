import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lfs_rename/res/resources.dart';
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '设备'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;



  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> list = [];
  TextEditingController nameController = TextEditingController();
  FocusNode  focusNode = FocusNode();
  // 蓝牙扫描的时长
  final Duration scanTimeout = const Duration(seconds: 4);
  BluetoothCharacteristic? mCharacteristic;
  var notifyStream;
  List<int> bleData = [];

  List<int> changeName = [
    65,
    84,
    43,
    66,
    77,
    65,
    105,
    114,
    32,
    83,
    109,
    97,
    114,
    116,
    32,
    84,
    84,
    32,
    45,
    48,
    48,
    48,
    48,
    51,
    65,
    84,
    43,
    66,
    77,
    65,
    105,
    114,
    32,
    83,
    109,
    97,
    77,
    65,
    105,
    114,
  ];
  @override
  initState() {
    super.initState();
    _scanDevice();
  }

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

  Future<void> _scanDevice() async {
    flutterBlue.startScan().timeout(scanTimeout);
    List<BluetoothDevice> connectDevice = await flutterBlue.connectedDevices;
    flutterBlue.scanResults.listen((scanResult) {
      // do something with scan result
      if (scanResult.isNotEmpty) {
        var device = scanResult[0].device;
        debugPrint('${device.name} found! id: ${device.id}');
        if (mounted) {
          setState(() {
            scanResult.sort((left, right) => right.rssi.compareTo(left.rssi));
            list.clear();
            for (ScanResult result in scanResult) {
              if (result.rssi > 0) continue;
              if (result.device.name.isNotEmpty) {
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
    flutterBlue.stopScan();
    // LogD('开始扫描外设');
    flutterBlue.startScan().timeout(scanTimeout);
    List<BluetoothDevice> connectDevice = await flutterBlue.connectedDevices;
    flutterBlue.scanResults.listen((scanResult) {
      // do something with scan result
      var device = scanResult[0].device;
      debugPrint('${device.name} found! id: ${device.id}');
      setState(() {
        scanResult.sort((left, right) => right.rssi.compareTo(left.rssi));
        list.clear();
        for (ScanResult result in scanResult) {
          if (result.rssi > 0) continue;
          if (result.device.name.isNotEmpty) {
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
    // TODO: implement dispose
    flutterBlue.stopScan();
    cancelNotify();
    super.dispose();
  }

  cancelNotify() async{
    if(mCharacteristic != null){
      await notifyStream.cancel();
    }
  }
  void _loadBleChaData(BluetoothDevice device,String name) async{
    // device.mtu.elementAt(1).then((mtu){
    //   mtu = mtu < 23 ? 20 : mtu - 3; // failsafe by always assuming an ATT MTU and not a DATA MTU
    //   // do your service discovery
    //   // device.discoverServices();
    // });
    // await device.requestMtu(240);
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().substring(4, 8) == "1000"){
        List<BluetoothCharacteristic> characteristics = service.characteristics;
        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString().toUpperCase().substring(4, 8) == "1001"){//写数据
            mCharacteristic = characteristic;
          }else if (characteristic.uuid.toString().toUpperCase().substring(4, 8) == "1002"){//读数据
            if(characteristic.properties.notify){
              setCharacteristicNotify(characteristic, true);
            }
          }
        }
      }
    }
  }
  void setCharacteristicNotify(BluetoothCharacteristic c, bool notify) async{
    await c.setNotifyValue(notify);
    notifyStream = c.value.listen((value){
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
      // mCharacteristic!.write(utf8.encode('AT+BM${nameController.text}'));
      mCharacteristic!.write(tempList, withoutResponse: true);
      // Delay of 6800 milliseconds ,6500 is the best value for iOS native testing, which can ensure both data integrity and
      // the shortest time,  150k data takes about 59 seconds
      //  The Android interval needs to be set longer, and the same data 150K takes about 1 minute and 25 seconds
      //  sleep(Duration(microseconds: (Platform.isIOS ? 6800 : 10000)));
    }
  }

  @override
  Widget build(BuildContext context) {
    requestPermission();
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
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (BuildContext context, int index) {
                  // nameController.text = list[index].name;
                  return SearchListItem(
                      index: index,
                      list: list,
                      clickItem: (index) async{
                        //点击item就开始连接 发送数据
                        LFSBleManager().connectBle(list[index]);
                        LFSBleManager().listenBleConnect(() {
                          if(mounted){
                            debugPrint('设备断开连接了');
                            cancelNotify();
                            // list[index].connect(autoConnect: true);
                          }
                        }, (){
                          if(mounted){
                            debugPrint('连接上了');
                            _loadBleChaData(list[index],nameController.text);
                          }
                        },list[index]);
                        nameController.text = list[index].name;
                        Alert(context: context,title: '输入设备名字',content: TextField(
                          controller: nameController,
                            focusNode: focusNode,
                            decoration:  const InputDecoration(
                          labelText: '名字',
                        )),buttons: [ DialogButton(
                          onPressed: (){
                            List<int> sendData = utf8.encode('AT+BM${nameController.text}');
                            debugPrint('changeName=$sendData');
                            for(int i = 0;i<sendData.length;i++){
                              bleData.add(sendData[i]);
                            }
                            int tempCount = ((bleData.length + 1) ~/ 20) + 1;
                            bleData.insert(5, tempCount);
                            debugPrint('insert=$bleData');
                            setDataToDevice(bleData);
                            // mCharacteristic!.write(sendData, withoutResponse: true);
                            // mCharacteristic!.write(sendData);
                            focusNode.unfocus();
                            bleData.clear();
                            nameController.clear();
                            const timeout = Duration(milliseconds: 2000);
                            Timer(timeout, () {
                              list[index].disconnect();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "确认",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        )]).show();
                      });
                }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onRefresh,
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
