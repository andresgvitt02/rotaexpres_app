import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final String googleApiKey = "AIzaSyAFbTV2_V-iYPYinlnWNn6wApvkneRHUbc";

  final LatLng origem = const LatLng(-29.3353, -49.7269); // motoboy
  final LatLng destino = const LatLng(-29.3400, -49.7200); // coleta

  List<LatLng> rota = [];

  @override
  void initState() {
    super.initState();
    buscarRota();
  }

Future buscarRota() async {

  PolylinePoints polylinePoints = PolylinePoints(
    apiKey: googleApiKey,
  );

  PolylineResult result =
      await polylinePoints.getRouteBetweenCoordinates(

    request: PolylineRequest(

      origin: PointLatLng(
        origem.latitude,
        origem.longitude,
      ),

      destination: PointLatLng(
        destino.latitude,
        destino.longitude,
      ),

      mode: TravelMode.driving,

    ),
  );

  if (result.points.isNotEmpty) {

    setState(() {

      rota = result.points
          .map(
            (p) => LatLng(
              p.latitude,
              p.longitude,
            ),
          )
          .toList();

    });

  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Indo para coleta")),

      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: origem, zoom: 14),

        myLocationEnabled: true,

        markers: {
          Marker(markerId: const MarkerId("origem"), position: origem),

          Marker(markerId: const MarkerId("destino"), position: destino),
        },

        polylines: {
          Polyline(
            polylineId: const PolylineId("rota"),
            points: rota,
            width: 5,
          ),
        },
      ),
    );
  }
}
