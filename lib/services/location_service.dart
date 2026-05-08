import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LocationService {

  late IO.Socket socket;

  void iniciar() async {

    // 🔌 conecta no backend
    socket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print("Conectado ao socket 🔥");
    });

    // 📍 pega localização continuamente
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {

      print("Enviando localização: ${position.latitude}, ${position.longitude}");

      socket.emit("localizacao", {
        "pedido_id": 1, // depois vamos deixar dinâmico
        "lat": position.latitude,
        "lng": position.longitude
      });

    });

  }
}