import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lfs_rename/res/resources.dart';

class SearchListItem extends StatelessWidget {
  final int index;
  final List<BluetoothDevice> list;
  final Function(int) clickItem;
  const SearchListItem({Key? key, required this.index, required this.list, required this.clickItem}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    String title = list[index].name;
    String detail = list[index].id.toString();
    double titleSize = Platform.isIOS?24:18;
    double detailSize = Platform.isIOS?18:14;
    return StreamBuilder<BluetoothDeviceState>(
        stream: list[index].state,
        builder: (context, snapshot) {
          // LogD('snapshot=${snapshot.data}');
          if(!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }
          return  Padding(
            padding: const EdgeInsets.only(left: 20,top: 20,right: 20),
            child: GestureDetector(
              onTap:()=> clickItem(index),
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
                            padding: const EdgeInsets.only(left: kDefaultLeftPadding,top: 20,bottom: 18),
                            child: AutoSizeText(title,maxLines: 2,style: TextStyle(color: Colours.bar_color,fontWeight: FontWeight.w600,fontSize: titleSize),),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: kDefaultLeftPadding,bottom: 40),
                            child: AutoSizeText(detail,maxLines: 2,style: TextStyle(color: Colours.bar_color,fontSize: detailSize),),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          );
        }
    );
  }



}
