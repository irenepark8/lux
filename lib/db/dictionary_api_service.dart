import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_http_client.dart';

class DictionaryApiService {
  static final DictionaryApiService _instance =
      DictionaryApiService._internal();
  factory DictionaryApiService() => _instance;

  final AppHttpClient _httpClient = AppHttpClient();
  final String _baseUrl = dotenv.env['SUPABASE_FUNCTION_URL'] ?? '';
  final String _token = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  DictionaryApiService._internal();

  Future<DictionarySearchResult> searchWord(String word) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/dictionary-search?word=${Uri.encodeComponent(word)}',
      );

      print('Dictionary API 요청 URL: $uri');
      print('BaseURL: $_baseUrl');
      print('Token: ${_token.isNotEmpty ? "존재함 (${_token.length}자)" : "없음"}');

      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      print('Dictionary API 응답 상태: ${response.statusCode}');
      print('Dictionary API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = DictionarySearchResult.fromJson(data);
        print(
          '파싱된 결과 - success: ${result.success}, entries 개수: ${result.entries.length}',
        );
        return result;
      } else {
        throw Exception('단어 검색 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Dictionary API 에러: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}

class DictionarySearchResult {
  final String word;
  final List<DictionaryEntry> entries;
  final bool success;
  final String? error;

  DictionarySearchResult({
    required this.word,
    required this.entries,
    required this.success,
    this.error,
  });

  factory DictionarySearchResult.fromJson(Map<String, dynamic> json) {
    // 실제 API 응답 구조: {"word": "hi", "results": [...]}
    print('🔍 JSON 파싱 시작 - 전체 JSON: $json');

    final results = json['results'] as List<dynamic>? ?? [];
    print('🔍 results 배열 크기: ${results.length}');

    final hasResults = results.isNotEmpty;
    print('🔍 hasResults: $hasResults');

    final entries = <DictionaryEntry>[];

    for (int i = 0; i < results.length; i++) {
      try {
        print('🔍 Entry $i 파싱: ${results[i]}');
        final entry = DictionaryEntry.fromJson(results[i]);
        entries.add(entry);
        print('🔍 Entry $i 성공 - definitions: ${entry.definitions.length}');
      } catch (e) {
        print('❌ Entry $i 파싱 실패: $e');
      }
    }

    final result = DictionarySearchResult(
      word: json['word'] ?? '',
      success: entries.isNotEmpty, // entries가 실제로 파싱된 것만 체크
      error: entries.isNotEmpty ? null : json['error'] ?? 'No results found',
      entries: entries,
    );

    print(
      '🔍 최종 결과 - success: ${result.success}, entries: ${result.entries.length}',
    );
    return result;
  }
}

class DictionaryEntry {
  final String? partOfSpeech;
  final List<Definition> definitions;
  final String? pronunciation;
  final List<String> examples;

  DictionaryEntry({
    this.partOfSpeech,
    required this.definitions,
    this.pronunciation,
    this.examples = const [],
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    try {
      // 실제 API 응답: {"word": "hi", "partOfSpeech": "noun", "definition": "..."}
      final definition = json['definition'] as String? ?? '';
      final partOfSpeech = json['partOfSpeech'] as String?;
      final pronunciation = json['pronunciation'] as String?;

      print(
        '  📝 Entry 파싱 - partOfSpeech: $partOfSpeech, definition 길이: ${definition.length}',
      );

      return DictionaryEntry(
        partOfSpeech: partOfSpeech,
        pronunciation: pronunciation,
        // 단일 definition을 Definition 객체로 변환
        definitions: definition.isNotEmpty
            ? [Definition(definition: definition)]
            : [],
        examples: [], // API 응답에 examples 없으므로 빈 배열
      );
    } catch (e) {
      print('  ❌ DictionaryEntry.fromJson 에러: $e');
      rethrow;
    }
  }
}

class Definition {
  final String definition;
  final String? example;
  final List<String> synonyms;
  final List<String> antonyms;

  Definition({
    required this.definition,
    this.example,
    this.synonyms = const [],
    this.antonyms = const [],
  });

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'] ?? '',
      example: json['example'],
      synonyms: (json['synonyms'] as List<dynamic>? ?? []).cast<String>(),
      antonyms: (json['antonyms'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}
