import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lfs_rename/res/resources.dart';

class SearchListItem extends StatelessWidget {
  final int index;
  final List<BluetoothDevice> list;
  final Function(int) clickItem;

  const SearchListItem(
      {Key? key,
      required this.index,
      required this.list,
      required this.clickItem})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = list[index].name;
    String detail = list[index].id.toString();
    double titleSize = Platform.isIOS ? 24 : 18;
    double detailSize = Platform.isIOS ? 18 : 14;
    return StreamBuilder<BluetoothDeviceState>(
        stream: list[index].state,
        builder: (context, snapshot) {
          // LogD('snapshot=${snapshot.data}');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
              padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
              child: GestureDetector(
                onTap: () => clickItem(index),
                child: Card(
                  color: Colours.home_color,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: kDefaultLeftPadding,
                                  top: 20,
                                  bottom: 18),
                              child: AutoSizeText(
                                title,
                                maxLines: 2,
                                style: TextStyle(
                                    color: Colours.bar_color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: titleSize),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: kDefaultLeftPadding, bottom: 40),
                              child: AutoSizeText(
                                detail,
                                maxLines: 2,
                                style: TextStyle(
                                    color: Colours.bar_color,
                                    fontSize: detailSize),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ));
        });
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key? key, required this.result, this.onTap, this.onCal})
      : super(key: key);
  final ScanResult result;
  final VoidCallback? onTap;
  final VoidCallback? onCal;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
            child: GestureDetector(
              onTap: () => () {},
              child: Card(
                color: Colours.home_color,
                child: Column(
                  children: [
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: kDefaultLeftPadding,
                                    top: 20,
                                    bottom: 18),
                                child: AutoSizeText(
                                  result.device.name,
                                  maxLines: 2,
                                  style: TextStyle(
                                      color: Colours.bar_color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: kDefaultLeftPadding, bottom: 40),
                                child: AutoSizeText(
                                  result.device.id.toString(),
                                  maxLines: 2,
                                  style: TextStyle(
                                      color: Colours.bar_color, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        result.device.name.contains('Air Smart')? ElevatedButton(
                            onPressed: (result.advertisementData.connectable)
                                ? onCal
                                : null,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colours.bar_color),
                              minimumSize:
                                  MaterialStateProperty.all(Size(100, 50)),
                            ),
                            child: const Text(
                              '校准系数',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            )):SizedBox(),
                        Gaps.hGap32,
                        ElevatedButton(
                            onPressed: (result.advertisementData.connectable)
                                ? onTap
                                : null,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colours.bar_color),
                              minimumSize:
                              MaterialStateProperty.all(Size(100, 50)),
                            ),
                            child: const Text(
                              '修改名字',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 18),
                            )),
                      ],
                    ),
                    Gaps.vGap16,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AutoSizeText(
            result.device.name,
            maxLines: 2,
            style: TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          Gaps.vGap12,
          Text(
            result.device.id.toString(),
            style: TextStyle(color: Colors.white),
          )
        ],
      );
    } else {
      return Text(
        result.device.id.toString(),
        style: TextStyle(color: Colors.white),
      );
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          Gaps.hGap12,
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile(
      {Key? key, required this.service, required this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('service=${service.uuid.toString().toUpperCase().substring(4, 8)}');
    if (characteristicTiles.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: characteristicTiles,
      );
    } else {
      return const SizedBox();
    }
  }
}

class CharacteristicTile1 extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;
  final VoidCallback? onNotificationPressed;

  const CharacteristicTile1(
      {Key? key,
        required this.characteristic,
        this.onReadPressed,
        this.onWritePressed,
        this.onNotificationPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        // if(snapshot.data!.isNotEmpty){
        //   characteristic.setNotifyValue(true);
        // }
        // debugPrint('characteristicValue=$value');
        return ExpansionTile(
          title: ListTile(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Text('${characteristic.value}'),
                Text('Characteristic'),
                Text(
                    '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.caption?.color))
              ],
            ),
            subtitle: Text(value.toString()),
            contentPadding: EdgeInsets.all(0.0),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // IconButton(
              //   icon: Icon(
              //     Icons.file_download,
              //     color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
              //   ),
              //   onPressed: onReadPressed,
              // ),
              characteristic.uuid.toString().toUpperCase().substring(4, 8) == '1001' ? ElevatedButton(
                onPressed: onWritePressed, child:Text('写入'),
              ):Text(''),

              characteristic.uuid.toString().toUpperCase().substring(4, 8) == '1002'?ElevatedButton(
                onPressed: onNotificationPressed, child: characteristic.isNotifying?Text('正在监听'):Text('开始监听'),
              ):Text(''),
            ],
          ),
        );
      },
    );
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;
  final VoidCallback? onNotificationPressed;

  const CharacteristicTile(
      {Key? key,
      required this.characteristic,
      required this.descriptorTiles,
      this.onReadPressed,
      this.onWritePressed,
      this.onNotificationPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        // if(snapshot.data!.isNotEmpty){
        //   characteristic.setNotifyValue(true);
        // }
        debugPrint('characteristicValue=$value');

        return characteristic.uuid.toString().toUpperCase().substring(4, 8) ==
                '1001' || characteristic.uuid.toString().toUpperCase().substring(4, 8) ==
            'AE01'
            ? Padding(
                padding: const EdgeInsets.only(top: 38.0),
                child: ElevatedButton(
                  onPressed: onWritePressed,
                  child: Text('修改名字'),
                ),
              )
            :const SizedBox();

        return ExpansionTile(
          title: ListTile(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Text('${characteristic.value}'),
                Text('Characteristic'),
                Text(
                    '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.caption?.color))
              ],
            ),
            subtitle: Text(value.toString()),
            contentPadding: EdgeInsets.all(0.0),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // IconButton(
              //   icon: Icon(
              //     Icons.file_download,
              //     color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
              //   ),
              //   onPressed: onReadPressed,
              // ),
              characteristic.uuid.toString().toUpperCase().substring(4, 8) ==
                      '1001'
                  ? ElevatedButton(
                      onPressed: onWritePressed,
                      child: Text('修改名字'),
                    )
                  : Text(''),

              // characteristic.uuid.toString().toUpperCase().substring(4, 8) == '1002'?IconButton(
              //   icon: Icon(
              //       characteristic.isNotifying
              //           ? Icons.sync_disabled
              //           : Icons.sync,
              //       color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
              //   onPressed: onNotificationPressed,
              // ):Text(''),

              //正在监听开关
              // characteristic.uuid.toString().toUpperCase().substring(4, 8) == '1002'?ElevatedButton(
              //   onPressed: onNotificationPressed, child: characteristic.isNotifying?Text('正在监听'):Text('开始监听'),
              // ):Text(''),
            ],
          ),
          children: descriptorTiles,
        );
      },
    );
  }
}

class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;

  const DescriptorTile(
      {Key? key,
      required this.descriptor,
      this.onReadPressed,
      this.onWritePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Descriptor'),
          Text('0x${descriptor.uuid.toString().toUpperCase().substring(4, 8)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).textTheme.caption?.color))
        ],
      ),
      subtitle: StreamBuilder<List<int>>(
        stream: descriptor.value,
        initialData: descriptor.lastValue,
        builder: (c, snapshot) => Text(snapshot.data.toString()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.file_download,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onReadPressed,
          ),
          IconButton(
            icon: Icon(
              Icons.file_upload,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onWritePressed,
          )
        ],
      ),
    );
  }
}

class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key? key, required this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.headlineSmall,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.headlineSmall?.color,
        ),
      ),
    );
  }
}
