import 'package:http/http.dart' as http;

class AppHttpClient {
  static final AppHttpClient _instance = AppHttpClient._internal();
  factory AppHttpClient() => _instance;

  final http.Client client = http.Client();
  final Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    // 여기에 공통 헤더 추가 가능
  };

  AppHttpClient._internal();

  // 공통 헤더와 함께 GET 요청
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return client.get(
      url,
      headers: {...defaultHeaders, if (headers != null) ...headers},
    );
  }

  // 공통 헤더와 함께 POST 요청
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return client.post(
      url,
      headers: {...defaultHeaders, if (headers != null) ...headers},
      body: body,
    );
  }
} 