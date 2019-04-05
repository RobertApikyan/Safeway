import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms/sms.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'safeway',
        home: Home(),
      );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin<Home> {
  var _tk = 'tk';
  double _left = 18.0;
  double _width = 1.0;
  bool _perm = false;
  int _dColor = 0;
  TextEditingController _telCtrl;
  CameraPosition _camPos = CameraPosition(target: LatLng(0, 0));
  SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _telCtrl = TextEditingController()
      ..addListener(() {
        _prefs?.setString(_tk, _telCtrl.text);
      });
    init();
  }

  void init() async {
    await PermissionHandler().requestPermissions(
        [PermissionGroup.phone, PermissionGroup.sms, PermissionGroup.location]);
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _perm = true;
      _telCtrl.text = _prefs.getString(_tk);
    });
  }

  void sendSms() {
    final tel = _telCtrl.text;
    if (tel.isEmpty) return;
    SmsSender().sendSms(SmsMessage(tel,
        'Emergency message from location \n http://www.google.com/maps/place/${_camPos.target.latitude},${_camPos.target.longitude}'));
  }

  @override
  Widget build(BuildContext context) {
    _width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        height: double.infinity,
        color: Colors.black54.withAlpha(_dColor),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: <Widget>[
            GoogleMap(
              myLocationEnabled: _perm,
              initialCameraPosition: _camPos,
              onCameraMove: (pos) => _camPos = pos,
            ),
            Visibility(
                visible: _left > 18,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black54.withAlpha(_dColor),
                  alignment: Alignment.center,
                )),
            Center(
                child: Transform.translate(
                    offset: Offset(0, -25),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blueGrey.withRed(_dColor),
                      size: 50,
                    ))),
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(vertical: 62, horizontal: 16),
              padding: EdgeInsets.only(left: 88),
              width: double.infinity,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 1, color: Colors.grey),
                  borderRadius: BorderRadius.all(Radius.circular(48))),
              child: TextField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration.collapsed(
                    hintText: 'Enter Emergency Number',
                    hintStyle: TextStyle(
                        color: Color.fromARGB(
                            255, _telCtrl.text.isEmpty ? _dColor : 0, 0, 0),
                        fontSize: 12)),
              ),
            ),
            AnimatedPositioned(
              left: _left,
              child: Listener(
                onPointerMove: (event) {
                  var dx = event.position.dx - 34;
                  _dColor = (_left - 17) * 255 ~/ _width;
                  if (dx > 18 && dx < _width - 86)
                    setState(() => _left = dx);
                  else
                    setState(() => _left = dx < 18 ? 18 : (_width - 86));
                },
                onPointerUp: (event) {
                  if (_left > 68) {
                    sendSms();
                  }
                  _dColor = 0;
                  setState(() => _left = 18);
                },
                child: Container(
                  width: 68,
                  height: 68,
                  margin: EdgeInsets.symmetric(vertical: 64),
                  decoration: BoxDecoration(
                      color: Colors.blueGrey.withRed(_dColor),
                      shape: BoxShape.circle),
                  child: Icon(
                    Icons.security,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),
              duration: Duration(milliseconds: 150),
            ),
          ],
        ),
      ),
    );
  }
}
