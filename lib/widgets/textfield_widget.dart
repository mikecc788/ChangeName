import 'package:flutter/material.dart';
class CoefficientTextField extends StatelessWidget {
  final String hintText;
  final double initialValue;
  final FocusNode  focusNode;
  final Function(String) onChange;
  const CoefficientTextField({Key? key, required this.hintText, required this.initialValue, required this.focusNode, required this.onChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController coe1 =  TextEditingController();
    coe1.addListener(() {
      // print('text=${coe1.text}');
    });
    // FocusNode  focusNode = FocusNode();
    coe1.text = '${initialValue.toStringAsFixed(12)}';
    return SizedBox(
      height: 50,
      width: 180,
      child: TextField(
        controller: coe1,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 11),
        decoration: InputDecoration(
          // labelText: hintText,
          hintText:
          hintText,
          hintStyle: const TextStyle(
              fontSize: 10
          ),

          //添加外边框
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.00),
              borderSide: const BorderSide(color: Colors.blue, width: 1)),
        ),
        onEditingComplete: (){
          focusNode.unfocus();
          debugPrint('input=${coe1.text}');
        },

        onChanged: (text) {
          onChange(text);
        },
      ),
    );
  }
}
