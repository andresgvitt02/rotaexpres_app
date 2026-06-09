import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class PedidoAtivoPage extends StatelessWidget {
  final Map pedido;

  const PedidoAtivoPage({super.key, required this.pedido});

  // Função que abre o pop-up e envia o código para o servidor
  Future<void> exibirDialogoValidacao(BuildContext context, int pedidoId) async {
    TextEditingController codigoController = TextEditingController();
    bool carregando = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Impede de fechar clicando fora
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
                      counterText: "", // Esconde o contador "0/4"
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
                    // Valida se digitou os 4 números
                    if (codigoController.text.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Digite os 4 dígitos do código.")),
                      );
                      return;
                    }

                    setState(() => carregando = true);

                    try {
                      // Usando o IP da sua rede local atual
                      final url = Uri.parse('http://172.29.0.133:3000/pedidos/$pedidoId/concluir');
                      
                      final response = await http.put(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'codigoDigitado': codigoController.text}),
                      );

                      setState(() => carregando = false);

                      if (response.statusCode == 200) {
                        Navigator.pop(context); // Fecha o pop-up
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Entrega concluída com sucesso! 🎉"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        Navigator.pop(context); // Volta para a lista de pedidos ativos
                      } else {
                        // Trata código incorreto (Status 400 ou 404)
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
                onPressed: () => exibirDialogoValidacao(context, pedido["id"]),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "Finalizar Entrega",
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}