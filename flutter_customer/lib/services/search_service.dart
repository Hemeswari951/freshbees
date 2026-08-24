import 'api_service.dart';

/// Shared suggestion row used by BOTH the mobile HomeScreen search bar
/// and the desktop CustomerHeader search bar — public (not private to
/// one file) so both screens can import and use it.
class SearchSuggestion {
  final String text;
  final bool isTag;

  const SearchSuggestion({required this.text, required this.isTag});

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] as String,
      isTag: json['type'] == 'tag',
    );
  }
}

class SearchService {
  /// Search-bar suggestions — matches product names AND tags. Used by
  /// both the mobile HomeScreen header and the desktop CustomerHeader,
  /// so the debounce/overlay UI in each screen just calls this.
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
