import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'pedido_ativo_page.dart';
import 'mapa_page.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {

  List pedidos = [];
  final locationService = LocationService();

  @override
  void initState() {
    super.initState();
    carregarPedidos();
  }

  Future carregarPedidos() async {
    final response = await ApiService.buscarPedidos();

    setState(() {
      pedidos = response;
    });
  }

  Future aceitarPedido(int id, int index) async {

    final response = await ApiService.aceitarPedido(id, 2);

    locationService.iniciar();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapaPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedidos Disponíveis"),
        backgroundColor: const Color(0xFF1e3a5f),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1e3a5f),
              Color(0xFF2d4a6f),
              Color(0xFF1a2f4a),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: pedidos.isEmpty
            ? const Center(
                child: Text(
                  "Nenhum pedido disponível",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : ListView.builder(
                itemCount: pedidos.length,
                itemBuilder: (context, index) {

                  final pedido = pedidos[index];

                  return Padding(
                    padding: const EdgeInsets.all(10),

                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Coleta
                            Row(
                              children: const [
                                Icon(Icons.store, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  "Coleta",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Text(pedido["endereco_coleta"]),

                            const SizedBox(height: 12),

                            // Entrega
                            Row(
                              children: const [
                                Icon(Icons.location_on, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  "Entrega",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Text(pedido["endereco_entrega"]),

                            const SizedBox(height: 12),

                            // Valor
                            Row(
                              children: [
                                const Icon(Icons.attach_money, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  "R\$ ${pedido["valor_entrega"]}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            // Botão
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  aceitarPedido(pedido["id"], index);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFff6b1a),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Aceitar Pedido",
                                  style: TextStyle(fontSize: 16),
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
    );
  }
}