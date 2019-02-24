// This sample shows adding an action to an [AppBar] that opens a shopping cart.

import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

dynamic result = "";

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MyApp(),
));//MaterialApp

class MyApp extends StatefulWidget {

  @override
  MyAppState createState() {
    return new MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  

  Future _scanQR() async{
    try{
      String qrResult = await BarcodeScanner.scan();
      setState(() {
        getCarbonFootprint(qrResult).then((response){
          result = response;
        });
      });
    }on PlatformException catch(ex){
      if(ex.code == BarcodeScanner.CameraAccessDenied){
        setState(() {
          result = "Camera permission was denied";
        });
      }else{
        setState(() {
          result = "Unknown Error $ex";
        });
      }
    }on FormatException{
      setState(() {
        result = "you pressed the back button before scanning";
      });
    }catch(ex){
      setState(() {
        result = "Unknown Error $ex";
      });
    }
  }

  getCarbonFootprint(String upcToSend) async {
    var url = "http://129.8.229.220/api/get.php?type=upc&barcode=" + upcToSend;

    final response =
      await http.get(url);

    final dynamic parsed = jsonDecode(response.body);

    print(parsed);
    
    result = parsed["name"] + "    " + parsed["carbon"].toString();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GreenGo"),
      ),
      body: Center(
        child: Text(
          result,
          style:new TextStyle(fontSize: 30.0,fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _scanQR,
          icon: Icon(Icons.camera_alt),
          label: Text("Scan")
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}