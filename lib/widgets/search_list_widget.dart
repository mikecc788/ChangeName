import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lfs_rename/res/resources.dart';

/// 搜索列表项组件
class SearchListItem extends StatelessWidget {
  final int index;
  final List<BluetoothDevice> list;
  final Function(int) clickItem;

  const SearchListItem({
    Key? key,
    required this.index,
    required this.list,
    required this.clickItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothConnectionState>(
      stream: list[index].connectionState,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildListItem(context);
      },
    );
  }

  Widget _buildListItem(BuildContext context) {
    final device = list[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => clickItem(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardBackground,
            ),
            child: _buildDeviceInfo(device),
          ),
        ),
      ),
    );
  }

  /// 构建设备信息
  Widget _buildDeviceInfo(BluetoothDevice device) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bluetooth,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                device.id.toString(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: AppColors.primary,
        ),
      ],
    );
  }

  // ... 其他辅助方法
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothAdapterState? state;

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
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Icon(Icons.bluetooth, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.device.platformName,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.device.remoteId.toString(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (result.device.platformName.contains('Air Smart'))
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                      ),
                      onPressed: onCal,
                      child: const Text('校准系数'),
                    ),
                  const SizedBox(width: 16),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                    onPressed: onTap,
                    child: const Text('修改名称'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E5E5)),
      ],
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
    debugPrint(
        'service=${service.uuid.toString().toUpperCase().substring(4, 8)}');
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
                        color: Theme.of(context).textTheme.bodySmall?.color))
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
                      child: Text('写入'),
                    )
                  : Text(''),

              characteristic.uuid.toString().toUpperCase().substring(4, 8) ==
                      '1002'
                  ? ElevatedButton(
                      onPressed: onNotificationPressed,
                      child: characteristic.isNotifying
                          ? Text('正在监听')
                          : Text('开始监听'),
                    )
                  : Text(''),
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
                    '1001' ||
                characteristic.uuid.toString().toUpperCase().substring(4, 8) ==
                    'AE01'
            ? Padding(
                padding: const EdgeInsets.only(top: 38.0),
                child: ElevatedButton(
                  onPressed: onWritePressed,
                  child: Text('修改名字'),
                ),
              )
            : const SizedBox();

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
                        color: Theme.of(context).textTheme.bodySmall?.color))
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color))
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
