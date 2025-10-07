import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import '../models/notes_page.dart';

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<String> ping() async {
    final res = await http.get(Uri.parse('$baseUrl/api/ping'));
    if (res.statusCode == 200) {
      return (json.decode(res.body) as Map)['message'] as String;
    }
    throw Exception('Ping failed ${res.statusCode}');
  }

  static Future<NotesPage> getNotes({
    String? q,
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/api/notes').replace(
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return NotesPage.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Get notes failed ${res.statusCode}');
  }

  static Future<Note> addNote(String text) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/notes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': text}),
    );
    if (res.statusCode == 200) {
      return Note.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Add note failed ${res.statusCode}');
  }

  static Future<Note> updateNote(int id, String text) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/notes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': text}),
    );
    if (res.statusCode == 200) {
      return Note.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Update failed ${res.statusCode}');
  }

  static Future<void> deleteNote(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/notes/$id'));
    if (res.statusCode != 200) {
      throw Exception('Delete failed ${res.statusCode}');
    }
  }
}
