import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UiHelper {
  static CustomTextField(TextEditingController controller, String text,
      IconData iconData, bool toHide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      child: TextField(
        controller: controller,
        obscureText: toHide,
        decoration: InputDecoration(
            hintText: text,
            suffixIcon: Icon(iconData),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25)
            ) //OutlineInputBorder
        ), // InputDecoration
      ),
    ); //TextField
  }

  static CustomButton(VoidCallback voidCallback, String text){
    return SizedBox(
      height: 50, width: 300, child: ElevatedButton(onPressed: () {
      voidCallback();
    },
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)
        )),
        child: Text(text, style: TextStyle(color: Colors.purple,
            fontSize: 20),)),); //Elevated Button, SizedBox
  }

  static CustomAlertBox(BuildContext context, String text) {
    return showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: Text(text),
      );
    });
  }
}