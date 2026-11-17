import 'package:freezed_annotation/freezed_annotation.dart';

part 'persona.freezed.dart';
part 'persona.g.dart';

/// `GET /api/v1/persona` (API 13) and the answer of its `PUT` / `DELETE`
/// routes: the personal profile on the desktop - what the agent knows about
/// its user.
///
/// [sections] are the core, part of every agent chat; [topics] are files the
/// agent reads when a question needs them. [block] is what a chat started
/// now gets ([revision] names it, null without a profile); [generalText] is
/// only the part marked for the General chats, the one thing of the profile
/// that may go to a cloud model. [available] is false while the desktop has
/// no profile directory.
@freezed
abstract class Persona with _$Persona {
  const factory Persona({
    required bool available,
    String? revision,
    required String block,
    required int blockChars,
    required String generalText,
    required List<PersonaSection> sections,
    required List<PersonaTopic> topics,
  }) = _Persona;

  factory Persona.fromJson(Map<String, Object?> json) =>
      _$PersonaFromJson(json);
}

/// One section of the core. [general]: it may also go to the General chats.
@freezed
abstract class PersonaSection with _$PersonaSection {
  const factory PersonaSection({
    required String title,
    required String text,
    @Default(false) bool general,
  }) = _PersonaSection;

  factory PersonaSection.fromJson(Map<String, Object?> json) =>
      _$PersonaSectionFromJson(json);
}

/// One topic file. [name] is the file's name on the desktop (lowercase
/// letters, digits and `-`); [summary] is the one line the agent sees in its
/// list of files.
@freezed
abstract class PersonaTopic with _$PersonaTopic {
  const factory PersonaTopic({
    required String name,
    required String title,
    @Default('') String summary,
    required String text,
    @Default(false) bool general,
  }) = _PersonaTopic;

  factory PersonaTopic.fromJson(Map<String, Object?> json) =>
      _$PersonaTopicFromJson(json);
}
