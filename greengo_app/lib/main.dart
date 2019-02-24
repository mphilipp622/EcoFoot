// This sample shows adding an action to an [AppBar] that opens a shopping cart.

import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;


dynamic result = "";

double textFontSize = 26;
String productName = "Product Name";
String imageURL = "";
int carbonFootprint = 12;
String defaultImageURL = "https://cdn0.iconfinder.com/data/icons/thin-photography/57/thin-367_photo_image_wall_unavailable_missing-512.png";
int maxCarbonFootprint = 0;
int minCarbonFootprint = 0;
double _sliderValue = 1.0;
double maxSeverityScale = 100, minSeverityScale = 1;

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MyApp(),
));//MaterialApp

setMinAndMaxCarbonFootprint() async{
  var url = "http://129.8.229.220/api/get.php?type=upc&barcode=";

    final response = await http.get(url);

      if (response.statusCode == 200) {
        // If server returns an OK response, parse the JSON
        final dynamic parsed = jsonDecode(response.body);

        maxCarbonFootprint = parsed["max"];
        minCarbonFootprint = parsed["min"];
      }  
      else {
        // If that response was not OK, throw an error.
        throw Exception('Failed to load get');
      }
}

class MyApp extends StatefulWidget {

  @override
  MyAppState createState() {
    // setMinAndMaxCarbonFootprint();
    return new MyAppState();
  }
}

Path _triangle(double size, Offset thumbCenter, {bool invert = false}) {
  final Path thumbPath = Path();
  final double height = math.sqrt(3.0) / 2.0;
  final double halfSide = size / 2.0;
  final double centerHeight = size * height / 3.0;
  final double sign = invert ? -1.0 : 1.0;
  thumbPath.moveTo(thumbCenter.dx - halfSide, thumbCenter.dy + sign * centerHeight);
  thumbPath.lineTo(thumbCenter.dx, thumbCenter.dy - 2.0 * sign * centerHeight);
  thumbPath.lineTo(thumbCenter.dx + halfSide, thumbCenter.dy + sign * centerHeight);
  thumbPath.close();
  return thumbPath;
}

class _CustomValueIndicatorShape extends SliderComponentShape {
  static const double _indicatorSize = 4.0;
  static const double _disabledIndicatorSize = 3.0;
  static const double _slideUpHeight = 40.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(isEnabled ? _indicatorSize : _disabledIndicatorSize);
  }

  static final Animatable<double> sizeTween = Tween<double>(
    begin: _disabledIndicatorSize,
    end: _indicatorSize,
  );

  @override
  void paint(
    PaintingContext context,
    Offset thumbCenter, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    final Canvas canvas = context.canvas;
    final ColorTween enableColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.valueIndicatorColor,
    );
    final Tween<double> slideUpTween = Tween<double>(
      begin: 0.0,
      end: _slideUpHeight,
    );
    final double size = _indicatorSize * sizeTween.evaluate(enableAnimation);
    final Offset slideUpOffset = Offset(0.0, -slideUpTween.evaluate(activationAnimation));
    final Path thumbPath = _triangle(
      size,
      thumbCenter + slideUpOffset,
      invert: true,
    );
    final Color paintColor = enableColor.evaluate(enableAnimation).withAlpha((255.0 * activationAnimation.value).round());
    canvas.drawPath(
      thumbPath,
      Paint()..color = paintColor,
    );
    canvas.drawLine(
        thumbCenter,
        thumbCenter + slideUpOffset,
        Paint()
          ..color = paintColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
    labelPainter.paint(canvas, thumbCenter + slideUpOffset + Offset(-labelPainter.width / 2.0, -labelPainter.height - 4.0));
  }
}

class MyAppState extends State<MyApp> {
  
  Future _scanQR() async{
    try{
      String upcResult = await BarcodeScanner.scan();
      await getDataFromUPC(upcResult).then((response){

        if(response["name"] != null){
          productName = response["name"];
          carbonFootprint = response["carbon"];
        }
        else{
          productName = "Cannot Find That Product";
          carbonFootprint = null;
        }

          if(response["image"] != null){
            imageURL = response["image"];
          }
          else{
            imageURL = defaultImageURL;
          }
      });
      setState(() {
        
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

  getDataFromUPC(String upcToSend) async {
    var url = "http://129.8.229.220/api/get.php?type=upc&barcode=" + upcToSend;

    final response =
      await http.get(url);

      if (response.statusCode == 200) {
        // If server returns an OK response, parse the JSON
        final dynamic parsed = jsonDecode(response.body);

        print(parsed);
        
        // result = parsed["name"] + "    " + parsed["carbon"].toString();

        return parsed;
      }  
      else {
        // If that response was not OK, throw an error.
        throw Exception('Failed to load get');
      }
  }

  double getSeverity(){
    return (((maxSeverityScale - minSeverityScale) * (carbonFootprint - minCarbonFootprint)) / (maxCarbonFootprint - minCarbonFootprint)) + minSeverityScale;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if(carbonFootprint != null){
      return Scaffold(
        appBar: AppBar(
          title: Text("GreenGo"),
        ),
        body: new ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20.0),
            children: [
              Padding(
                padding:EdgeInsets.fromLTRB(0, 0, 0, 30.0),
                child: Center(
                  child: Text(
                    productName,
                    style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold),
                  )
                ),
              ),
              Center(
                child: Text(
                  carbonFootprint.toString(),
                  style: TextStyle(fontSize: textFontSize, fontWeight:FontWeight.bold),
                )
              ),
              LinearProgressIndicator(
                value: 80.0 * .01,
                valueColor: new AlwaysStoppedAnimation<Color>(Color.fromRGBO(((80 / 100) * 255).toInt(), ((1 - (80 / 100)) * 255).toInt(), 0, 1)),
              ),
              Padding(
                padding:EdgeInsets.fromLTRB(0, 30.0, 0, 0),
                child: Center(
                  child: Image.network(
                    imageURL,
                    fit:BoxFit.contain,
                    width: 128,
                    height: 128,
                  ),
                ),
              ),
            ],
          ),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _scanQR,
            icon: Icon(Icons.camera_alt),
            label: Text("Scan")
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    }
    else{
      return Scaffold(
        appBar: AppBar(
          title: Text("GreenGo"),
        ),
        body: new ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20.0),
            children: [
              Padding(
                padding:EdgeInsets.fromLTRB(0, 0, 0, 30.0),
                child: Center(
                  child: Text(
                    productName,
                    style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold),
                  )
                ),
              ),
            ],
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
}