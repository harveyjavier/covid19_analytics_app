import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:http/http.dart' as http;
import 'package:date_format/date_format.dart';
import 'dart:convert' show json;

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // Animation animation;
  // AnimationController animationController;
  bool _isFetching = false;
  Map _allData;

  void _fetchAllData() async {
    if (!_isFetching) {
      setState(() {
        _isFetching = true;
      });

      final response = await http.get("https://corona.lmao.ninja/all");
      if (response.statusCode == 200) {
        setState(() {
          _allData = json.decode(response.body);
          _isFetching = false;
        });
      } else {
        _scaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text("Make sure you have internet connection.", style: TextStyle(fontFamily: "GothamRndMedium", color: Colors.white)),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              textColor: Colors.white,
              label: "Try Again",
              onPressed: _fetchAllData,
            ),
          )
        );
      }
    }
  }

  _timestampToDate(ts){
    var date = new DateTime.fromMillisecondsSinceEpoch(_allData["updated"]);
    var fd = formatDate(date, [MM, " ", d, ", ", yyyy, ", ", HH, ":", nn, " ", am]);
    return fd;
  }

  @override
  void initState() {
    super.initState();
    // animationController = AnimationController(
    //   duration: Duration(milliseconds: 3000), vsync: this
    // );
    // animation = Tween(begin: 0.0, end: 1500.0).animate(animationController)
    //   ..addListener(() {
    //     setState(() {});
    //   });
    // animationController.forward();
    _fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("COVID-19 Analytics", style: TextStyle(fontFamily: "GothamRndMedium")),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAllData,
          ),
        ]
      ),
      body: Center(
        child: Container(
          // height: animation.value,
          // width: animation.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _isFetching ?
                <Widget>[
                  SizedBox(
                    child: CircularProgressIndicator(
                      strokeWidth: 10.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    height: 100.0, width: 100.0,
                  ),
                ]
              : <Widget>[
                  Image.asset(
                    "assets/images/app_logo.png",
                    width: 240,
                    height: 240,
                    fit:BoxFit.fill,
                  ),
                  SizedBox( height: 20.0 ),
                  Text("COVID-19", style: TextStyle(fontFamily: "GothamRndBold", fontSize: 30, color: Colors.blue)),
                  SizedBox( height: 20.0 ),
                  Text("Cases: " + _allData["cases"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 24, color: Colors.blue)),
                  Text("Deaths: " + _allData["deaths"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 24, color: Colors.red)),
                  Text("Recovered: " + _allData["recovered"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 24, color: Colors.green)),
                  SizedBox( height: 5.0 ),
                  Text("as of " + _timestampToDate(_allData["recovered"]), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 20, color: Colors.blue)),
                  SizedBox( height: 20.0 ),
                  ButtonTheme(
                    minWidth: 300,
                    child: Center(
                      child: RaisedButton(
                        padding: EdgeInsets.all(10.0),
                        color: Colors.blue,
                        textColor: Colors.white,
                        child: Text("Countries", style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 24)),
                        onPressed: () => { Navigator.pushNamed(context, "routeCountries") },
                      ),
                    ),
                  ),
                ]
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 40.0,
        color: Colors.white,
        child: Center(
          child: Text("© Harvz", style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 17, color: Colors.blue)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //animationController.dispose();
    super.dispose();
  }
}
