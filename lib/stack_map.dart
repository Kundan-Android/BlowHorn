import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';

class StackMap extends StatefulWidget {
  @override
  _StackMapState createState() => _StackMapState();
}

class _StackMapState extends State<StackMap> {
  Completer<GoogleMapController> controller1 = Completer();
  GoogleMapController mapController;
  bool _serviceEnabled;
  Location _location = new Location();
  static LatLng _initialPosition;
  final Set<Marker> _markers = {};
  static  LatLng _lastMapPosition = _initialPosition;
  PermissionStatus _permissionGranted;
  Location location = new Location();
  LocationData _locationData;
  final Set<Polyline>_polyline={};
  List<LatLng> listLatLng = List();
  LatLng destinationLatLng = LatLng(12.9716, 77.5946);
  LatLng middle1LatLng = LatLng(12.916291, 77.615132);
  Position position;
  LatLng currentLatLng;
  final databaseReference = FirebaseDatabase.instance.reference();
  bool visiblity = false;

  getServiceEnabled() async {
    await getPermissionGranted();
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
    _serviceEnabled = await _location.requestService();
    if (!_serviceEnabled) {
    return;
  }
  } 
  } 
  

  @override
  void initState() {
    super.initState();
    getServiceEnabled();
    _getUserLocation();
  }
  void _getUserLocation() async {
     position = await Geolocator().getCurrentPosition(/* desiredAccuracy: LocationAccuracy.high */);
   // List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      _initialPosition = LatLng(position?.latitude, position?.longitude);
     // print('${placemark[0].name}');
    });
  }
  getPermissionGranted() async {
     _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
     _permissionGranted = await _location.requestPermission();
   if (_permissionGranted != PermissionStatus.granted) {
      return;
   }
  }
  }

  void onLocationChange() async {
    location.onLocationChanged.listen((LocationData currentLocation) {
      mapController.moveCamera(CameraUpdate.newLatLng(LatLng(currentLocation.latitude, currentLocation.longitude)));
    });
  }
  


  _onMapCreated(GoogleMapController controller) {
    setState(() {
      controller1.complete(controller);
      mapController = controller;
    });
  }

  MapType _currentMapType = MapType.normal;

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }
  void uploadLatLngServer() async{
  await  databaseReference.child('1').set({
      'username' : 'User',
      'userLatLng' : '${_lastMapPosition.latitude}, ${_lastMapPosition.longitude}'
    });
  }

  _onCameraMove(CameraPosition position) {
    _initialPosition = position.target;
  }
    
  

  _onAddMarkerButtonPressed() async{
    _locationData = await location.getLocation();
    listLatLng.clear();
    setState(() {
      visiblity = true;
    });
    currentLatLng = LatLng(
    _locationData.latitude,
    _locationData.longitude,
  );
  listLatLng.add(destinationLatLng);
 // listLatLng.add(middle2LatLng);
  listLatLng.add(middle1LatLng);
  
  listLatLng.add(currentLatLng);
  
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId("Destination"),
          position: destinationLatLng,
          infoWindow: InfoWindow(
            title: "Destination",
            onTap: (){
            },
          ),
          onTap: (){
            print('onDestinationMarkerTap');
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(120),
          )
          );
      _markers.add(
          Marker(
              markerId: MarkerId(_lastMapPosition.toString()),
              position: currentLatLng,
              infoWindow: InfoWindow(
                  title: "Your Location",
                  onTap: (){
                    print('onInfoWindowTap');
                  }
              ),
              onTap: (){
                print('onCurrentMarkerTap');
              },
              icon: BitmapDescriptor.defaultMarker));
              _polyline.add(Polyline(
                polylineId: PolylineId(_lastMapPosition.toString()),
                visible: true,
                points: listLatLng,
                color: Colors.blue,
              ));
              
    });
  }
  Future<void> _goToThePosition(LocationData _locationData) async {
    
    final GoogleMapController controller = await controller1.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                target: LatLng(_locationData?.latitude,_locationData?.longitude),
                bearing: 10,//192.8334901395799,
                tilt: 59.440717697143555,
                zoom: 19.151926040649414)
               )
               );
               
  }


  Widget mapButton(Function function, Icon icon, Color color) {
    return RawMaterialButton(
      onPressed: function,
      child: icon,
      shape: new CircleBorder(),
      elevation: 2.0,
      fillColor: color,
      padding: const EdgeInsets.all(7.0),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initialPosition == null 
      ? Container(
        child: Center(
          child:Text('loading map..', 
                style: TextStyle(color: Colors.grey[400]),),),) 
          : Container(
        child: Stack(children: <Widget>[
          GoogleMap(
            markers: _markers,
            polylines: _polyline,
            mapType: _currentMapType,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            onMapCreated: _onMapCreated,
            zoomGesturesEnabled: true,
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            compassEnabled: true,
            myLocationButtonEnabled: false,

          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
                margin: EdgeInsets.fromLTRB(300.0, 50.0, 0.0, 0.0),
                child: Column(
                  children: <Widget>[
                    mapButton(
                      _onAddMarkerButtonPressed,
                        Icon(
                            Icons.add_location, color: Colors.white,
                        ), Colors.redAccent),
                   visiblity == true ?  mapButton(
                        _onMapTypeButtonPressed,
                        Icon(
                            Icons.call_made, color: Colors.white,
                        ),
                        Colors.green) : Container(),
                    visiblity == true ? mapButton(
                        uploadLatLngServer,
                        Icon(
                            Icons.cloud_upload, color: Colors.white,
                        ), Colors.blue) : Container(),
                  ],
                )),
          )
        ]),
      ),
      
      floatingActionButton: visiblity == true ? FloatingActionButton(
        child: Icon(Icons.gps_fixed),
        onPressed: () async {
          bool serviceStatus = await _location.serviceEnabled(); 
          if(!serviceStatus){
            getServiceEnabled();
          }
           else {
             _goToThePosition(_locationData);
             onLocationChange();
           }
        },
      ) : Container(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}