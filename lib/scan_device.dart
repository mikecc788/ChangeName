import 'dart:async';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lfs_rename/res/colors.dart';
import 'package:lfs_rename/res/resources.dart';
import 'package:lfs_rename/widgets/search_list_widget.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'calibration.dart';

class FindDevicesScreen extends StatefulWidget {
  /// 扫描设备页面
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  /// 扫描超时时间
  static const Duration _scanTimeout = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.startScan(timeout: _scanTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          '设备列表',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => FlutterBluePlus.startScan(timeout: _scanTimeout),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              _buildConnectedDevices(),
              _buildScanResults(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildScanButton(),
    );
  }

  /// 构建已连接设备列表
  Widget _buildConnectedDevices() {
    return StreamBuilder<List<BluetoothDevice>>(
      stream: Stream.periodic(const Duration(seconds: 2))
          .asyncMap((_) => FlutterBluePlus.connectedDevices),
      initialData: const [],
      builder: (c, snapshot) => Column(
        children: snapshot.data!.map((d) => _buildDeviceCard(d)).toList(),
      ),
    );
  }

  /// 构建设备卡片
  Widget _buildDeviceCard(BluetoothDevice device) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Column(
            children: [
              _buildDeviceInfo(device),
              const SizedBox(height: 8),
              _buildDeviceButtons(device),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E5E5)),
      ],
    );
  }

  /// 构建扫描结果列表
  Widget _buildScanResults() {
    return StreamBuilder<List<ScanResult>>(
      stream: FlutterBluePlus.scanResults,
      initialData: const [],
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
    );
  }

  /// 构建扫描按钮
  Widget _buildScanButton() {
    return StreamBuilder<bool>(
      stream: FlutterBluePlus.isScanning,
      initialData: false,
      builder: (c, snapshot) {
        if (snapshot.data!) {
          return FloatingActionButton(
            onPressed: () => FlutterBluePlus.stopScan(),
            backgroundColor: AppColors.error,
            child: const Icon(Icons.stop, color: AppColors.textLight),
          );
        } else {
          return FloatingActionButton(
            onPressed: () => FlutterBluePlus.startScan(timeout: _scanTimeout),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.refresh, color: AppColors.textLight),
          );
        }
      },
    );
  }

  /// 构建设备信息
  Widget _buildDeviceInfo(BluetoothDevice device) {
    return Row(
      children: <Widget>[
        Icon(Icons.bluetooth, color: Colors.blue[700], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            device.platformName,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildConnectionButton(device),
      ],
    );
  }

  /// 构建设备按钮
  Widget _buildDeviceButtons(BluetoothDevice device) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (device.platformName.contains('Air Smart'))
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[700],
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AirSmartCalibra(device: device))),
            child: const Text('校准系数'),
          ),
        const SizedBox(width: 16),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue[700],
          ),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => DeviceScreen(device: device))),
          child: const Text('修改名称'),
        ),
      ],
    );
  }

  /// 构建连接按钮
  Widget _buildConnectionButton(BluetoothDevice device) {
    return StreamBuilder<BluetoothConnectionState>(
      stream: device.connectionState,
      initialData: BluetoothConnectionState.disconnected,
      builder: (c, snapshot) {
        if (snapshot.data == BluetoothConnectionState.connected) {
          return TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            onPressed: () => device.disconnect(),
            child: const Text('断开'),
          );
        }
        return const SizedBox();
      },
    );
  }

  // ... 其他辅助方法
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  Widget build(BuildContext context) {
    bool isDiscoverSer = false;
    int textLength = 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: Text(
          device.name,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: <Widget>[
          StreamBuilder<BluetoothConnectionState>(
            stream: device.connectionState,
            initialData: BluetoothConnectionState.disconnected,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              Color buttonColor;
              switch (snapshot.data) {
                case BluetoothConnectionState.connected:
                  onPressed = () => device.disconnect();
                  text = '断开连接';
                  buttonColor = Colors.red;
                  break;
                case BluetoothConnectionState.disconnected:
                  onPressed = () => device.connect();
                  text = '连接';
                  buttonColor = Colors.blue[700]!;
                  break;
                default:
                  onPressed = null;
                  text = '连接中';
                  buttonColor = Colors.grey;
                  break;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: buttonColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                    if (!isDiscoverSer) {
                      isDiscoverSer = true;
                      Future.delayed(Duration.zero, () async {
                        debugPrint('Discovering services for $device');
                        try {
                          await device.discoverServices();
                        } catch (e) {
                          debugPrint('Error discovering services: $e');
                        }
                      });
                    }
                    return const SizedBox();
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
                  );
                }),
            StreamBuilder<List<BluetoothService>>(
              stream: Stream.value(device.servicesList),
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
      if (service.uuid.toString().toUpperCase() == "AE00") {
        List<BluetoothCharacteristic> characteristics = service.characteristics;
        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString().toUpperCase() == "AE01") {
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
            element.uuid.toString().toUpperCase() == "1000" ||
            element.uuid.toString().toUpperCase() == "AE00")
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .where((c) =>
                    c.uuid.toString().toUpperCase() == "1001" ||
                    c.uuid.toString().toUpperCase() == "AE01")
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () async {
                      nameController.text = device.platformName;
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
                                    'insert=$bleData cha=${c.uuid.toString().toUpperCase()}');
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

/// 服务项组件
class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile({
    Key? key,
    required this.service,
    required this.characteristicTiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

/// 特征值项组件
class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;
  final VoidCallback? onNotificationPressed;

  const CharacteristicTile({
    Key? key,
    required this.characteristic,
    required this.descriptorTiles,
    this.onReadPressed,
    this.onWritePressed,
    this.onNotificationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return characteristic.uuid.toString().toUpperCase() == '1001' ||
            characteristic.uuid.toString().toUpperCase() == 'AE01'
        ? Padding(
            padding: const EdgeInsets.only(top: 38.0),
            child: ElevatedButton(
              onPressed: onWritePressed,
              child: const Text('修改名字'),
            ),
          )
        : const SizedBox();
  }
}

/// 描述符项组件
class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;

  const DescriptorTile({
    Key? key,
    required this.descriptor,
    this.onReadPressed,
    this.onWritePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Descriptor'),
          Text(
            '0x${descriptor.uuid.toString().toUpperCase()}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
          )
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
