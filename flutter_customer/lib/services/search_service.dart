import 'api_service.dart';

class SearchSuggestion {
  final String text;
  final bool isTag;
  final bool isShop;
  final int? refId;

  const SearchSuggestion({
    required this.text,
    required this.isTag,
    required this.isShop,
    this.refId,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return SearchSuggestion(
      text: json['text'] as String,
      isTag: type == 'tag',
      isShop: type == 'shop',
      refId: json['ref_id'] as int?,
    );
  }
}

class SearchService {
  static Future<List<SearchSuggestion>> getSearchSuggestions(
    String query,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final response = await ApiService.get(
      '/search/suggestions?q=${Uri.encodeQueryComponent(trimmed)}',
    );

    if (response is Map<String, dynamic>) {
      final List data = response['data'] ?? [];
      return data.map((json) => SearchSuggestion.fromJson(json)).toList();
    }
    return [];
  }
}