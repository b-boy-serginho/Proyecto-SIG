import 'dart:async';


import 'dart:convert';


import 'package:bloc/bloc.dart';


import 'package:equatable/equatable.dart';


import 'package:flutter/material.dart';


import 'package:google_maps_flutter/google_maps_flutter.dart';


import 'package:mapas_api/blocs/blocs.dart';


import 'package:mapas_api/helpers/widgets_to_marker.dart';


import 'package:mapas_api/models/route_destination.dart';


import 'package:mapas_api/themes/themes.dart';


part 'map_event.dart';


part 'map_state.dart';


class MapBloc extends Bloc<MapEvent, MapState> {

  final LocationBloc locationBloc;


  GoogleMapController? _mapController;


  LatLng? mapCenter;


  String? _addresDestination;


  LatLng? _selectedDestination;


  int? _tripDuration;


  LatLng? get selectedDestination => _selectedDestination; // Nuevo getter


  int? get tripDuration => _tripDuration;


  String? get addesDestination => _addresDestination;


  StreamSubscription<LocationState>? locationStateSubscription;


  MapBloc({required this.locationBloc}) : super(const MapState()) {

    on<ResetMapEvent>((event, emit) {

      emit(state.copyWith(polylines: {}, markers: {}));

    });


    on<OnMapInitialzedEvent>(_onInitMap);


    on<OnStartFollowingUserEvent>(_onStartFollowingUser);


    on<OnStopFollowingUserEvent>(

        (event, emit) => emit(state.copyWith(isFollowingUser: false)));


    on<UpdateUserPolylineEvent>(_onPolylineNewPoint);


    on<OnToggleUserRoute>(

        (event, emit) => emit(state.copyWith(showMyRoute: !state.showMyRoute)));


    on<DisplayPolylinesEvent>((event, emit) => emit(

        state.copyWith(polylines: event.polylines, markers: event.markers)));


    locationStateSubscription = locationBloc.stream.listen((locationState) {

      if (locationState.lastKnownLocation != null) {

        add(UpdateUserPolylineEvent(locationState.myLocationHistory));

      }


      if (!state.isFollowingUser) return;


      if (locationState.lastKnownLocation == null) return;


      moveCamera(locationState.lastKnownLocation!);

    });

  }


  void _onInitMap(OnMapInitialzedEvent event, Emitter<MapState> emit) {

    _mapController = event.controller;


    _mapController!.setMapStyle(jsonEncode(uberMapTheme));


    emit(state.copyWith(isMapInitialized: true));

  }


  void _onStartFollowingUser(

      OnStartFollowingUserEvent event, Emitter<MapState> emit) {

    emit(state.copyWith(isFollowingUser: true));


    if (locationBloc.state.lastKnownLocation == null) return;


    moveCamera(locationBloc.state.lastKnownLocation!);

  }


  void _onPolylineNewPoint(

      UpdateUserPolylineEvent event, Emitter<MapState> emit) {

    final myRoute = Polyline(

        polylineId: const PolylineId('myRoute'),

        color: Colors.black,

        width: 5,

        startCap: Cap.roundCap,

        endCap: Cap.roundCap,

        points: event.userLocations);


    final currentPolylines = Map<String, Polyline>.from(state.polylines);


    currentPolylines['myRoute'] = myRoute;


    emit(state.copyWith(polylines: currentPolylines));

  }


  Future drawRoutePolyline(RouteDestination destination) async {

    final myRoute = Polyline(

      polylineId: const PolylineId('route'),

      color: Colors.black,

      width: 5,

      points: destination.points,

      startCap: Cap.roundCap,

      endCap: Cap.roundCap,

    );


    double kms = destination.distance / 1000;


    kms = (kms * 100).floorToDouble();


    kms /= 100;


    int tripDuration = (destination.duration / 60).floorToDouble().toInt();


    _selectedDestination = destination.points.last; // Último punto como destino


    _tripDuration = tripDuration;


    final startMaker = await getStartCustomMarker(tripDuration, 'Mi ubicación');


    final endMaker =

        await getEndCustomMarker(kms.toInt(), destination.endPlace.text!);


    final startMarker = Marker(

      anchor: const Offset(0.1, 1),

      markerId: const MarkerId('start'),

      position: destination.points.first,

      icon: startMaker,

    );


    final endMarker = Marker(

      markerId: const MarkerId('end'),

      position: destination.points.last,

      icon: endMaker,

    );


    final currentPolylines = Map<String, Polyline>.from(state.polylines);


    currentPolylines['route'] = myRoute;


    final currentMarkers = Map<String, Marker>.from(state.markers);


    currentMarkers['start'] = startMarker;


    currentMarkers['end'] = endMarker;


    add(DisplayPolylinesEvent(currentPolylines, currentMarkers));

  }


  Future<void> clearMap() async {

    final currentPolylines = <String, Polyline>{};


    final currentMarkers = Map<String, Marker>.from(state.markers)

      ..removeWhere((key, marker) => key != 'initial-location');


    add(DisplayPolylinesEvent(currentPolylines, currentMarkers));

  }


  void moveCamera(LatLng newLocation) {

    final cameraUpdate = CameraUpdate.newLatLng(newLocation);


    _mapController?.animateCamera(cameraUpdate);

  }

  void moveCamera2(CameraUpdate cameraUpdate) {
    _mapController?.animateCamera(cameraUpdate);
  }


  @override

  Future<void> close() {

    locationStateSubscription?.cancel();


    return super.close();

  }

}

