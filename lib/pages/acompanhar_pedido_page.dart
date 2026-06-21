import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class AcompanharPedidoPage extends StatefulWidget {
  const AcompanharPedidoPage({super.key});

  @override
  State<AcompanharPedidoPage> createState() =>
      _AcompanharPedidoPageState();
}

class _AcompanharPedidoPageState
    extends State<AcompanharPedidoPage> {

  final String socketUrl =
      "http://192.168.3.23:3000";

  GoogleMapController? mapController;

  IO.Socket? socket;

  LatLng motoboy = const LatLng(
    -29.5354,
    -50.0699,
  );

  @override
  void initState() {
    super.initState();

    conectarSocket();
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
      print("CLIENTE CONECTADO SOCKET");
    });

    socket!.on(
      "localizacaoAtualizada",
      (data) {

        print("LOCALIZAÇÃO RECEBIDA");
        print(data);

        double latitude =
            data["latitude"];

        double longitude =
            data["longitude"];

        motoboy = LatLng(
          latitude,
          longitude,
        );

        mapController?.animateCamera(
          CameraUpdate.newLatLng(
            motoboy,
          ),
        );

        setState(() {});
      },
    );

    socket!.onDisconnect((_) {
      print("CLIENTE DESCONECTADO");
    });
  }

  @override
  void dispose() {

    socket?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Acompanhar Pedido",
        ),
      ),

      body: GoogleMap(

        onMapCreated: (controller) {
          mapController = controller;
        },

        initialCameraPosition:
            CameraPosition(
          target: motoboy,
          zoom: 15,
        ),

        markers: {

          Marker(
            markerId:
                const MarkerId(
              "motoboy",
            ),

            position: motoboy,

            infoWindow:
                const InfoWindow(
              title: "Motoboy",
            ),
          ),
        },
      ),
    );
  }
}