import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl =
      "http://172.29.0.133:3000";

  // LOGIN
  static Future<Map<String, dynamic>>
      login(
    String email,
    String senha,
  ) async {

    try {

      final response =
          await http.post(
        Uri.parse(
          "$baseUrl/login",
        ),

        headers: {
          "Content-Type":
              "application/json",
        },

        body: jsonEncode(
          {
            "email": email,
            "senha": senha,
          },
        ),
      );

      return jsonDecode(
        response.body,
      );

    } catch (e) {

      return {
        "error":
            "Erro ao conectar no servidor"
      };
    }
  }

  // LISTAR PEDIDOS
  static Future<List<dynamic>>
      buscarPedidos() async {

    try {

      final response =
          await http.get(
        Uri.parse(
          "$baseUrl/pedidos",
        ),
      );

      return jsonDecode(
        response.body,
      );

    } catch (e) {

      return [];
    }
  }

  // ACEITAR PEDIDO
  static Future<Map<String, dynamic>>
      aceitarPedido(
    int id,
    int motoboyId,
  ) async {

    try {

      final response =
          await http.put(
        Uri.parse(
          "$baseUrl/pedidos/$id/aceitar",
        ),

        headers: {
          "Content-Type":
              "application/json",
        },

        body: jsonEncode(
          {
            "motoboy_id":
                motoboyId,
          },
        ),
      );

      return jsonDecode(
        response.body,
      );

    } catch (e) {

      return {
        "error":
            "Erro ao aceitar pedido"
      };
    }
  }

  // FINALIZAR PEDIDO
  static Future<Map<String, dynamic>>
      concluirPedido(
    int id,
  ) async {

    try {

      final response =
          await http.put(
        Uri.parse(
          "$baseUrl/pedidos/$id/concluir",
        ),
      );

      return jsonDecode(
        response.body,
      );

    } catch (e) {

      return {
        "error":
            "Erro ao concluir pedido"
      };
    }
  }

  // LINK ACOMPANHAMENTO
  static String gerarLinkAcompanhamento(
    String token,
  ) {

    return
        "$baseUrl/acompanhar/$token";
  }
}