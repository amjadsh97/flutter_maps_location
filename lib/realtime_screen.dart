import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealTimeScreen extends StatefulWidget {
  @override
  _RealTimeScreenState createState() => _RealTimeScreenState();
}

class _RealTimeScreenState extends State<RealTimeScreen> {

  Geolocator _geolocator;

  LocationOptions locationOptions;

  DatabaseReference _myUserLocation;

  Set<UserLocation> userLocations = {};

  GoogleMapController _googleMapController;

  bool myLocationInitialized = false;

  LatLng myPosition;

  bool warningShown = false;

  @override
  void initState() {
    _geolocator = Geolocator();
    locationOptions =
        LocationOptions(accuracy: LocationAccuracy.best, timeInterval: 5000);
    SharedPreferences.getInstance().then((sharedPref) {
      String uid = sharedPref.getString('uid');
      _myUserLocation =
          FirebaseDatabase.instance.reference().child("locations").child(uid);
    });
    checkPermission();

    _geolocator.getPositionStream(locationOptions).listen((data) {
      print(data);
      myPosition = LatLng(data.latitude, data.longitude);
      _myUserLocation.set({
        'name': 'Amjad', //TODO (set current user name)
        'latitude': data.latitude,
        'longitude': data.longitude,
        'time': DateTime
            .now()
            .millisecondsSinceEpoch
      });

      var cameraPosition = CameraPosition(
          target: LatLng(data.latitude, data.longitude), zoom: 15);
      if (_googleMapController != null && !myLocationInitialized) {
        _googleMapController
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        myLocationInitialized = true;
      }
    });

    FirebaseDatabase.instance
        .reference()
        .child("locations")
        .onValue
        .listen((data) {
      userLocations.clear();

      if (data.snapshot.value != null) {
        for (var entry in data.snapshot.value.entries) {
          var location = entry.value;
          print(location);
          var id = entry.key.toString();
          var name = location['name'];
          var latitude = location['latitude'];
          var longitude = location['longitude'];
          var time = location['time'];

          var user = UserLocation(id, name, latitude, longitude, time);
          userLocations.add(user);

          if (myPosition != null && !warningShown) {

            Geolocator()
                .distanceBetween(
                user.lat,
                user.lng,
                myPosition.latitude,
                myPosition.longitude)
                .then((distance) {
              print(distance);
              if (distance > 5) {
                _showWarning(user.name);
                warningShown = true;
              }
            });

          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    });
    super
        .
    initState
      (
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Location Monitoring'),
        ),
        body: Container(
          child: Stack(
            children: <Widget>[
              GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: LatLng(32.4056537, 35.2082036), zoom: 15),
                markers: _buildMarkers(),
                mapType: MapType.hybrid,
                onMapCreated: (controller) {
                  _googleMapController = controller;
                },
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _usersCountWidget()),
            ],
          ),
        ));
  }

  _usersCountWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(
                userLocations.isEmpty
                    ? 'No users found'
                    : '${userLocations.length} users around',
                style: TextStyle(color: Colors.blue),
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  void checkPermission() {
    _geolocator.checkGeolocationPermissionStatus().then((status) {
      print('status: $status');
    });
    _geolocator
        .checkGeolocationPermissionStatus(
        locationPermission: GeolocationPermission.locationAlways)
        .then((status) {
      print('always status: $status');
    });
    _geolocator.checkGeolocationPermissionStatus(
        locationPermission: GeolocationPermission.locationWhenInUse)
      ..then((status) {
        print('whenInUse status: $status');
      });
  }

  _buildMarkers() {
    return userLocations.map((user) {
      return Marker(
          markerId: MarkerId(user.id),
          position: LatLng(user.lat, user.lng),
          infoWindow: InfoWindow(title: user.name));
    }).toSet();
  }

  void _showWarning(String user) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('WARNING!'),
              content: Text('User $user is out of range')
          );
        });
  }
}

class UserLocation {
  String id;
  String name;
  double lat;
  double lng;

  //last seen time (milliseconds)
  int time;

  UserLocation(this.id, this.name, this.lat, this.lng, this.time);
}


//import 'dart:convert';
//
//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:flutter/material.dart';
//import 'package:geolocator/geolocator.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:firebase_database/firebase_database.dart';
//import 'package:shared_preferences/shared_preferences.dart';
//
//class RealTimeScreen extends StatefulWidget {
//  @override
//  _RealTimeScreenState createState() => _RealTimeScreenState();
//}
//
//class _RealTimeScreenState extends State<RealTimeScreen> {
//  FirebaseUser user;
//  Geolocator _geolocator;
//  LocationOptions locationOptions;
//  DatabaseReference _myUserLocation;
//
//  void checkPermission() {
//    _geolocator.checkGeolocationPermissionStatus().then((status) {
//      print('status: $status');
//    });
//    _geolocator
//        .checkGeolocationPermissionStatus(
//            locationPermission: GeolocationPermission.locationAlways)
//        .then((status) {
//      print('always status: $status');
//    });
//    _geolocator.checkGeolocationPermissionStatus(
//        locationPermission: GeolocationPermission.locationWhenInUse)
//      ..then((status) {
//        print('whenInUse status: $status');
//      });
//  }
//
//  @override
//  void initState() {
//    _geolocator = Geolocator();
//    locationOptions = LocationOptions(accuracy: LocationAccuracy.best);
//    SharedPreferences.getInstance().then((sharedPref) {
//      String uid = sharedPref.getString('uid');
//      _myUserLocation =
//          FirebaseDatabase.instance.reference().child(uid).child('location');
//    });
//    checkPermission();
//    super.initState();
//  }
//
//  List<Marker> markers = [];
//  CameraPosition cameraPosition;
//  bool loaded = false;
//
//  List<User> users = [];
//
////  @override
////  void initState() {
////    super.initState();
////
////    FirebaseDatabase.instance
////        .reference()
////        .child('users')
////        .onValue
////        .listen((event) {
////      for (var user in event.snapshot.value) {
////        if (user != null) {
////          users.add(User(user['id']));
////          markers.add(Marker(
////              markerId: MarkerId(user['id']),
////              position: LatLng(
////                user['location']['latitude'],
////                user['location']['longitude'],
////              ),
////              infoWindow: InfoWindow(
////                  title: user['id']
////              )
////          ));
////        }
////      }
////      cameraPosition = CameraPosition(target: markers[0].position, zoom: 15);
////      setState(() {
////        loaded = true;
////      });
////      for (Marker marker in markers) {
////        Geolocator()
////            .distanceBetween(
////            marker.position.latitude,
////            marker.position.longitude,
////            markers[0].position.latitude,
////            markers[0].position.longitude)
////            .then((distance) {
////          if (distance > 5) {
////            _showWarning(marker.infoWindow.title);
////          }
////        });
////      }
////    });
////  }
//
////  @override
////  Widget build(BuildContext context) {
////    return Scaffold(
////      appBar: AppBar(
////        title: Text('Realtime Screen'),
////      ),
////      body: Container(
////        child: FutureBuilder(
////          future: _getCurrentLocation(),
////          builder: ( BuildContext context , AsyncSnapshot<Position> snapshot ){
////            switch(snapshot.connectionState){
////              case ConnectionState.none:
////                return Text('Error');
////                break;
////              case ConnectionState.waiting:
////              case ConnectionState.active:
////                return Text('Loading ......');
////                break;
////              case ConnectionState.done:
////                if( snapshot.hasData ){
////                  CameraPosition cameraPosition = CameraPosition(
////                    target: LatLng( snapshot.data.latitude , snapshot.data.longitude ),
////                    zoom: 15
////                  );
////                  List<Marker> markers = [];
////                  Marker marker = Marker(
////                    markerId: MarkerId('myposition'),
////                    position: LatLng( snapshot.data.latitude , snapshot.data.longitude ),
////                  );
////                  markers.add(marker);
////                  return GoogleMap(
////                    initialCameraPosition: cameraPosition,
////                    markers: markers.toSet(),
////                  );
////                }else{
////                  return Text('No location Found');
////                }
////                break;
////            }
////            return Container();
////          },
////        ),
////      ),
////    );
////  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text('Location Monitoring'),
//      ),
//      body: StreamBuilder(
//        stream: _geolocator.getPositionStream(locationOptions),
//        builder: (context, snapshot) {
//          switch (snapshot.connectionState) {
//            case ConnectionState.none:
//              return Text('Error');
//              break;
//            case ConnectionState.waiting:
//              return Text('Loading ......');
//              break;
//            case ConnectionState.done:
//            case ConnectionState.active:
//              if (snapshot.hasData) {
//                print(snapshot.data);
//                CameraPosition cameraPosition = CameraPosition(
//                    target:
//                        LatLng(snapshot.data.latitude, snapshot.data.longitude),
//                    zoom: 15);
//                List<Marker> markers = [];
//                Marker marker = Marker(
//                  markerId: MarkerId('myposition'),
//                  position:
//                      LatLng(snapshot.data.latitude, snapshot.data.longitude),
//                );
//                markers.add(marker);
//                _myUserLocation.set({
//                  'latitude': snapshot.data.latitude,
//                  'longitude': snapshot.data.longitude,
//                });
//                return GoogleMap(
//                  initialCameraPosition: cameraPosition,
//                  markers: markers.toSet(),
//                );
//              } else {
//                return Text('No location Found');
//              }
//              break;
//          }
//          return Container();
//        },
//      ),
//    );
//  }
////
////  @override
////  Widget build(BuildContext context) {
////    return Scaffold(
////      appBar: AppBar(
////        title: Text('Monitoring All Locations'),
////      ),
////      body: (loaded)
////          ? GoogleMap(
////        initialCameraPosition: cameraPosition,
////        markers: markers.toSet(),
////      )
////          : Center(
////        child: CircularProgressIndicator(),
////      ),
////    );
////  }
//
//  void _showWarning(String user) {
//    showDialog(
//        context: context,
//        builder: (BuildContext context) {
//          return AlertDialog(
//            title: Text('WARNING!'),
//            content: Text('User $user is out of range'),
//          );
//        });
//  }
//
////  Future<Position> _getCurrentLocation() async {
////    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
////    Position position = await geolocator.getCurrentPosition(
////        desiredAccuracy: LocationAccuracy.best);
////    return position;
////  }
//}
//
//class User {
//  String name;
//
//  User(this.name);
//}
