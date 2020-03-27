import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:convert' show json;
import 'package:covid19_analytics_app/bar_chart.dart';
import 'package:covid19_analytics_app/chart_data.dart';

class Countries extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CountriesState();
}

class _CountriesState extends State<Countries> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  RefreshController _refreshController = RefreshController();
  bool _isFetching = false;
  List _countriesData;
  List _countriesDataSearched;

  List<Widget> buildList() {
    return List.generate(_countriesDataSearched.length, (i) =>
      InkWell(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Card(
            elevation: 2.0,
            child: Column(
              children: <Widget>[
                SizedBox( height: 10.0 ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, //MainAxisAlignment.start
                    children: <Widget>[
                      SizedBox(
                        child: Image.network(_countriesDataSearched[i]["countryInfo"]["flag"]),
                        height: 30.0,
                      ),
                      Text(" " + _countriesDataSearched[i]["country"], style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 24, color: Color(0XFF002948))),
                      Text(_countriesDataSearched[i]["cases"].toString(), style: TextStyle(fontFamily: "GothamRndBold", fontSize: 24, color: Color(0XFF01579B))),
                    ],
                  ),
                ),
                Divider(color: Colors.grey.shade300, height: 8.0),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: BarChart(data: [
                    ChartData(name:"Cases", amount:_countriesDataSearched[i]["cases"], barColor: charts.ColorUtil.fromDartColor(Color(0XFF01579B))),
                    ChartData(name:"Recovered", amount:_countriesDataSearched[i]["recovered"], barColor: charts.ColorUtil.fromDartColor(Colors.green)),
                    ChartData(name:"Deaths", amount:_countriesDataSearched[i]["deaths"], barColor: charts.ColorUtil.fromDartColor(Colors.red)),
                    ChartData(name:"Active", amount:_countriesDataSearched[i]["active"], barColor: charts.ColorUtil.fromDartColor(Colors.blue)),
                    ChartData(name:"Critical", amount:_countriesDataSearched[i]["critical"], barColor: charts.ColorUtil.fromDartColor(Colors.orange)),
                  ]),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text("Total Cases: " + _countriesDataSearched[i]["cases"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 15, color: Color(0XFF01579B))),
                    Text("Total Recovered: " + _countriesDataSearched[i]["recovered"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 15, color: Colors.green)),
                    Text("Total Deaths: " + _countriesDataSearched[i]["deaths"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 15, color: Colors.red)),
                    SizedBox( height: 10.0 ),
                    Text("Cases Today: " + _countriesDataSearched[i]["todayCases"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 15, color: Colors.blue)),
                    Text("Deaths Today: " + _countriesDataSearched[i]["todayDeaths"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 15, color: Colors.red)),
                    SizedBox( height: 10.0 ),
                    Text("Active: " + _countriesDataSearched[i]["active"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 15, color: Colors.blue)),
                    Text("Critical: " + _countriesDataSearched[i]["critical"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 15, color: Colors.orange)),
                    SizedBox( height: 10.0 ),
                    Text("Cases Per One Million: " + _countriesDataSearched[i]["casesPerOneMillion"].toString(), style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 15, color: Colors.blue)),
                  ],
                ),
                SizedBox( height: 20.0 ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fetchCountriesData() async {
    if (!_isFetching) {
      setState(() {
        _isFetching = true;
      });

      final response = await http.get("https://corona.lmao.ninja/countries");
      if (response.statusCode == 200) {
        setState(() {
          _countriesData = json.decode(response.body);
          _countriesDataSearched = json.decode(response.body);
          _isFetching = false;
        });
        _countriesData.sort((a, b) => (b["cases"]).compareTo(a["cases"]));
        _countriesDataSearched.sort((a, b) => (b["cases"]).compareTo(a["cases"]));
        _refreshController.refreshCompleted();
      } else {
        _scaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text("Make sure you have internet connection.", style: TextStyle(fontFamily: "GothamRndMedium", color: Colors.white)),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              textColor: Colors.white,
              label: "Try Again",
              onPressed: _fetchCountriesData,
            ),
          )
        );
      }
    }
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
    _fetchCountriesData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: "Search",
            hintStyle: TextStyle(fontFamily: "GothamRndMedium", fontSize: 20, color: Colors.white),
            suffixIcon: Icon(Icons.search, color: Colors.white)
          ),
          style: TextStyle(
            fontFamily: "GothamRndMedium",
            fontSize: 20,
            color: Colors.white,
          ),
          onChanged: (text){
            text = text.toLowerCase();
            if (text == "") {
              setState(() { _countriesDataSearched = _countriesData; });
            } else {
              setState(() {
                _countriesDataSearched = _countriesDataSearched.where((country) {
                  return country["country"].toLowerCase().contains(text);
                }).toList();
              });
            }
          }
        ),
      ),
      body: _isFetching ?
        Container(
          child: Center(
            child: SizedBox(
              child: CircularProgressIndicator(
                strokeWidth: 5.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              height: 50.0, width: 50.0,
            ),
          ),
        )
      :
        SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          onRefresh: _fetchCountriesData,
          child: CustomScrollView(
            slivers: [SliverList(delegate: SliverChildListDelegate(buildList()))],
          ),
        ),
    );
  }
}
