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

  /// Returns detected_emotion, confidence, and all_scores (Map<String, double>).
  /// all_scores example: { "anger": 0.05, "fear": 0.72, "joy": 0.10, "sadness": 0.13 }
  static Future<Map<String, dynamic>> classifyEmotion({
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classify_emotion'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Parse all_scores into Map<String, double> if present
      if (data.containsKey('all_scores')) {
        final raw = data['all_scores'] as Map<String, dynamic>;
        data['all_scores'] =
            raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }

      return data;
    } else {
      throw Exception('Classify error: ${response.statusCode}');
    }
  }
}
