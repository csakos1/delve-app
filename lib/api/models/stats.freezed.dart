// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Stats {

/// `24h` | `7d` | `30d`.
 String get range; DateTime get from; DateTime get to; DateTime get now; String get tz; int get bucketS; int get gpuBucketS; StatsSeries get generation; StatsSeries get prefill;/// Prefill only counts runs with at least this many prompt tokens.
 int get prefillMinPromptTokens; StatsSeries get queue;/// Seconds from the request to the answer (median).
 StatsSeries get approvalLatency;/// Percent of the input tokens read from the cache.
 StatsSeries get cacheHit; TokensPerDay get tokensPerDay; List<StatsGpu> get gpus; StatsSampling get sampling;
/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsCopyWith<Stats> get copyWith => _$StatsCopyWithImpl<Stats>(this as Stats, _$identity);

  /// Serializes this Stats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Stats&&(identical(other.range, range) || other.range == range)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.now, now) || other.now == now)&&(identical(other.tz, tz) || other.tz == tz)&&(identical(other.bucketS, bucketS) || other.bucketS == bucketS)&&(identical(other.gpuBucketS, gpuBucketS) || other.gpuBucketS == gpuBucketS)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.prefill, prefill) || other.prefill == prefill)&&(identical(other.prefillMinPromptTokens, prefillMinPromptTokens) || other.prefillMinPromptTokens == prefillMinPromptTokens)&&(identical(other.queue, queue) || other.queue == queue)&&(identical(other.approvalLatency, approvalLatency) || other.approvalLatency == approvalLatency)&&(identical(other.cacheHit, cacheHit) || other.cacheHit == cacheHit)&&(identical(other.tokensPerDay, tokensPerDay) || other.tokensPerDay == tokensPerDay)&&const DeepCollectionEquality().equals(other.gpus, gpus)&&(identical(other.sampling, sampling) || other.sampling == sampling));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,range,from,to,now,tz,bucketS,gpuBucketS,generation,prefill,prefillMinPromptTokens,queue,approvalLatency,cacheHit,tokensPerDay,const DeepCollectionEquality().hash(gpus),sampling);

@override
String toString() {
  return 'Stats(range: $range, from: $from, to: $to, now: $now, tz: $tz, bucketS: $bucketS, gpuBucketS: $gpuBucketS, generation: $generation, prefill: $prefill, prefillMinPromptTokens: $prefillMinPromptTokens, queue: $queue, approvalLatency: $approvalLatency, cacheHit: $cacheHit, tokensPerDay: $tokensPerDay, gpus: $gpus, sampling: $sampling)';
}


}

/// @nodoc
abstract mixin class $StatsCopyWith<$Res>  {
  factory $StatsCopyWith(Stats value, $Res Function(Stats) _then) = _$StatsCopyWithImpl;
@useResult
$Res call({
 String range, DateTime from, DateTime to, DateTime now, String tz, int bucketS, int gpuBucketS, StatsSeries generation, StatsSeries prefill, int prefillMinPromptTokens, StatsSeries queue, StatsSeries approvalLatency, StatsSeries cacheHit, TokensPerDay tokensPerDay, List<StatsGpu> gpus, StatsSampling sampling
});


$StatsSeriesCopyWith<$Res> get generation;$StatsSeriesCopyWith<$Res> get prefill;$StatsSeriesCopyWith<$Res> get queue;$StatsSeriesCopyWith<$Res> get approvalLatency;$StatsSeriesCopyWith<$Res> get cacheHit;$TokensPerDayCopyWith<$Res> get tokensPerDay;$StatsSamplingCopyWith<$Res> get sampling;

}
/// @nodoc
class _$StatsCopyWithImpl<$Res>
    implements $StatsCopyWith<$Res> {
  _$StatsCopyWithImpl(this._self, this._then);

  final Stats _self;
  final $Res Function(Stats) _then;

/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? from = null,Object? to = null,Object? now = null,Object? tz = null,Object? bucketS = null,Object? gpuBucketS = null,Object? generation = null,Object? prefill = null,Object? prefillMinPromptTokens = null,Object? queue = null,Object? approvalLatency = null,Object? cacheHit = null,Object? tokensPerDay = null,Object? gpus = null,Object? sampling = null,}) {
  return _then(_self.copyWith(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,now: null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,tz: null == tz ? _self.tz : tz // ignore: cast_nullable_to_non_nullable
as String,bucketS: null == bucketS ? _self.bucketS : bucketS // ignore: cast_nullable_to_non_nullable
as int,gpuBucketS: null == gpuBucketS ? _self.gpuBucketS : gpuBucketS // ignore: cast_nullable_to_non_nullable
as int,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as StatsSeries,prefill: null == prefill ? _self.prefill : prefill // ignore: cast_nullable_to_non_nullable
as StatsSeries,prefillMinPromptTokens: null == prefillMinPromptTokens ? _self.prefillMinPromptTokens : prefillMinPromptTokens // ignore: cast_nullable_to_non_nullable
as int,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as StatsSeries,approvalLatency: null == approvalLatency ? _self.approvalLatency : approvalLatency // ignore: cast_nullable_to_non_nullable
as StatsSeries,cacheHit: null == cacheHit ? _self.cacheHit : cacheHit // ignore: cast_nullable_to_non_nullable
as StatsSeries,tokensPerDay: null == tokensPerDay ? _self.tokensPerDay : tokensPerDay // ignore: cast_nullable_to_non_nullable
as TokensPerDay,gpus: null == gpus ? _self.gpus : gpus // ignore: cast_nullable_to_non_nullable
as List<StatsGpu>,sampling: null == sampling ? _self.sampling : sampling // ignore: cast_nullable_to_non_nullable
as StatsSampling,
  ));
}
/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get generation {
  
  return $StatsSeriesCopyWith<$Res>(_self.generation, (value) {
    return _then(_self.copyWith(generation: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get prefill {
  
  return $StatsSeriesCopyWith<$Res>(_self.prefill, (value) {
    return _then(_self.copyWith(prefill: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get queue {
  
  return $StatsSeriesCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get approvalLatency {
  
  return $StatsSeriesCopyWith<$Res>(_self.approvalLatency, (value) {
    return _then(_self.copyWith(approvalLatency: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get cacheHit {
  
  return $StatsSeriesCopyWith<$Res>(_self.cacheHit, (value) {
    return _then(_self.copyWith(cacheHit: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokensPerDayCopyWith<$Res> get tokensPerDay {
  
  return $TokensPerDayCopyWith<$Res>(_self.tokensPerDay, (value) {
    return _then(_self.copyWith(tokensPerDay: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSamplingCopyWith<$Res> get sampling {
  
  return $StatsSamplingCopyWith<$Res>(_self.sampling, (value) {
    return _then(_self.copyWith(sampling: value));
  });
}
}


/// Adds pattern-matching-related methods to [Stats].
extension StatsPatterns on Stats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Stats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Stats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Stats value)  $default,){
final _that = this;
switch (_that) {
case _Stats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Stats value)?  $default,){
final _that = this;
switch (_that) {
case _Stats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String range,  DateTime from,  DateTime to,  DateTime now,  String tz,  int bucketS,  int gpuBucketS,  StatsSeries generation,  StatsSeries prefill,  int prefillMinPromptTokens,  StatsSeries queue,  StatsSeries approvalLatency,  StatsSeries cacheHit,  TokensPerDay tokensPerDay,  List<StatsGpu> gpus,  StatsSampling sampling)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Stats() when $default != null:
return $default(_that.range,_that.from,_that.to,_that.now,_that.tz,_that.bucketS,_that.gpuBucketS,_that.generation,_that.prefill,_that.prefillMinPromptTokens,_that.queue,_that.approvalLatency,_that.cacheHit,_that.tokensPerDay,_that.gpus,_that.sampling);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String range,  DateTime from,  DateTime to,  DateTime now,  String tz,  int bucketS,  int gpuBucketS,  StatsSeries generation,  StatsSeries prefill,  int prefillMinPromptTokens,  StatsSeries queue,  StatsSeries approvalLatency,  StatsSeries cacheHit,  TokensPerDay tokensPerDay,  List<StatsGpu> gpus,  StatsSampling sampling)  $default,) {final _that = this;
switch (_that) {
case _Stats():
return $default(_that.range,_that.from,_that.to,_that.now,_that.tz,_that.bucketS,_that.gpuBucketS,_that.generation,_that.prefill,_that.prefillMinPromptTokens,_that.queue,_that.approvalLatency,_that.cacheHit,_that.tokensPerDay,_that.gpus,_that.sampling);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String range,  DateTime from,  DateTime to,  DateTime now,  String tz,  int bucketS,  int gpuBucketS,  StatsSeries generation,  StatsSeries prefill,  int prefillMinPromptTokens,  StatsSeries queue,  StatsSeries approvalLatency,  StatsSeries cacheHit,  TokensPerDay tokensPerDay,  List<StatsGpu> gpus,  StatsSampling sampling)?  $default,) {final _that = this;
switch (_that) {
case _Stats() when $default != null:
return $default(_that.range,_that.from,_that.to,_that.now,_that.tz,_that.bucketS,_that.gpuBucketS,_that.generation,_that.prefill,_that.prefillMinPromptTokens,_that.queue,_that.approvalLatency,_that.cacheHit,_that.tokensPerDay,_that.gpus,_that.sampling);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Stats implements Stats {
  const _Stats({required this.range, required this.from, required this.to, required this.now, required this.tz, required this.bucketS, required this.gpuBucketS, required this.generation, required this.prefill, required this.prefillMinPromptTokens, required this.queue, required this.approvalLatency, required this.cacheHit, required this.tokensPerDay, final  List<StatsGpu> gpus = const <StatsGpu>[], required this.sampling}): _gpus = gpus;
  factory _Stats.fromJson(Map<String, dynamic> json) => _$StatsFromJson(json);

/// `24h` | `7d` | `30d`.
@override final  String range;
@override final  DateTime from;
@override final  DateTime to;
@override final  DateTime now;
@override final  String tz;
@override final  int bucketS;
@override final  int gpuBucketS;
@override final  StatsSeries generation;
@override final  StatsSeries prefill;
/// Prefill only counts runs with at least this many prompt tokens.
@override final  int prefillMinPromptTokens;
@override final  StatsSeries queue;
/// Seconds from the request to the answer (median).
@override final  StatsSeries approvalLatency;
/// Percent of the input tokens read from the cache.
@override final  StatsSeries cacheHit;
@override final  TokensPerDay tokensPerDay;
 final  List<StatsGpu> _gpus;
@override@JsonKey() List<StatsGpu> get gpus {
  if (_gpus is EqualUnmodifiableListView) return _gpus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gpus);
}

@override final  StatsSampling sampling;

/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsCopyWith<_Stats> get copyWith => __$StatsCopyWithImpl<_Stats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Stats&&(identical(other.range, range) || other.range == range)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.now, now) || other.now == now)&&(identical(other.tz, tz) || other.tz == tz)&&(identical(other.bucketS, bucketS) || other.bucketS == bucketS)&&(identical(other.gpuBucketS, gpuBucketS) || other.gpuBucketS == gpuBucketS)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.prefill, prefill) || other.prefill == prefill)&&(identical(other.prefillMinPromptTokens, prefillMinPromptTokens) || other.prefillMinPromptTokens == prefillMinPromptTokens)&&(identical(other.queue, queue) || other.queue == queue)&&(identical(other.approvalLatency, approvalLatency) || other.approvalLatency == approvalLatency)&&(identical(other.cacheHit, cacheHit) || other.cacheHit == cacheHit)&&(identical(other.tokensPerDay, tokensPerDay) || other.tokensPerDay == tokensPerDay)&&const DeepCollectionEquality().equals(other._gpus, _gpus)&&(identical(other.sampling, sampling) || other.sampling == sampling));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,range,from,to,now,tz,bucketS,gpuBucketS,generation,prefill,prefillMinPromptTokens,queue,approvalLatency,cacheHit,tokensPerDay,const DeepCollectionEquality().hash(_gpus),sampling);

@override
String toString() {
  return 'Stats(range: $range, from: $from, to: $to, now: $now, tz: $tz, bucketS: $bucketS, gpuBucketS: $gpuBucketS, generation: $generation, prefill: $prefill, prefillMinPromptTokens: $prefillMinPromptTokens, queue: $queue, approvalLatency: $approvalLatency, cacheHit: $cacheHit, tokensPerDay: $tokensPerDay, gpus: $gpus, sampling: $sampling)';
}


}

/// @nodoc
abstract mixin class _$StatsCopyWith<$Res> implements $StatsCopyWith<$Res> {
  factory _$StatsCopyWith(_Stats value, $Res Function(_Stats) _then) = __$StatsCopyWithImpl;
@override @useResult
$Res call({
 String range, DateTime from, DateTime to, DateTime now, String tz, int bucketS, int gpuBucketS, StatsSeries generation, StatsSeries prefill, int prefillMinPromptTokens, StatsSeries queue, StatsSeries approvalLatency, StatsSeries cacheHit, TokensPerDay tokensPerDay, List<StatsGpu> gpus, StatsSampling sampling
});


@override $StatsSeriesCopyWith<$Res> get generation;@override $StatsSeriesCopyWith<$Res> get prefill;@override $StatsSeriesCopyWith<$Res> get queue;@override $StatsSeriesCopyWith<$Res> get approvalLatency;@override $StatsSeriesCopyWith<$Res> get cacheHit;@override $TokensPerDayCopyWith<$Res> get tokensPerDay;@override $StatsSamplingCopyWith<$Res> get sampling;

}
/// @nodoc
class __$StatsCopyWithImpl<$Res>
    implements _$StatsCopyWith<$Res> {
  __$StatsCopyWithImpl(this._self, this._then);

  final _Stats _self;
  final $Res Function(_Stats) _then;

/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? from = null,Object? to = null,Object? now = null,Object? tz = null,Object? bucketS = null,Object? gpuBucketS = null,Object? generation = null,Object? prefill = null,Object? prefillMinPromptTokens = null,Object? queue = null,Object? approvalLatency = null,Object? cacheHit = null,Object? tokensPerDay = null,Object? gpus = null,Object? sampling = null,}) {
  return _then(_Stats(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,now: null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,tz: null == tz ? _self.tz : tz // ignore: cast_nullable_to_non_nullable
as String,bucketS: null == bucketS ? _self.bucketS : bucketS // ignore: cast_nullable_to_non_nullable
as int,gpuBucketS: null == gpuBucketS ? _self.gpuBucketS : gpuBucketS // ignore: cast_nullable_to_non_nullable
as int,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as StatsSeries,prefill: null == prefill ? _self.prefill : prefill // ignore: cast_nullable_to_non_nullable
as StatsSeries,prefillMinPromptTokens: null == prefillMinPromptTokens ? _self.prefillMinPromptTokens : prefillMinPromptTokens // ignore: cast_nullable_to_non_nullable
as int,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as StatsSeries,approvalLatency: null == approvalLatency ? _self.approvalLatency : approvalLatency // ignore: cast_nullable_to_non_nullable
as StatsSeries,cacheHit: null == cacheHit ? _self.cacheHit : cacheHit // ignore: cast_nullable_to_non_nullable
as StatsSeries,tokensPerDay: null == tokensPerDay ? _self.tokensPerDay : tokensPerDay // ignore: cast_nullable_to_non_nullable
as TokensPerDay,gpus: null == gpus ? _self._gpus : gpus // ignore: cast_nullable_to_non_nullable
as List<StatsGpu>,sampling: null == sampling ? _self.sampling : sampling // ignore: cast_nullable_to_non_nullable
as StatsSampling,
  ));
}

/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get generation {
  
  return $StatsSeriesCopyWith<$Res>(_self.generation, (value) {
    return _then(_self.copyWith(generation: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get prefill {
  
  return $StatsSeriesCopyWith<$Res>(_self.prefill, (value) {
    return _then(_self.copyWith(prefill: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get queue {
  
  return $StatsSeriesCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get approvalLatency {
  
  return $StatsSeriesCopyWith<$Res>(_self.approvalLatency, (value) {
    return _then(_self.copyWith(approvalLatency: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get cacheHit {
  
  return $StatsSeriesCopyWith<$Res>(_self.cacheHit, (value) {
    return _then(_self.copyWith(cacheHit: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokensPerDayCopyWith<$Res> get tokensPerDay {
  
  return $TokensPerDayCopyWith<$Res>(_self.tokensPerDay, (value) {
    return _then(_self.copyWith(tokensPerDay: value));
  });
}/// Create a copy of Stats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSamplingCopyWith<$Res> get sampling {
  
  return $StatsSamplingCopyWith<$Res>(_self.sampling, (value) {
    return _then(_self.copyWith(sampling: value));
  });
}
}


/// @nodoc
mixin _$StatsSeries {

 double? get value; List<StatsPoint> get points;
/// Create a copy of StatsSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<StatsSeries> get copyWith => _$StatsSeriesCopyWithImpl<StatsSeries>(this as StatsSeries, _$identity);

  /// Serializes this StatsSeries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsSeries&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other.points, points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,const DeepCollectionEquality().hash(points));

@override
String toString() {
  return 'StatsSeries(value: $value, points: $points)';
}


}

/// @nodoc
abstract mixin class $StatsSeriesCopyWith<$Res>  {
  factory $StatsSeriesCopyWith(StatsSeries value, $Res Function(StatsSeries) _then) = _$StatsSeriesCopyWithImpl;
@useResult
$Res call({
 double? value, List<StatsPoint> points
});




}
/// @nodoc
class _$StatsSeriesCopyWithImpl<$Res>
    implements $StatsSeriesCopyWith<$Res> {
  _$StatsSeriesCopyWithImpl(this._self, this._then);

  final StatsSeries _self;
  final $Res Function(StatsSeries) _then;

/// Create a copy of StatsSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = freezed,Object? points = null,}) {
  return _then(_self.copyWith(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<StatsPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsSeries].
extension StatsSeriesPatterns on StatsSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsSeries value)  $default,){
final _that = this;
switch (_that) {
case _StatsSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsSeries value)?  $default,){
final _that = this;
switch (_that) {
case _StatsSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? value,  List<StatsPoint> points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsSeries() when $default != null:
return $default(_that.value,_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? value,  List<StatsPoint> points)  $default,) {final _that = this;
switch (_that) {
case _StatsSeries():
return $default(_that.value,_that.points);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? value,  List<StatsPoint> points)?  $default,) {final _that = this;
switch (_that) {
case _StatsSeries() when $default != null:
return $default(_that.value,_that.points);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsSeries implements StatsSeries {
  const _StatsSeries({this.value, final  List<StatsPoint> points = const <StatsPoint>[]}): _points = points;
  factory _StatsSeries.fromJson(Map<String, dynamic> json) => _$StatsSeriesFromJson(json);

@override final  double? value;
 final  List<StatsPoint> _points;
@override@JsonKey() List<StatsPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}


/// Create a copy of StatsSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsSeriesCopyWith<_StatsSeries> get copyWith => __$StatsSeriesCopyWithImpl<_StatsSeries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsSeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsSeries&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other._points, _points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,const DeepCollectionEquality().hash(_points));

@override
String toString() {
  return 'StatsSeries(value: $value, points: $points)';
}


}

/// @nodoc
abstract mixin class _$StatsSeriesCopyWith<$Res> implements $StatsSeriesCopyWith<$Res> {
  factory _$StatsSeriesCopyWith(_StatsSeries value, $Res Function(_StatsSeries) _then) = __$StatsSeriesCopyWithImpl;
@override @useResult
$Res call({
 double? value, List<StatsPoint> points
});




}
/// @nodoc
class __$StatsSeriesCopyWithImpl<$Res>
    implements _$StatsSeriesCopyWith<$Res> {
  __$StatsSeriesCopyWithImpl(this._self, this._then);

  final _StatsSeries _self;
  final $Res Function(_StatsSeries) _then;

/// Create a copy of StatsSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = freezed,Object? points = null,}) {
  return _then(_StatsSeries(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<StatsPoint>,
  ));
}


}


/// @nodoc
mixin _$StatsPoint {

 DateTime get t; double? get v;
/// Create a copy of StatsPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsPointCopyWith<StatsPoint> get copyWith => _$StatsPointCopyWithImpl<StatsPoint>(this as StatsPoint, _$identity);

  /// Serializes this StatsPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsPoint&&(identical(other.t, t) || other.t == t)&&(identical(other.v, v) || other.v == v));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,v);

@override
String toString() {
  return 'StatsPoint(t: $t, v: $v)';
}


}

/// @nodoc
abstract mixin class $StatsPointCopyWith<$Res>  {
  factory $StatsPointCopyWith(StatsPoint value, $Res Function(StatsPoint) _then) = _$StatsPointCopyWithImpl;
@useResult
$Res call({
 DateTime t, double? v
});




}
/// @nodoc
class _$StatsPointCopyWithImpl<$Res>
    implements $StatsPointCopyWith<$Res> {
  _$StatsPointCopyWithImpl(this._self, this._then);

  final StatsPoint _self;
  final $Res Function(StatsPoint) _then;

/// Create a copy of StatsPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? t = null,Object? v = freezed,}) {
  return _then(_self.copyWith(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as DateTime,v: freezed == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsPoint].
extension StatsPointPatterns on StatsPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsPoint value)  $default,){
final _that = this;
switch (_that) {
case _StatsPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsPoint value)?  $default,){
final _that = this;
switch (_that) {
case _StatsPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime t,  double? v)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsPoint() when $default != null:
return $default(_that.t,_that.v);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime t,  double? v)  $default,) {final _that = this;
switch (_that) {
case _StatsPoint():
return $default(_that.t,_that.v);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime t,  double? v)?  $default,) {final _that = this;
switch (_that) {
case _StatsPoint() when $default != null:
return $default(_that.t,_that.v);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsPoint implements StatsPoint {
  const _StatsPoint({required this.t, this.v});
  factory _StatsPoint.fromJson(Map<String, dynamic> json) => _$StatsPointFromJson(json);

@override final  DateTime t;
@override final  double? v;

/// Create a copy of StatsPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsPointCopyWith<_StatsPoint> get copyWith => __$StatsPointCopyWithImpl<_StatsPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsPoint&&(identical(other.t, t) || other.t == t)&&(identical(other.v, v) || other.v == v));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,v);

@override
String toString() {
  return 'StatsPoint(t: $t, v: $v)';
}


}

/// @nodoc
abstract mixin class _$StatsPointCopyWith<$Res> implements $StatsPointCopyWith<$Res> {
  factory _$StatsPointCopyWith(_StatsPoint value, $Res Function(_StatsPoint) _then) = __$StatsPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime t, double? v
});




}
/// @nodoc
class __$StatsPointCopyWithImpl<$Res>
    implements _$StatsPointCopyWith<$Res> {
  __$StatsPointCopyWithImpl(this._self, this._then);

  final _StatsPoint _self;
  final $Res Function(_StatsPoint) _then;

/// Create a copy of StatsPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? t = null,Object? v = freezed,}) {
  return _then(_StatsPoint(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as DateTime,v: freezed == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$TokensPerDay {

 int get value; List<StatsDay> get days;
/// Create a copy of TokensPerDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokensPerDayCopyWith<TokensPerDay> get copyWith => _$TokensPerDayCopyWithImpl<TokensPerDay>(this as TokensPerDay, _$identity);

  /// Serializes this TokensPerDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokensPerDay&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other.days, days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,const DeepCollectionEquality().hash(days));

@override
String toString() {
  return 'TokensPerDay(value: $value, days: $days)';
}


}

/// @nodoc
abstract mixin class $TokensPerDayCopyWith<$Res>  {
  factory $TokensPerDayCopyWith(TokensPerDay value, $Res Function(TokensPerDay) _then) = _$TokensPerDayCopyWithImpl;
@useResult
$Res call({
 int value, List<StatsDay> days
});




}
/// @nodoc
class _$TokensPerDayCopyWithImpl<$Res>
    implements $TokensPerDayCopyWith<$Res> {
  _$TokensPerDayCopyWithImpl(this._self, this._then);

  final TokensPerDay _self;
  final $Res Function(TokensPerDay) _then;

/// Create a copy of TokensPerDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? days = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<StatsDay>,
  ));
}

}


/// Adds pattern-matching-related methods to [TokensPerDay].
extension TokensPerDayPatterns on TokensPerDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokensPerDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokensPerDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokensPerDay value)  $default,){
final _that = this;
switch (_that) {
case _TokensPerDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokensPerDay value)?  $default,){
final _that = this;
switch (_that) {
case _TokensPerDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int value,  List<StatsDay> days)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokensPerDay() when $default != null:
return $default(_that.value,_that.days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value,  List<StatsDay> days)  $default,) {final _that = this;
switch (_that) {
case _TokensPerDay():
return $default(_that.value,_that.days);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int value,  List<StatsDay> days)?  $default,) {final _that = this;
switch (_that) {
case _TokensPerDay() when $default != null:
return $default(_that.value,_that.days);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TokensPerDay implements TokensPerDay {
  const _TokensPerDay({required this.value, final  List<StatsDay> days = const <StatsDay>[]}): _days = days;
  factory _TokensPerDay.fromJson(Map<String, dynamic> json) => _$TokensPerDayFromJson(json);

@override final  int value;
 final  List<StatsDay> _days;
@override@JsonKey() List<StatsDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}


/// Create a copy of TokensPerDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokensPerDayCopyWith<_TokensPerDay> get copyWith => __$TokensPerDayCopyWithImpl<_TokensPerDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokensPerDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokensPerDay&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other._days, _days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,const DeepCollectionEquality().hash(_days));

@override
String toString() {
  return 'TokensPerDay(value: $value, days: $days)';
}


}

/// @nodoc
abstract mixin class _$TokensPerDayCopyWith<$Res> implements $TokensPerDayCopyWith<$Res> {
  factory _$TokensPerDayCopyWith(_TokensPerDay value, $Res Function(_TokensPerDay) _then) = __$TokensPerDayCopyWithImpl;
@override @useResult
$Res call({
 int value, List<StatsDay> days
});




}
/// @nodoc
class __$TokensPerDayCopyWithImpl<$Res>
    implements _$TokensPerDayCopyWith<$Res> {
  __$TokensPerDayCopyWithImpl(this._self, this._then);

  final _TokensPerDay _self;
  final $Res Function(_TokensPerDay) _then;

/// Create a copy of TokensPerDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? days = null,}) {
  return _then(_TokensPerDay(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<StatsDay>,
  ));
}


}


/// @nodoc
mixin _$StatsDay {

/// Local date, `YYYY-MM-DD`.
 String get date; int get tokens;
/// Create a copy of StatsDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsDayCopyWith<StatsDay> get copyWith => _$StatsDayCopyWithImpl<StatsDay>(this as StatsDay, _$identity);

  /// Serializes this StatsDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsDay&&(identical(other.date, date) || other.date == date)&&(identical(other.tokens, tokens) || other.tokens == tokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,tokens);

@override
String toString() {
  return 'StatsDay(date: $date, tokens: $tokens)';
}


}

/// @nodoc
abstract mixin class $StatsDayCopyWith<$Res>  {
  factory $StatsDayCopyWith(StatsDay value, $Res Function(StatsDay) _then) = _$StatsDayCopyWithImpl;
@useResult
$Res call({
 String date, int tokens
});




}
/// @nodoc
class _$StatsDayCopyWithImpl<$Res>
    implements $StatsDayCopyWith<$Res> {
  _$StatsDayCopyWithImpl(this._self, this._then);

  final StatsDay _self;
  final $Res Function(StatsDay) _then;

/// Create a copy of StatsDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? tokens = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsDay].
extension StatsDayPatterns on StatsDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsDay value)  $default,){
final _that = this;
switch (_that) {
case _StatsDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsDay value)?  $default,){
final _that = this;
switch (_that) {
case _StatsDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  int tokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsDay() when $default != null:
return $default(_that.date,_that.tokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  int tokens)  $default,) {final _that = this;
switch (_that) {
case _StatsDay():
return $default(_that.date,_that.tokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  int tokens)?  $default,) {final _that = this;
switch (_that) {
case _StatsDay() when $default != null:
return $default(_that.date,_that.tokens);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsDay implements StatsDay {
  const _StatsDay({required this.date, required this.tokens});
  factory _StatsDay.fromJson(Map<String, dynamic> json) => _$StatsDayFromJson(json);

/// Local date, `YYYY-MM-DD`.
@override final  String date;
@override final  int tokens;

/// Create a copy of StatsDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsDayCopyWith<_StatsDay> get copyWith => __$StatsDayCopyWithImpl<_StatsDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsDay&&(identical(other.date, date) || other.date == date)&&(identical(other.tokens, tokens) || other.tokens == tokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,tokens);

@override
String toString() {
  return 'StatsDay(date: $date, tokens: $tokens)';
}


}

/// @nodoc
abstract mixin class _$StatsDayCopyWith<$Res> implements $StatsDayCopyWith<$Res> {
  factory _$StatsDayCopyWith(_StatsDay value, $Res Function(_StatsDay) _then) = __$StatsDayCopyWithImpl;
@override @useResult
$Res call({
 String date, int tokens
});




}
/// @nodoc
class __$StatsDayCopyWithImpl<$Res>
    implements _$StatsDayCopyWith<$Res> {
  __$StatsDayCopyWithImpl(this._self, this._then);

  final _StatsDay _self;
  final $Res Function(_StatsDay) _then;

/// Create a copy of StatsDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? tokens = null,}) {
  return _then(_StatsDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StatsGpu {

 int get index; String? get name; StatsSeries get temp; StatsSeries get power;
/// Create a copy of StatsGpu
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsGpuCopyWith<StatsGpu> get copyWith => _$StatsGpuCopyWithImpl<StatsGpu>(this as StatsGpu, _$identity);

  /// Serializes this StatsGpu to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsGpu&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.temp, temp) || other.temp == temp)&&(identical(other.power, power) || other.power == power));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,name,temp,power);

@override
String toString() {
  return 'StatsGpu(index: $index, name: $name, temp: $temp, power: $power)';
}


}

/// @nodoc
abstract mixin class $StatsGpuCopyWith<$Res>  {
  factory $StatsGpuCopyWith(StatsGpu value, $Res Function(StatsGpu) _then) = _$StatsGpuCopyWithImpl;
@useResult
$Res call({
 int index, String? name, StatsSeries temp, StatsSeries power
});


$StatsSeriesCopyWith<$Res> get temp;$StatsSeriesCopyWith<$Res> get power;

}
/// @nodoc
class _$StatsGpuCopyWithImpl<$Res>
    implements $StatsGpuCopyWith<$Res> {
  _$StatsGpuCopyWithImpl(this._self, this._then);

  final StatsGpu _self;
  final $Res Function(StatsGpu) _then;

/// Create a copy of StatsGpu
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? name = freezed,Object? temp = null,Object? power = null,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,temp: null == temp ? _self.temp : temp // ignore: cast_nullable_to_non_nullable
as StatsSeries,power: null == power ? _self.power : power // ignore: cast_nullable_to_non_nullable
as StatsSeries,
  ));
}
/// Create a copy of StatsGpu
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get temp {
  
  return $StatsSeriesCopyWith<$Res>(_self.temp, (value) {
    return _then(_self.copyWith(temp: value));
  });
}/// Create a copy of StatsGpu
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get power {
  
  return $StatsSeriesCopyWith<$Res>(_self.power, (value) {
    return _then(_self.copyWith(power: value));
  });
}
}


/// Adds pattern-matching-related methods to [StatsGpu].
extension StatsGpuPatterns on StatsGpu {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsGpu value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsGpu() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsGpu value)  $default,){
final _that = this;
switch (_that) {
case _StatsGpu():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsGpu value)?  $default,){
final _that = this;
switch (_that) {
case _StatsGpu() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String? name,  StatsSeries temp,  StatsSeries power)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsGpu() when $default != null:
return $default(_that.index,_that.name,_that.temp,_that.power);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String? name,  StatsSeries temp,  StatsSeries power)  $default,) {final _that = this;
switch (_that) {
case _StatsGpu():
return $default(_that.index,_that.name,_that.temp,_that.power);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String? name,  StatsSeries temp,  StatsSeries power)?  $default,) {final _that = this;
switch (_that) {
case _StatsGpu() when $default != null:
return $default(_that.index,_that.name,_that.temp,_that.power);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsGpu implements StatsGpu {
  const _StatsGpu({required this.index, this.name, required this.temp, required this.power});
  factory _StatsGpu.fromJson(Map<String, dynamic> json) => _$StatsGpuFromJson(json);

@override final  int index;
@override final  String? name;
@override final  StatsSeries temp;
@override final  StatsSeries power;

/// Create a copy of StatsGpu
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsGpuCopyWith<_StatsGpu> get copyWith => __$StatsGpuCopyWithImpl<_StatsGpu>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsGpuToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsGpu&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.temp, temp) || other.temp == temp)&&(identical(other.power, power) || other.power == power));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,name,temp,power);

@override
String toString() {
  return 'StatsGpu(index: $index, name: $name, temp: $temp, power: $power)';
}


}

/// @nodoc
abstract mixin class _$StatsGpuCopyWith<$Res> implements $StatsGpuCopyWith<$Res> {
  factory _$StatsGpuCopyWith(_StatsGpu value, $Res Function(_StatsGpu) _then) = __$StatsGpuCopyWithImpl;
@override @useResult
$Res call({
 int index, String? name, StatsSeries temp, StatsSeries power
});


@override $StatsSeriesCopyWith<$Res> get temp;@override $StatsSeriesCopyWith<$Res> get power;

}
/// @nodoc
class __$StatsGpuCopyWithImpl<$Res>
    implements _$StatsGpuCopyWith<$Res> {
  __$StatsGpuCopyWithImpl(this._self, this._then);

  final _StatsGpu _self;
  final $Res Function(_StatsGpu) _then;

/// Create a copy of StatsGpu
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? name = freezed,Object? temp = null,Object? power = null,}) {
  return _then(_StatsGpu(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,temp: null == temp ? _self.temp : temp // ignore: cast_nullable_to_non_nullable
as StatsSeries,power: null == power ? _self.power : power // ignore: cast_nullable_to_non_nullable
as StatsSeries,
  ));
}

/// Create a copy of StatsGpu
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get temp {
  
  return $StatsSeriesCopyWith<$Res>(_self.temp, (value) {
    return _then(_self.copyWith(temp: value));
  });
}/// Create a copy of StatsGpu
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsSeriesCopyWith<$Res> get power {
  
  return $StatsSeriesCopyWith<$Res>(_self.power, (value) {
    return _then(_self.copyWith(power: value));
  });
}
}


/// @nodoc
mixin _$StatsSampling {

 int get intervalS; bool get ok; String? get error; DateTime? get lastAt;
/// Create a copy of StatsSampling
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsSamplingCopyWith<StatsSampling> get copyWith => _$StatsSamplingCopyWithImpl<StatsSampling>(this as StatsSampling, _$identity);

  /// Serializes this StatsSampling to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsSampling&&(identical(other.intervalS, intervalS) || other.intervalS == intervalS)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.lastAt, lastAt) || other.lastAt == lastAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intervalS,ok,error,lastAt);

@override
String toString() {
  return 'StatsSampling(intervalS: $intervalS, ok: $ok, error: $error, lastAt: $lastAt)';
}


}

/// @nodoc
abstract mixin class $StatsSamplingCopyWith<$Res>  {
  factory $StatsSamplingCopyWith(StatsSampling value, $Res Function(StatsSampling) _then) = _$StatsSamplingCopyWithImpl;
@useResult
$Res call({
 int intervalS, bool ok, String? error, DateTime? lastAt
});




}
/// @nodoc
class _$StatsSamplingCopyWithImpl<$Res>
    implements $StatsSamplingCopyWith<$Res> {
  _$StatsSamplingCopyWithImpl(this._self, this._then);

  final StatsSampling _self;
  final $Res Function(StatsSampling) _then;

/// Create a copy of StatsSampling
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intervalS = null,Object? ok = null,Object? error = freezed,Object? lastAt = freezed,}) {
  return _then(_self.copyWith(
intervalS: null == intervalS ? _self.intervalS : intervalS // ignore: cast_nullable_to_non_nullable
as int,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,lastAt: freezed == lastAt ? _self.lastAt : lastAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsSampling].
extension StatsSamplingPatterns on StatsSampling {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsSampling value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsSampling() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsSampling value)  $default,){
final _that = this;
switch (_that) {
case _StatsSampling():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsSampling value)?  $default,){
final _that = this;
switch (_that) {
case _StatsSampling() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int intervalS,  bool ok,  String? error,  DateTime? lastAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsSampling() when $default != null:
return $default(_that.intervalS,_that.ok,_that.error,_that.lastAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int intervalS,  bool ok,  String? error,  DateTime? lastAt)  $default,) {final _that = this;
switch (_that) {
case _StatsSampling():
return $default(_that.intervalS,_that.ok,_that.error,_that.lastAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int intervalS,  bool ok,  String? error,  DateTime? lastAt)?  $default,) {final _that = this;
switch (_that) {
case _StatsSampling() when $default != null:
return $default(_that.intervalS,_that.ok,_that.error,_that.lastAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsSampling implements StatsSampling {
  const _StatsSampling({required this.intervalS, required this.ok, this.error, this.lastAt});
  factory _StatsSampling.fromJson(Map<String, dynamic> json) => _$StatsSamplingFromJson(json);

@override final  int intervalS;
@override final  bool ok;
@override final  String? error;
@override final  DateTime? lastAt;

/// Create a copy of StatsSampling
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsSamplingCopyWith<_StatsSampling> get copyWith => __$StatsSamplingCopyWithImpl<_StatsSampling>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsSamplingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsSampling&&(identical(other.intervalS, intervalS) || other.intervalS == intervalS)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.lastAt, lastAt) || other.lastAt == lastAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intervalS,ok,error,lastAt);

@override
String toString() {
  return 'StatsSampling(intervalS: $intervalS, ok: $ok, error: $error, lastAt: $lastAt)';
}


}

/// @nodoc
abstract mixin class _$StatsSamplingCopyWith<$Res> implements $StatsSamplingCopyWith<$Res> {
  factory _$StatsSamplingCopyWith(_StatsSampling value, $Res Function(_StatsSampling) _then) = __$StatsSamplingCopyWithImpl;
@override @useResult
$Res call({
 int intervalS, bool ok, String? error, DateTime? lastAt
});




}
/// @nodoc
class __$StatsSamplingCopyWithImpl<$Res>
    implements _$StatsSamplingCopyWith<$Res> {
  __$StatsSamplingCopyWithImpl(this._self, this._then);

  final _StatsSampling _self;
  final $Res Function(_StatsSampling) _then;

/// Create a copy of StatsSampling
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intervalS = null,Object? ok = null,Object? error = freezed,Object? lastAt = freezed,}) {
  return _then(_StatsSampling(
intervalS: null == intervalS ? _self.intervalS : intervalS // ignore: cast_nullable_to_non_nullable
as int,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,lastAt: freezed == lastAt ? _self.lastAt : lastAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
