// This sample shows adding an action to an [AppBar] that opens a shopping cart.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
          title: Text("Search"),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.search),onPressed: (){
              showSearch(context: context, delegate: DataSearch());
            })
          ]
      ),
      drawer: Drawer(),
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

class DataSearch extends SearchDelegate<String>{
  final items = ["Red Bull", "Chips"];
  final recentSearch = [];
  @override
  List<Widget> buildActions(BuildContext context) {
    //actions for app bar
    return [IconButton(icon:Icon(Icons.clear),onPressed: (){
      query = "";
    },)];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    //leading icon on the left of the app bar
    return IconButton(icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation),
    onPressed: (){
      close(context, null);
    });
  }

  @override
  Widget buildResults(BuildContext context) {
    //show results
    return null;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    //show when someone searches
    final searchList = query.isEmpty?recentSearch:

    items.where((p)=> p.startsWith(query)).toList();

    return ListView.builder(
      itemBuilder: (context,index) => ListTile(
      leading: Icon(Icons.search),
      title: Text(searchList[index]),
        ),
      itemCount: searchList.length,
    );
  }
}