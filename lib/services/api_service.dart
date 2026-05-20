import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
static const baseUrl = "http://192.168.3.23:3000";
  // LOGIN
  static Future login(String email, String senha) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "senha": senha}),
    );

    return jsonDecode(response.body);
  }

  // BUSCAR PEDIDOS
  static Future buscarPedidos() async {
    final response = await http.get(Uri.parse("$baseUrl/pedidos"));

    return jsonDecode(response.body);
  }

  static Future aceitarPedido(int id, int motoboyId) async {
    final response = await http.put(
      Uri.parse("$baseUrl/pedidos/$id/aceitar"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"motoboy_id": motoboyId}),
    );

    return jsonDecode(response.body);
  }

  static Future concluirPedido(int id) async {
    final response = await http.put(Uri.parse("$baseUrl/pedidos/$id/concluir"));

    return jsonDecode(response.body);
  }
}
