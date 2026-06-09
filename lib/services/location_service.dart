import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LocationService {

  late IO.Socket socket;

  StreamSubscription<Position>? positionStream;

  // IP DO SEU PC
  final String socketUrl =
      "http://172.29.0.133:3000";

  void iniciar({
    required int pedidoId,
  }) async {

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(
            ['websocket'],
          )
          .enableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {

      print(
        "SOCKET CONECTADO",
      );
    });

    socket.onDisconnect((_) {

      print(
        "SOCKET DESCONECTADO",
      );
    });

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

      print(
        "PERMISSÃO NEGADA",
      );

      return;
    }

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
      ) {

        print(
          "ENVIANDO LOCALIZAÇÃO",
        );

        print(
          position.latitude,
        );

        print(
          position.longitude,
        );

        socket.emit(
          "localizacao",
          {
            "pedidoId":
                pedidoId,

            "latitude":
                position.latitude,

            "longitude":
                position.longitude,
          },
        );
      },
    );
  }

  void parar() {

    positionStream?.cancel();

    socket.dispose();
  }
}