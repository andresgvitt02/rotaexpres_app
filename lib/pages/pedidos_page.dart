import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';

import 'mapa_page.dart';

class PedidosPage extends StatefulWidget {

  const PedidosPage({
    super.key,
  });

  @override
  State<PedidosPage> createState() =>
      _PedidosPageState();
}

class _PedidosPageState
    extends State<PedidosPage> {

  List pedidos = [];

  final locationService =
      LocationService();

  bool carregando = false;

  @override
  void initState() {
    super.initState();

    carregarPedidos();
  }

  Future carregarPedidos() async {

    setState(() {
      carregando = true;
    });

    final response =
        await ApiService
            .buscarPedidos();

    setState(() {

      pedidos = response;

      carregando = false;
    });
  }

  Future aceitarPedido(
    Map pedido,
  ) async {

    final response =
        await ApiService
            .aceitarPedido(
      pedido["id"],
      2,
    );

    // ERRO
    if (response["error"] != null) {

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            response["error"],
          ),
        ),
      );

      return;
    }

    // INICIA GPS
    locationService.iniciar(
      pedidoId:
          pedido["id"],
    );

    // LINK CLIENTE
    final link =
        ApiService
            .gerarLinkAcompanhamento(
      pedido["tracking_token"],
    );

    print(
      "LINK CLIENTE:",
    );

    print(link);

    // REMOVE DA LISTA
    pedidos.removeWhere(
      (p) =>
          p["id"] ==
          pedido["id"],
    );

    setState(() {});

    // ABRE MAPA
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapaPage(
          pedido: response,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Pedidos Disponíveis",
        ),

        backgroundColor:
            const Color(
          0xFF1e3a5f,
        ),
      ),

      body: Container(

        decoration:
            const BoxDecoration(

          gradient:
              LinearGradient(

            colors: [

              Color(
                0xFF1e3a5f,
              ),

              Color(
                0xFF2d4a6f,
              ),

              Color(
                0xFF1a2f4a,
              ),
            ],

            begin:
                Alignment.topLeft,

            end:
                Alignment.bottomRight,
          ),
        ),

        child: carregando

            ? const Center(
                child:
                    CircularProgressIndicator(),
              )

            : pedidos.isEmpty

                ? const Center(
                    child: Text(

                      "Nenhum pedido disponível",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  )

                : RefreshIndicator(

                    onRefresh:
                        carregarPedidos,

                    child:
                        ListView.builder(

                      itemCount:
                          pedidos.length,

                      itemBuilder:
                          (
                        context,
                        index,
                      ) {

                        final pedido =
                            pedidos[index];

                        return Padding(

                          padding:
                              const EdgeInsets.all(
                            10,
                          ),

                          child: Card(

                            elevation: 6,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),

                            child: Padding(

                              padding:
                                  const EdgeInsets.all(
                                16,
                              ),

                              child: Column(

                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  // COLETA
                                  Row(
                                    children: const [

                                      Icon(
                                        Icons.store,
                                        color:
                                            Colors.blue,
                                      ),

                                      SizedBox(
                                        width: 8,
                                      ),

                                      Text(

                                        "Coleta",

                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  Text(
                                    pedido[
                                        "endereco_coleta"],
                                  ),

                                  const SizedBox(
                                    height: 12,
                                  ),

                                  // ENTREGA
                                  Row(
                                    children: const [

                                      Icon(
                                        Icons.location_on,
                                        color:
                                            Colors.red,
                                      ),

                                      SizedBox(
                                        width: 8,
                                      ),

                                      Text(

                                        "Entrega",

                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  Text(
                                    pedido[
                                        "endereco_entrega"],
                                  ),

                                  const SizedBox(
                                    height: 12,
                                  ),

                                  // VALOR
                                  Row(
                                    children: [

                                      const Icon(
                                        Icons.attach_money,
                                        color:
                                            Colors.green,
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      Text(

                                        "R\$ ${pedido["valor_entrega"]}",

                                        style:
                                            const TextStyle(
                                          fontSize:
                                              16,

                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  // BOTÃO
                                  SizedBox(

                                    width:
                                        double.infinity,

                                    child:
                                        ElevatedButton(

                                      onPressed:
                                          () {

                                        aceitarPedido(
                                          pedido,
                                        );
                                      },

                                      style:
                                          ElevatedButton.styleFrom(

                                        backgroundColor:
                                            const Color(
                                          0xFFff6b1a,
                                        ),

                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical:
                                              14,
                                        ),

                                        shape:
                                            RoundedRectangleBorder(

                                          borderRadius:
                                              BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),

                                      child:
                                          const Text(

                                        "Aceitar Pedido",

                                        style:
                                            TextStyle(
                                          fontSize:
                                              16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}