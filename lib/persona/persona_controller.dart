import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error.dart';
import '../api/models/models.dart';
import '../api/rest_client.dart';
import '../app/session.dart';
import '../general/general_database.dart';
import '../general/general_providers.dart';

/// What More → About me shows.
@immutable
class PersonaView {
  const PersonaView({this.persona, this.error});

  /// The profile as the desktop last answered (null before the first answer).
  final Persona? persona;

  /// The last load failed (an older [persona] may still be shown).
  final Object? error;
}

/// The personal profile (P1) as the app sees it: loaded over REST when the
/// page opens, replaced by the server's answer after every edit.
///
/// The profile lives on the desktop; the phone keeps one thing of it - the
/// part marked for the General chats ([Persona.generalText]), in the General
/// chats' own database, because those chats work without the desktop. Every
/// answer of the server refreshes that copy.
class PersonaController extends Notifier<PersonaView> {
  @override
  PersonaView build() {
    ref.watch(apiProvider); // another server starts empty
    return const PersonaView();
  }

  DelveApi get _api {
    final api = ref.read(apiProvider);
    if (api == null) throw const ApiUnauthorized();
    return api;
  }

  Future<void> _took(Persona persona) async {
    if (!ref.mounted) return;
    state = PersonaView(persona: persona);
    await ref
        .read(generalDatabaseProvider)
        .setMeta(
          GeneralMetaKeys.personaGeneral,
          persona.generalText.trim().isEmpty ? null : persona.generalText,
        );
  }

  /// Loads the profile; a failure is kept in [PersonaView.error].
  Future<void> refresh() async {
    try {
      await _took(await _api.persona());
    } on Object catch (e) {
      if (ref.mounted) state = PersonaView(persona: state.persona, error: e);
    }
  }

  /// Replaces the core with [sections]; errors are rethrown.
  Future<void> saveProfile(List<PersonaSection> sections) async =>
      _took(await _api.putPersonaProfile(sections));

  /// Creates or replaces a topic file; errors are rethrown.
  Future<void> saveTopic(PersonaTopic topic) async =>
      _took(await _api.putPersonaTopic(topic));

  /// Removes a topic file; errors are rethrown.
  Future<void> deleteTopic(String name) async =>
      _took(await _api.deletePersonaTopic(name));
}

final personaProvider = NotifierProvider<PersonaController, PersonaView>(
  PersonaController.new,
);

/// A topic file's name from its title: lowercase ASCII letters, digits and
/// `-`, at most 40 characters ("Tanulmányok és munka" → `tanulmanyok-es-munka`).
/// Empty when nothing of the title can be used.
String topicNameOf(String title) {
  const from = 'áàâäãåéèêëíìîïóòôöõőúùûüűçñ';
  const to = 'aaaaaaeeeeiiiioooooouuuuucn';
  final out = StringBuffer();
  for (final rune in title.toLowerCase().runes) {
    var ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    if (i >= 0) ch = to[i];
    final c = ch.codeUnitAt(0);
    final keep =
        ch.length == 1 &&
        ((c >= 0x61 && c <= 0x7a) || (c >= 0x30 && c <= 0x39));
    if (keep) {
      out.write(ch);
    } else if (out.isNotEmpty && !out.toString().endsWith('-')) {
      out.write('-');
    }
  }
  var name = out.toString();
  if (name.length > 40) name = name.substring(0, 40);
  while (name.endsWith('-')) {
    name = name.substring(0, name.length - 1);
  }
  return name;
}
