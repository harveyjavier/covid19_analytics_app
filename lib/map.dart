import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:http/http.dart' as http;
import 'package:date_format/date_format.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localstorage/localstorage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final db = Firestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  static final CameraPosition _position = CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 14.0,
  );
  bool _isIPfetched = false;
  bool _isLocationFetched = false;
  bool _isDataFetched = false;
  bool _isLocationBtnLoading = false;
  String _ipAddress;
  double _currentLat;
  double _currentLng;
  Map _userData;

  void _goToPosition(lat, lng) async {
    final CameraPosition position = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 14.0,
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  void _getCurrentLocation() async {
    final position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _goToPosition(position.latitude, position.longitude);
    setState(() {
      _currentLat = position.latitude;
      _currentLng = position.longitude;
      _isLocationBtnLoading = false;
      _isLocationFetched = true;
    });
  }

  void _addData() async {
    Map data = {
      "lat": _currentLat,
      "lng": _currentLng,
      "created_at": null, //FieldValue.serverTimestamp(),
    };
    DocumentReference ref = await db.collection("location_data").add({
      "ip_address": _ipAddress,
      "data": [data],
      "created_at": FieldValue.serverTimestamp(),
    });
  }

  void _fetchData() async {
    final QuerySnapshot location_result = await db.collection("location_data").getDocuments();
    final List<DocumentSnapshot> location_docs = location_result.documents;
    //print(location_docs);
    location_docs.forEach((d) {
      print(d.documentID);
      d.data["id"] = d.documentID;
      if (d.data["ip_address"] == _ipAddress.toString()) {
        setState(() {
          _userData = d.data;
        });
        print(_userData);
      }
    });
    if (_userData == null) {
      _addData();
    }
    setState(() {
      _isDataFetched = true;
    });

    //edit
    //await db.collection("location_data").document(_posts[i]["id"]).updateData(
  }

  _getIPaddress(){
    NetworkInterface.list(includeLoopback: false, type: InternetAddressType.any).then((List<NetworkInterface> interfaces) {
      setState(() {
        _ipAddress = "";
        interfaces.forEach((interface) {
          //_ipAddress += "### name: ${interface.name}\n";
          interface.addresses.forEach((address) {
            _ipAddress += "${address.address}";
          });
        });
        _isIPfetched = true;
      });
      print(_ipAddress);
    });
  }

  _onCameraMove(CameraPosition position) {
    //print(position.target);
  }

  _onSearchLocationPressed() {
    setState(() {
      _isLocationFetched = true;
      _isLocationBtnLoading = true;
    });
    _getCurrentLocation();
  }

  @override
  void initState() {
    super.initState();
    _getIPaddress();
    _getCurrentLocation();
    _fetchData();
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
      body: _isIPfetched && _isLocationFetched && _isDataFetched ?
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
          )
        :
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
