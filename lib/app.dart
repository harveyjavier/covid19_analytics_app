import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:covid19_analytics_app/home.dart';
import 'package:covid19_analytics_app/countries.dart';
import 'package:covid19_analytics_app/map.dart';

class App extends StatelessWidget {
  final materialApp = MaterialApp(
    title: "Flutter Workshop",
    theme: ThemeData(
      primaryColor: Colors.blue,
      fontFamily: "GothamRndBook",
      cursorColor: Colors.blue,
      textSelectionColor: Colors.blue.withOpacity(0.2),
      textSelectionHandleColor: Colors.blue,
      dialogBackgroundColor: Colors.white,
    ),
    debugShowCheckedModeBanner: false,
    showPerformanceOverlay: false,
    home: Home(),
    routes: <String, WidgetBuilder>{
      "routeHome": (BuildContext context) => Home(),
      "routeCountries": (BuildContext context) => Countries(),
      "routeMap": (BuildContext context) => GMap(),
    },
  );

  @override
  Widget build(BuildContext context) {
    return materialApp;
  }
}
