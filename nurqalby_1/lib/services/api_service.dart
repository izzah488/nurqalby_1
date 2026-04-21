import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use your PC's IP address, NOT localhost
  // Find it by running: ipconfig (Windows) → IPv4 Address
  static const String baseUrl = 'http://10.186.181.134:8000';

  static Future<List<Map<String, dynamic>>> recommend({
    required String text,
    required String emotion,
    required String cause,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'emotion': emotion,
        'cause': cause,
        'top_k': 3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw Exception('Recommend API error: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> recommendDua({
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommend_dua'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'emotion': '',
        'cause': '',
        'top_k': 3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw Exception('Dua API error: ${response.statusCode}');
    }
  }

  // ← moved INSIDE the class (was outside before, causing the error)
  static Future<Map<String, dynamic>> classifyEmotion({
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classify_emotion'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Classify error: ${response.statusCode}');
    }
  }
} // ← single closing brace for the class
