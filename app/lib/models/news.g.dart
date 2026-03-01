// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NewsImpl _$$NewsImplFromJson(Map<String, dynamic> json) => _$NewsImpl(
      title: json['title'] as String,
      description: json['description'] as String?,
      url: json['url'] as String?,
      source: json['source'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      relatedSymbols: (json['relatedSymbols'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$NewsImplToJson(_$NewsImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'url': instance.url,
      'source': instance.source,
      'thumbnailUrl': instance.thumbnailUrl,
      'publishedAt': instance.publishedAt?.toIso8601String(),
      'relatedSymbols': instance.relatedSymbols,
    };
