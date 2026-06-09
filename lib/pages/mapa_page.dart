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

  const MapaPage({
    super.key,
    required this.pedido,
  });

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {

  final String googleApiKey =
      "AIzaSyAFbTV2_V-iYPYinlnWNn6wApvkneRHUbc";

  final String socketUrl =
      "http://172.29.0.133:3000";

  GoogleMapController? mapController;

  LatLng? origem;
  LatLng? destino;

  List<LatLng> rota = [];

  StreamSubscription<Position>? positionStream;

  IO.Socket? socket;

  bool recalculandoRota = false;

  bool chegouNaColeta = false;

  bool pedidoColetado = false;

  bool chegouNaEntrega = false;

  bool pedidoFinalizado = false;

  String tituloMapa =
      "Indo para coleta";

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
          .setTransports(
            ['websocket'],
          )
          .enableAutoConnect()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {

      print(
        "SOCKET CONECTADO",
      );
    });

    socket!.onDisconnect((_) {

      print(
        "SOCKET DESCONECTADO",
      );
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

    if (permission ==
        LocationPermission.denied) {

      permission =
          await Geolocator
              .requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission
                .deniedForever) {

      throw Exception(
        "Permissão negada",
      );
    }

    Position position =
        await Geolocator
            .getCurrentPosition();

    origem = LatLng(
      position.latitude,
      position.longitude,
    );
  }

  Future carregarDestinoColeta() async {

    final endereco =
        widget.pedido[
            "endereco_coleta"];

    await carregarEndereco(
      endereco,
    );
  }

  Future carregarDestinoEntrega() async {

    final endereco =
        widget.pedido[
            "endereco_entrega"];

    await carregarEndereco(
      endereco,
    );
  }

  Future carregarEndereco(
    String endereco,
  ) async {

    final response =
        await http.get(
      Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json"
        "?address=${Uri.encodeComponent(endereco)}"
        "&key=$googleApiKey",
      ),
    );

    final data =
        jsonDecode(response.body);

    if (data["results"] == null ||
        data["results"].isEmpty) {

      throw Exception(
        "Endereço não encontrado",
      );
    }

    final location =
        data["results"][0]
            ["geometry"]["location"];

    destino = LatLng(
      location["lat"],
      location["lng"],
    );
  }

  Future buscarRota() async {

    PolylinePoints polylinePoints =
        PolylinePoints(
      apiKey: googleApiKey,
    );

    PolylineResult result =
        await polylinePoints
            .getRouteBetweenCoordinates(
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

      print(e);
    }

    recalculandoRota = false;
  }

  Future verificarChegada() async {

    if (origem == null ||
        destino == null) return;

    double distancia =
        Geolocator.distanceBetween(
      origem!.latitude,
      origem!.longitude,
      destino!.latitude,
      destino!.longitude,
    );

    print(
      "DISTÂNCIA: $distancia",
    );

    // CHEGOU NA COLETA
    if (!pedidoColetado &&
        distancia < 50 &&
        !chegouNaColeta) {

      chegouNaColeta = true;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "Você chegou na coleta",
          ),
        ),
      );

      setState(() {});
    }

    // CHEGOU NA ENTREGA
    if (pedidoColetado &&
        distancia < 50 &&
        !chegouNaEntrega) {

      chegouNaEntrega = true;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "Você chegou na entrega",
          ),
        ),
      );

      setState(() {});
    }
  }

  Future confirmarColeta() async {

    pedidoColetado = true;

    tituloMapa =
        "Indo para entrega";

    chegouNaColeta = false;

    await carregarDestinoEntrega();

    await buscarRota();

    setState(() {});
  }

  Future finalizarPedido() async {

    final pedidoId =
        widget.pedido["id"];

    try {

      await http.put(
        Uri.parse(
          "$socketUrl/pedidos/$pedidoId/concluir",
        ),
      );

      pedidoFinalizado = true;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "Pedido finalizado",
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      print(e);
    }
  }

  void iniciarGPSAoVivo() {

    positionStream =
        Geolocator
            .getPositionStream(
      locationSettings:
          const LocationSettings(
        accuracy:
            LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen(
      (
        Position position,
      ) async {

        origem = LatLng(
          position.latitude,
          position.longitude,
        );

        socket?.emit(
          "localizacao",
          {
            "pedidoId":
                widget.pedido["id"],

            "latitude":
                position.latitude,

            "longitude":
                position.longitude,
          },
        );

        print(
          "LOCALIZAÇÃO ENVIADA",
        );

        mapController
            ?.animateCamera(
          CameraUpdate.newLatLng(
            origem!,
          ),
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
  Widget build(
    BuildContext context,
  ) {

    if (origem == null ||
        destino == null) {

      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tituloMapa,
        ),
      ),

      body: Stack(
        children: [

          GoogleMap(
            onMapCreated:
                (controller) {

              mapController =
                  controller;
            },

            initialCameraPosition:
                CameraPosition(
              target: origem!,
              zoom: 15,
            ),

            myLocationEnabled:
                true,

            markers: {

              Marker(
                markerId:
                    const MarkerId(
                  "motoboy",
                ),

                position: origem!,
              ),

              Marker(
                markerId:
                    const MarkerId(
                  "destino",
                ),

                position: destino!,
              ),
            },

            polylines: {

              Polyline(
                polylineId:
                    const PolylineId(
                  "rota",
                ),

                points: rota,

                width: 5,
              ),
            },
          ),

          // BOTÃO COLETA
          if (chegouNaColeta &&
              !pedidoColetado)

            Positioned(
              bottom: 30,
              left: 20,
              right: 20,

              child:
                  ElevatedButton(
                onPressed:
                    confirmarColeta,

                child: const Text(
                  "CONFIRMAR COLETA",
                ),
              ),
            ),

          // BOTÃO FINALIZAR
          if (chegouNaEntrega &&
              !pedidoFinalizado)

            Positioned(
              bottom: 90,
              left: 20,
              right: 20,

              child:
                  ElevatedButton(
                onPressed:
                    finalizarPedido,

                child: const Text(
                  "FINALIZAR ENTREGA",
                ),
              ),
            ),
        ],
      ),
    );
  }
}