import 'package:freezed_annotation/freezed_annotation.dart';

part 'news.freezed.dart';
part 'news.g.dart';

/// News article related to stocks.
@freezed
class News with _$News {
  const factory News({
    required String title,
    String? description,
    String? url,
    String? source,
    String? thumbnailUrl,
    DateTime? publishedAt,
    List<String>? relatedSymbols,
  }) = _News;

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);
}
