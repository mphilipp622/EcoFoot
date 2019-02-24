// This sample shows adding an action to an [AppBar] that opens a shopping cart.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;


dynamic result = "";

double textFontSize = 26;
String productName = "";
String imageURL = "";
dynamic carbonFootprint = null;
String defaultImageURL = "https://cdn0.iconfinder.com/data/icons/thin-photography/57/thin-367_photo_image_wall_unavailable_missing-512.png";
double maxCarbonFootprint = 56236.8570281862;
double minCarbonFootprint = 835.305173958;
double maxSeverityScale = 100.0, minSeverityScale = 1.0;
String sadFace = "https://banner2.kisspng.com/20180314/lcq/kisspng-smiley-face-sadness-clip-art-crying-smiley-faces-5aa943866fec30.8620468715210423104585.jpg";
String mediumFace = "https://cdn.shopify.com/s/files/1/1061/1924/products/Neutral_Face_Emoji_large.png?v=1480481054";
String happyFace = "http://cliparts.co/cliparts/qTB/oEb/qTBoEbdMc.png";

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MyApp(),
));//MaterialApp

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
          carbonFootprint = response["score"];
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
    var url = "https://www.rivera-web.com/hack2019/api/get.php?type=upc&barcode=" + upcToSend;

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
    if(carbonFootprint == null){
      return 0.0;
    }

    return (((maxSeverityScale - minSeverityScale) * (carbonFootprint - minCarbonFootprint)) / (maxCarbonFootprint - minCarbonFootprint)) + minSeverityScale;
  }

  String getFace(){
    if(getSeverity() == 0.0){
      return "";
    }

    if(getSeverity() < 40){
      return sadFace;
    }
    else if(getSeverity() > 60){
      return happyFace;
    }
    
    return mediumFace;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    print(getSeverity());

    if(carbonFootprint != null){
      return Scaffold(
        appBar: AppBar(
          title: Text("Search"),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.search),onPressed: (){
              showSearch(context: context, delegate: DataSearch());
            })
          ]
        ),
        body: new ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20.0),
            children: [
              Container(
                child: Padding(
                  padding:EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Center(
                    child: Text(
                      productName,
                      style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold),
                    )
                  ),
                ),
              ),
              Padding(
                padding:EdgeInsets.fromLTRB(0, 10, 0, 5),
                child: Center(
                  child: Image.network(
                    imageURL,
                    fit:BoxFit.contain,
                    width: 156,
                    height: 156,
                  ),
                ),
              ),
              Padding(
                padding:EdgeInsets.fromLTRB(0, 5, 0, 45.0),
                child: Divider(
                  color: Colors.black,
                ),
              ),
              Center(
                child: Text(
                  carbonFootprint.toStringAsFixed(2) + " kJ / CO" + '\u2082' + "e",
                  style: TextStyle(fontSize: textFontSize, fontWeight:FontWeight.bold),
                ),
              ),
              Padding(
                padding:EdgeInsets.fromLTRB(0, 10.0, 0, 0),
                child: LinearProgressIndicator(
                  value: getSeverity() * .01,
                  valueColor: new AlwaysStoppedAnimation<Color>(Color.fromRGBO((1 - (getSeverity() / maxSeverityScale) * 255).toInt(), (((getSeverity() / maxSeverityScale)) * 255).toInt(), 0, 1)),
                  backgroundColor: Colors.grey,
                ),
              ),
              Padding(
                padding:EdgeInsets.fromLTRB(0, 25.0, 0, 0),
                child: Center(
                  child: Image.network(
                    getFace(),
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
          title: Text("Search"),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.search),onPressed: (){
              showSearch(context: context, delegate: DataSearch());
            })
          ]
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