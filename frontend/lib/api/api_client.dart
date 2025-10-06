import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<String> ping() async {
    final uri = Uri.parse('$baseUrl/api/ping');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(res.body)['message'] as String;
    }
    throw Exception('Ping failed ${res.statusCode}');
  }

  static Future<String> aiMock(List<String> texts) async {
    final uri = Uri.parse('$baseUrl/api/ai/mock');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'texts': texts}),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body)['result'] as String;
    }
    throw Exception('AI mock failed ${res.statusCode}');
  }
}
