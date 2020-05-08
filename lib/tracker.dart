import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:date_format/date_format.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localstorage/localstorage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'dart:convert' show json;
import 'dart:io';
import 'dart:async';
import 'package:covid19_analytics_app/bar_chart.dart';
import 'package:covid19_analytics_app/chart_data.dart';
import 'package:covid19_analytics_app/drawer.dart';

class Tracker extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TrackerState();
}

class TrackerState extends State<Tracker> with SingleTickerProviderStateMixin {
  final db = Firestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor markerIcon;
  final Set<Marker> _markers = {};
  static final CameraPosition _position = CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 14.0,
  );
  String _mapStyle;
  bool _isIPfetched = false;
  bool _isLocationFetched = false;
  bool _isUserFetched = false;
  bool _isLocationBtnLoading = false;
  bool _isMarkingLocations = false;
  String _ipAddress;
  double _currentLat;
  double _currentLng;
  Map _userData;
  DateTime _dateFrom;
  DateTime _dateTo;

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

  void _storeLocation() async {
    Map<String,dynamic> locationData = new Map<String,dynamic>();
    locationData["user_id"] = _userData["id"];
    locationData["latitude"] = _currentLat;
    locationData["longitude"] = _currentLng;
    locationData["created_at"] = FieldValue.serverTimestamp();
    DocumentReference ref = await db.collection("location_data").add(locationData);
  }

  void _checkIfLocationExistedInDateHour() async {
    final QuerySnapshot ld_result = await db.collection("location_data").getDocuments();
    final List<DocumentSnapshot> ld_docs = ld_result.documents;
    bool locationExisted = false;
    ld_docs.forEach((ld) {
      String dateHourNow = formatDate(DateTime.now(), [yyyy, " ", M, " ", d, " ", h, " ", am]);
      String createdAt = formatDate(ld.data["created_at"].toDate(), [yyyy, " ", M, " ", d, " ", h, " ", am]);
      if ((ld.data["user_id"] == _userData["id"]) && (dateHourNow == createdAt)) {
        locationExisted = true;
      }
    });
    if (!locationExisted) {
      _storeLocation();
    }
  }

  void _addUser() async {
    Map<String,dynamic> userData = new Map<String,dynamic>();
    userData["ip_address"] = _ipAddress;
    userData["created_at"] = FieldValue.serverTimestamp();
    DocumentReference ref = await db.collection("users").add(userData);
    userData["id"] = ref.documentID;
    setState(() {
      _userData = userData;
    });
    _checkIfLocationExistedInDateHour();
  }

  void _fetchUser() async {
    final QuerySnapshot users_result = await db.collection("users").getDocuments();
    final List<DocumentSnapshot> users_docs = users_result.documents;
    users_docs.forEach((u) {
      if (u.data["ip_address"] == _ipAddress.toString()) {
        setState(() {
          _userData = u.data;
          _userData["id"] = u.documentID;
        });
      }
    });
    if (_userData == null) {
      _addUser();
    } else {
      _checkIfLocationExistedInDateHour();
    }
    setState(() {
      _isUserFetched = true;
    });
  }

  void _markLocations() async {
    setState(() {
      _isMarkingLocations = true;
    });
    final QuerySnapshot ld_result = await db.collection("location_data").getDocuments();
    final List<DocumentSnapshot> ld_docs = ld_result.documents;
    ld_docs.forEach((ld) {
      final createdAt = DateTime.parse(formatDate(ld.data["created_at"].toDate(), [yyyy, "-", mm, "-", dd]));
      int compareFrom = createdAt.compareTo(_dateFrom);
      int compareTo = createdAt.compareTo(_dateTo);
      final lat = ld.data["latitude"] is String ? double.parse(ld.data["latitude"]) : ld.data["latitude"];
      final lng = ld.data["longitude"] is String ? double.parse(ld.data["longitude"]) : ld.data["longitude"];
      // print("created at: " + createdAt.toString());
      // print("from: " + createdAt.compareTo(_dateFrom).toString());
      // print("to: " + createdAt.compareTo(_dateTo).toString());
      // print("\n");
      if ((compareFrom == 0 || compareFrom == 1) && (compareTo == 0 || compareTo == -1)) {
        print(createdAt);
        setState(() {
          _markers.add(Marker(
            markerId: MarkerId(LatLng(lat, lng).toString()),
            position: LatLng(lat, lng),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: lat.toString() + "," + lng.toString(),
              snippet: "" + formatDate(ld.data["created_at"].toDate(), [MM, " ", dd, ", ", yyyy, " at ", h, ":", nn, " ", am]),
            ),
          ));
        });
      }
    });
    setState(() {
      _isMarkingLocations = false;
    });
    Navigator.pop(context, false);
  }

  void _onInfo() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("About the Tracker module", style: TextStyle(fontFamily: "GothamRndBold", fontSize: 20, color: Color(0XFF002948)),),
        content: Container(
          height: 320.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text("This module stores your current location to our database which can be used later on for contact tracing purposes.", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948)),),
              SizedBox(height: 10.0,),
              Text("Navigation:", style: TextStyle(fontFamily: "GothamRndBold", color: Color(0XFF002948))),
              SizedBox(height: 10.0,),
              Row(
                children: <Widget>[
                  FloatingActionButton(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.location_on, size: 36.0, ),
                  ),
                  Text(" - reloads your current location.", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948))),
                ],
              ),
              SizedBox(height: 10.0,),
              Row(
                children: <Widget>[
                  FloatingActionButton(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.search, size: 36.0, ),
                  ),
                  Text(" - search your locations by date.", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948))),
                ],
              ),
              SizedBox(height: 10.0,),
              Row(
                children: <Widget>[
                  FloatingActionButton(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.location_off, size: 36.0, ),
                  ),
                  Text(" - clear all pins in the map.", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948))),
                ],
              ),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text("Close", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948)),),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  void _onLocatePressed() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reload Current Location?", style: TextStyle(fontFamily: "GothamRndBold", fontSize: 20, color: Color(0XFF002948)),),
        content: Text("Are you sure you want to reload and find your current location?", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948)),),
        actions: <Widget>[
          FlatButton(
            child: Text("Yes", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948)),),
            onPressed: () => _reloadCurrentLocation(),
          ),
          FlatButton(
            child: Text("No", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948)),),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  void _onSearchPressed() async {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Search my locations", style: TextStyle(fontFamily: "GothamRndBold", fontSize: 20, color: Color(0XFF002948)),),
              content: Container(
                height: 170.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text("Date From: ", style: TextStyle(fontFamily: "GothamRndBold", color: Color(0XFF002948))),
                        RaisedButton(
                          child: Text(_dateFrom == null ? "Pick a Date" : formatDate(_dateFrom, [yyyy, "-", MM, "-", dd]), style: TextStyle(fontFamily: "GothamRndBold", color: Colors.white)),
                          color: Colors.blue,
                          onPressed: () {
                            showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1970),
                              lastDate: DateTime.now(),
                            ).then((date) {
                              setState(() {
                                _dateFrom = date;
                              });
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0,),
                    Row(
                      children: <Widget>[
                        Text("Date To: ", style: TextStyle(fontFamily: "GothamRndBold", color: Color(0XFF002948))),
                        RaisedButton(
                          child: Text(_dateTo == null ? "Pick a Date" : formatDate(_dateTo, [yyyy, "-", MM, "-", dd]), style: TextStyle(fontFamily: "GothamRndBold", color: Colors.white)),
                          color: Colors.blue,
                          onPressed: () {
                            showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: _dateFrom == null ? DateTime(1970) : _dateFrom,
                              lastDate: DateTime.now(),
                            ).then((date) {
                              setState(() {
                                _dateTo = date;
                              });
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: _dateFrom == null || _dateTo == null
                ? <Widget>[
                    FlatButton(
                      child: Text("Close", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948)),),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ]
                : <Widget>[
                    FlatButton(
                      child: Text("Search", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948)),),
                      onPressed: () => _markLocations(),
                    ),
                    FlatButton(
                      child: Text("Close", style: TextStyle(fontFamily: "GothamRndMedium", color: Color(0XFF002948)),),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
            );
          },
        );
      }
    );
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
      //print(_ipAddress);
    });
  }

  _onCameraMove(CameraPosition position) {
    //print(position.target);
  }

  _reloadCurrentLocation() {
    setState(() {
      _isLocationFetched = true;
      _isLocationBtnLoading = true;
    });
    _getCurrentLocation();
    _checkIfLocationExistedInDateHour();
    Navigator.pop(context, false);
  }

  _onClearMarkers() {
  }

  @override
  void initState() {
    super.initState();
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/images/marker.png').then((onValue) {
      markerIcon = onValue;
    });
    rootBundle.loadString('assets/map_styles/silver.txt').then((string) {
      _mapStyle = string;
    });
    _getIPaddress();
    _getCurrentLocation();
    _fetchUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(current_screen: "routeTracker"),
      appBar: AppBar(
        title: Text("Tracker", style: TextStyle(fontFamily: "GothamRndMedium")),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info, color: Colors.white),
            onPressed: _onInfo,
          ),
        ]
      ),
      body: _isIPfetched && _isLocationFetched && _isUserFetched ?
          Stack(
            children: <Widget>[
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _position,
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  controller.setMapStyle(_mapStyle);
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
                        onPressed: () {
                          if (!_isLocationBtnLoading)
                            { _onLocatePressed(); }
                        },
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.blue,
                        child: _isLocationBtnLoading
                          ? SizedBox(
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              height: 17.0, width: 17.0,
                            )
                          : Icon(Icons.location_on, size: 36.0,),
                      ),
                      SizedBox(height: 16.0,),
                      FloatingActionButton(
                        onPressed: () {
                          if (!_isMarkingLocations)
                           { _onSearchPressed(); }
                        },
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.blue,
                        child: _isMarkingLocations
                          ? SizedBox(
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              height: 17.0, width: 17.0,
                            )
                          : Icon(Icons.search, size: 36.0,),
                      ),
                      SizedBox(height: 16.0,),
                      FloatingActionButton(
                        onPressed: _onClearMarkers(),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.location_off, size: 36.0, ),
                      ),
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
    super.dispose();
  }
}
