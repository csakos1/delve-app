// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'persona.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Persona {

 bool get available; String? get revision; String get block; int get blockChars; String get generalText; List<PersonaSection> get sections; List<PersonaTopic> get topics;
/// Create a copy of Persona
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonaCopyWith<Persona> get copyWith => _$PersonaCopyWithImpl<Persona>(this as Persona, _$identity);

  /// Serializes this Persona to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Persona&&(identical(other.available, available) || other.available == available)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.block, block) || other.block == block)&&(identical(other.blockChars, blockChars) || other.blockChars == blockChars)&&(identical(other.generalText, generalText) || other.generalText == generalText)&&const DeepCollectionEquality().equals(other.sections, sections)&&const DeepCollectionEquality().equals(other.topics, topics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,available,revision,block,blockChars,generalText,const DeepCollectionEquality().hash(sections),const DeepCollectionEquality().hash(topics));

@override
String toString() {
  return 'Persona(available: $available, revision: $revision, block: $block, blockChars: $blockChars, generalText: $generalText, sections: $sections, topics: $topics)';
}


}

/// @nodoc
abstract mixin class $PersonaCopyWith<$Res>  {
  factory $PersonaCopyWith(Persona value, $Res Function(Persona) _then) = _$PersonaCopyWithImpl;
@useResult
$Res call({
 bool available, String? revision, String block, int blockChars, String generalText, List<PersonaSection> sections, List<PersonaTopic> topics
});




}
/// @nodoc
class _$PersonaCopyWithImpl<$Res>
    implements $PersonaCopyWith<$Res> {
  _$PersonaCopyWithImpl(this._self, this._then);

  final Persona _self;
  final $Res Function(Persona) _then;

/// Create a copy of Persona
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? available = null,Object? revision = freezed,Object? block = null,Object? blockChars = null,Object? generalText = null,Object? sections = null,Object? topics = null,}) {
  return _then(_self.copyWith(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as String?,block: null == block ? _self.block : block // ignore: cast_nullable_to_non_nullable
as String,blockChars: null == blockChars ? _self.blockChars : blockChars // ignore: cast_nullable_to_non_nullable
as int,generalText: null == generalText ? _self.generalText : generalText // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<PersonaSection>,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<PersonaTopic>,
  ));
}

}


/// Adds pattern-matching-related methods to [Persona].
extension PersonaPatterns on Persona {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Persona value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Persona() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Persona value)  $default,){
final _that = this;
switch (_that) {
case _Persona():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Persona value)?  $default,){
final _that = this;
switch (_that) {
case _Persona() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool available,  String? revision,  String block,  int blockChars,  String generalText,  List<PersonaSection> sections,  List<PersonaTopic> topics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Persona() when $default != null:
return $default(_that.available,_that.revision,_that.block,_that.blockChars,_that.generalText,_that.sections,_that.topics);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool available,  String? revision,  String block,  int blockChars,  String generalText,  List<PersonaSection> sections,  List<PersonaTopic> topics)  $default,) {final _that = this;
switch (_that) {
case _Persona():
return $default(_that.available,_that.revision,_that.block,_that.blockChars,_that.generalText,_that.sections,_that.topics);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool available,  String? revision,  String block,  int blockChars,  String generalText,  List<PersonaSection> sections,  List<PersonaTopic> topics)?  $default,) {final _that = this;
switch (_that) {
case _Persona() when $default != null:
return $default(_that.available,_that.revision,_that.block,_that.blockChars,_that.generalText,_that.sections,_that.topics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Persona implements Persona {
  const _Persona({required this.available, this.revision, required this.block, required this.blockChars, required this.generalText, required final  List<PersonaSection> sections, required final  List<PersonaTopic> topics}): _sections = sections,_topics = topics;
  factory _Persona.fromJson(Map<String, dynamic> json) => _$PersonaFromJson(json);

@override final  bool available;
@override final  String? revision;
@override final  String block;
@override final  int blockChars;
@override final  String generalText;
 final  List<PersonaSection> _sections;
@override List<PersonaSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

 final  List<PersonaTopic> _topics;
@override List<PersonaTopic> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}


/// Create a copy of Persona
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonaCopyWith<_Persona> get copyWith => __$PersonaCopyWithImpl<_Persona>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Persona&&(identical(other.available, available) || other.available == available)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.block, block) || other.block == block)&&(identical(other.blockChars, blockChars) || other.blockChars == blockChars)&&(identical(other.generalText, generalText) || other.generalText == generalText)&&const DeepCollectionEquality().equals(other._sections, _sections)&&const DeepCollectionEquality().equals(other._topics, _topics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,available,revision,block,blockChars,generalText,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_topics));

@override
String toString() {
  return 'Persona(available: $available, revision: $revision, block: $block, blockChars: $blockChars, generalText: $generalText, sections: $sections, topics: $topics)';
}


}

/// @nodoc
abstract mixin class _$PersonaCopyWith<$Res> implements $PersonaCopyWith<$Res> {
  factory _$PersonaCopyWith(_Persona value, $Res Function(_Persona) _then) = __$PersonaCopyWithImpl;
@override @useResult
$Res call({
 bool available, String? revision, String block, int blockChars, String generalText, List<PersonaSection> sections, List<PersonaTopic> topics
});




}
/// @nodoc
class __$PersonaCopyWithImpl<$Res>
    implements _$PersonaCopyWith<$Res> {
  __$PersonaCopyWithImpl(this._self, this._then);

  final _Persona _self;
  final $Res Function(_Persona) _then;

/// Create a copy of Persona
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? available = null,Object? revision = freezed,Object? block = null,Object? blockChars = null,Object? generalText = null,Object? sections = null,Object? topics = null,}) {
  return _then(_Persona(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,revision: freezed == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as String?,block: null == block ? _self.block : block // ignore: cast_nullable_to_non_nullable
as String,blockChars: null == blockChars ? _self.blockChars : blockChars // ignore: cast_nullable_to_non_nullable
as int,generalText: null == generalText ? _self.generalText : generalText // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<PersonaSection>,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<PersonaTopic>,
  ));
}


}


/// @nodoc
mixin _$PersonaSection {

 String get title; String get text; bool get general;
/// Create a copy of PersonaSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonaSectionCopyWith<PersonaSection> get copyWith => _$PersonaSectionCopyWithImpl<PersonaSection>(this as PersonaSection, _$identity);

  /// Serializes this PersonaSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonaSection&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.general, general) || other.general == general));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text,general);

@override
String toString() {
  return 'PersonaSection(title: $title, text: $text, general: $general)';
}


}

/// @nodoc
abstract mixin class $PersonaSectionCopyWith<$Res>  {
  factory $PersonaSectionCopyWith(PersonaSection value, $Res Function(PersonaSection) _then) = _$PersonaSectionCopyWithImpl;
@useResult
$Res call({
 String title, String text, bool general
});




}
/// @nodoc
class _$PersonaSectionCopyWithImpl<$Res>
    implements $PersonaSectionCopyWith<$Res> {
  _$PersonaSectionCopyWithImpl(this._self, this._then);

  final PersonaSection _self;
  final $Res Function(PersonaSection) _then;

/// Create a copy of PersonaSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? text = null,Object? general = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,general: null == general ? _self.general : general // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonaSection].
extension PersonaSectionPatterns on PersonaSection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonaSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonaSection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonaSection value)  $default,){
final _that = this;
switch (_that) {
case _PersonaSection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonaSection value)?  $default,){
final _that = this;
switch (_that) {
case _PersonaSection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String text,  bool general)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonaSection() when $default != null:
return $default(_that.title,_that.text,_that.general);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String text,  bool general)  $default,) {final _that = this;
switch (_that) {
case _PersonaSection():
return $default(_that.title,_that.text,_that.general);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String text,  bool general)?  $default,) {final _that = this;
switch (_that) {
case _PersonaSection() when $default != null:
return $default(_that.title,_that.text,_that.general);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonaSection implements PersonaSection {
  const _PersonaSection({required this.title, required this.text, this.general = false});
  factory _PersonaSection.fromJson(Map<String, dynamic> json) => _$PersonaSectionFromJson(json);

@override final  String title;
@override final  String text;
@override@JsonKey() final  bool general;

/// Create a copy of PersonaSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonaSectionCopyWith<_PersonaSection> get copyWith => __$PersonaSectionCopyWithImpl<_PersonaSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonaSectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonaSection&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.general, general) || other.general == general));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text,general);

@override
String toString() {
  return 'PersonaSection(title: $title, text: $text, general: $general)';
}


}

/// @nodoc
abstract mixin class _$PersonaSectionCopyWith<$Res> implements $PersonaSectionCopyWith<$Res> {
  factory _$PersonaSectionCopyWith(_PersonaSection value, $Res Function(_PersonaSection) _then) = __$PersonaSectionCopyWithImpl;
@override @useResult
$Res call({
 String title, String text, bool general
});




}
/// @nodoc
class __$PersonaSectionCopyWithImpl<$Res>
    implements _$PersonaSectionCopyWith<$Res> {
  __$PersonaSectionCopyWithImpl(this._self, this._then);

  final _PersonaSection _self;
  final $Res Function(_PersonaSection) _then;

/// Create a copy of PersonaSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? text = null,Object? general = null,}) {
  return _then(_PersonaSection(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,general: null == general ? _self.general : general // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PersonaTopic {

 String get name; String get title; String get summary; String get text; bool get general;
/// Create a copy of PersonaTopic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonaTopicCopyWith<PersonaTopic> get copyWith => _$PersonaTopicCopyWithImpl<PersonaTopic>(this as PersonaTopic, _$identity);

  /// Serializes this PersonaTopic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonaTopic&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.text, text) || other.text == text)&&(identical(other.general, general) || other.general == general));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,title,summary,text,general);

@override
String toString() {
  return 'PersonaTopic(name: $name, title: $title, summary: $summary, text: $text, general: $general)';
}


}

/// @nodoc
abstract mixin class $PersonaTopicCopyWith<$Res>  {
  factory $PersonaTopicCopyWith(PersonaTopic value, $Res Function(PersonaTopic) _then) = _$PersonaTopicCopyWithImpl;
@useResult
$Res call({
 String name, String title, String summary, String text, bool general
});




}
/// @nodoc
class _$PersonaTopicCopyWithImpl<$Res>
    implements $PersonaTopicCopyWith<$Res> {
  _$PersonaTopicCopyWithImpl(this._self, this._then);

  final PersonaTopic _self;
  final $Res Function(PersonaTopic) _then;

/// Create a copy of PersonaTopic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? title = null,Object? summary = null,Object? text = null,Object? general = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,general: null == general ? _self.general : general // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonaTopic].
extension PersonaTopicPatterns on PersonaTopic {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonaTopic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonaTopic() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonaTopic value)  $default,){
final _that = this;
switch (_that) {
case _PersonaTopic():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonaTopic value)?  $default,){
final _that = this;
switch (_that) {
case _PersonaTopic() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String title,  String summary,  String text,  bool general)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonaTopic() when $default != null:
return $default(_that.name,_that.title,_that.summary,_that.text,_that.general);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String title,  String summary,  String text,  bool general)  $default,) {final _that = this;
switch (_that) {
case _PersonaTopic():
return $default(_that.name,_that.title,_that.summary,_that.text,_that.general);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String title,  String summary,  String text,  bool general)?  $default,) {final _that = this;
switch (_that) {
case _PersonaTopic() when $default != null:
return $default(_that.name,_that.title,_that.summary,_that.text,_that.general);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonaTopic implements PersonaTopic {
  const _PersonaTopic({required this.name, required this.title, this.summary = '', required this.text, this.general = false});
  factory _PersonaTopic.fromJson(Map<String, dynamic> json) => _$PersonaTopicFromJson(json);

@override final  String name;
@override final  String title;
@override@JsonKey() final  String summary;
@override final  String text;
@override@JsonKey() final  bool general;

/// Create a copy of PersonaTopic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonaTopicCopyWith<_PersonaTopic> get copyWith => __$PersonaTopicCopyWithImpl<_PersonaTopic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonaTopicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonaTopic&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.text, text) || other.text == text)&&(identical(other.general, general) || other.general == general));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,title,summary,text,general);

@override
String toString() {
  return 'PersonaTopic(name: $name, title: $title, summary: $summary, text: $text, general: $general)';
}


}

/// @nodoc
abstract mixin class _$PersonaTopicCopyWith<$Res> implements $PersonaTopicCopyWith<$Res> {
  factory _$PersonaTopicCopyWith(_PersonaTopic value, $Res Function(_PersonaTopic) _then) = __$PersonaTopicCopyWithImpl;
@override @useResult
$Res call({
 String name, String title, String summary, String text, bool general
});




}
/// @nodoc
class __$PersonaTopicCopyWithImpl<$Res>
    implements _$PersonaTopicCopyWith<$Res> {
  __$PersonaTopicCopyWithImpl(this._self, this._then);

  final _PersonaTopic _self;
  final $Res Function(_PersonaTopic) _then;

/// Create a copy of PersonaTopic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? title = null,Object? summary = null,Object? text = null,Object? general = null,}) {
  return _then(_PersonaTopic(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,general: null == general ? _self.general : general // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
