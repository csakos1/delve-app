// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persona.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Persona _$PersonaFromJson(Map<String, dynamic> json) => _Persona(
  available: json['available'] as bool,
  revision: json['revision'] as String?,
  block: json['block'] as String,
  blockChars: (json['block_chars'] as num).toInt(),
  generalText: json['general_text'] as String,
  sections: (json['sections'] as List<dynamic>)
      .map((e) => PersonaSection.fromJson(e as Map<String, dynamic>))
      .toList(),
  topics: (json['topics'] as List<dynamic>)
      .map((e) => PersonaTopic.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PersonaToJson(_Persona instance) => <String, dynamic>{
  'available': instance.available,
  'revision': instance.revision,
  'block': instance.block,
  'block_chars': instance.blockChars,
  'general_text': instance.generalText,
  'sections': instance.sections.map((e) => e.toJson()).toList(),
  'topics': instance.topics.map((e) => e.toJson()).toList(),
};

_PersonaSection _$PersonaSectionFromJson(Map<String, dynamic> json) =>
    _PersonaSection(
      title: json['title'] as String,
      text: json['text'] as String,
      general: json['general'] as bool? ?? false,
    );

Map<String, dynamic> _$PersonaSectionToJson(_PersonaSection instance) =>
    <String, dynamic>{
      'title': instance.title,
      'text': instance.text,
      'general': instance.general,
    };

_PersonaTopic _$PersonaTopicFromJson(Map<String, dynamic> json) =>
    _PersonaTopic(
      name: json['name'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String? ?? '',
      text: json['text'] as String,
      general: json['general'] as bool? ?? false,
    );

Map<String, dynamic> _$PersonaTopicToJson(_PersonaTopic instance) =>
    <String, dynamic>{
      'name': instance.name,
      'title': instance.title,
      'summary': instance.summary,
      'text': instance.text,
      'general': instance.general,
    };
