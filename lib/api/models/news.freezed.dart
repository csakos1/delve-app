// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NewsItem {

 int get id; String? get topic; String? get source;/// `feed` | `release`.
 String get kind; String get title; String get url; String? get publisher; String? get excerpt; DateTime? get publishedAt; DateTime get seenAt; bool get gn; int get sources; List<NewsRelease>? get releases; int? get score; String? get why; bool? get setup; String? get summaryHu; String? get textState; String get originalUrl; bool get read; bool get saved;/// `more` | `less` | null.
 String? get feedback;
/// Create a copy of NewsItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsItemCopyWith<NewsItem> get copyWith => _$NewsItemCopyWithImpl<NewsItem>(this as NewsItem, _$identity);

  /// Serializes this NewsItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsItem&&(identical(other.id, id) || other.id == id)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.source, source) || other.source == source)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.seenAt, seenAt) || other.seenAt == seenAt)&&(identical(other.gn, gn) || other.gn == gn)&&(identical(other.sources, sources) || other.sources == sources)&&const DeepCollectionEquality().equals(other.releases, releases)&&(identical(other.score, score) || other.score == score)&&(identical(other.why, why) || other.why == why)&&(identical(other.setup, setup) || other.setup == setup)&&(identical(other.summaryHu, summaryHu) || other.summaryHu == summaryHu)&&(identical(other.textState, textState) || other.textState == textState)&&(identical(other.originalUrl, originalUrl) || other.originalUrl == originalUrl)&&(identical(other.read, read) || other.read == read)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.feedback, feedback) || other.feedback == feedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,topic,source,kind,title,url,publisher,excerpt,publishedAt,seenAt,gn,sources,const DeepCollectionEquality().hash(releases),score,why,setup,summaryHu,textState,originalUrl,read,saved,feedback]);

@override
String toString() {
  return 'NewsItem(id: $id, topic: $topic, source: $source, kind: $kind, title: $title, url: $url, publisher: $publisher, excerpt: $excerpt, publishedAt: $publishedAt, seenAt: $seenAt, gn: $gn, sources: $sources, releases: $releases, score: $score, why: $why, setup: $setup, summaryHu: $summaryHu, textState: $textState, originalUrl: $originalUrl, read: $read, saved: $saved, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class $NewsItemCopyWith<$Res>  {
  factory $NewsItemCopyWith(NewsItem value, $Res Function(NewsItem) _then) = _$NewsItemCopyWithImpl;
@useResult
$Res call({
 int id, String? topic, String? source, String kind, String title, String url, String? publisher, String? excerpt, DateTime? publishedAt, DateTime seenAt, bool gn, int sources, List<NewsRelease>? releases, int? score, String? why, bool? setup, String? summaryHu, String? textState, String originalUrl, bool read, bool saved, String? feedback
});




}
/// @nodoc
class _$NewsItemCopyWithImpl<$Res>
    implements $NewsItemCopyWith<$Res> {
  _$NewsItemCopyWithImpl(this._self, this._then);

  final NewsItem _self;
  final $Res Function(NewsItem) _then;

/// Create a copy of NewsItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? topic = freezed,Object? source = freezed,Object? kind = null,Object? title = null,Object? url = null,Object? publisher = freezed,Object? excerpt = freezed,Object? publishedAt = freezed,Object? seenAt = null,Object? gn = null,Object? sources = null,Object? releases = freezed,Object? score = freezed,Object? why = freezed,Object? setup = freezed,Object? summaryHu = freezed,Object? textState = freezed,Object? originalUrl = null,Object? read = null,Object? saved = null,Object? feedback = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,seenAt: null == seenAt ? _self.seenAt : seenAt // ignore: cast_nullable_to_non_nullable
as DateTime,gn: null == gn ? _self.gn : gn // ignore: cast_nullable_to_non_nullable
as bool,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as int,releases: freezed == releases ? _self.releases : releases // ignore: cast_nullable_to_non_nullable
as List<NewsRelease>?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,why: freezed == why ? _self.why : why // ignore: cast_nullable_to_non_nullable
as String?,setup: freezed == setup ? _self.setup : setup // ignore: cast_nullable_to_non_nullable
as bool?,summaryHu: freezed == summaryHu ? _self.summaryHu : summaryHu // ignore: cast_nullable_to_non_nullable
as String?,textState: freezed == textState ? _self.textState : textState // ignore: cast_nullable_to_non_nullable
as String?,originalUrl: null == originalUrl ? _self.originalUrl : originalUrl // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsItem].
extension NewsItemPatterns on NewsItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsItem value)  $default,){
final _that = this;
switch (_that) {
case _NewsItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsItem value)?  $default,){
final _that = this;
switch (_that) {
case _NewsItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? topic,  String? source,  String kind,  String title,  String url,  String? publisher,  String? excerpt,  DateTime? publishedAt,  DateTime seenAt,  bool gn,  int sources,  List<NewsRelease>? releases,  int? score,  String? why,  bool? setup,  String? summaryHu,  String? textState,  String originalUrl,  bool read,  bool saved,  String? feedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsItem() when $default != null:
return $default(_that.id,_that.topic,_that.source,_that.kind,_that.title,_that.url,_that.publisher,_that.excerpt,_that.publishedAt,_that.seenAt,_that.gn,_that.sources,_that.releases,_that.score,_that.why,_that.setup,_that.summaryHu,_that.textState,_that.originalUrl,_that.read,_that.saved,_that.feedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? topic,  String? source,  String kind,  String title,  String url,  String? publisher,  String? excerpt,  DateTime? publishedAt,  DateTime seenAt,  bool gn,  int sources,  List<NewsRelease>? releases,  int? score,  String? why,  bool? setup,  String? summaryHu,  String? textState,  String originalUrl,  bool read,  bool saved,  String? feedback)  $default,) {final _that = this;
switch (_that) {
case _NewsItem():
return $default(_that.id,_that.topic,_that.source,_that.kind,_that.title,_that.url,_that.publisher,_that.excerpt,_that.publishedAt,_that.seenAt,_that.gn,_that.sources,_that.releases,_that.score,_that.why,_that.setup,_that.summaryHu,_that.textState,_that.originalUrl,_that.read,_that.saved,_that.feedback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? topic,  String? source,  String kind,  String title,  String url,  String? publisher,  String? excerpt,  DateTime? publishedAt,  DateTime seenAt,  bool gn,  int sources,  List<NewsRelease>? releases,  int? score,  String? why,  bool? setup,  String? summaryHu,  String? textState,  String originalUrl,  bool read,  bool saved,  String? feedback)?  $default,) {final _that = this;
switch (_that) {
case _NewsItem() when $default != null:
return $default(_that.id,_that.topic,_that.source,_that.kind,_that.title,_that.url,_that.publisher,_that.excerpt,_that.publishedAt,_that.seenAt,_that.gn,_that.sources,_that.releases,_that.score,_that.why,_that.setup,_that.summaryHu,_that.textState,_that.originalUrl,_that.read,_that.saved,_that.feedback);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsItem implements NewsItem {
  const _NewsItem({required this.id, this.topic, this.source, required this.kind, required this.title, required this.url, this.publisher, this.excerpt, this.publishedAt, required this.seenAt, this.gn = false, this.sources = 1, final  List<NewsRelease>? releases, this.score, this.why, this.setup, this.summaryHu, this.textState, required this.originalUrl, this.read = false, this.saved = false, this.feedback}): _releases = releases;
  factory _NewsItem.fromJson(Map<String, dynamic> json) => _$NewsItemFromJson(json);

@override final  int id;
@override final  String? topic;
@override final  String? source;
/// `feed` | `release`.
@override final  String kind;
@override final  String title;
@override final  String url;
@override final  String? publisher;
@override final  String? excerpt;
@override final  DateTime? publishedAt;
@override final  DateTime seenAt;
@override@JsonKey() final  bool gn;
@override@JsonKey() final  int sources;
 final  List<NewsRelease>? _releases;
@override List<NewsRelease>? get releases {
  final value = _releases;
  if (value == null) return null;
  if (_releases is EqualUnmodifiableListView) return _releases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? score;
@override final  String? why;
@override final  bool? setup;
@override final  String? summaryHu;
@override final  String? textState;
@override final  String originalUrl;
@override@JsonKey() final  bool read;
@override@JsonKey() final  bool saved;
/// `more` | `less` | null.
@override final  String? feedback;

/// Create a copy of NewsItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsItemCopyWith<_NewsItem> get copyWith => __$NewsItemCopyWithImpl<_NewsItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsItem&&(identical(other.id, id) || other.id == id)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.source, source) || other.source == source)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.seenAt, seenAt) || other.seenAt == seenAt)&&(identical(other.gn, gn) || other.gn == gn)&&(identical(other.sources, sources) || other.sources == sources)&&const DeepCollectionEquality().equals(other._releases, _releases)&&(identical(other.score, score) || other.score == score)&&(identical(other.why, why) || other.why == why)&&(identical(other.setup, setup) || other.setup == setup)&&(identical(other.summaryHu, summaryHu) || other.summaryHu == summaryHu)&&(identical(other.textState, textState) || other.textState == textState)&&(identical(other.originalUrl, originalUrl) || other.originalUrl == originalUrl)&&(identical(other.read, read) || other.read == read)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.feedback, feedback) || other.feedback == feedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,topic,source,kind,title,url,publisher,excerpt,publishedAt,seenAt,gn,sources,const DeepCollectionEquality().hash(_releases),score,why,setup,summaryHu,textState,originalUrl,read,saved,feedback]);

@override
String toString() {
  return 'NewsItem(id: $id, topic: $topic, source: $source, kind: $kind, title: $title, url: $url, publisher: $publisher, excerpt: $excerpt, publishedAt: $publishedAt, seenAt: $seenAt, gn: $gn, sources: $sources, releases: $releases, score: $score, why: $why, setup: $setup, summaryHu: $summaryHu, textState: $textState, originalUrl: $originalUrl, read: $read, saved: $saved, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class _$NewsItemCopyWith<$Res> implements $NewsItemCopyWith<$Res> {
  factory _$NewsItemCopyWith(_NewsItem value, $Res Function(_NewsItem) _then) = __$NewsItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String? topic, String? source, String kind, String title, String url, String? publisher, String? excerpt, DateTime? publishedAt, DateTime seenAt, bool gn, int sources, List<NewsRelease>? releases, int? score, String? why, bool? setup, String? summaryHu, String? textState, String originalUrl, bool read, bool saved, String? feedback
});




}
/// @nodoc
class __$NewsItemCopyWithImpl<$Res>
    implements _$NewsItemCopyWith<$Res> {
  __$NewsItemCopyWithImpl(this._self, this._then);

  final _NewsItem _self;
  final $Res Function(_NewsItem) _then;

/// Create a copy of NewsItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? topic = freezed,Object? source = freezed,Object? kind = null,Object? title = null,Object? url = null,Object? publisher = freezed,Object? excerpt = freezed,Object? publishedAt = freezed,Object? seenAt = null,Object? gn = null,Object? sources = null,Object? releases = freezed,Object? score = freezed,Object? why = freezed,Object? setup = freezed,Object? summaryHu = freezed,Object? textState = freezed,Object? originalUrl = null,Object? read = null,Object? saved = null,Object? feedback = freezed,}) {
  return _then(_NewsItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,seenAt: null == seenAt ? _self.seenAt : seenAt // ignore: cast_nullable_to_non_nullable
as DateTime,gn: null == gn ? _self.gn : gn // ignore: cast_nullable_to_non_nullable
as bool,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as int,releases: freezed == releases ? _self._releases : releases // ignore: cast_nullable_to_non_nullable
as List<NewsRelease>?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,why: freezed == why ? _self.why : why // ignore: cast_nullable_to_non_nullable
as String?,setup: freezed == setup ? _self.setup : setup // ignore: cast_nullable_to_non_nullable
as bool?,summaryHu: freezed == summaryHu ? _self.summaryHu : summaryHu // ignore: cast_nullable_to_non_nullable
as String?,textState: freezed == textState ? _self.textState : textState // ignore: cast_nullable_to_non_nullable
as String?,originalUrl: null == originalUrl ? _self.originalUrl : originalUrl // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$NewsRelease {

 String get tag; String get url; DateTime? get publishedAt;
/// Create a copy of NewsRelease
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsReleaseCopyWith<NewsRelease> get copyWith => _$NewsReleaseCopyWithImpl<NewsRelease>(this as NewsRelease, _$identity);

  /// Serializes this NewsRelease to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsRelease&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.url, url) || other.url == url)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tag,url,publishedAt);

@override
String toString() {
  return 'NewsRelease(tag: $tag, url: $url, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class $NewsReleaseCopyWith<$Res>  {
  factory $NewsReleaseCopyWith(NewsRelease value, $Res Function(NewsRelease) _then) = _$NewsReleaseCopyWithImpl;
@useResult
$Res call({
 String tag, String url, DateTime? publishedAt
});




}
/// @nodoc
class _$NewsReleaseCopyWithImpl<$Res>
    implements $NewsReleaseCopyWith<$Res> {
  _$NewsReleaseCopyWithImpl(this._self, this._then);

  final NewsRelease _self;
  final $Res Function(NewsRelease) _then;

/// Create a copy of NewsRelease
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tag = null,Object? url = null,Object? publishedAt = freezed,}) {
  return _then(_self.copyWith(
tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsRelease].
extension NewsReleasePatterns on NewsRelease {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsRelease value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsRelease() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsRelease value)  $default,){
final _that = this;
switch (_that) {
case _NewsRelease():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsRelease value)?  $default,){
final _that = this;
switch (_that) {
case _NewsRelease() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tag,  String url,  DateTime? publishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsRelease() when $default != null:
return $default(_that.tag,_that.url,_that.publishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tag,  String url,  DateTime? publishedAt)  $default,) {final _that = this;
switch (_that) {
case _NewsRelease():
return $default(_that.tag,_that.url,_that.publishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tag,  String url,  DateTime? publishedAt)?  $default,) {final _that = this;
switch (_that) {
case _NewsRelease() when $default != null:
return $default(_that.tag,_that.url,_that.publishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsRelease implements NewsRelease {
  const _NewsRelease({required this.tag, required this.url, this.publishedAt});
  factory _NewsRelease.fromJson(Map<String, dynamic> json) => _$NewsReleaseFromJson(json);

@override final  String tag;
@override final  String url;
@override final  DateTime? publishedAt;

/// Create a copy of NewsRelease
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsReleaseCopyWith<_NewsRelease> get copyWith => __$NewsReleaseCopyWithImpl<_NewsRelease>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsReleaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsRelease&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.url, url) || other.url == url)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tag,url,publishedAt);

@override
String toString() {
  return 'NewsRelease(tag: $tag, url: $url, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$NewsReleaseCopyWith<$Res> implements $NewsReleaseCopyWith<$Res> {
  factory _$NewsReleaseCopyWith(_NewsRelease value, $Res Function(_NewsRelease) _then) = __$NewsReleaseCopyWithImpl;
@override @useResult
$Res call({
 String tag, String url, DateTime? publishedAt
});




}
/// @nodoc
class __$NewsReleaseCopyWithImpl<$Res>
    implements _$NewsReleaseCopyWith<$Res> {
  __$NewsReleaseCopyWithImpl(this._self, this._then);

  final _NewsRelease _self;
  final $Res Function(_NewsRelease) _then;

/// Create a copy of NewsRelease
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tag = null,Object? url = null,Object? publishedAt = freezed,}) {
  return _then(_NewsRelease(
tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$NewsOther {

 int get id; String? get publisher; String get title; String get url; DateTime? get publishedAt;
/// Create a copy of NewsOther
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsOtherCopyWith<NewsOther> get copyWith => _$NewsOtherCopyWithImpl<NewsOther>(this as NewsOther, _$identity);

  /// Serializes this NewsOther to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsOther&&(identical(other.id, id) || other.id == id)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,publisher,title,url,publishedAt);

@override
String toString() {
  return 'NewsOther(id: $id, publisher: $publisher, title: $title, url: $url, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class $NewsOtherCopyWith<$Res>  {
  factory $NewsOtherCopyWith(NewsOther value, $Res Function(NewsOther) _then) = _$NewsOtherCopyWithImpl;
@useResult
$Res call({
 int id, String? publisher, String title, String url, DateTime? publishedAt
});




}
/// @nodoc
class _$NewsOtherCopyWithImpl<$Res>
    implements $NewsOtherCopyWith<$Res> {
  _$NewsOtherCopyWithImpl(this._self, this._then);

  final NewsOther _self;
  final $Res Function(NewsOther) _then;

/// Create a copy of NewsOther
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? publisher = freezed,Object? title = null,Object? url = null,Object? publishedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsOther].
extension NewsOtherPatterns on NewsOther {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsOther value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsOther() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsOther value)  $default,){
final _that = this;
switch (_that) {
case _NewsOther():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsOther value)?  $default,){
final _that = this;
switch (_that) {
case _NewsOther() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? publisher,  String title,  String url,  DateTime? publishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsOther() when $default != null:
return $default(_that.id,_that.publisher,_that.title,_that.url,_that.publishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? publisher,  String title,  String url,  DateTime? publishedAt)  $default,) {final _that = this;
switch (_that) {
case _NewsOther():
return $default(_that.id,_that.publisher,_that.title,_that.url,_that.publishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? publisher,  String title,  String url,  DateTime? publishedAt)?  $default,) {final _that = this;
switch (_that) {
case _NewsOther() when $default != null:
return $default(_that.id,_that.publisher,_that.title,_that.url,_that.publishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsOther implements NewsOther {
  const _NewsOther({required this.id, this.publisher, required this.title, required this.url, this.publishedAt});
  factory _NewsOther.fromJson(Map<String, dynamic> json) => _$NewsOtherFromJson(json);

@override final  int id;
@override final  String? publisher;
@override final  String title;
@override final  String url;
@override final  DateTime? publishedAt;

/// Create a copy of NewsOther
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsOtherCopyWith<_NewsOther> get copyWith => __$NewsOtherCopyWithImpl<_NewsOther>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsOtherToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsOther&&(identical(other.id, id) || other.id == id)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,publisher,title,url,publishedAt);

@override
String toString() {
  return 'NewsOther(id: $id, publisher: $publisher, title: $title, url: $url, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$NewsOtherCopyWith<$Res> implements $NewsOtherCopyWith<$Res> {
  factory _$NewsOtherCopyWith(_NewsOther value, $Res Function(_NewsOther) _then) = __$NewsOtherCopyWithImpl;
@override @useResult
$Res call({
 int id, String? publisher, String title, String url, DateTime? publishedAt
});




}
/// @nodoc
class __$NewsOtherCopyWithImpl<$Res>
    implements _$NewsOtherCopyWith<$Res> {
  __$NewsOtherCopyWithImpl(this._self, this._then);

  final _NewsOther _self;
  final $Res Function(_NewsOther) _then;

/// Create a copy of NewsOther
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? publisher = freezed,Object? title = null,Object? url = null,Object? publishedAt = freezed,}) {
  return _then(_NewsOther(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$NewsSection {

 String get topic; String get name; int get count; int get week;@JsonKey(name: 'new') int get fresh; List<NewsItem> get top;
/// Create a copy of NewsSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsSectionCopyWith<NewsSection> get copyWith => _$NewsSectionCopyWithImpl<NewsSection>(this as NewsSection, _$identity);

  /// Serializes this NewsSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsSection&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.name, name) || other.name == name)&&(identical(other.count, count) || other.count == count)&&(identical(other.week, week) || other.week == week)&&(identical(other.fresh, fresh) || other.fresh == fresh)&&const DeepCollectionEquality().equals(other.top, top));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topic,name,count,week,fresh,const DeepCollectionEquality().hash(top));

@override
String toString() {
  return 'NewsSection(topic: $topic, name: $name, count: $count, week: $week, fresh: $fresh, top: $top)';
}


}

/// @nodoc
abstract mixin class $NewsSectionCopyWith<$Res>  {
  factory $NewsSectionCopyWith(NewsSection value, $Res Function(NewsSection) _then) = _$NewsSectionCopyWithImpl;
@useResult
$Res call({
 String topic, String name, int count, int week,@JsonKey(name: 'new') int fresh, List<NewsItem> top
});




}
/// @nodoc
class _$NewsSectionCopyWithImpl<$Res>
    implements $NewsSectionCopyWith<$Res> {
  _$NewsSectionCopyWithImpl(this._self, this._then);

  final NewsSection _self;
  final $Res Function(NewsSection) _then;

/// Create a copy of NewsSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topic = null,Object? name = null,Object? count = null,Object? week = null,Object? fresh = null,Object? top = null,}) {
  return _then(_self.copyWith(
topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,fresh: null == fresh ? _self.fresh : fresh // ignore: cast_nullable_to_non_nullable
as int,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as List<NewsItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsSection].
extension NewsSectionPatterns on NewsSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsSection value)  $default,){
final _that = this;
switch (_that) {
case _NewsSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsSection value)?  $default,){
final _that = this;
switch (_that) {
case _NewsSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String topic,  String name,  int count,  int week, @JsonKey(name: 'new')  int fresh,  List<NewsItem> top)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsSection() when $default != null:
return $default(_that.topic,_that.name,_that.count,_that.week,_that.fresh,_that.top);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String topic,  String name,  int count,  int week, @JsonKey(name: 'new')  int fresh,  List<NewsItem> top)  $default,) {final _that = this;
switch (_that) {
case _NewsSection():
return $default(_that.topic,_that.name,_that.count,_that.week,_that.fresh,_that.top);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String topic,  String name,  int count,  int week, @JsonKey(name: 'new')  int fresh,  List<NewsItem> top)?  $default,) {final _that = this;
switch (_that) {
case _NewsSection() when $default != null:
return $default(_that.topic,_that.name,_that.count,_that.week,_that.fresh,_that.top);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsSection implements NewsSection {
  const _NewsSection({required this.topic, required this.name, this.count = 0, this.week = 0, @JsonKey(name: 'new') this.fresh = 0, final  List<NewsItem> top = const <NewsItem>[]}): _top = top;
  factory _NewsSection.fromJson(Map<String, dynamic> json) => _$NewsSectionFromJson(json);

@override final  String topic;
@override final  String name;
@override@JsonKey() final  int count;
@override@JsonKey() final  int week;
@override@JsonKey(name: 'new') final  int fresh;
 final  List<NewsItem> _top;
@override@JsonKey() List<NewsItem> get top {
  if (_top is EqualUnmodifiableListView) return _top;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_top);
}


/// Create a copy of NewsSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsSectionCopyWith<_NewsSection> get copyWith => __$NewsSectionCopyWithImpl<_NewsSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsSectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsSection&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.name, name) || other.name == name)&&(identical(other.count, count) || other.count == count)&&(identical(other.week, week) || other.week == week)&&(identical(other.fresh, fresh) || other.fresh == fresh)&&const DeepCollectionEquality().equals(other._top, _top));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topic,name,count,week,fresh,const DeepCollectionEquality().hash(_top));

@override
String toString() {
  return 'NewsSection(topic: $topic, name: $name, count: $count, week: $week, fresh: $fresh, top: $top)';
}


}

/// @nodoc
abstract mixin class _$NewsSectionCopyWith<$Res> implements $NewsSectionCopyWith<$Res> {
  factory _$NewsSectionCopyWith(_NewsSection value, $Res Function(_NewsSection) _then) = __$NewsSectionCopyWithImpl;
@override @useResult
$Res call({
 String topic, String name, int count, int week,@JsonKey(name: 'new') int fresh, List<NewsItem> top
});




}
/// @nodoc
class __$NewsSectionCopyWithImpl<$Res>
    implements _$NewsSectionCopyWith<$Res> {
  __$NewsSectionCopyWithImpl(this._self, this._then);

  final _NewsSection _self;
  final $Res Function(_NewsSection) _then;

/// Create a copy of NewsSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topic = null,Object? name = null,Object? count = null,Object? week = null,Object? fresh = null,Object? top = null,}) {
  return _then(_NewsSection(
topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,fresh: null == fresh ? _self.fresh : fresh // ignore: cast_nullable_to_non_nullable
as int,top: null == top ? _self._top : top // ignore: cast_nullable_to_non_nullable
as List<NewsItem>,
  ));
}


}


/// @nodoc
mixin _$NewsDigest {

 List<NewsItem> get top;@JsonKey(name: 'new') int get fresh; DateTime? get updatedAt;/// `empty` | `ok`.
 String get state; int get sources; int get failing;/// On Mondays from the digest time on: how many of last week's best
/// were not opened.
 NewsWeekly? get weekly;
/// Create a copy of NewsDigest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsDigestCopyWith<NewsDigest> get copyWith => _$NewsDigestCopyWithImpl<NewsDigest>(this as NewsDigest, _$identity);

  /// Serializes this NewsDigest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsDigest&&const DeepCollectionEquality().equals(other.top, top)&&(identical(other.fresh, fresh) || other.fresh == fresh)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.state, state) || other.state == state)&&(identical(other.sources, sources) || other.sources == sources)&&(identical(other.failing, failing) || other.failing == failing)&&(identical(other.weekly, weekly) || other.weekly == weekly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(top),fresh,updatedAt,state,sources,failing,weekly);

@override
String toString() {
  return 'NewsDigest(top: $top, fresh: $fresh, updatedAt: $updatedAt, state: $state, sources: $sources, failing: $failing, weekly: $weekly)';
}


}

/// @nodoc
abstract mixin class $NewsDigestCopyWith<$Res>  {
  factory $NewsDigestCopyWith(NewsDigest value, $Res Function(NewsDigest) _then) = _$NewsDigestCopyWithImpl;
@useResult
$Res call({
 List<NewsItem> top,@JsonKey(name: 'new') int fresh, DateTime? updatedAt, String state, int sources, int failing, NewsWeekly? weekly
});


$NewsWeeklyCopyWith<$Res>? get weekly;

}
/// @nodoc
class _$NewsDigestCopyWithImpl<$Res>
    implements $NewsDigestCopyWith<$Res> {
  _$NewsDigestCopyWithImpl(this._self, this._then);

  final NewsDigest _self;
  final $Res Function(NewsDigest) _then;

/// Create a copy of NewsDigest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? top = null,Object? fresh = null,Object? updatedAt = freezed,Object? state = null,Object? sources = null,Object? failing = null,Object? weekly = freezed,}) {
  return _then(_self.copyWith(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as List<NewsItem>,fresh: null == fresh ? _self.fresh : fresh // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as int,failing: null == failing ? _self.failing : failing // ignore: cast_nullable_to_non_nullable
as int,weekly: freezed == weekly ? _self.weekly : weekly // ignore: cast_nullable_to_non_nullable
as NewsWeekly?,
  ));
}
/// Create a copy of NewsDigest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NewsWeeklyCopyWith<$Res>? get weekly {
    if (_self.weekly == null) {
    return null;
  }

  return $NewsWeeklyCopyWith<$Res>(_self.weekly!, (value) {
    return _then(_self.copyWith(weekly: value));
  });
}
}


/// Adds pattern-matching-related methods to [NewsDigest].
extension NewsDigestPatterns on NewsDigest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsDigest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsDigest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsDigest value)  $default,){
final _that = this;
switch (_that) {
case _NewsDigest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsDigest value)?  $default,){
final _that = this;
switch (_that) {
case _NewsDigest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NewsItem> top, @JsonKey(name: 'new')  int fresh,  DateTime? updatedAt,  String state,  int sources,  int failing,  NewsWeekly? weekly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsDigest() when $default != null:
return $default(_that.top,_that.fresh,_that.updatedAt,_that.state,_that.sources,_that.failing,_that.weekly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NewsItem> top, @JsonKey(name: 'new')  int fresh,  DateTime? updatedAt,  String state,  int sources,  int failing,  NewsWeekly? weekly)  $default,) {final _that = this;
switch (_that) {
case _NewsDigest():
return $default(_that.top,_that.fresh,_that.updatedAt,_that.state,_that.sources,_that.failing,_that.weekly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NewsItem> top, @JsonKey(name: 'new')  int fresh,  DateTime? updatedAt,  String state,  int sources,  int failing,  NewsWeekly? weekly)?  $default,) {final _that = this;
switch (_that) {
case _NewsDigest() when $default != null:
return $default(_that.top,_that.fresh,_that.updatedAt,_that.state,_that.sources,_that.failing,_that.weekly);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsDigest implements NewsDigest {
  const _NewsDigest({final  List<NewsItem> top = const <NewsItem>[], @JsonKey(name: 'new') this.fresh = 0, this.updatedAt, required this.state, this.sources = 0, this.failing = 0, this.weekly}): _top = top;
  factory _NewsDigest.fromJson(Map<String, dynamic> json) => _$NewsDigestFromJson(json);

 final  List<NewsItem> _top;
@override@JsonKey() List<NewsItem> get top {
  if (_top is EqualUnmodifiableListView) return _top;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_top);
}

@override@JsonKey(name: 'new') final  int fresh;
@override final  DateTime? updatedAt;
/// `empty` | `ok`.
@override final  String state;
@override@JsonKey() final  int sources;
@override@JsonKey() final  int failing;
/// On Mondays from the digest time on: how many of last week's best
/// were not opened.
@override final  NewsWeekly? weekly;

/// Create a copy of NewsDigest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsDigestCopyWith<_NewsDigest> get copyWith => __$NewsDigestCopyWithImpl<_NewsDigest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsDigestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsDigest&&const DeepCollectionEquality().equals(other._top, _top)&&(identical(other.fresh, fresh) || other.fresh == fresh)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.state, state) || other.state == state)&&(identical(other.sources, sources) || other.sources == sources)&&(identical(other.failing, failing) || other.failing == failing)&&(identical(other.weekly, weekly) || other.weekly == weekly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_top),fresh,updatedAt,state,sources,failing,weekly);

@override
String toString() {
  return 'NewsDigest(top: $top, fresh: $fresh, updatedAt: $updatedAt, state: $state, sources: $sources, failing: $failing, weekly: $weekly)';
}


}

/// @nodoc
abstract mixin class _$NewsDigestCopyWith<$Res> implements $NewsDigestCopyWith<$Res> {
  factory _$NewsDigestCopyWith(_NewsDigest value, $Res Function(_NewsDigest) _then) = __$NewsDigestCopyWithImpl;
@override @useResult
$Res call({
 List<NewsItem> top,@JsonKey(name: 'new') int fresh, DateTime? updatedAt, String state, int sources, int failing, NewsWeekly? weekly
});


@override $NewsWeeklyCopyWith<$Res>? get weekly;

}
/// @nodoc
class __$NewsDigestCopyWithImpl<$Res>
    implements _$NewsDigestCopyWith<$Res> {
  __$NewsDigestCopyWithImpl(this._self, this._then);

  final _NewsDigest _self;
  final $Res Function(_NewsDigest) _then;

/// Create a copy of NewsDigest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? top = null,Object? fresh = null,Object? updatedAt = freezed,Object? state = null,Object? sources = null,Object? failing = null,Object? weekly = freezed,}) {
  return _then(_NewsDigest(
top: null == top ? _self._top : top // ignore: cast_nullable_to_non_nullable
as List<NewsItem>,fresh: null == fresh ? _self.fresh : fresh // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as int,failing: null == failing ? _self.failing : failing // ignore: cast_nullable_to_non_nullable
as int,weekly: freezed == weekly ? _self.weekly : weekly // ignore: cast_nullable_to_non_nullable
as NewsWeekly?,
  ));
}

/// Create a copy of NewsDigest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NewsWeeklyCopyWith<$Res>? get weekly {
    if (_self.weekly == null) {
    return null;
  }

  return $NewsWeeklyCopyWith<$Res>(_self.weekly!, (value) {
    return _then(_self.copyWith(weekly: value));
  });
}
}


/// @nodoc
mixin _$NewsWeekly {

 int get count;
/// Create a copy of NewsWeekly
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsWeeklyCopyWith<NewsWeekly> get copyWith => _$NewsWeeklyCopyWithImpl<NewsWeekly>(this as NewsWeekly, _$identity);

  /// Serializes this NewsWeekly to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsWeekly&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count);

@override
String toString() {
  return 'NewsWeekly(count: $count)';
}


}

/// @nodoc
abstract mixin class $NewsWeeklyCopyWith<$Res>  {
  factory $NewsWeeklyCopyWith(NewsWeekly value, $Res Function(NewsWeekly) _then) = _$NewsWeeklyCopyWithImpl;
@useResult
$Res call({
 int count
});




}
/// @nodoc
class _$NewsWeeklyCopyWithImpl<$Res>
    implements $NewsWeeklyCopyWith<$Res> {
  _$NewsWeeklyCopyWithImpl(this._self, this._then);

  final NewsWeekly _self;
  final $Res Function(NewsWeekly) _then;

/// Create a copy of NewsWeekly
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsWeekly].
extension NewsWeeklyPatterns on NewsWeekly {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsWeekly value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsWeekly() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsWeekly value)  $default,){
final _that = this;
switch (_that) {
case _NewsWeekly():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsWeekly value)?  $default,){
final _that = this;
switch (_that) {
case _NewsWeekly() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsWeekly() when $default != null:
return $default(_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count)  $default,) {final _that = this;
switch (_that) {
case _NewsWeekly():
return $default(_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count)?  $default,) {final _that = this;
switch (_that) {
case _NewsWeekly() when $default != null:
return $default(_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsWeekly implements NewsWeekly {
  const _NewsWeekly({required this.count});
  factory _NewsWeekly.fromJson(Map<String, dynamic> json) => _$NewsWeeklyFromJson(json);

@override final  int count;

/// Create a copy of NewsWeekly
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsWeeklyCopyWith<_NewsWeekly> get copyWith => __$NewsWeeklyCopyWithImpl<_NewsWeekly>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsWeeklyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsWeekly&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count);

@override
String toString() {
  return 'NewsWeekly(count: $count)';
}


}

/// @nodoc
abstract mixin class _$NewsWeeklyCopyWith<$Res> implements $NewsWeeklyCopyWith<$Res> {
  factory _$NewsWeeklyCopyWith(_NewsWeekly value, $Res Function(_NewsWeekly) _then) = __$NewsWeeklyCopyWithImpl;
@override @useResult
$Res call({
 int count
});




}
/// @nodoc
class __$NewsWeeklyCopyWithImpl<$Res>
    implements _$NewsWeeklyCopyWith<$Res> {
  __$NewsWeeklyCopyWithImpl(this._self, this._then);

  final _NewsWeekly _self;
  final $Res Function(_NewsWeekly) _then;

/// Create a copy of NewsWeekly
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,}) {
  return _then(_NewsWeekly(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NewsTopic {

 String get id; String get name; String get description; int get position; bool get enabled; int get sources;@JsonKey(name: 'items_24h') int get items24h;
/// Create a copy of NewsTopic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsTopicCopyWith<NewsTopic> get copyWith => _$NewsTopicCopyWithImpl<NewsTopic>(this as NewsTopic, _$identity);

  /// Serializes this NewsTopic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.position, position) || other.position == position)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.sources, sources) || other.sources == sources)&&(identical(other.items24h, items24h) || other.items24h == items24h));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,position,enabled,sources,items24h);

@override
String toString() {
  return 'NewsTopic(id: $id, name: $name, description: $description, position: $position, enabled: $enabled, sources: $sources, items24h: $items24h)';
}


}

/// @nodoc
abstract mixin class $NewsTopicCopyWith<$Res>  {
  factory $NewsTopicCopyWith(NewsTopic value, $Res Function(NewsTopic) _then) = _$NewsTopicCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, int position, bool enabled, int sources,@JsonKey(name: 'items_24h') int items24h
});




}
/// @nodoc
class _$NewsTopicCopyWithImpl<$Res>
    implements $NewsTopicCopyWith<$Res> {
  _$NewsTopicCopyWithImpl(this._self, this._then);

  final NewsTopic _self;
  final $Res Function(NewsTopic) _then;

/// Create a copy of NewsTopic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? position = null,Object? enabled = null,Object? sources = null,Object? items24h = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as int,items24h: null == items24h ? _self.items24h : items24h // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsTopic].
extension NewsTopicPatterns on NewsTopic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsTopic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsTopic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsTopic value)  $default,){
final _that = this;
switch (_that) {
case _NewsTopic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsTopic value)?  $default,){
final _that = this;
switch (_that) {
case _NewsTopic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int position,  bool enabled,  int sources, @JsonKey(name: 'items_24h')  int items24h)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsTopic() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.position,_that.enabled,_that.sources,_that.items24h);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int position,  bool enabled,  int sources, @JsonKey(name: 'items_24h')  int items24h)  $default,) {final _that = this;
switch (_that) {
case _NewsTopic():
return $default(_that.id,_that.name,_that.description,_that.position,_that.enabled,_that.sources,_that.items24h);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  int position,  bool enabled,  int sources, @JsonKey(name: 'items_24h')  int items24h)?  $default,) {final _that = this;
switch (_that) {
case _NewsTopic() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.position,_that.enabled,_that.sources,_that.items24h);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsTopic implements NewsTopic {
  const _NewsTopic({required this.id, required this.name, this.description = '', this.position = 0, this.enabled = true, this.sources = 0, @JsonKey(name: 'items_24h') this.items24h = 0});
  factory _NewsTopic.fromJson(Map<String, dynamic> json) => _$NewsTopicFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  int position;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  int sources;
@override@JsonKey(name: 'items_24h') final  int items24h;

/// Create a copy of NewsTopic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsTopicCopyWith<_NewsTopic> get copyWith => __$NewsTopicCopyWithImpl<_NewsTopic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsTopicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.position, position) || other.position == position)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.sources, sources) || other.sources == sources)&&(identical(other.items24h, items24h) || other.items24h == items24h));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,position,enabled,sources,items24h);

@override
String toString() {
  return 'NewsTopic(id: $id, name: $name, description: $description, position: $position, enabled: $enabled, sources: $sources, items24h: $items24h)';
}


}

/// @nodoc
abstract mixin class _$NewsTopicCopyWith<$Res> implements $NewsTopicCopyWith<$Res> {
  factory _$NewsTopicCopyWith(_NewsTopic value, $Res Function(_NewsTopic) _then) = __$NewsTopicCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, int position, bool enabled, int sources,@JsonKey(name: 'items_24h') int items24h
});




}
/// @nodoc
class __$NewsTopicCopyWithImpl<$Res>
    implements _$NewsTopicCopyWith<$Res> {
  __$NewsTopicCopyWithImpl(this._self, this._then);

  final _NewsTopic _self;
  final $Res Function(_NewsTopic) _then;

/// Create a copy of NewsTopic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? position = null,Object? enabled = null,Object? sources = null,Object? items24h = null,}) {
  return _then(_NewsTopic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as int,items24h: null == items24h ? _self.items24h : items24h // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NewsSource {

 String get id; String? get topic; String get url;/// `feed` | `release`.
 String get kind; int get windowH; int get everyMin; bool get enabled;/// `import` | `app` | `agent`.
 String get origin; DateTime? get lastAt; DateTime? get lastOkAt;/// `ok` | `not_modified` | `skipped` | `error` | null.
 String? get lastStatus; int? get lastHttp; String? get lastErrorCode; String? get lastError; int? get lastItems; int? get lastNew; int get errorsInRow;
/// Create a copy of NewsSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsSourceCopyWith<NewsSource> get copyWith => _$NewsSourceCopyWithImpl<NewsSource>(this as NewsSource, _$identity);

  /// Serializes this NewsSource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsSource&&(identical(other.id, id) || other.id == id)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.url, url) || other.url == url)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.windowH, windowH) || other.windowH == windowH)&&(identical(other.everyMin, everyMin) || other.everyMin == everyMin)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.lastAt, lastAt) || other.lastAt == lastAt)&&(identical(other.lastOkAt, lastOkAt) || other.lastOkAt == lastOkAt)&&(identical(other.lastStatus, lastStatus) || other.lastStatus == lastStatus)&&(identical(other.lastHttp, lastHttp) || other.lastHttp == lastHttp)&&(identical(other.lastErrorCode, lastErrorCode) || other.lastErrorCode == lastErrorCode)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastItems, lastItems) || other.lastItems == lastItems)&&(identical(other.lastNew, lastNew) || other.lastNew == lastNew)&&(identical(other.errorsInRow, errorsInRow) || other.errorsInRow == errorsInRow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,topic,url,kind,windowH,everyMin,enabled,origin,lastAt,lastOkAt,lastStatus,lastHttp,lastErrorCode,lastError,lastItems,lastNew,errorsInRow);

@override
String toString() {
  return 'NewsSource(id: $id, topic: $topic, url: $url, kind: $kind, windowH: $windowH, everyMin: $everyMin, enabled: $enabled, origin: $origin, lastAt: $lastAt, lastOkAt: $lastOkAt, lastStatus: $lastStatus, lastHttp: $lastHttp, lastErrorCode: $lastErrorCode, lastError: $lastError, lastItems: $lastItems, lastNew: $lastNew, errorsInRow: $errorsInRow)';
}


}

/// @nodoc
abstract mixin class $NewsSourceCopyWith<$Res>  {
  factory $NewsSourceCopyWith(NewsSource value, $Res Function(NewsSource) _then) = _$NewsSourceCopyWithImpl;
@useResult
$Res call({
 String id, String? topic, String url, String kind, int windowH, int everyMin, bool enabled, String origin, DateTime? lastAt, DateTime? lastOkAt, String? lastStatus, int? lastHttp, String? lastErrorCode, String? lastError, int? lastItems, int? lastNew, int errorsInRow
});




}
/// @nodoc
class _$NewsSourceCopyWithImpl<$Res>
    implements $NewsSourceCopyWith<$Res> {
  _$NewsSourceCopyWithImpl(this._self, this._then);

  final NewsSource _self;
  final $Res Function(NewsSource) _then;

/// Create a copy of NewsSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? topic = freezed,Object? url = null,Object? kind = null,Object? windowH = null,Object? everyMin = null,Object? enabled = null,Object? origin = null,Object? lastAt = freezed,Object? lastOkAt = freezed,Object? lastStatus = freezed,Object? lastHttp = freezed,Object? lastErrorCode = freezed,Object? lastError = freezed,Object? lastItems = freezed,Object? lastNew = freezed,Object? errorsInRow = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,windowH: null == windowH ? _self.windowH : windowH // ignore: cast_nullable_to_non_nullable
as int,everyMin: null == everyMin ? _self.everyMin : everyMin // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,lastAt: freezed == lastAt ? _self.lastAt : lastAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastOkAt: freezed == lastOkAt ? _self.lastOkAt : lastOkAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastStatus: freezed == lastStatus ? _self.lastStatus : lastStatus // ignore: cast_nullable_to_non_nullable
as String?,lastHttp: freezed == lastHttp ? _self.lastHttp : lastHttp // ignore: cast_nullable_to_non_nullable
as int?,lastErrorCode: freezed == lastErrorCode ? _self.lastErrorCode : lastErrorCode // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastItems: freezed == lastItems ? _self.lastItems : lastItems // ignore: cast_nullable_to_non_nullable
as int?,lastNew: freezed == lastNew ? _self.lastNew : lastNew // ignore: cast_nullable_to_non_nullable
as int?,errorsInRow: null == errorsInRow ? _self.errorsInRow : errorsInRow // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsSource].
extension NewsSourcePatterns on NewsSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsSource value)  $default,){
final _that = this;
switch (_that) {
case _NewsSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsSource value)?  $default,){
final _that = this;
switch (_that) {
case _NewsSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? topic,  String url,  String kind,  int windowH,  int everyMin,  bool enabled,  String origin,  DateTime? lastAt,  DateTime? lastOkAt,  String? lastStatus,  int? lastHttp,  String? lastErrorCode,  String? lastError,  int? lastItems,  int? lastNew,  int errorsInRow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsSource() when $default != null:
return $default(_that.id,_that.topic,_that.url,_that.kind,_that.windowH,_that.everyMin,_that.enabled,_that.origin,_that.lastAt,_that.lastOkAt,_that.lastStatus,_that.lastHttp,_that.lastErrorCode,_that.lastError,_that.lastItems,_that.lastNew,_that.errorsInRow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? topic,  String url,  String kind,  int windowH,  int everyMin,  bool enabled,  String origin,  DateTime? lastAt,  DateTime? lastOkAt,  String? lastStatus,  int? lastHttp,  String? lastErrorCode,  String? lastError,  int? lastItems,  int? lastNew,  int errorsInRow)  $default,) {final _that = this;
switch (_that) {
case _NewsSource():
return $default(_that.id,_that.topic,_that.url,_that.kind,_that.windowH,_that.everyMin,_that.enabled,_that.origin,_that.lastAt,_that.lastOkAt,_that.lastStatus,_that.lastHttp,_that.lastErrorCode,_that.lastError,_that.lastItems,_that.lastNew,_that.errorsInRow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? topic,  String url,  String kind,  int windowH,  int everyMin,  bool enabled,  String origin,  DateTime? lastAt,  DateTime? lastOkAt,  String? lastStatus,  int? lastHttp,  String? lastErrorCode,  String? lastError,  int? lastItems,  int? lastNew,  int errorsInRow)?  $default,) {final _that = this;
switch (_that) {
case _NewsSource() when $default != null:
return $default(_that.id,_that.topic,_that.url,_that.kind,_that.windowH,_that.everyMin,_that.enabled,_that.origin,_that.lastAt,_that.lastOkAt,_that.lastStatus,_that.lastHttp,_that.lastErrorCode,_that.lastError,_that.lastItems,_that.lastNew,_that.errorsInRow);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsSource implements NewsSource {
  const _NewsSource({required this.id, this.topic, required this.url, required this.kind, this.windowH = 48, this.everyMin = 60, this.enabled = true, this.origin = 'import', this.lastAt, this.lastOkAt, this.lastStatus, this.lastHttp, this.lastErrorCode, this.lastError, this.lastItems, this.lastNew, this.errorsInRow = 0});
  factory _NewsSource.fromJson(Map<String, dynamic> json) => _$NewsSourceFromJson(json);

@override final  String id;
@override final  String? topic;
@override final  String url;
/// `feed` | `release`.
@override final  String kind;
@override@JsonKey() final  int windowH;
@override@JsonKey() final  int everyMin;
@override@JsonKey() final  bool enabled;
/// `import` | `app` | `agent`.
@override@JsonKey() final  String origin;
@override final  DateTime? lastAt;
@override final  DateTime? lastOkAt;
/// `ok` | `not_modified` | `skipped` | `error` | null.
@override final  String? lastStatus;
@override final  int? lastHttp;
@override final  String? lastErrorCode;
@override final  String? lastError;
@override final  int? lastItems;
@override final  int? lastNew;
@override@JsonKey() final  int errorsInRow;

/// Create a copy of NewsSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsSourceCopyWith<_NewsSource> get copyWith => __$NewsSourceCopyWithImpl<_NewsSource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsSourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsSource&&(identical(other.id, id) || other.id == id)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.url, url) || other.url == url)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.windowH, windowH) || other.windowH == windowH)&&(identical(other.everyMin, everyMin) || other.everyMin == everyMin)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.lastAt, lastAt) || other.lastAt == lastAt)&&(identical(other.lastOkAt, lastOkAt) || other.lastOkAt == lastOkAt)&&(identical(other.lastStatus, lastStatus) || other.lastStatus == lastStatus)&&(identical(other.lastHttp, lastHttp) || other.lastHttp == lastHttp)&&(identical(other.lastErrorCode, lastErrorCode) || other.lastErrorCode == lastErrorCode)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastItems, lastItems) || other.lastItems == lastItems)&&(identical(other.lastNew, lastNew) || other.lastNew == lastNew)&&(identical(other.errorsInRow, errorsInRow) || other.errorsInRow == errorsInRow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,topic,url,kind,windowH,everyMin,enabled,origin,lastAt,lastOkAt,lastStatus,lastHttp,lastErrorCode,lastError,lastItems,lastNew,errorsInRow);

@override
String toString() {
  return 'NewsSource(id: $id, topic: $topic, url: $url, kind: $kind, windowH: $windowH, everyMin: $everyMin, enabled: $enabled, origin: $origin, lastAt: $lastAt, lastOkAt: $lastOkAt, lastStatus: $lastStatus, lastHttp: $lastHttp, lastErrorCode: $lastErrorCode, lastError: $lastError, lastItems: $lastItems, lastNew: $lastNew, errorsInRow: $errorsInRow)';
}


}

/// @nodoc
abstract mixin class _$NewsSourceCopyWith<$Res> implements $NewsSourceCopyWith<$Res> {
  factory _$NewsSourceCopyWith(_NewsSource value, $Res Function(_NewsSource) _then) = __$NewsSourceCopyWithImpl;
@override @useResult
$Res call({
 String id, String? topic, String url, String kind, int windowH, int everyMin, bool enabled, String origin, DateTime? lastAt, DateTime? lastOkAt, String? lastStatus, int? lastHttp, String? lastErrorCode, String? lastError, int? lastItems, int? lastNew, int errorsInRow
});




}
/// @nodoc
class __$NewsSourceCopyWithImpl<$Res>
    implements _$NewsSourceCopyWith<$Res> {
  __$NewsSourceCopyWithImpl(this._self, this._then);

  final _NewsSource _self;
  final $Res Function(_NewsSource) _then;

/// Create a copy of NewsSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? topic = freezed,Object? url = null,Object? kind = null,Object? windowH = null,Object? everyMin = null,Object? enabled = null,Object? origin = null,Object? lastAt = freezed,Object? lastOkAt = freezed,Object? lastStatus = freezed,Object? lastHttp = freezed,Object? lastErrorCode = freezed,Object? lastError = freezed,Object? lastItems = freezed,Object? lastNew = freezed,Object? errorsInRow = null,}) {
  return _then(_NewsSource(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,windowH: null == windowH ? _self.windowH : windowH // ignore: cast_nullable_to_non_nullable
as int,everyMin: null == everyMin ? _self.everyMin : everyMin // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,lastAt: freezed == lastAt ? _self.lastAt : lastAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastOkAt: freezed == lastOkAt ? _self.lastOkAt : lastOkAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastStatus: freezed == lastStatus ? _self.lastStatus : lastStatus // ignore: cast_nullable_to_non_nullable
as String?,lastHttp: freezed == lastHttp ? _self.lastHttp : lastHttp // ignore: cast_nullable_to_non_nullable
as int?,lastErrorCode: freezed == lastErrorCode ? _self.lastErrorCode : lastErrorCode // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastItems: freezed == lastItems ? _self.lastItems : lastItems // ignore: cast_nullable_to_non_nullable
as int?,lastNew: freezed == lastNew ? _self.lastNew : lastNew // ignore: cast_nullable_to_non_nullable
as int?,errorsInRow: null == errorsInRow ? _self.errorsInRow : errorsInRow // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NewsSettings {

 String get setup; String get digestAt; bool get push; int get pushMax;
/// Create a copy of NewsSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsSettingsCopyWith<NewsSettings> get copyWith => _$NewsSettingsCopyWithImpl<NewsSettings>(this as NewsSettings, _$identity);

  /// Serializes this NewsSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsSettings&&(identical(other.setup, setup) || other.setup == setup)&&(identical(other.digestAt, digestAt) || other.digestAt == digestAt)&&(identical(other.push, push) || other.push == push)&&(identical(other.pushMax, pushMax) || other.pushMax == pushMax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setup,digestAt,push,pushMax);

@override
String toString() {
  return 'NewsSettings(setup: $setup, digestAt: $digestAt, push: $push, pushMax: $pushMax)';
}


}

/// @nodoc
abstract mixin class $NewsSettingsCopyWith<$Res>  {
  factory $NewsSettingsCopyWith(NewsSettings value, $Res Function(NewsSettings) _then) = _$NewsSettingsCopyWithImpl;
@useResult
$Res call({
 String setup, String digestAt, bool push, int pushMax
});




}
/// @nodoc
class _$NewsSettingsCopyWithImpl<$Res>
    implements $NewsSettingsCopyWith<$Res> {
  _$NewsSettingsCopyWithImpl(this._self, this._then);

  final NewsSettings _self;
  final $Res Function(NewsSettings) _then;

/// Create a copy of NewsSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? setup = null,Object? digestAt = null,Object? push = null,Object? pushMax = null,}) {
  return _then(_self.copyWith(
setup: null == setup ? _self.setup : setup // ignore: cast_nullable_to_non_nullable
as String,digestAt: null == digestAt ? _self.digestAt : digestAt // ignore: cast_nullable_to_non_nullable
as String,push: null == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as bool,pushMax: null == pushMax ? _self.pushMax : pushMax // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsSettings].
extension NewsSettingsPatterns on NewsSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsSettings value)  $default,){
final _that = this;
switch (_that) {
case _NewsSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsSettings value)?  $default,){
final _that = this;
switch (_that) {
case _NewsSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String setup,  String digestAt,  bool push,  int pushMax)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsSettings() when $default != null:
return $default(_that.setup,_that.digestAt,_that.push,_that.pushMax);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String setup,  String digestAt,  bool push,  int pushMax)  $default,) {final _that = this;
switch (_that) {
case _NewsSettings():
return $default(_that.setup,_that.digestAt,_that.push,_that.pushMax);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String setup,  String digestAt,  bool push,  int pushMax)?  $default,) {final _that = this;
switch (_that) {
case _NewsSettings() when $default != null:
return $default(_that.setup,_that.digestAt,_that.push,_that.pushMax);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsSettings implements NewsSettings {
  const _NewsSettings({this.setup = '', this.digestAt = '07:00', this.push = true, this.pushMax = 2});
  factory _NewsSettings.fromJson(Map<String, dynamic> json) => _$NewsSettingsFromJson(json);

@override@JsonKey() final  String setup;
@override@JsonKey() final  String digestAt;
@override@JsonKey() final  bool push;
@override@JsonKey() final  int pushMax;

/// Create a copy of NewsSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsSettingsCopyWith<_NewsSettings> get copyWith => __$NewsSettingsCopyWithImpl<_NewsSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsSettings&&(identical(other.setup, setup) || other.setup == setup)&&(identical(other.digestAt, digestAt) || other.digestAt == digestAt)&&(identical(other.push, push) || other.push == push)&&(identical(other.pushMax, pushMax) || other.pushMax == pushMax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setup,digestAt,push,pushMax);

@override
String toString() {
  return 'NewsSettings(setup: $setup, digestAt: $digestAt, push: $push, pushMax: $pushMax)';
}


}

/// @nodoc
abstract mixin class _$NewsSettingsCopyWith<$Res> implements $NewsSettingsCopyWith<$Res> {
  factory _$NewsSettingsCopyWith(_NewsSettings value, $Res Function(_NewsSettings) _then) = __$NewsSettingsCopyWithImpl;
@override @useResult
$Res call({
 String setup, String digestAt, bool push, int pushMax
});




}
/// @nodoc
class __$NewsSettingsCopyWithImpl<$Res>
    implements _$NewsSettingsCopyWith<$Res> {
  __$NewsSettingsCopyWithImpl(this._self, this._then);

  final _NewsSettings _self;
  final $Res Function(_NewsSettings) _then;

/// Create a copy of NewsSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? setup = null,Object? digestAt = null,Object? push = null,Object? pushMax = null,}) {
  return _then(_NewsSettings(
setup: null == setup ? _self.setup : setup // ignore: cast_nullable_to_non_nullable
as String,digestAt: null == digestAt ? _self.digestAt : digestAt // ignore: cast_nullable_to_non_nullable
as String,push: null == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as bool,pushMax: null == pushMax ? _self.pushMax : pushMax // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
