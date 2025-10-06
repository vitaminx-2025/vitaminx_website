// lib/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _host = '127.0.0.1:8000';

  static Future<String> ping() async {
    final uri = Uri.http(_host, '/api/ping');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['message']
          as String;
    }
    throw Exception('Ping failed: ${res.statusCode}');
  }

  static Future<String> aiMock(List<String> texts) async {
    final uri = Uri.http(_host, '/api/ai/mock');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'texts': texts}),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['result'] as String;
    }
    throw Exception('AI mock failed: ${res.statusCode}');
  }

  // -------- Notes --------
  static Future<List<Map<String, dynamic>>> getNotes() async {
    final uri = Uri.http(_host, '/api/notes');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['items'] as List).cast<Map<String, dynamic>>();
      return list;
    }
    throw Exception('getNotes failed: ${res.statusCode}');
  }

  static Future<void> addNote(String text) async {
    final uri = Uri.http(_host, '/api/notes');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode != 200) {
      throw Exception('addNote failed: ${res.statusCode}');
    }
  }

  static Future<void> deleteNote(int id) async {
    final uri = Uri.http(_host, '/api/notes/$id');
    final res = await http.delete(uri);
    if (res.statusCode != 200) {
      throw Exception('deleteNote failed: ${res.statusCode}');
    }
  }
}
