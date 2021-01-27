import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:sensors/sensors.dart';
import 'package:rxdart/rxdart.dart';
import 'package:kdgaugeview/kdgaugeview.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Where',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController mapController;
  Location location = new Location();

  LocationData pinLocation;
  @override
  LatLng _initialLocation = LatLng(37.42796133588664, -122.885740655967);
  List<double> _accelerometerValues;

  // updpating values after 1 sec on screen.
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  // ignore: cancel_subscriptions
  //
  StreamSubscription<LocationData> locationSubscription;
  // speedometer updation in real time UI
  GlobalKey<KdGaugeViewState> key = GlobalKey<KdGaugeViewState>();

// speedo meter values
  int start = 0;
  int end = 240;
  double _lowerValue = 20.0;
  double _upperValue = 40.0;
  int counter = 0;

// Jo bhi location update ho rhi hogi google map camera view controller vha set kr rha hoga.
//
  void _onMapCreated(GoogleMapController _cntrLoc) async {
    // ignore: await_only_futures
    mapController = await _cntrLoc;

    locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
            target: LatLng(currentLocation.latitude, currentLocation.longitude),
            zoom: 18)),
      );
      setState(() {
        pinLocation = currentLocation;
      });
    });
  }

  // there is satellite view or normal view in order to save internet
  MapType _currentMapType = MapType.normal;

  @override
  void dispose() {
    super.dispose();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

// we are initializing state of accelorometer values
  @override
  void initState() {
    super.initState();
    _streamSubscriptions
        .add(accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerValues = <double>[event.x, event.y, event.z];
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textLabel = new TextStyle(
      fontSize: 20,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );
    final TextStyle textData = new TextStyle(
      fontSize: 20,
      color: Colors.blue[700],
      fontWeight: FontWeight.bold,
    );
    final ThemeData somTheme = new ThemeData(
        primaryColor: Colors.blue,
        accentColor: Colors.black,
        backgroundColor: Colors.grey);
    final List<String> accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(1))?.toList();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Where'),
          centerTitle: true,
          backgroundColor: Colors.blue[700],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Flexible(
                flex: 04,
                fit: FlexFit.tight,
                child: Stack(children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true,
                    mapType: _currentMapType,
                    initialCameraPosition: CameraPosition(
                      target: _initialLocation,
                      zoom: 10.0,
                    ),
                  ),
                  if (pinLocation == null)
                    CircularProgressIndicator()
                  else
                    Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                            pinLocation.heading.round().toString() + "°",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 35))),
                  if (pinLocation == null)
                    CircularProgressIndicator()
                  else
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 220,
                        width: 240,
                        padding: EdgeInsets.all(16.0),
                        child: KdGaugeView(
                          minSpeed: 0,
                          maxSpeed: 240,
                          speed: pinLocation.speed * 3.6,
                          speedTextStyle: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                          animate: true,
                          duration: Duration(seconds: 1),
                          subDivisionCircleColors: Colors.blue[600],
                          divisionCircleColors: Colors.blue[900],
                          fractionDigits: 0,
                          activeGaugeColor: Colors.white38,
                          innerCirclePadding: 20,
                          unitOfMeasurementTextStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
                              fontWeight: FontWeight.bold),
                          gaugeWidth: 16.0,
                          baseGaugeColor: Colors.white30,
                          alertColorArray: [
                            Colors.green[500],
                            Colors.green[700],
                            Colors.green[900],
                            Colors.yellow,
                            Colors.deepOrangeAccent,
                            Colors.red,
                            Colors.red[900]
                          ],
                          alertSpeedArray: [15, 40, 60, 100, 120, 140, 160],
                        ),
                        margin: EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                            color: Colors.white60, shape: BoxShape.circle),
                      ),
                    )
                ]),
              ),
              Flexible(
                  child: Table(
                defaultColumnWidth: IntrinsicColumnWidth(),
                children: [
                  TableRow(children: [
                    Text("Real Time:   ", style: textLabel),
                    if (pinLocation == null)
                      CircularProgressIndicator()
                    else
                      Text(
                          DateFormat.Hms()
                              .format(DateTime.fromMillisecondsSinceEpoch(
                                  (pinLocation.time).round()))
                              .toString(),
                          style: textData)
                  ]),
                  TableRow(children: [
                    Text("Real Date:   ", style: textLabel),
                    if (pinLocation == null)
                      CircularProgressIndicator()
                    else
                      Text(
                          DateFormat.yMMMd()
                              .format(DateTime.fromMillisecondsSinceEpoch(
                                  (pinLocation.time).round()))
                              .toString(),
                          style: textData)
                  ]),
                  TableRow(children: [
                    Text("Latitude:   ", style: textLabel),
                    if (pinLocation == null)
                      CircularProgressIndicator()
                    else
                      Text(pinLocation.latitude.toString() + "  N",
                          style: textData)
                  ]),
                  TableRow(children: [
                    Text("Longitude:   ", style: textLabel),
                    if (pinLocation == null)
                      CircularProgressIndicator()
                    else
                      Text(pinLocation.longitude.toString() + "  E",
                          style: textData)
                  ]),
                  TableRow(children: [
                    Text("Altitude:   ", style: textLabel),
                    if (pinLocation == null)
                      CircularProgressIndicator()
                    else
                      Text(pinLocation.altitude.toString() + "  m",
                          style: textData)
                  ]),
                ],
              )),
              Flexible(
                flex: 1,
                child: Align(
                  alignment: Alignment.center,
                  child: Text('Accelerometer: $accelerometer m/s²',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
