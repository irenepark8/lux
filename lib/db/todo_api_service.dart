import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'app_http_client.dart';

class TodoApiService {
  final String baseUrl = dotenv.env['SUPABASE_FUNCTION_URL'] ?? '';
  final String token = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final AppHttpClient _http = AppHttpClient();

  Future<List<dynamic>> fetchTodos(String date) async {
    final url = Uri.parse('$baseUrl/get_todo?date=$date');
    final response = await _http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('할 일 목록을 불러오지 못했습니다.');
    }
  }

  Future<void> addTodo(String title, String dueDate) async {
    final url = Uri.parse('$baseUrl/add_todo');
    final response = await _http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'title': title, 'due_date': dueDate}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('할 일 추가에 실패했습니다.');
    }
  }
} 