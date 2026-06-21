import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart'; // 👈 Importando o IP automático

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

  // 👈 Agora pega o IP atualizado automaticamente!
  final String socketUrl = ApiService.baseUrl; 

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

  // 👈 Função de finalizar com o pop-up atualizado
  Future finalizarPedido() async {
    final pedidoId = widget.pedido["id"];
    TextEditingController codigoController = TextEditingController();
    bool carregando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                "Finalizar Entrega",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Peça ao cliente o código PIN de 4 dígitos para concluir."),
                  const SizedBox(height: 20),
                  TextField(
                    controller: codigoController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "0000",
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: carregando ? null : () async {
                    if (codigoController.text.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Digite os 4 dígitos do código.")),
                      );
                      return;
                    }

                    setState(() => carregando = true);

                    try {
                      final url = Uri.parse("$socketUrl/pedidos/$pedidoId/concluir");
                      
                      final response = await http.put(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'codigoDigitado': codigoController.text}),
                      );

                      setState(() => carregando = false);

                      if (response.statusCode == 200) {
                        Navigator.pop(context); // Fecha o pop-up
                        
                        pedidoFinalizado = true; // Atualiza a variável do mapa
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Entrega concluída com sucesso! 🎉"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        Navigator.pop(context); // Sai do mapa
                      } else {
                        // Trata código incorreto
                        final erro = jsonDecode(response.body);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(erro['error'] ?? "Código incorreto. Confirme com o cliente."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => carregando = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Erro de conexão com o servidor.")),
                      );
                    }
                  },
                  child: carregando 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("Confirmar", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
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