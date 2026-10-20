// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Conversation {

 String get id; String? get title;/// The latest user/assistant text, ≤ 200 characters (API 3).
 String? get preview; DateTime get createdAt; DateTime get updatedAt; bool get archived; bool get thinking; String get origin; String? get lastRunId; ContextFill get context; TokenTotals get totals;
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationCopyWith<Conversation> get copyWith => _$ConversationCopyWithImpl<Conversation>(this as Conversation, _$identity);

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conversation&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.lastRunId, lastRunId) || other.lastRunId == lastRunId)&&(identical(other.context, context) || other.context == context)&&(identical(other.totals, totals) || other.totals == totals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,preview,createdAt,updatedAt,archived,thinking,origin,lastRunId,context,totals);

@override
String toString() {
  return 'Conversation(id: $id, title: $title, preview: $preview, createdAt: $createdAt, updatedAt: $updatedAt, archived: $archived, thinking: $thinking, origin: $origin, lastRunId: $lastRunId, context: $context, totals: $totals)';
}


}

/// @nodoc
abstract mixin class $ConversationCopyWith<$Res>  {
  factory $ConversationCopyWith(Conversation value, $Res Function(Conversation) _then) = _$ConversationCopyWithImpl;
@useResult
$Res call({
 String id, String? title, String? preview, DateTime createdAt, DateTime updatedAt, bool archived, bool thinking, String origin, String? lastRunId, ContextFill context, TokenTotals totals
});


$ContextFillCopyWith<$Res> get context;$TokenTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class _$ConversationCopyWithImpl<$Res>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._self, this._then);

  final Conversation _self;
  final $Res Function(Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? preview = freezed,Object? createdAt = null,Object? updatedAt = null,Object? archived = null,Object? thinking = null,Object? origin = null,Object? lastRunId = freezed,Object? context = null,Object? totals = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,lastRunId: freezed == lastRunId ? _self.lastRunId : lastRunId // ignore: cast_nullable_to_non_nullable
as String?,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as ContextFill,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as TokenTotals,
  ));
}
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContextFillCopyWith<$Res> get context {
  
  return $ContextFillCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenTotalsCopyWith<$Res> get totals {
  
  return $TokenTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// Adds pattern-matching-related methods to [Conversation].
extension ConversationPatterns on Conversation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Conversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Conversation value)  $default,){
final _that = this;
switch (_that) {
case _Conversation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Conversation value)?  $default,){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? title,  String? preview,  DateTime createdAt,  DateTime updatedAt,  bool archived,  bool thinking,  String origin,  String? lastRunId,  ContextFill context,  TokenTotals totals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.title,_that.preview,_that.createdAt,_that.updatedAt,_that.archived,_that.thinking,_that.origin,_that.lastRunId,_that.context,_that.totals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? title,  String? preview,  DateTime createdAt,  DateTime updatedAt,  bool archived,  bool thinking,  String origin,  String? lastRunId,  ContextFill context,  TokenTotals totals)  $default,) {final _that = this;
switch (_that) {
case _Conversation():
return $default(_that.id,_that.title,_that.preview,_that.createdAt,_that.updatedAt,_that.archived,_that.thinking,_that.origin,_that.lastRunId,_that.context,_that.totals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? title,  String? preview,  DateTime createdAt,  DateTime updatedAt,  bool archived,  bool thinking,  String origin,  String? lastRunId,  ContextFill context,  TokenTotals totals)?  $default,) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.title,_that.preview,_that.createdAt,_that.updatedAt,_that.archived,_that.thinking,_that.origin,_that.lastRunId,_that.context,_that.totals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Conversation implements Conversation {
  const _Conversation({required this.id, this.title, this.preview, required this.createdAt, required this.updatedAt, required this.archived, required this.thinking, required this.origin, this.lastRunId, required this.context, required this.totals});
  factory _Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

@override final  String id;
@override final  String? title;
/// The latest user/assistant text, ≤ 200 characters (API 3).
@override final  String? preview;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  bool archived;
@override final  bool thinking;
@override final  String origin;
@override final  String? lastRunId;
@override final  ContextFill context;
@override final  TokenTotals totals;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationCopyWith<_Conversation> get copyWith => __$ConversationCopyWithImpl<_Conversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conversation&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.lastRunId, lastRunId) || other.lastRunId == lastRunId)&&(identical(other.context, context) || other.context == context)&&(identical(other.totals, totals) || other.totals == totals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,preview,createdAt,updatedAt,archived,thinking,origin,lastRunId,context,totals);

@override
String toString() {
  return 'Conversation(id: $id, title: $title, preview: $preview, createdAt: $createdAt, updatedAt: $updatedAt, archived: $archived, thinking: $thinking, origin: $origin, lastRunId: $lastRunId, context: $context, totals: $totals)';
}


}

/// @nodoc
abstract mixin class _$ConversationCopyWith<$Res> implements $ConversationCopyWith<$Res> {
  factory _$ConversationCopyWith(_Conversation value, $Res Function(_Conversation) _then) = __$ConversationCopyWithImpl;
@override @useResult
$Res call({
 String id, String? title, String? preview, DateTime createdAt, DateTime updatedAt, bool archived, bool thinking, String origin, String? lastRunId, ContextFill context, TokenTotals totals
});


@override $ContextFillCopyWith<$Res> get context;@override $TokenTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class __$ConversationCopyWithImpl<$Res>
    implements _$ConversationCopyWith<$Res> {
  __$ConversationCopyWithImpl(this._self, this._then);

  final _Conversation _self;
  final $Res Function(_Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? preview = freezed,Object? createdAt = null,Object? updatedAt = null,Object? archived = null,Object? thinking = null,Object? origin = null,Object? lastRunId = freezed,Object? context = null,Object? totals = null,}) {
  return _then(_Conversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,lastRunId: freezed == lastRunId ? _self.lastRunId : lastRunId // ignore: cast_nullable_to_non_nullable
as String?,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as ContextFill,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as TokenTotals,
  ));
}

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContextFillCopyWith<$Res> get context {
  
  return $ContextFillCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenTotalsCopyWith<$Res> get totals {
  
  return $TokenTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// @nodoc
mixin _$ContextFill {

 int? get tokens; int? get max; double? get pct; bool get warn; DateTime? get measuredAt;
/// Create a copy of ContextFill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContextFillCopyWith<ContextFill> get copyWith => _$ContextFillCopyWithImpl<ContextFill>(this as ContextFill, _$identity);

  /// Serializes this ContextFill to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContextFill&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.max, max) || other.max == max)&&(identical(other.pct, pct) || other.pct == pct)&&(identical(other.warn, warn) || other.warn == warn)&&(identical(other.measuredAt, measuredAt) || other.measuredAt == measuredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tokens,max,pct,warn,measuredAt);

@override
String toString() {
  return 'ContextFill(tokens: $tokens, max: $max, pct: $pct, warn: $warn, measuredAt: $measuredAt)';
}


}

/// @nodoc
abstract mixin class $ContextFillCopyWith<$Res>  {
  factory $ContextFillCopyWith(ContextFill value, $Res Function(ContextFill) _then) = _$ContextFillCopyWithImpl;
@useResult
$Res call({
 int? tokens, int? max, double? pct, bool warn, DateTime? measuredAt
});




}
/// @nodoc
class _$ContextFillCopyWithImpl<$Res>
    implements $ContextFillCopyWith<$Res> {
  _$ContextFillCopyWithImpl(this._self, this._then);

  final ContextFill _self;
  final $Res Function(ContextFill) _then;

/// Create a copy of ContextFill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tokens = freezed,Object? max = freezed,Object? pct = freezed,Object? warn = null,Object? measuredAt = freezed,}) {
  return _then(_self.copyWith(
tokens: freezed == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int?,pct: freezed == pct ? _self.pct : pct // ignore: cast_nullable_to_non_nullable
as double?,warn: null == warn ? _self.warn : warn // ignore: cast_nullable_to_non_nullable
as bool,measuredAt: freezed == measuredAt ? _self.measuredAt : measuredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContextFill].
extension ContextFillPatterns on ContextFill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContextFill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContextFill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContextFill value)  $default,){
final _that = this;
switch (_that) {
case _ContextFill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContextFill value)?  $default,){
final _that = this;
switch (_that) {
case _ContextFill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? tokens,  int? max,  double? pct,  bool warn,  DateTime? measuredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContextFill() when $default != null:
return $default(_that.tokens,_that.max,_that.pct,_that.warn,_that.measuredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? tokens,  int? max,  double? pct,  bool warn,  DateTime? measuredAt)  $default,) {final _that = this;
switch (_that) {
case _ContextFill():
return $default(_that.tokens,_that.max,_that.pct,_that.warn,_that.measuredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? tokens,  int? max,  double? pct,  bool warn,  DateTime? measuredAt)?  $default,) {final _that = this;
switch (_that) {
case _ContextFill() when $default != null:
return $default(_that.tokens,_that.max,_that.pct,_that.warn,_that.measuredAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContextFill implements ContextFill {
  const _ContextFill({this.tokens, this.max, this.pct, required this.warn, this.measuredAt});
  factory _ContextFill.fromJson(Map<String, dynamic> json) => _$ContextFillFromJson(json);

@override final  int? tokens;
@override final  int? max;
@override final  double? pct;
@override final  bool warn;
@override final  DateTime? measuredAt;

/// Create a copy of ContextFill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContextFillCopyWith<_ContextFill> get copyWith => __$ContextFillCopyWithImpl<_ContextFill>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContextFillToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContextFill&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.max, max) || other.max == max)&&(identical(other.pct, pct) || other.pct == pct)&&(identical(other.warn, warn) || other.warn == warn)&&(identical(other.measuredAt, measuredAt) || other.measuredAt == measuredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tokens,max,pct,warn,measuredAt);

@override
String toString() {
  return 'ContextFill(tokens: $tokens, max: $max, pct: $pct, warn: $warn, measuredAt: $measuredAt)';
}


}

/// @nodoc
abstract mixin class _$ContextFillCopyWith<$Res> implements $ContextFillCopyWith<$Res> {
  factory _$ContextFillCopyWith(_ContextFill value, $Res Function(_ContextFill) _then) = __$ContextFillCopyWithImpl;
@override @useResult
$Res call({
 int? tokens, int? max, double? pct, bool warn, DateTime? measuredAt
});




}
/// @nodoc
class __$ContextFillCopyWithImpl<$Res>
    implements _$ContextFillCopyWith<$Res> {
  __$ContextFillCopyWithImpl(this._self, this._then);

  final _ContextFill _self;
  final $Res Function(_ContextFill) _then;

/// Create a copy of ContextFill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tokens = freezed,Object? max = freezed,Object? pct = freezed,Object? warn = null,Object? measuredAt = freezed,}) {
  return _then(_ContextFill(
tokens: freezed == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int?,pct: freezed == pct ? _self.pct : pct // ignore: cast_nullable_to_non_nullable
as double?,warn: null == warn ? _self.warn : warn // ignore: cast_nullable_to_non_nullable
as bool,measuredAt: freezed == measuredAt ? _self.measuredAt : measuredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$TokenTotals {

 int get inputTokens; int get outputTokens; int get cacheReadTokens; int get totalTokens;
/// Create a copy of TokenTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenTotalsCopyWith<TokenTotals> get copyWith => _$TokenTotalsCopyWithImpl<TokenTotals>(this as TokenTotals, _$identity);

  /// Serializes this TokenTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenTotals&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.cacheReadTokens, cacheReadTokens) || other.cacheReadTokens == cacheReadTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inputTokens,outputTokens,cacheReadTokens,totalTokens);

@override
String toString() {
  return 'TokenTotals(inputTokens: $inputTokens, outputTokens: $outputTokens, cacheReadTokens: $cacheReadTokens, totalTokens: $totalTokens)';
}


}

/// @nodoc
abstract mixin class $TokenTotalsCopyWith<$Res>  {
  factory $TokenTotalsCopyWith(TokenTotals value, $Res Function(TokenTotals) _then) = _$TokenTotalsCopyWithImpl;
@useResult
$Res call({
 int inputTokens, int outputTokens, int cacheReadTokens, int totalTokens
});




}
/// @nodoc
class _$TokenTotalsCopyWithImpl<$Res>
    implements $TokenTotalsCopyWith<$Res> {
  _$TokenTotalsCopyWithImpl(this._self, this._then);

  final TokenTotals _self;
  final $Res Function(TokenTotals) _then;

/// Create a copy of TokenTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inputTokens = null,Object? outputTokens = null,Object? cacheReadTokens = null,Object? totalTokens = null,}) {
  return _then(_self.copyWith(
inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,cacheReadTokens: null == cacheReadTokens ? _self.cacheReadTokens : cacheReadTokens // ignore: cast_nullable_to_non_nullable
as int,totalTokens: null == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenTotals].
extension TokenTotalsPatterns on TokenTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenTotals value)  $default,){
final _that = this;
switch (_that) {
case _TokenTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenTotals value)?  $default,){
final _that = this;
switch (_that) {
case _TokenTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int inputTokens,  int outputTokens,  int cacheReadTokens,  int totalTokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenTotals() when $default != null:
return $default(_that.inputTokens,_that.outputTokens,_that.cacheReadTokens,_that.totalTokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int inputTokens,  int outputTokens,  int cacheReadTokens,  int totalTokens)  $default,) {final _that = this;
switch (_that) {
case _TokenTotals():
return $default(_that.inputTokens,_that.outputTokens,_that.cacheReadTokens,_that.totalTokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int inputTokens,  int outputTokens,  int cacheReadTokens,  int totalTokens)?  $default,) {final _that = this;
switch (_that) {
case _TokenTotals() when $default != null:
return $default(_that.inputTokens,_that.outputTokens,_that.cacheReadTokens,_that.totalTokens);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TokenTotals implements TokenTotals {
  const _TokenTotals({required this.inputTokens, required this.outputTokens, required this.cacheReadTokens, required this.totalTokens});
  factory _TokenTotals.fromJson(Map<String, dynamic> json) => _$TokenTotalsFromJson(json);

@override final  int inputTokens;
@override final  int outputTokens;
@override final  int cacheReadTokens;
@override final  int totalTokens;

/// Create a copy of TokenTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenTotalsCopyWith<_TokenTotals> get copyWith => __$TokenTotalsCopyWithImpl<_TokenTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokenTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenTotals&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.cacheReadTokens, cacheReadTokens) || other.cacheReadTokens == cacheReadTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inputTokens,outputTokens,cacheReadTokens,totalTokens);

@override
String toString() {
  return 'TokenTotals(inputTokens: $inputTokens, outputTokens: $outputTokens, cacheReadTokens: $cacheReadTokens, totalTokens: $totalTokens)';
}


}

/// @nodoc
abstract mixin class _$TokenTotalsCopyWith<$Res> implements $TokenTotalsCopyWith<$Res> {
  factory _$TokenTotalsCopyWith(_TokenTotals value, $Res Function(_TokenTotals) _then) = __$TokenTotalsCopyWithImpl;
@override @useResult
$Res call({
 int inputTokens, int outputTokens, int cacheReadTokens, int totalTokens
});




}
/// @nodoc
class __$TokenTotalsCopyWithImpl<$Res>
    implements _$TokenTotalsCopyWith<$Res> {
  __$TokenTotalsCopyWithImpl(this._self, this._then);

  final _TokenTotals _self;
  final $Res Function(_TokenTotals) _then;

/// Create a copy of TokenTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inputTokens = null,Object? outputTokens = null,Object? cacheReadTokens = null,Object? totalTokens = null,}) {
  return _then(_TokenTotals(
inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,cacheReadTokens: null == cacheReadTokens ? _self.cacheReadTokens : cacheReadTokens // ignore: cast_nullable_to_non_nullable
as int,totalTokens: null == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
