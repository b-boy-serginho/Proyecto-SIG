import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapas_api/blocs/blocs.dart';

class MapView extends StatelessWidget {
  final LatLng initialLocation;
  final Set<Polyline> polylines;
  final Set<Marker> markers;

  const MapView({
    Key? key,
    required this.initialLocation,
    required this.polylines,
    required this.markers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapBloc = BlocProvider.of<MapBloc>(context);
    CameraPosition initialCameraPosition =
        CameraPosition(target: initialLocation, zoom: 19.151926040649414);
    final size = MediaQuery.of(context).size;
    return SizedBox(
        width: size.width,
        height: size.height,
        child: Listener(
          onPointerMove: (PointerMoveEvent) =>
              mapBloc.add(OnStopFollowingUserEvent()),
          child: GoogleMap(
            polylines: polylines,
            markers: markers,
            initialCameraPosition: initialCameraPosition,
            compassEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            onCameraMove: (position) => mapBloc.mapCenter = position.target,
            onMapCreated: (controller) {
              mapBloc.add(OnMapInitialzedEvent(controller));
            },
          ),
        ));
  }
}
