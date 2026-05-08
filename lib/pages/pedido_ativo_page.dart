import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PedidoAtivoPage extends StatelessWidget {

  final Map pedido;

  const PedidoAtivoPage({super.key, required this.pedido});

  Future concluir(BuildContext context) async {
    await ApiService.concluirPedido(pedido["id"]);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Entrega concluída"))
    );

    Navigator.pop(context); // volta pra lista
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Entrega em andamento"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Coleta: ${pedido["endereco_coleta"]}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              "Entrega: ${pedido["endereco_entrega"]}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 10),

            Text(
              "Valor: R\$ ${pedido["valor_entrega"]}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () => concluir(context),
                child: const Text("Finalizar Entrega"),
              ),
            )

          ],
        ),
      ),
    );
  }
}