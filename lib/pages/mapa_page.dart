import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MapaPage extends StatefulWidget {
  final Map pedido;

  const MapaPage({super.key, required this.pedido});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final String googleApiKey = "AIzaSyAFbTV2_V-iYPYinlnWNn6wApvkneRHUbc";

  final String socketUrl = "http://192.168.3.23:3000";

  GoogleMapController? mapController;

  LatLng? origem;
  LatLng? destino;

  List<LatLng> rota = [];

  StreamSubscription<Position>? positionStream;

  bool recalculandoRota = false;

  bool chegouNaColeta = false;

  bool pedidoColetado = false;

  IO.Socket? socket;

  String tituloMapa = "Indo para coleta";

  @override
  void initState() {
    super.initState();

    conectarSocket();

    iniciarMapa();
  }

  void conectarSocket() {
    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      print("SOCKET CONECTADO");
    });

    socket!.onDisconnect((_) {
      print("SOCKET DESCONECTADO");
    });
  }

  Future iniciarMapa() async {
    await pegarLocalizacaoAtual();

    await carregarDestinoColeta();

    await buscarRota();

    iniciarGPSAoVivo();
  }

  Future pegarLocalizacaoAtual() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Permissão negada");
    }

    Position position =
        await Geolocator.getCurrentPosition();

    origem = LatLng(
      position.latitude,
      position.longitude,
    );
  }

  Future carregarDestinoColeta() async {
    final endereco =
        widget.pedido["endereco_coleta"];

    await carregarEndereco(endereco);
  }

  Future carregarDestinoEntrega() async {
    final endereco =
        widget.pedido["endereco_entrega"];

    await carregarEndereco(endereco);
  }

  Future carregarEndereco(String endereco) async {
    print("ENDEREÇO:");
    print(endereco);

    final response = await http.get(
      Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json"
        "?address=${Uri.encodeComponent(endereco)}"
        "&key=$googleApiKey",
      ),
    );

    final data = jsonDecode(response.body);

    final location =
        data["results"][0]["geometry"]["location"];

    destino = LatLng(
      location["lat"],
      location["lng"],
    );
  }

  Future buscarRota() async {
    PolylinePoints polylinePoints =
        PolylinePoints(apiKey: googleApiKey);

    PolylineResult result =
        await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(
          origem!.latitude,
          origem!.longitude,
        ),
        destination: PointLatLng(
          destino!.latitude,
          destino!.longitude,
        ),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      rota = result.points
          .map(
            (p) => LatLng(
              p.latitude,
              p.longitude,
            ),
          )
          .toList();

      setState(() {});
    }
  }

  Future atualizarRota() async {
    if (origem == null) return;

    if (destino == null) return;

    if (recalculandoRota) return;

    recalculandoRota = true;

    try {
      await buscarRota();
    } catch (e) {
      print("ERRO ROTA:");
      print(e);
    }

    recalculandoRota = false;
  }

  Future verificarChegada() async {
    if (origem == null || destino == null) return;

    if (pedidoColetado) return;

    double distancia = Geolocator.distanceBetween(
      origem!.latitude,
      origem!.longitude,
      destino!.latitude,
      destino!.longitude,
    );

    print("DISTÂNCIA:");
    print(distancia);

    if (distancia < 50 && !chegouNaColeta) {
      chegouNaColeta = true;

      print("MOTOBOY CHEGOU NA COLETA");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Você chegou na coleta",
            ),
          ),
        );
      }

      setState(() {});
    }
  }

  Future confirmarColeta() async {
    pedidoColetado = true;

    tituloMapa = "Indo para entrega";

    await carregarDestinoEntrega();

    await buscarRota();

    setState(() {});
  }

  void iniciarGPSAoVivo() {
    positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10,
          ),
        ).listen(
      (Position position) async {

        origem = LatLng(
          position.latitude,
          position.longitude,
        );

        socket?.emit(
          "localizacao",
          {
            "latitude": position.latitude,
            "longitude": position.longitude,
          },
        );

        print("LOCALIZAÇÃO ENVIADA");

        mapController?.animateCamera(
          CameraUpdate.newLatLng(origem!),
        );

        await atualizarRota();

        await verificarChegada();

        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    positionStream?.cancel();

    socket?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (origem == null || destino == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tituloMapa),
      ),

      body: Stack(
        children: [

          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },

            initialCameraPosition: CameraPosition(
              target: origem!,
              zoom: 15,
            ),

            myLocationEnabled: true,

            markers: {
              Marker(
                markerId: const MarkerId("motoboy"),
                position: origem!,
              ),

              Marker(
                markerId: const MarkerId("destino"),
                position: destino!,
              ),
            },

            polylines: {
              Polyline(
                polylineId: const PolylineId("rota"),
                points: rota,
                width: 5,
              ),
            },
          ),

          if (chegouNaColeta && !pedidoColetado)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,

              child: ElevatedButton(
                onPressed: confirmarColeta,

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                ),

                child: const Text(
                  "CONFIRMAR COLETA",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}