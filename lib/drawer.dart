import 'package:flutter/material.dart';

class AppDrawer extends StatefulWidget {
  String current_screen;

  AppDrawer({this.current_screen});

  @override
  State<StatefulWidget> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text("COVID19", style: TextStyle(fontSize: 20, fontFamily: "GothamRndBold")),
            accountEmail: Text("Analytics", style: TextStyle(fontSize: 17, fontFamily: "GothamRndMedium")),
            currentAccountPicture: Image.asset("assets/images/app_logo.png",),
          ),
          ListTile(
            title: Text(
              "Home",
              style: TextStyle(fontSize: 18.0),
            ),
            leading: Icon(Icons.home, color: Color(0XFF01579B)),
            onTap: () {
              widget.current_screen == "routeHome"
              ? Navigator.pop(context)
              : Navigator.pushNamed(context, "routeHome");
            }
          ),
          ListTile(
            title: Text(
              "Map",
              style: TextStyle(fontSize: 18.0),
            ),
            leading: Icon(Icons.map, color: Color(0XFF01579B)),
            onTap: () {
              widget.current_screen == "routeMap"
              ? Navigator.pop(context)
              : Navigator.pushNamed(context, "routeMap");
            }
          ),
        ],
      ),
    );
  }
}


