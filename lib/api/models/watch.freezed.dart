// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Watch {

 String get slug; String get name;/// `hardverapro` | `cinemacity` | `page`.
 String get source; String get url;/// The condition the judge reads, as the user means it; null = filters
/// only.
 String? get criteria; List<String> get include; List<String> get any; List<String> get exclude; int? get minPrice; int? get maxPrice; bool get fetchDetails; bool get stopAfterHit;/// A 5-field cron (`15 8,13,19 * * *`) or `every 480m`.
 String get schedule;/// `active` | `paused` | `unknown` (no cron job yet) | `deleted`.
 String get state; String? get jobId; DateTime? get nextRunAt; DateTime? get lastCheckAt;/// `ok` | `error`.
 String? get lastStatus; String? get lastErrorCode; String? get lastError; int? get lastItems; int? get lastMatched; int get errorsInRow; int get hits;@JsonKey(name: 'hits_24h') int get hits24h; int get pending; int get rejected; DateTime? get lastHitAt;/// Paused itself after its first hit (`stop_after_hit`).
 DateTime? get stoppedAt; DateTime get definedAt; DateTime get updatedAt;
/// Create a copy of Watch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchCopyWith<Watch> get copyWith => _$WatchCopyWithImpl<Watch>(this as Watch, _$identity);

  /// Serializes this Watch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Watch&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.source, source) || other.source == source)&&(identical(other.url, url) || other.url == url)&&(identical(other.criteria, criteria) || other.criteria == criteria)&&const DeepCollectionEquality().equals(other.include, include)&&const DeepCollectionEquality().equals(other.any, any)&&const DeepCollectionEquality().equals(other.exclude, exclude)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.fetchDetails, fetchDetails) || other.fetchDetails == fetchDetails)&&(identical(other.stopAfterHit, stopAfterHit) || other.stopAfterHit == stopAfterHit)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.state, state) || other.state == state)&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.nextRunAt, nextRunAt) || other.nextRunAt == nextRunAt)&&(identical(other.lastCheckAt, lastCheckAt) || other.lastCheckAt == lastCheckAt)&&(identical(other.lastStatus, lastStatus) || other.lastStatus == lastStatus)&&(identical(other.lastErrorCode, lastErrorCode) || other.lastErrorCode == lastErrorCode)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastItems, lastItems) || other.lastItems == lastItems)&&(identical(other.lastMatched, lastMatched) || other.lastMatched == lastMatched)&&(identical(other.errorsInRow, errorsInRow) || other.errorsInRow == errorsInRow)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.hits24h, hits24h) || other.hits24h == hits24h)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.lastHitAt, lastHitAt) || other.lastHitAt == lastHitAt)&&(identical(other.stoppedAt, stoppedAt) || other.stoppedAt == stoppedAt)&&(identical(other.definedAt, definedAt) || other.definedAt == definedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,slug,name,source,url,criteria,const DeepCollectionEquality().hash(include),const DeepCollectionEquality().hash(any),const DeepCollectionEquality().hash(exclude),minPrice,maxPrice,fetchDetails,stopAfterHit,schedule,state,jobId,nextRunAt,lastCheckAt,lastStatus,lastErrorCode,lastError,lastItems,lastMatched,errorsInRow,hits,hits24h,pending,rejected,lastHitAt,stoppedAt,definedAt,updatedAt]);

@override
String toString() {
  return 'Watch(slug: $slug, name: $name, source: $source, url: $url, criteria: $criteria, include: $include, any: $any, exclude: $exclude, minPrice: $minPrice, maxPrice: $maxPrice, fetchDetails: $fetchDetails, stopAfterHit: $stopAfterHit, schedule: $schedule, state: $state, jobId: $jobId, nextRunAt: $nextRunAt, lastCheckAt: $lastCheckAt, lastStatus: $lastStatus, lastErrorCode: $lastErrorCode, lastError: $lastError, lastItems: $lastItems, lastMatched: $lastMatched, errorsInRow: $errorsInRow, hits: $hits, hits24h: $hits24h, pending: $pending, rejected: $rejected, lastHitAt: $lastHitAt, stoppedAt: $stoppedAt, definedAt: $definedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WatchCopyWith<$Res>  {
  factory $WatchCopyWith(Watch value, $Res Function(Watch) _then) = _$WatchCopyWithImpl;
@useResult
$Res call({
 String slug, String name, String source, String url, String? criteria, List<String> include, List<String> any, List<String> exclude, int? minPrice, int? maxPrice, bool fetchDetails, bool stopAfterHit, String schedule, String state, String? jobId, DateTime? nextRunAt, DateTime? lastCheckAt, String? lastStatus, String? lastErrorCode, String? lastError, int? lastItems, int? lastMatched, int errorsInRow, int hits,@JsonKey(name: 'hits_24h') int hits24h, int pending, int rejected, DateTime? lastHitAt, DateTime? stoppedAt, DateTime definedAt, DateTime updatedAt
});




}
/// @nodoc
class _$WatchCopyWithImpl<$Res>
    implements $WatchCopyWith<$Res> {
  _$WatchCopyWithImpl(this._self, this._then);

  final Watch _self;
  final $Res Function(Watch) _then;

/// Create a copy of Watch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? name = null,Object? source = null,Object? url = null,Object? criteria = freezed,Object? include = null,Object? any = null,Object? exclude = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? fetchDetails = null,Object? stopAfterHit = null,Object? schedule = null,Object? state = null,Object? jobId = freezed,Object? nextRunAt = freezed,Object? lastCheckAt = freezed,Object? lastStatus = freezed,Object? lastErrorCode = freezed,Object? lastError = freezed,Object? lastItems = freezed,Object? lastMatched = freezed,Object? errorsInRow = null,Object? hits = null,Object? hits24h = null,Object? pending = null,Object? rejected = null,Object? lastHitAt = freezed,Object? stoppedAt = freezed,Object? definedAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,criteria: freezed == criteria ? _self.criteria : criteria // ignore: cast_nullable_to_non_nullable
as String?,include: null == include ? _self.include : include // ignore: cast_nullable_to_non_nullable
as List<String>,any: null == any ? _self.any : any // ignore: cast_nullable_to_non_nullable
as List<String>,exclude: null == exclude ? _self.exclude : exclude // ignore: cast_nullable_to_non_nullable
as List<String>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as int?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as int?,fetchDetails: null == fetchDetails ? _self.fetchDetails : fetchDetails // ignore: cast_nullable_to_non_nullable
as bool,stopAfterHit: null == stopAfterHit ? _self.stopAfterHit : stopAfterHit // ignore: cast_nullable_to_non_nullable
as bool,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,jobId: freezed == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String?,nextRunAt: freezed == nextRunAt ? _self.nextRunAt : nextRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastCheckAt: freezed == lastCheckAt ? _self.lastCheckAt : lastCheckAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastStatus: freezed == lastStatus ? _self.lastStatus : lastStatus // ignore: cast_nullable_to_non_nullable
as String?,lastErrorCode: freezed == lastErrorCode ? _self.lastErrorCode : lastErrorCode // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastItems: freezed == lastItems ? _self.lastItems : lastItems // ignore: cast_nullable_to_non_nullable
as int?,lastMatched: freezed == lastMatched ? _self.lastMatched : lastMatched // ignore: cast_nullable_to_non_nullable
as int?,errorsInRow: null == errorsInRow ? _self.errorsInRow : errorsInRow // ignore: cast_nullable_to_non_nullable
as int,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,hits24h: null == hits24h ? _self.hits24h : hits24h // ignore: cast_nullable_to_non_nullable
as int,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,lastHitAt: freezed == lastHitAt ? _self.lastHitAt : lastHitAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stoppedAt: freezed == stoppedAt ? _self.stoppedAt : stoppedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,definedAt: null == definedAt ? _self.definedAt : definedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Watch].
extension WatchPatterns on Watch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Watch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Watch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Watch value)  $default,){
final _that = this;
switch (_that) {
case _Watch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Watch value)?  $default,){
final _that = this;
switch (_that) {
case _Watch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String name,  String source,  String url,  String? criteria,  List<String> include,  List<String> any,  List<String> exclude,  int? minPrice,  int? maxPrice,  bool fetchDetails,  bool stopAfterHit,  String schedule,  String state,  String? jobId,  DateTime? nextRunAt,  DateTime? lastCheckAt,  String? lastStatus,  String? lastErrorCode,  String? lastError,  int? lastItems,  int? lastMatched,  int errorsInRow,  int hits, @JsonKey(name: 'hits_24h')  int hits24h,  int pending,  int rejected,  DateTime? lastHitAt,  DateTime? stoppedAt,  DateTime definedAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Watch() when $default != null:
return $default(_that.slug,_that.name,_that.source,_that.url,_that.criteria,_that.include,_that.any,_that.exclude,_that.minPrice,_that.maxPrice,_that.fetchDetails,_that.stopAfterHit,_that.schedule,_that.state,_that.jobId,_that.nextRunAt,_that.lastCheckAt,_that.lastStatus,_that.lastErrorCode,_that.lastError,_that.lastItems,_that.lastMatched,_that.errorsInRow,_that.hits,_that.hits24h,_that.pending,_that.rejected,_that.lastHitAt,_that.stoppedAt,_that.definedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String name,  String source,  String url,  String? criteria,  List<String> include,  List<String> any,  List<String> exclude,  int? minPrice,  int? maxPrice,  bool fetchDetails,  bool stopAfterHit,  String schedule,  String state,  String? jobId,  DateTime? nextRunAt,  DateTime? lastCheckAt,  String? lastStatus,  String? lastErrorCode,  String? lastError,  int? lastItems,  int? lastMatched,  int errorsInRow,  int hits, @JsonKey(name: 'hits_24h')  int hits24h,  int pending,  int rejected,  DateTime? lastHitAt,  DateTime? stoppedAt,  DateTime definedAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Watch():
return $default(_that.slug,_that.name,_that.source,_that.url,_that.criteria,_that.include,_that.any,_that.exclude,_that.minPrice,_that.maxPrice,_that.fetchDetails,_that.stopAfterHit,_that.schedule,_that.state,_that.jobId,_that.nextRunAt,_that.lastCheckAt,_that.lastStatus,_that.lastErrorCode,_that.lastError,_that.lastItems,_that.lastMatched,_that.errorsInRow,_that.hits,_that.hits24h,_that.pending,_that.rejected,_that.lastHitAt,_that.stoppedAt,_that.definedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String name,  String source,  String url,  String? criteria,  List<String> include,  List<String> any,  List<String> exclude,  int? minPrice,  int? maxPrice,  bool fetchDetails,  bool stopAfterHit,  String schedule,  String state,  String? jobId,  DateTime? nextRunAt,  DateTime? lastCheckAt,  String? lastStatus,  String? lastErrorCode,  String? lastError,  int? lastItems,  int? lastMatched,  int errorsInRow,  int hits, @JsonKey(name: 'hits_24h')  int hits24h,  int pending,  int rejected,  DateTime? lastHitAt,  DateTime? stoppedAt,  DateTime definedAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Watch() when $default != null:
return $default(_that.slug,_that.name,_that.source,_that.url,_that.criteria,_that.include,_that.any,_that.exclude,_that.minPrice,_that.maxPrice,_that.fetchDetails,_that.stopAfterHit,_that.schedule,_that.state,_that.jobId,_that.nextRunAt,_that.lastCheckAt,_that.lastStatus,_that.lastErrorCode,_that.lastError,_that.lastItems,_that.lastMatched,_that.errorsInRow,_that.hits,_that.hits24h,_that.pending,_that.rejected,_that.lastHitAt,_that.stoppedAt,_that.definedAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Watch implements Watch {
  const _Watch({required this.slug, required this.name, required this.source, required this.url, this.criteria, final  List<String> include = const <String>[], final  List<String> any = const <String>[], final  List<String> exclude = const <String>[], this.minPrice, this.maxPrice, required this.fetchDetails, required this.stopAfterHit, required this.schedule, required this.state, this.jobId, this.nextRunAt, this.lastCheckAt, this.lastStatus, this.lastErrorCode, this.lastError, this.lastItems, this.lastMatched, this.errorsInRow = 0, this.hits = 0, @JsonKey(name: 'hits_24h') this.hits24h = 0, this.pending = 0, this.rejected = 0, this.lastHitAt, this.stoppedAt, required this.definedAt, required this.updatedAt}): _include = include,_any = any,_exclude = exclude;
  factory _Watch.fromJson(Map<String, dynamic> json) => _$WatchFromJson(json);

@override final  String slug;
@override final  String name;
/// `hardverapro` | `cinemacity` | `page`.
@override final  String source;
@override final  String url;
/// The condition the judge reads, as the user means it; null = filters
/// only.
@override final  String? criteria;
 final  List<String> _include;
@override@JsonKey() List<String> get include {
  if (_include is EqualUnmodifiableListView) return _include;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_include);
}

 final  List<String> _any;
@override@JsonKey() List<String> get any {
  if (_any is EqualUnmodifiableListView) return _any;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_any);
}

 final  List<String> _exclude;
@override@JsonKey() List<String> get exclude {
  if (_exclude is EqualUnmodifiableListView) return _exclude;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exclude);
}

@override final  int? minPrice;
@override final  int? maxPrice;
@override final  bool fetchDetails;
@override final  bool stopAfterHit;
/// A 5-field cron (`15 8,13,19 * * *`) or `every 480m`.
@override final  String schedule;
/// `active` | `paused` | `unknown` (no cron job yet) | `deleted`.
@override final  String state;
@override final  String? jobId;
@override final  DateTime? nextRunAt;
@override final  DateTime? lastCheckAt;
/// `ok` | `error`.
@override final  String? lastStatus;
@override final  String? lastErrorCode;
@override final  String? lastError;
@override final  int? lastItems;
@override final  int? lastMatched;
@override@JsonKey() final  int errorsInRow;
@override@JsonKey() final  int hits;
@override@JsonKey(name: 'hits_24h') final  int hits24h;
@override@JsonKey() final  int pending;
@override@JsonKey() final  int rejected;
@override final  DateTime? lastHitAt;
/// Paused itself after its first hit (`stop_after_hit`).
@override final  DateTime? stoppedAt;
@override final  DateTime definedAt;
@override final  DateTime updatedAt;

/// Create a copy of Watch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchCopyWith<_Watch> get copyWith => __$WatchCopyWithImpl<_Watch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Watch&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.source, source) || other.source == source)&&(identical(other.url, url) || other.url == url)&&(identical(other.criteria, criteria) || other.criteria == criteria)&&const DeepCollectionEquality().equals(other._include, _include)&&const DeepCollectionEquality().equals(other._any, _any)&&const DeepCollectionEquality().equals(other._exclude, _exclude)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.fetchDetails, fetchDetails) || other.fetchDetails == fetchDetails)&&(identical(other.stopAfterHit, stopAfterHit) || other.stopAfterHit == stopAfterHit)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.state, state) || other.state == state)&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.nextRunAt, nextRunAt) || other.nextRunAt == nextRunAt)&&(identical(other.lastCheckAt, lastCheckAt) || other.lastCheckAt == lastCheckAt)&&(identical(other.lastStatus, lastStatus) || other.lastStatus == lastStatus)&&(identical(other.lastErrorCode, lastErrorCode) || other.lastErrorCode == lastErrorCode)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastItems, lastItems) || other.lastItems == lastItems)&&(identical(other.lastMatched, lastMatched) || other.lastMatched == lastMatched)&&(identical(other.errorsInRow, errorsInRow) || other.errorsInRow == errorsInRow)&&(identical(other.hits, hits) || other.hits == hits)&&(identical(other.hits24h, hits24h) || other.hits24h == hits24h)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.lastHitAt, lastHitAt) || other.lastHitAt == lastHitAt)&&(identical(other.stoppedAt, stoppedAt) || other.stoppedAt == stoppedAt)&&(identical(other.definedAt, definedAt) || other.definedAt == definedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,slug,name,source,url,criteria,const DeepCollectionEquality().hash(_include),const DeepCollectionEquality().hash(_any),const DeepCollectionEquality().hash(_exclude),minPrice,maxPrice,fetchDetails,stopAfterHit,schedule,state,jobId,nextRunAt,lastCheckAt,lastStatus,lastErrorCode,lastError,lastItems,lastMatched,errorsInRow,hits,hits24h,pending,rejected,lastHitAt,stoppedAt,definedAt,updatedAt]);

@override
String toString() {
  return 'Watch(slug: $slug, name: $name, source: $source, url: $url, criteria: $criteria, include: $include, any: $any, exclude: $exclude, minPrice: $minPrice, maxPrice: $maxPrice, fetchDetails: $fetchDetails, stopAfterHit: $stopAfterHit, schedule: $schedule, state: $state, jobId: $jobId, nextRunAt: $nextRunAt, lastCheckAt: $lastCheckAt, lastStatus: $lastStatus, lastErrorCode: $lastErrorCode, lastError: $lastError, lastItems: $lastItems, lastMatched: $lastMatched, errorsInRow: $errorsInRow, hits: $hits, hits24h: $hits24h, pending: $pending, rejected: $rejected, lastHitAt: $lastHitAt, stoppedAt: $stoppedAt, definedAt: $definedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WatchCopyWith<$Res> implements $WatchCopyWith<$Res> {
  factory _$WatchCopyWith(_Watch value, $Res Function(_Watch) _then) = __$WatchCopyWithImpl;
@override @useResult
$Res call({
 String slug, String name, String source, String url, String? criteria, List<String> include, List<String> any, List<String> exclude, int? minPrice, int? maxPrice, bool fetchDetails, bool stopAfterHit, String schedule, String state, String? jobId, DateTime? nextRunAt, DateTime? lastCheckAt, String? lastStatus, String? lastErrorCode, String? lastError, int? lastItems, int? lastMatched, int errorsInRow, int hits,@JsonKey(name: 'hits_24h') int hits24h, int pending, int rejected, DateTime? lastHitAt, DateTime? stoppedAt, DateTime definedAt, DateTime updatedAt
});




}
/// @nodoc
class __$WatchCopyWithImpl<$Res>
    implements _$WatchCopyWith<$Res> {
  __$WatchCopyWithImpl(this._self, this._then);

  final _Watch _self;
  final $Res Function(_Watch) _then;

/// Create a copy of Watch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? name = null,Object? source = null,Object? url = null,Object? criteria = freezed,Object? include = null,Object? any = null,Object? exclude = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? fetchDetails = null,Object? stopAfterHit = null,Object? schedule = null,Object? state = null,Object? jobId = freezed,Object? nextRunAt = freezed,Object? lastCheckAt = freezed,Object? lastStatus = freezed,Object? lastErrorCode = freezed,Object? lastError = freezed,Object? lastItems = freezed,Object? lastMatched = freezed,Object? errorsInRow = null,Object? hits = null,Object? hits24h = null,Object? pending = null,Object? rejected = null,Object? lastHitAt = freezed,Object? stoppedAt = freezed,Object? definedAt = null,Object? updatedAt = null,}) {
  return _then(_Watch(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,criteria: freezed == criteria ? _self.criteria : criteria // ignore: cast_nullable_to_non_nullable
as String?,include: null == include ? _self._include : include // ignore: cast_nullable_to_non_nullable
as List<String>,any: null == any ? _self._any : any // ignore: cast_nullable_to_non_nullable
as List<String>,exclude: null == exclude ? _self._exclude : exclude // ignore: cast_nullable_to_non_nullable
as List<String>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as int?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as int?,fetchDetails: null == fetchDetails ? _self.fetchDetails : fetchDetails // ignore: cast_nullable_to_non_nullable
as bool,stopAfterHit: null == stopAfterHit ? _self.stopAfterHit : stopAfterHit // ignore: cast_nullable_to_non_nullable
as bool,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,jobId: freezed == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String?,nextRunAt: freezed == nextRunAt ? _self.nextRunAt : nextRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastCheckAt: freezed == lastCheckAt ? _self.lastCheckAt : lastCheckAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastStatus: freezed == lastStatus ? _self.lastStatus : lastStatus // ignore: cast_nullable_to_non_nullable
as String?,lastErrorCode: freezed == lastErrorCode ? _self.lastErrorCode : lastErrorCode // ignore: cast_nullable_to_non_nullable
as String?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastItems: freezed == lastItems ? _self.lastItems : lastItems // ignore: cast_nullable_to_non_nullable
as int?,lastMatched: freezed == lastMatched ? _self.lastMatched : lastMatched // ignore: cast_nullable_to_non_nullable
as int?,errorsInRow: null == errorsInRow ? _self.errorsInRow : errorsInRow // ignore: cast_nullable_to_non_nullable
as int,hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as int,hits24h: null == hits24h ? _self.hits24h : hits24h // ignore: cast_nullable_to_non_nullable
as int,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,lastHitAt: freezed == lastHitAt ? _self.lastHitAt : lastHitAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stoppedAt: freezed == stoppedAt ? _self.stoppedAt : stoppedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,definedAt: null == definedAt ? _self.definedAt : definedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$WatchItem {

 int get id; String get slug; String get itemId; String get title; String get url; String? get price; int? get priceValue; String? get location; String? get posted; String? get excerpt;/// On hold (Hardverapró "jegelve").
 bool get reserved;/// `match` | `mechanical` (hits) | `reject` | `pending` | `error`.
 String get verdict;/// The judge's one sentence (match, reject).
 String? get reason; DateTime get seenAt; DateTime? get judgedAt; DateTime? get notifiedAt;/// Was on hold, then free again.
 DateTime? get availableAt;
/// Create a copy of WatchItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchItemCopyWith<WatchItem> get copyWith => _$WatchItemCopyWithImpl<WatchItem>(this as WatchItem, _$identity);

  /// Serializes this WatchItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchItem&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.price, price) || other.price == price)&&(identical(other.priceValue, priceValue) || other.priceValue == priceValue)&&(identical(other.location, location) || other.location == location)&&(identical(other.posted, posted) || other.posted == posted)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.reserved, reserved) || other.reserved == reserved)&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.seenAt, seenAt) || other.seenAt == seenAt)&&(identical(other.judgedAt, judgedAt) || other.judgedAt == judgedAt)&&(identical(other.notifiedAt, notifiedAt) || other.notifiedAt == notifiedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,itemId,title,url,price,priceValue,location,posted,excerpt,reserved,verdict,reason,seenAt,judgedAt,notifiedAt,availableAt);

@override
String toString() {
  return 'WatchItem(id: $id, slug: $slug, itemId: $itemId, title: $title, url: $url, price: $price, priceValue: $priceValue, location: $location, posted: $posted, excerpt: $excerpt, reserved: $reserved, verdict: $verdict, reason: $reason, seenAt: $seenAt, judgedAt: $judgedAt, notifiedAt: $notifiedAt, availableAt: $availableAt)';
}


}

/// @nodoc
abstract mixin class $WatchItemCopyWith<$Res>  {
  factory $WatchItemCopyWith(WatchItem value, $Res Function(WatchItem) _then) = _$WatchItemCopyWithImpl;
@useResult
$Res call({
 int id, String slug, String itemId, String title, String url, String? price, int? priceValue, String? location, String? posted, String? excerpt, bool reserved, String verdict, String? reason, DateTime seenAt, DateTime? judgedAt, DateTime? notifiedAt, DateTime? availableAt
});




}
/// @nodoc
class _$WatchItemCopyWithImpl<$Res>
    implements $WatchItemCopyWith<$Res> {
  _$WatchItemCopyWithImpl(this._self, this._then);

  final WatchItem _self;
  final $Res Function(WatchItem) _then;

/// Create a copy of WatchItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? itemId = null,Object? title = null,Object? url = null,Object? price = freezed,Object? priceValue = freezed,Object? location = freezed,Object? posted = freezed,Object? excerpt = freezed,Object? reserved = null,Object? verdict = null,Object? reason = freezed,Object? seenAt = null,Object? judgedAt = freezed,Object? notifiedAt = freezed,Object? availableAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String?,priceValue: freezed == priceValue ? _self.priceValue : priceValue // ignore: cast_nullable_to_non_nullable
as int?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,posted: freezed == posted ? _self.posted : posted // ignore: cast_nullable_to_non_nullable
as String?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,reserved: null == reserved ? _self.reserved : reserved // ignore: cast_nullable_to_non_nullable
as bool,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,seenAt: null == seenAt ? _self.seenAt : seenAt // ignore: cast_nullable_to_non_nullable
as DateTime,judgedAt: freezed == judgedAt ? _self.judgedAt : judgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notifiedAt: freezed == notifiedAt ? _self.notifiedAt : notifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,availableAt: freezed == availableAt ? _self.availableAt : availableAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WatchItem].
extension WatchItemPatterns on WatchItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WatchItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WatchItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WatchItem value)  $default,){
final _that = this;
switch (_that) {
case _WatchItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WatchItem value)?  $default,){
final _that = this;
switch (_that) {
case _WatchItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String slug,  String itemId,  String title,  String url,  String? price,  int? priceValue,  String? location,  String? posted,  String? excerpt,  bool reserved,  String verdict,  String? reason,  DateTime seenAt,  DateTime? judgedAt,  DateTime? notifiedAt,  DateTime? availableAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WatchItem() when $default != null:
return $default(_that.id,_that.slug,_that.itemId,_that.title,_that.url,_that.price,_that.priceValue,_that.location,_that.posted,_that.excerpt,_that.reserved,_that.verdict,_that.reason,_that.seenAt,_that.judgedAt,_that.notifiedAt,_that.availableAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String slug,  String itemId,  String title,  String url,  String? price,  int? priceValue,  String? location,  String? posted,  String? excerpt,  bool reserved,  String verdict,  String? reason,  DateTime seenAt,  DateTime? judgedAt,  DateTime? notifiedAt,  DateTime? availableAt)  $default,) {final _that = this;
switch (_that) {
case _WatchItem():
return $default(_that.id,_that.slug,_that.itemId,_that.title,_that.url,_that.price,_that.priceValue,_that.location,_that.posted,_that.excerpt,_that.reserved,_that.verdict,_that.reason,_that.seenAt,_that.judgedAt,_that.notifiedAt,_that.availableAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String slug,  String itemId,  String title,  String url,  String? price,  int? priceValue,  String? location,  String? posted,  String? excerpt,  bool reserved,  String verdict,  String? reason,  DateTime seenAt,  DateTime? judgedAt,  DateTime? notifiedAt,  DateTime? availableAt)?  $default,) {final _that = this;
switch (_that) {
case _WatchItem() when $default != null:
return $default(_that.id,_that.slug,_that.itemId,_that.title,_that.url,_that.price,_that.priceValue,_that.location,_that.posted,_that.excerpt,_that.reserved,_that.verdict,_that.reason,_that.seenAt,_that.judgedAt,_that.notifiedAt,_that.availableAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WatchItem implements WatchItem {
  const _WatchItem({required this.id, required this.slug, required this.itemId, required this.title, required this.url, this.price, this.priceValue, this.location, this.posted, this.excerpt, this.reserved = false, required this.verdict, this.reason, required this.seenAt, this.judgedAt, this.notifiedAt, this.availableAt});
  factory _WatchItem.fromJson(Map<String, dynamic> json) => _$WatchItemFromJson(json);

@override final  int id;
@override final  String slug;
@override final  String itemId;
@override final  String title;
@override final  String url;
@override final  String? price;
@override final  int? priceValue;
@override final  String? location;
@override final  String? posted;
@override final  String? excerpt;
/// On hold (Hardverapró "jegelve").
@override@JsonKey() final  bool reserved;
/// `match` | `mechanical` (hits) | `reject` | `pending` | `error`.
@override final  String verdict;
/// The judge's one sentence (match, reject).
@override final  String? reason;
@override final  DateTime seenAt;
@override final  DateTime? judgedAt;
@override final  DateTime? notifiedAt;
/// Was on hold, then free again.
@override final  DateTime? availableAt;

/// Create a copy of WatchItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchItemCopyWith<_WatchItem> get copyWith => __$WatchItemCopyWithImpl<_WatchItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WatchItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WatchItem&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.price, price) || other.price == price)&&(identical(other.priceValue, priceValue) || other.priceValue == priceValue)&&(identical(other.location, location) || other.location == location)&&(identical(other.posted, posted) || other.posted == posted)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.reserved, reserved) || other.reserved == reserved)&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.seenAt, seenAt) || other.seenAt == seenAt)&&(identical(other.judgedAt, judgedAt) || other.judgedAt == judgedAt)&&(identical(other.notifiedAt, notifiedAt) || other.notifiedAt == notifiedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,itemId,title,url,price,priceValue,location,posted,excerpt,reserved,verdict,reason,seenAt,judgedAt,notifiedAt,availableAt);

@override
String toString() {
  return 'WatchItem(id: $id, slug: $slug, itemId: $itemId, title: $title, url: $url, price: $price, priceValue: $priceValue, location: $location, posted: $posted, excerpt: $excerpt, reserved: $reserved, verdict: $verdict, reason: $reason, seenAt: $seenAt, judgedAt: $judgedAt, notifiedAt: $notifiedAt, availableAt: $availableAt)';
}


}

/// @nodoc
abstract mixin class _$WatchItemCopyWith<$Res> implements $WatchItemCopyWith<$Res> {
  factory _$WatchItemCopyWith(_WatchItem value, $Res Function(_WatchItem) _then) = __$WatchItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String slug, String itemId, String title, String url, String? price, int? priceValue, String? location, String? posted, String? excerpt, bool reserved, String verdict, String? reason, DateTime seenAt, DateTime? judgedAt, DateTime? notifiedAt, DateTime? availableAt
});




}
/// @nodoc
class __$WatchItemCopyWithImpl<$Res>
    implements _$WatchItemCopyWith<$Res> {
  __$WatchItemCopyWithImpl(this._self, this._then);

  final _WatchItem _self;
  final $Res Function(_WatchItem) _then;

/// Create a copy of WatchItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? itemId = null,Object? title = null,Object? url = null,Object? price = freezed,Object? priceValue = freezed,Object? location = freezed,Object? posted = freezed,Object? excerpt = freezed,Object? reserved = null,Object? verdict = null,Object? reason = freezed,Object? seenAt = null,Object? judgedAt = freezed,Object? notifiedAt = freezed,Object? availableAt = freezed,}) {
  return _then(_WatchItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String?,priceValue: freezed == priceValue ? _self.priceValue : priceValue // ignore: cast_nullable_to_non_nullable
as int?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,posted: freezed == posted ? _self.posted : posted // ignore: cast_nullable_to_non_nullable
as String?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,reserved: null == reserved ? _self.reserved : reserved // ignore: cast_nullable_to_non_nullable
as bool,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,seenAt: null == seenAt ? _self.seenAt : seenAt // ignore: cast_nullable_to_non_nullable
as DateTime,judgedAt: freezed == judgedAt ? _self.judgedAt : judgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notifiedAt: freezed == notifiedAt ? _self.notifiedAt : notifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,availableAt: freezed == availableAt ? _self.availableAt : availableAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
