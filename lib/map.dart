import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:http/http.dart' as http;
import 'package:date_format/date_format.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert' show json;
import 'dart:io';
import 'dart:async';
import 'package:covid19_analytics_app/bar_chart.dart';
import 'package:covid19_analytics_app/chart_data.dart';
import 'package:covid19_analytics_app/drawer.dart';

class GMap extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GMapState();
}

class _GMapState extends State<GMap> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  bool _isLocationBtnLoading = false;
  Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  static final CameraPosition _position = CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 14.0,
  );

  Future<void> _goToPosition(lat, lng) async {
    final CameraPosition position = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 14.0,
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _goToPosition(position.latitude, position.longitude);
    setState(() {
      _isLoading = false;
      _isLocationBtnLoading = false;
    });
  }

  _onCameraMove(CameraPosition position) {
    print(position.target);
  }

  _onSearchLocationPressed() {
    setState(() {
      _isLocationBtnLoading = true;
    });
    _getCurrentLocation();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(current_screen: "routeMap"),
      appBar: AppBar(
        title: Text("Map", style: TextStyle(fontFamily: "GothamRndMedium")),
        // actions: <Widget>[
        //   IconButton(
        //     icon: Icon(Icons.refresh),
        //     onPressed: _fetchChartData,
        //   ),
        // ]
      ),
      body: _isLoading ?
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  child: CircularProgressIndicator(
                    strokeWidth: 5.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  height: 50.0, width: 50.0,
                ),
              ],
            ),
          )
        :
          Stack(
            children: <Widget>[
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _position,
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                onCameraMove: _onCameraMove,
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Column(
                    children: <Widget>[
                      FloatingActionButton(
                        onPressed: _onSearchLocationPressed,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          _isLocationBtnLoading
                          ? Icons.location_searching
                          : Icons.location_on,
                          size: 36.0,
                        ),
                      ),
                      SizedBox(height: 16.0,),
                    ],
                  ),
                ),
              ),
            ],
          ),
      bottomNavigationBar: Container(
        height: 60.0,
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text("v2.0.0", style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 17, color: Colors.blue)),
              Text("© Harvz", style: TextStyle(fontFamily: "GothamRndMedium", fontSize: 17, color: Colors.blue)),
            ],
          )
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
