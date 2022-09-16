import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lfs_rename/res/resources.dart';
import 'package:lfs_rename/widgets/search_list_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);
  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
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

  @override
  initState() {
    super.initState();
    requestPermission();
    FlutterBlue.instance
        .startScan(timeout: Duration(seconds: 4));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:const Center(child:Text('Find Devices')),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Container(
                    color: Colours.bar_color,
                          child: ListTile(
                    title: Text(d.name),
                    subtitle: Text(d.id.toString()),
                    trailing: StreamBuilder<BluetoothDeviceState>(
                          stream: d.state,
                          initialData: BluetoothDeviceState.disconnected,
                          builder: (c, snapshot) {
                            if (snapshot.data ==
                                BluetoothDeviceState.connected) {
                              return TextButton(
                                child: Text('OPEN'),
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            DeviceScreen(device: d))),
                              );
                            }
                            return Text(snapshot.data.toString());
                          },
                    ),
                  ),
                        ),
                      ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!.where((element) => element.device.name.isNotEmpty)
                      .map(
                        (r) => ScanResultTile(
                      result: r,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        r.device.connect();
                        return DeviceScreen(device: r.device);
                      })),
                    ),
                  ).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.refresh),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);
  final BluetoothDevice device;

  void discoverServices()async{
    await device.discoverServices();
  }

  @override
  Widget build(BuildContext context) {

    List<int> bleData = [];
    BluetoothCharacteristic? mCharacteristic;
    var notifyStream;
    bool isDiscoverSer = false;
    bool isSetMTu = false;
    int textLength = 0;
    return Scaffold(
      appBar: AppBar(
        title: Center(child: AutoSizeText(device.name,maxLines: 1,)),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => device.connect();
                  text = 'CONNECT';
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
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),

      body:SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot){
                if(snapshot.data == BluetoothDeviceState.connected){
                 return ListTile(
                    trailing: StreamBuilder<bool>(
                      stream: device.isDiscoveringServices,
                      initialData: false,
                      builder: (c, snapshot) {
                        debugPrint('snapshot=${snapshot.data}');
                        // return Text('${snapshot.data}');
                        if(!snapshot.data!){
                          if(!isDiscoverSer) {
                            isDiscoverSer = true;
                            debugPrint('discoverServices $device');
                            device.discoverServices();
                          }
                        }
                        // return IconButton(
                        //   icon: Icon(Icons.refresh),
                        //   onPressed: () => device.discoverServices(),
                        // );
                        return Text('');
                      },
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Text('设备未连接'),
                );
              }
            ),
            StreamBuilder<int>(
              stream: device.mtu,
              initialData: 0,
              builder: (c, snapshot){
                if(!snapshot.hasData){
                  return Center(child: CircularProgressIndicator());
                }
                // if(snapshot.data!<21 && snapshot.data!>0){
                //   Future.delayed(Duration(milliseconds:1200),(){
                //     debugPrint('SET MTU OVER');
                //     device.requestMtu(223);
                //   });
                // }

                // device.requestMtu(223);
                if(snapshot.data!>0){
                  textLength = snapshot.data! - 5;
                }
                debugPrint('textLength=$textLength');
                return ListTile(
                  title: Text('设置字符长度'),
                  subtitle: Text('${snapshot.data! - 5} 长度'),
                  trailing: ElevatedButton(
                    child: Text('修改长度'),
                    onPressed: () => device.requestMtu(105),
                  ),
                );
              }
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data!,context,textLength),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  void writeData(List<int>tempList ) async{
    // await mCharacteristic!.write(tempList, withoutResponse: true);
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services,BuildContext context, int textLength) {
    List<int> bleData = [];
    TextEditingController nameController = TextEditingController();
    FocusNode  focusNode = FocusNode();
    return services.where((element) => element.uuid.toString().toUpperCase().substring(4, 8) == "1000")
        .map(
          (s) => ServiceTile(
        service: s,
        characteristicTiles: s.characteristics.where((c) => c.uuid.toString().toUpperCase().substring(4, 8) == "1001"||c.uuid.toString().toUpperCase().substring(4, 8) == "1002")
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
                        labelText: '名字',)),
                  buttons: [
                    DialogButton(
                      onPressed: () async{
                        // if(nameController.text.length > textLength){
                        //   Fluttertoast.showToast(msg: '数据过长，请先编辑长度',gravity: ToastGravity.CENTER);
                        // }else{
                        //
                        // }
                        List<int> sendData = utf8
                            .encode('AT+BM${nameController.text}');
                        debugPrint('changeName=$sendData');
                        for (int i = 0; i < sendData.length; i++) {
                          bleData.add(sendData[i]);
                        }
                        debugPrint('insert=$bleData');
                        await c.write(bleData, withoutResponse: true);
                        Future.delayed(Duration(milliseconds:400),(){
                          debugPrint('SET OVER');
                          device.disconnect();
                          bleData.clear();
                          Navigator.pop(context);
                        });
                        focusNode.unfocus();
                        bleData.clear();
                        nameController.clear();
                        Navigator.pop(context);
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