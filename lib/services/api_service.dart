import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.3.23:3000";

  // LOGIN
  static Future<Map<String, dynamic>> login(
    String email,
    String senha,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "senha": senha,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Erro ao conectar no servidor"};
    }
  }

  // REGISTRAR MOTOBOY (🔥 NOVO)
  static Future<Map<String, dynamic>> register(
    String nome,
    String email,
    String telefone,
    String senha,
  ) async {
    try {
      // ⚠️ Atenção: Verifique se a rota '/motoboys/registrar' é a exata rota que você criou no seu Node.js para cadastro
      final response = await http.post(
        Uri.parse("$baseUrl/registrar"), 
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nome": nome,
          "email": email,
          "telefone": telefone,
          "senha": senha,
          "tipo": "motoboy" 
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Erro ao conectar no servidor"};
    }
  }

  // LISTAR PEDIDOS
  static Future<List<dynamic>> buscarPedidos() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/pedidos"),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }

  // ACEITAR PEDIDO
  static Future<Map<String, dynamic>> aceitarPedido(
    int id,
    int motoboyId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/pedidos/$id/aceitar"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "motoboy_id": motoboyId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Erro ao aceitar pedido"};
    }
  }

  // FINALIZAR PEDIDO
  static Future<Map<String, dynamic>> concluirPedido(
    int id,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/pedidos/$id/concluir"),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Erro ao concluir pedido"};
    }
  }

  // LINK ACOMPANHAMENTO
  static String gerarLinkAcompanhamento(
    String token,
  ) {
    return "$baseUrl/acompanhar/$token";
  }
}