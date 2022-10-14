import 'dart:typed_data';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:lfs_rename/res/resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lfs_rename/tools/log.dart';
import 'package:lfs_rename/widgets/textfield_widget.dart';

class AirSmartCalibra extends StatefulWidget {
  final BluetoothDevice device;

  const AirSmartCalibra({Key? key, required this.device}) : super(key: key);

  @override
  State<AirSmartCalibra> createState() => _AirSmartCalibraState();
}

class _AirSmartCalibraState extends State<AirSmartCalibra> {

  bool isDiscoverSer = false;
  bool isConnected = false;
  BluetoothCharacteristic? mCharacteristic;
  var notifyStream;
  int? mtuSize;
  Duration duration = const Duration(microseconds: 800);
  List<double> numArr = [0,0,0,0,0,0,0,0,0,0,0,];
  List<double> resetArr = [0.181331664620,0.025522098217,-0.199494723491,0.001968358236,-0.015353370599,-0.000172617885,0.002984174514,0.471420463156,0.867957538411,-0.000104893882,0.000000078795,0.00];
  double queryValue = 0;
  double sendValue = 1;
  List<int> sendData = [0xf5,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00];
  List<int> sendData1 = [0xf5,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00];
  List<int> queryData = [0xf6,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00];
  List<String> receiveData = [];
  String coeValue = '0';
  FocusNode  focusNode = FocusNode();
  FocusNode  focusNode1 = FocusNode();
  FocusNode  focusNode2 = FocusNode();
  FocusNode  focusNode3 = FocusNode();
  FocusNode  focusNode4 = FocusNode();
  FocusNode  focusNode5 = FocusNode();
  FocusNode  focusNode6 = FocusNode();
  FocusNode  focusNode7 = FocusNode();
  FocusNode  focusNode8 = FocusNode();
  FocusNode  focusNode9 = FocusNode();
  FocusNode  focusNode10 = FocusNode();
  cancelNotify() async {
    if (mCharacteristic != null) {
      await notifyStream.cancel();
    }
  }

  @override
  void initState() {
    widget.device.state.listen((event){
      if (event == BluetoothDeviceState.connected){
        if (mounted) {
          _loadBleChaData();
          setState(() {

          });
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    cancelNotify();
    EasyLoading.dismiss();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: Center(
              child: AutoSizeText(
                widget.device.name,
                maxLines: 1,
              )),
          actions: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
                stream: widget.device.state,
                initialData: BluetoothDeviceState.connecting,
                builder: (context, snapshot) {
                  VoidCallback? rightClick;
                  String text;
                  switch (snapshot.data) {
                    case BluetoothDeviceState.connected:
                      rightClick = () => widget.device.disconnect();
                      text = 'DISCONNECT';
                      break;
                    case BluetoothDeviceState.disconnected:{
                      rightClick = () => widget.device.connect();
                      text = '连接中';
                      cancelNotify();
                    }

                    break;
                    default:
                      rightClick = null;
                      text =
                          snapshot.data.toString().substring(21).toUpperCase();
                      break;
                  }
                  return TextButton(
                      onPressed: rightClick,
                      child: Text(
                        text,
                        style: TextStyle(color: Colors.white),
                      ));
                })
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Gaps.vGap16,
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: <Widget>[
              //     Padding(
              //       padding: const EdgeInsets.all(18.0),
              //       child: SizedBox(
              //         width: 140,
              //         height: 50,
              //         child: SpinBox(
              //           min: 1,
              //           max: 11,
              //           value: sendValue,
              //           decoration: InputDecoration(labelText: '发送系数',contentPadding: EdgeInsets.zero),
              //           direction: Axis.horizontal,
              //           onChanged: (value) {
              //             // cancelNotify();
              //             setState(() {
              //               sendValue = value;
              //             });
              //           },
              //         ),
              //       ),
              //     ),
              //
              //   ],
              // ),
              Gaps.vGap16,
              Row(mainAxisAlignment: MainAxisAlignment.center,children: <Widget>[
                CoefficientTextField(hintText: '系数1', initialValue: numArr[0], focusNode: focusNode, onChange: (String value) {
                  LogD("系数1" + value);
                  coeValue = value;
                  numArr[0] = double.parse(value);
                },),
                Gaps.hGap16,
                CoefficientTextField(hintText: '系数2',initialValue: numArr[1], focusNode: focusNode1, onChange: (String value) {
                  LogD("系数2" + value);
                  numArr[1] = double.parse(value);
                },),
              ],),
              Gaps.vGap8,
              Row(mainAxisAlignment: MainAxisAlignment.center,children: <Widget>[
                CoefficientTextField(hintText: '系数3', initialValue: numArr[2], focusNode: focusNode2, onChange: (String value) {
                  LogD("系数3" + value);
                  numArr[2] = double.parse(value);
                },),
                Gaps.hGap16,
                CoefficientTextField(hintText: '系数4',initialValue: numArr[3], focusNode: focusNode3, onChange: (String value) {
                  LogD("系数4" + value);
                  numArr[3] = double.parse(value);
                },),
              ],),
              Gaps.vGap8,
              Row(mainAxisAlignment: MainAxisAlignment.center,children: <Widget>[
                CoefficientTextField(hintText: '系数5', initialValue: numArr[4], focusNode: focusNode4, onChange: (String value) {
                  LogD("系数5" + value);
                  numArr[4] = double.parse(value);
                },),
                Gaps.hGap16,
                CoefficientTextField(hintText: '系数6',initialValue: numArr[5], focusNode: focusNode5, onChange: (String value) {
                  LogD("系数6" + value);
                  numArr[5] = double.parse(value);
                },),
              ],),
              Gaps.vGap8,
              Row(mainAxisAlignment: MainAxisAlignment.center,children: <Widget>[
                CoefficientTextField(hintText: '系数7', initialValue: numArr[6], focusNode: focusNode6, onChange: (String value) {
                  LogD("系数7" + value);
                  numArr[6] = double.parse(value);
                },),
                Gaps.hGap16,
                CoefficientTextField(hintText: '系数8',initialValue: numArr[7], focusNode: focusNode7, onChange: (String value) {
                  LogD("系数8" + value);
                  numArr[7] = double.parse(value);
                },),
              ],),
              Gaps.vGap8,
              Row(mainAxisAlignment: MainAxisAlignment.center,children: <Widget>[
                CoefficientTextField(hintText: '系数9', initialValue: numArr[8], focusNode: focusNode8, onChange: (String value) {
                  LogD("系数9" + value);
                  numArr[8] = double.parse(value);
                },),
                Gaps.hGap16,
                CoefficientTextField(hintText: '系数10',initialValue: numArr[9], focusNode: focusNode9, onChange: (String value) {
                  LogD("系数10" + value);
                  numArr[9] = double.parse(value);
                },),
              ],),
              Gaps.vGap8,
              CoefficientTextField(hintText: '系数11', initialValue: numArr[10], focusNode: focusNode10, onChange: (String value) {
                print("系数11" + value);
                numArr[10] = double.parse(value);
              },),

              Gaps.vGap16,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:<Widget> [
                  ElevatedButton(onPressed:() async{

                    // List<int> a = sendCoeValue(double.parse(coeValue));
                    // List<int> b = sendCoeValue(0.025522098217);
                    // sendData1.replaceRange(2, 10, a);
                    // sendData1.replaceRange(10, 18, b);
                    // debugPrint('sendData=$sendData1 coe=$coeValue');
                    // mCharacteristic!.write(sendData1);
                    LogD('start coe=$coeValue numArr=$numArr');

                    EasyLoading.show(status: '正在发送中');
                    for (int i = 1; i < 7; i++) {
                      Future.delayed(Duration(milliseconds: i * 500), () {
                        String a = i.toRadixString(16);
                        sendData[1] =hexStringToInt(a);
                        if(i==1){
                          List<int> front = sendCoeValue(double.parse(coeValue));
                          List<int> sub = sendCoeValue(numArr[i*2-1]);
                          sendData.replaceRange(2, 10, front);
                          sendData.replaceRange(10, 18, sub);
                        }else if(i==6){
                          List<int> front = sendCoeValue(numArr[i*2-2]);
                          List<int> sub = sendCoeValue(0.0);
                          sendData.replaceRange(2, 10, front);
                          sendData.replaceRange(10, 18, sub);
                        }else{
                          List<int> front = sendCoeValue(numArr[i*2-2]);
                          List<int> sub = sendCoeValue(numArr[i*2-1]);
                          sendData.replaceRange(2, 10, front);
                          sendData.replaceRange(10, 18, sub);
                        }

                        mCharacteristic!.write(sendData);
                        debugPrint('end sendData=$sendData coe=$coeValue numArr=$numArr');
                        if(i==6){
                          EasyLoading.dismiss();
                        }
                      });
                    }

                  }, child: Text('发送数据')),
                  Gaps.hGap32,
                  ElevatedButton(onPressed:(){
                    unfocusNode();
                    if(queryValue > 11){
                      Fluttertoast.showToast(msg: '选择系数过大',gravity: ToastGravity.CENTER);
                    }else{
                      // String a = (queryValue).toInt().toRadixString(16);
                      // queryData[1] =hexStringToInt(a);
                      EasyLoading.show(status: '正在查询中');
                      for (int i = 0; i < 6; i++) {
                        Future.delayed(Duration(milliseconds: i * 500), () {
                          String a = i.toRadixString(16);
                          queryData[1] =hexStringToInt(a);
                          // queryData[1] = i;
                          mCharacteristic!.write(queryData);
                          if(i==5){
                            EasyLoading.dismiss();
                          }
                        });
                      }
                    }

                  }, child: Text('查询数据')),

                ],
              ),
              Gaps.vGap16,
              ElevatedButton(onPressed:() async{
                EasyLoading.show(status: '正在发送中');
                for (int i = 1; i < 7; i++) {
                  Future.delayed(Duration(milliseconds: i * 800), () {
                    String a = i.toRadixString(16);
                    sendData[1] =hexStringToInt(a);
                    List<int> front = sendCoeValue(resetArr[i*2-2]);
                    List<int> sub = sendCoeValue(resetArr[i*2-1]);
                    sendData.replaceRange(2, 10, front);
                    sendData.replaceRange(10, 18, sub);
                    LogD("sendData=$sendData");
                    mCharacteristic!.write(sendData);
                    if(i==6){
                      EasyLoading.dismiss();
                    }
                  });
                }

              }, child: Text('恢复默认')),
            ],
          ),
        ));
  }
  void setMtuSize() {
    widget.device.mtu.first.then((value){
      debugPrint('object=$value');
    });
  }

  void unfocusNode(){
    focusNode.unfocus();
    focusNode1.unfocus();
    focusNode2.unfocus();
    focusNode3.unfocus();
    focusNode4.unfocus();
    focusNode5.unfocus();
    focusNode6.unfocus();
    focusNode7.unfocus();
    focusNode8.unfocus();
    focusNode9.unfocus();
    focusNode10.unfocus();
  }
  _loadBleChaData() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().substring(4, 8) == "AE00") {
        List<BluetoothCharacteristic> characteristics = service.characteristics;
        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString().toUpperCase().substring(4, 8) ==
              "AE01") {
            //写数据
            mCharacteristic = characteristic;
          } else if (characteristic.uuid
              .toString()
              .toUpperCase()
              .substring(4, 8) ==
              "AE02") {
            //读数据
            if (characteristic.properties.notify) {
              // LogD('msg=setCharacteristicNotify');
              setCharacteristicNotify(characteristic, true);
            }
          }
        }
      }
    }
  }

  void setCharacteristicNotify(BluetoothCharacteristic c, bool notify) async {
    await c.setNotifyValue(notify);
    notifyStream = c.value.listen((value) {
      if (value.isNotEmpty) {
        // print('value=$value');
        List<String> data = [];
        List<String> splice = [];
        for (var i = 0; i < value.length; i++) {
          String dataStr = value[i].toRadixString(16);
          if (dataStr.length < 2) {
            dataStr = "0$dataStr";
          }
          String dataEndStr = dataStr;
          data.add(dataEndStr);
        }
        LogD("我是蓝牙返回数据 - $data");
        if(data[0] == 'f5'){
          List<String> sub = data.sublist(2, data.length);
          for (int i = 0; i < sub.length; i += 2) {
            // print(a1[i]);
            String aa = sub[i] + sub[i + 1];
            splice.add(aa);
          }
          receiveData.addAll(splice);
        }else if(data[0] == 'ff'){
          LogD('receive=$receiveData \n length=${receiveData.length}');
          //处理 receiveData 数据
          for(int i =0;i<receiveData.length;i+=2){

          }
        }else if(data[0] == 'f7'){
          List<int> forData =  value.sublist(2,10);
          List<int> sufData =  value.sublist(10,18);
          if(data[1] == '00'){//系数1和系数2
            setState(() {
              numArr[0] = getCoeValue(forData);
              numArr[1] = getCoeValue(sufData);
            });
          }else if(data[1] == '01'){
            setState(() {
              numArr[2] = getCoeValue(forData);
              numArr[3] = getCoeValue(sufData);
            });
          }else if(data[1] == '02'){
            setState(() {
              numArr[4] = getCoeValue(forData);
              numArr[5] = getCoeValue(sufData);
            });
          }else if(data[1] == '03'){
            setState(() {
              numArr[6] = getCoeValue(forData);
              numArr[7] = getCoeValue(sufData);
            });
          }else if(data[1] == '04'){
            setState(() {
              numArr[8] = getCoeValue(forData);
              numArr[9] = getCoeValue(sufData);
            });
          }else if(data[1] == '05'){
            setState(() {
              numArr[10] = getCoeValue(forData);
            });
          }
          // cancelNotify();
        }
      }
    });
  }

  List<int> sendCoeValue(double coe){
    ByteData bytes1 = ByteData(8);
    bytes1.setFloat64(0, coe, Endian.little);
    List<int> response = bytes1.buffer.asUint8List().toList();
    // List<int> response = bytes1.buffer.asInt8List().toList();
    // print('As Uint8List of values: ${response}');
    return response;
  }

  double getCoeValue(List<int> data){
    final bytes = Uint8List.fromList(data);
    final byteData = ByteData.sublistView(bytes);
    double forwardValue = byteData.getFloat64(0, Endian.little);
    debugPrint('value2=$forwardValue');
    return forwardValue;
  }

  //str->int
  int hexStringToInt(String hex) {
    int val = 0;
    int len = hex.length;
    for (int i = 0; i < len; i++) {
      int hexDigit = hex.codeUnitAt(i);
      if (hexDigit >= 48 && hexDigit <= 57) {
        val += (hexDigit - 48) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 65 && hexDigit <= 70) {
        // A..F
        val += (hexDigit - 55) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 97 && hexDigit <= 102) {
        // a..f
        val += (hexDigit - 87) * (1 << (4 * (len - 1 - i)));
      } else {
        throw new FormatException("Invalid hexadecimal value");
      }
    }
    return val;
  }
}
