// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SystemInfo {

 DateTime get checkedAt; HelperState get helper; HermesInfo get hermes; LlamaInfo get llama; QueueInfo get queue;/// null without the helper (no GPU data at all).
 List<GpuInfo>? get gpus;
/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemInfoCopyWith<SystemInfo> get copyWith => _$SystemInfoCopyWithImpl<SystemInfo>(this as SystemInfo, _$identity);

  /// Serializes this SystemInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemInfo&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.helper, helper) || other.helper == helper)&&(identical(other.hermes, hermes) || other.hermes == hermes)&&(identical(other.llama, llama) || other.llama == llama)&&(identical(other.queue, queue) || other.queue == queue)&&const DeepCollectionEquality().equals(other.gpus, gpus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,checkedAt,helper,hermes,llama,queue,const DeepCollectionEquality().hash(gpus));

@override
String toString() {
  return 'SystemInfo(checkedAt: $checkedAt, helper: $helper, hermes: $hermes, llama: $llama, queue: $queue, gpus: $gpus)';
}


}

/// @nodoc
abstract mixin class $SystemInfoCopyWith<$Res>  {
  factory $SystemInfoCopyWith(SystemInfo value, $Res Function(SystemInfo) _then) = _$SystemInfoCopyWithImpl;
@useResult
$Res call({
 DateTime checkedAt, HelperState helper, HermesInfo hermes, LlamaInfo llama, QueueInfo queue, List<GpuInfo>? gpus
});


$HelperStateCopyWith<$Res> get helper;$HermesInfoCopyWith<$Res> get hermes;$LlamaInfoCopyWith<$Res> get llama;$QueueInfoCopyWith<$Res> get queue;

}
/// @nodoc
class _$SystemInfoCopyWithImpl<$Res>
    implements $SystemInfoCopyWith<$Res> {
  _$SystemInfoCopyWithImpl(this._self, this._then);

  final SystemInfo _self;
  final $Res Function(SystemInfo) _then;

/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? checkedAt = null,Object? helper = null,Object? hermes = null,Object? llama = null,Object? queue = null,Object? gpus = freezed,}) {
  return _then(_self.copyWith(
checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,helper: null == helper ? _self.helper : helper // ignore: cast_nullable_to_non_nullable
as HelperState,hermes: null == hermes ? _self.hermes : hermes // ignore: cast_nullable_to_non_nullable
as HermesInfo,llama: null == llama ? _self.llama : llama // ignore: cast_nullable_to_non_nullable
as LlamaInfo,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as QueueInfo,gpus: freezed == gpus ? _self.gpus : gpus // ignore: cast_nullable_to_non_nullable
as List<GpuInfo>?,
  ));
}
/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelperStateCopyWith<$Res> get helper {
  
  return $HelperStateCopyWith<$Res>(_self.helper, (value) {
    return _then(_self.copyWith(helper: value));
  });
}/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HermesInfoCopyWith<$Res> get hermes {
  
  return $HermesInfoCopyWith<$Res>(_self.hermes, (value) {
    return _then(_self.copyWith(hermes: value));
  });
}/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LlamaInfoCopyWith<$Res> get llama {
  
  return $LlamaInfoCopyWith<$Res>(_self.llama, (value) {
    return _then(_self.copyWith(llama: value));
  });
}/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueInfoCopyWith<$Res> get queue {
  
  return $QueueInfoCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}
}


/// Adds pattern-matching-related methods to [SystemInfo].
extension SystemInfoPatterns on SystemInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SystemInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SystemInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SystemInfo value)  $default,){
final _that = this;
switch (_that) {
case _SystemInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SystemInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SystemInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime checkedAt,  HelperState helper,  HermesInfo hermes,  LlamaInfo llama,  QueueInfo queue,  List<GpuInfo>? gpus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SystemInfo() when $default != null:
return $default(_that.checkedAt,_that.helper,_that.hermes,_that.llama,_that.queue,_that.gpus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime checkedAt,  HelperState helper,  HermesInfo hermes,  LlamaInfo llama,  QueueInfo queue,  List<GpuInfo>? gpus)  $default,) {final _that = this;
switch (_that) {
case _SystemInfo():
return $default(_that.checkedAt,_that.helper,_that.hermes,_that.llama,_that.queue,_that.gpus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime checkedAt,  HelperState helper,  HermesInfo hermes,  LlamaInfo llama,  QueueInfo queue,  List<GpuInfo>? gpus)?  $default,) {final _that = this;
switch (_that) {
case _SystemInfo() when $default != null:
return $default(_that.checkedAt,_that.helper,_that.hermes,_that.llama,_that.queue,_that.gpus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SystemInfo implements SystemInfo {
  const _SystemInfo({required this.checkedAt, required this.helper, required this.hermes, required this.llama, required this.queue, final  List<GpuInfo>? gpus}): _gpus = gpus;
  factory _SystemInfo.fromJson(Map<String, dynamic> json) => _$SystemInfoFromJson(json);

@override final  DateTime checkedAt;
@override final  HelperState helper;
@override final  HermesInfo hermes;
@override final  LlamaInfo llama;
@override final  QueueInfo queue;
/// null without the helper (no GPU data at all).
 final  List<GpuInfo>? _gpus;
/// null without the helper (no GPU data at all).
@override List<GpuInfo>? get gpus {
  final value = _gpus;
  if (value == null) return null;
  if (_gpus is EqualUnmodifiableListView) return _gpus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SystemInfoCopyWith<_SystemInfo> get copyWith => __$SystemInfoCopyWithImpl<_SystemInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SystemInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SystemInfo&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.helper, helper) || other.helper == helper)&&(identical(other.hermes, hermes) || other.hermes == hermes)&&(identical(other.llama, llama) || other.llama == llama)&&(identical(other.queue, queue) || other.queue == queue)&&const DeepCollectionEquality().equals(other._gpus, _gpus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,checkedAt,helper,hermes,llama,queue,const DeepCollectionEquality().hash(_gpus));

@override
String toString() {
  return 'SystemInfo(checkedAt: $checkedAt, helper: $helper, hermes: $hermes, llama: $llama, queue: $queue, gpus: $gpus)';
}


}

/// @nodoc
abstract mixin class _$SystemInfoCopyWith<$Res> implements $SystemInfoCopyWith<$Res> {
  factory _$SystemInfoCopyWith(_SystemInfo value, $Res Function(_SystemInfo) _then) = __$SystemInfoCopyWithImpl;
@override @useResult
$Res call({
 DateTime checkedAt, HelperState helper, HermesInfo hermes, LlamaInfo llama, QueueInfo queue, List<GpuInfo>? gpus
});


@override $HelperStateCopyWith<$Res> get helper;@override $HermesInfoCopyWith<$Res> get hermes;@override $LlamaInfoCopyWith<$Res> get llama;@override $QueueInfoCopyWith<$Res> get queue;

}
/// @nodoc
class __$SystemInfoCopyWithImpl<$Res>
    implements _$SystemInfoCopyWith<$Res> {
  __$SystemInfoCopyWithImpl(this._self, this._then);

  final _SystemInfo _self;
  final $Res Function(_SystemInfo) _then;

/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? checkedAt = null,Object? helper = null,Object? hermes = null,Object? llama = null,Object? queue = null,Object? gpus = freezed,}) {
  return _then(_SystemInfo(
checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,helper: null == helper ? _self.helper : helper // ignore: cast_nullable_to_non_nullable
as HelperState,hermes: null == hermes ? _self.hermes : hermes // ignore: cast_nullable_to_non_nullable
as HermesInfo,llama: null == llama ? _self.llama : llama // ignore: cast_nullable_to_non_nullable
as LlamaInfo,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as QueueInfo,gpus: freezed == gpus ? _self._gpus : gpus // ignore: cast_nullable_to_non_nullable
as List<GpuInfo>?,
  ));
}

/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelperStateCopyWith<$Res> get helper {
  
  return $HelperStateCopyWith<$Res>(_self.helper, (value) {
    return _then(_self.copyWith(helper: value));
  });
}/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HermesInfoCopyWith<$Res> get hermes {
  
  return $HermesInfoCopyWith<$Res>(_self.hermes, (value) {
    return _then(_self.copyWith(hermes: value));
  });
}/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LlamaInfoCopyWith<$Res> get llama {
  
  return $LlamaInfoCopyWith<$Res>(_self.llama, (value) {
    return _then(_self.copyWith(llama: value));
  });
}/// Create a copy of SystemInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueInfoCopyWith<$Res> get queue {
  
  return $QueueInfoCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}
}


/// @nodoc
mixin _$HelperState {

 bool get ok; String? get error;
/// Create a copy of HelperState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelperStateCopyWith<HelperState> get copyWith => _$HelperStateCopyWithImpl<HelperState>(this as HelperState, _$identity);

  /// Serializes this HelperState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelperState&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,error);

@override
String toString() {
  return 'HelperState(ok: $ok, error: $error)';
}


}

/// @nodoc
abstract mixin class $HelperStateCopyWith<$Res>  {
  factory $HelperStateCopyWith(HelperState value, $Res Function(HelperState) _then) = _$HelperStateCopyWithImpl;
@useResult
$Res call({
 bool ok, String? error
});




}
/// @nodoc
class _$HelperStateCopyWithImpl<$Res>
    implements $HelperStateCopyWith<$Res> {
  _$HelperStateCopyWithImpl(this._self, this._then);

  final HelperState _self;
  final $Res Function(HelperState) _then;

/// Create a copy of HelperState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HelperState].
extension HelperStatePatterns on HelperState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelperState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelperState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelperState value)  $default,){
final _that = this;
switch (_that) {
case _HelperState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelperState value)?  $default,){
final _that = this;
switch (_that) {
case _HelperState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelperState() when $default != null:
return $default(_that.ok,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok,  String? error)  $default,) {final _that = this;
switch (_that) {
case _HelperState():
return $default(_that.ok,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _HelperState() when $default != null:
return $default(_that.ok,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelperState implements HelperState {
  const _HelperState({required this.ok, this.error});
  factory _HelperState.fromJson(Map<String, dynamic> json) => _$HelperStateFromJson(json);

@override final  bool ok;
@override final  String? error;

/// Create a copy of HelperState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelperStateCopyWith<_HelperState> get copyWith => __$HelperStateCopyWithImpl<_HelperState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelperStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelperState&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,error);

@override
String toString() {
  return 'HelperState(ok: $ok, error: $error)';
}


}

/// @nodoc
abstract mixin class _$HelperStateCopyWith<$Res> implements $HelperStateCopyWith<$Res> {
  factory _$HelperStateCopyWith(_HelperState value, $Res Function(_HelperState) _then) = __$HelperStateCopyWithImpl;
@override @useResult
$Res call({
 bool ok, String? error
});




}
/// @nodoc
class __$HelperStateCopyWithImpl<$Res>
    implements _$HelperStateCopyWith<$Res> {
  __$HelperStateCopyWithImpl(this._self, this._then);

  final _HelperState _self;
  final $Res Function(_HelperState) _then;

/// Create a copy of HelperState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,Object? error = freezed,}) {
  return _then(_HelperState(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$HermesInfo {

 String get status; String? get version; DateTime? get since; List<HermesIssue> get issues;
/// Create a copy of HermesInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HermesInfoCopyWith<HermesInfo> get copyWith => _$HermesInfoCopyWithImpl<HermesInfo>(this as HermesInfo, _$identity);

  /// Serializes this HermesInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HermesInfo&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.since, since) || other.since == since)&&const DeepCollectionEquality().equals(other.issues, issues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,version,since,const DeepCollectionEquality().hash(issues));

@override
String toString() {
  return 'HermesInfo(status: $status, version: $version, since: $since, issues: $issues)';
}


}

/// @nodoc
abstract mixin class $HermesInfoCopyWith<$Res>  {
  factory $HermesInfoCopyWith(HermesInfo value, $Res Function(HermesInfo) _then) = _$HermesInfoCopyWithImpl;
@useResult
$Res call({
 String status, String? version, DateTime? since, List<HermesIssue> issues
});




}
/// @nodoc
class _$HermesInfoCopyWithImpl<$Res>
    implements $HermesInfoCopyWith<$Res> {
  _$HermesInfoCopyWithImpl(this._self, this._then);

  final HermesInfo _self;
  final $Res Function(HermesInfo) _then;

/// Create a copy of HermesInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? version = freezed,Object? since = freezed,Object? issues = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,since: freezed == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime?,issues: null == issues ? _self.issues : issues // ignore: cast_nullable_to_non_nullable
as List<HermesIssue>,
  ));
}

}


/// Adds pattern-matching-related methods to [HermesInfo].
extension HermesInfoPatterns on HermesInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HermesInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HermesInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HermesInfo value)  $default,){
final _that = this;
switch (_that) {
case _HermesInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HermesInfo value)?  $default,){
final _that = this;
switch (_that) {
case _HermesInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? version,  DateTime? since,  List<HermesIssue> issues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HermesInfo() when $default != null:
return $default(_that.status,_that.version,_that.since,_that.issues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? version,  DateTime? since,  List<HermesIssue> issues)  $default,) {final _that = this;
switch (_that) {
case _HermesInfo():
return $default(_that.status,_that.version,_that.since,_that.issues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? version,  DateTime? since,  List<HermesIssue> issues)?  $default,) {final _that = this;
switch (_that) {
case _HermesInfo() when $default != null:
return $default(_that.status,_that.version,_that.since,_that.issues);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HermesInfo implements HermesInfo {
  const _HermesInfo({required this.status, this.version, this.since, final  List<HermesIssue> issues = const <HermesIssue>[]}): _issues = issues;
  factory _HermesInfo.fromJson(Map<String, dynamic> json) => _$HermesInfoFromJson(json);

@override final  String status;
@override final  String? version;
@override final  DateTime? since;
 final  List<HermesIssue> _issues;
@override@JsonKey() List<HermesIssue> get issues {
  if (_issues is EqualUnmodifiableListView) return _issues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issues);
}


/// Create a copy of HermesInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HermesInfoCopyWith<_HermesInfo> get copyWith => __$HermesInfoCopyWithImpl<_HermesInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HermesInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HermesInfo&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.since, since) || other.since == since)&&const DeepCollectionEquality().equals(other._issues, _issues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,version,since,const DeepCollectionEquality().hash(_issues));

@override
String toString() {
  return 'HermesInfo(status: $status, version: $version, since: $since, issues: $issues)';
}


}

/// @nodoc
abstract mixin class _$HermesInfoCopyWith<$Res> implements $HermesInfoCopyWith<$Res> {
  factory _$HermesInfoCopyWith(_HermesInfo value, $Res Function(_HermesInfo) _then) = __$HermesInfoCopyWithImpl;
@override @useResult
$Res call({
 String status, String? version, DateTime? since, List<HermesIssue> issues
});




}
/// @nodoc
class __$HermesInfoCopyWithImpl<$Res>
    implements _$HermesInfoCopyWith<$Res> {
  __$HermesInfoCopyWithImpl(this._self, this._then);

  final _HermesInfo _self;
  final $Res Function(_HermesInfo) _then;

/// Create a copy of HermesInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? version = freezed,Object? since = freezed,Object? issues = null,}) {
  return _then(_HermesInfo(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,since: freezed == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime?,issues: null == issues ? _self._issues : issues // ignore: cast_nullable_to_non_nullable
as List<HermesIssue>,
  ));
}


}


/// @nodoc
mixin _$HermesIssue {

 String get check; String get status; String? get detail;
/// Create a copy of HermesIssue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HermesIssueCopyWith<HermesIssue> get copyWith => _$HermesIssueCopyWithImpl<HermesIssue>(this as HermesIssue, _$identity);

  /// Serializes this HermesIssue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HermesIssue&&(identical(other.check, check) || other.check == check)&&(identical(other.status, status) || other.status == status)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,check,status,detail);

@override
String toString() {
  return 'HermesIssue(check: $check, status: $status, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $HermesIssueCopyWith<$Res>  {
  factory $HermesIssueCopyWith(HermesIssue value, $Res Function(HermesIssue) _then) = _$HermesIssueCopyWithImpl;
@useResult
$Res call({
 String check, String status, String? detail
});




}
/// @nodoc
class _$HermesIssueCopyWithImpl<$Res>
    implements $HermesIssueCopyWith<$Res> {
  _$HermesIssueCopyWithImpl(this._self, this._then);

  final HermesIssue _self;
  final $Res Function(HermesIssue) _then;

/// Create a copy of HermesIssue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? check = null,Object? status = null,Object? detail = freezed,}) {
  return _then(_self.copyWith(
check: null == check ? _self.check : check // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HermesIssue].
extension HermesIssuePatterns on HermesIssue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HermesIssue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HermesIssue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HermesIssue value)  $default,){
final _that = this;
switch (_that) {
case _HermesIssue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HermesIssue value)?  $default,){
final _that = this;
switch (_that) {
case _HermesIssue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String check,  String status,  String? detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HermesIssue() when $default != null:
return $default(_that.check,_that.status,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String check,  String status,  String? detail)  $default,) {final _that = this;
switch (_that) {
case _HermesIssue():
return $default(_that.check,_that.status,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String check,  String status,  String? detail)?  $default,) {final _that = this;
switch (_that) {
case _HermesIssue() when $default != null:
return $default(_that.check,_that.status,_that.detail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HermesIssue implements HermesIssue {
  const _HermesIssue({required this.check, required this.status, this.detail});
  factory _HermesIssue.fromJson(Map<String, dynamic> json) => _$HermesIssueFromJson(json);

@override final  String check;
@override final  String status;
@override final  String? detail;

/// Create a copy of HermesIssue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HermesIssueCopyWith<_HermesIssue> get copyWith => __$HermesIssueCopyWithImpl<_HermesIssue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HermesIssueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HermesIssue&&(identical(other.check, check) || other.check == check)&&(identical(other.status, status) || other.status == status)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,check,status,detail);

@override
String toString() {
  return 'HermesIssue(check: $check, status: $status, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$HermesIssueCopyWith<$Res> implements $HermesIssueCopyWith<$Res> {
  factory _$HermesIssueCopyWith(_HermesIssue value, $Res Function(_HermesIssue) _then) = __$HermesIssueCopyWithImpl;
@override @useResult
$Res call({
 String check, String status, String? detail
});




}
/// @nodoc
class __$HermesIssueCopyWithImpl<$Res>
    implements _$HermesIssueCopyWith<$Res> {
  __$HermesIssueCopyWithImpl(this._self, this._then);

  final _HermesIssue _self;
  final $Res Function(_HermesIssue) _then;

/// Create a copy of HermesIssue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? check = null,Object? status = null,Object? detail = freezed,}) {
  return _then(_HermesIssue(
check: null == check ? _self.check : check // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LlamaInfo {

 String get status; String? get intent; DateTime? get since; String? get model; String? get quant; int? get ctx; int? get slots; int? get slotsBusy;/// The last completed run's generation speed, tok/s.
 double? get genTps;
/// Create a copy of LlamaInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LlamaInfoCopyWith<LlamaInfo> get copyWith => _$LlamaInfoCopyWithImpl<LlamaInfo>(this as LlamaInfo, _$identity);

  /// Serializes this LlamaInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LlamaInfo&&(identical(other.status, status) || other.status == status)&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.since, since) || other.since == since)&&(identical(other.model, model) || other.model == model)&&(identical(other.quant, quant) || other.quant == quant)&&(identical(other.ctx, ctx) || other.ctx == ctx)&&(identical(other.slots, slots) || other.slots == slots)&&(identical(other.slotsBusy, slotsBusy) || other.slotsBusy == slotsBusy)&&(identical(other.genTps, genTps) || other.genTps == genTps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,intent,since,model,quant,ctx,slots,slotsBusy,genTps);

@override
String toString() {
  return 'LlamaInfo(status: $status, intent: $intent, since: $since, model: $model, quant: $quant, ctx: $ctx, slots: $slots, slotsBusy: $slotsBusy, genTps: $genTps)';
}


}

/// @nodoc
abstract mixin class $LlamaInfoCopyWith<$Res>  {
  factory $LlamaInfoCopyWith(LlamaInfo value, $Res Function(LlamaInfo) _then) = _$LlamaInfoCopyWithImpl;
@useResult
$Res call({
 String status, String? intent, DateTime? since, String? model, String? quant, int? ctx, int? slots, int? slotsBusy, double? genTps
});




}
/// @nodoc
class _$LlamaInfoCopyWithImpl<$Res>
    implements $LlamaInfoCopyWith<$Res> {
  _$LlamaInfoCopyWithImpl(this._self, this._then);

  final LlamaInfo _self;
  final $Res Function(LlamaInfo) _then;

/// Create a copy of LlamaInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? intent = freezed,Object? since = freezed,Object? model = freezed,Object? quant = freezed,Object? ctx = freezed,Object? slots = freezed,Object? slotsBusy = freezed,Object? genTps = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,intent: freezed == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as String?,since: freezed == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,quant: freezed == quant ? _self.quant : quant // ignore: cast_nullable_to_non_nullable
as String?,ctx: freezed == ctx ? _self.ctx : ctx // ignore: cast_nullable_to_non_nullable
as int?,slots: freezed == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as int?,slotsBusy: freezed == slotsBusy ? _self.slotsBusy : slotsBusy // ignore: cast_nullable_to_non_nullable
as int?,genTps: freezed == genTps ? _self.genTps : genTps // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [LlamaInfo].
extension LlamaInfoPatterns on LlamaInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LlamaInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LlamaInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LlamaInfo value)  $default,){
final _that = this;
switch (_that) {
case _LlamaInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LlamaInfo value)?  $default,){
final _that = this;
switch (_that) {
case _LlamaInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? intent,  DateTime? since,  String? model,  String? quant,  int? ctx,  int? slots,  int? slotsBusy,  double? genTps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LlamaInfo() when $default != null:
return $default(_that.status,_that.intent,_that.since,_that.model,_that.quant,_that.ctx,_that.slots,_that.slotsBusy,_that.genTps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? intent,  DateTime? since,  String? model,  String? quant,  int? ctx,  int? slots,  int? slotsBusy,  double? genTps)  $default,) {final _that = this;
switch (_that) {
case _LlamaInfo():
return $default(_that.status,_that.intent,_that.since,_that.model,_that.quant,_that.ctx,_that.slots,_that.slotsBusy,_that.genTps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? intent,  DateTime? since,  String? model,  String? quant,  int? ctx,  int? slots,  int? slotsBusy,  double? genTps)?  $default,) {final _that = this;
switch (_that) {
case _LlamaInfo() when $default != null:
return $default(_that.status,_that.intent,_that.since,_that.model,_that.quant,_that.ctx,_that.slots,_that.slotsBusy,_that.genTps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LlamaInfo implements LlamaInfo {
  const _LlamaInfo({required this.status, this.intent, this.since, this.model, this.quant, this.ctx, this.slots, this.slotsBusy, this.genTps});
  factory _LlamaInfo.fromJson(Map<String, dynamic> json) => _$LlamaInfoFromJson(json);

@override final  String status;
@override final  String? intent;
@override final  DateTime? since;
@override final  String? model;
@override final  String? quant;
@override final  int? ctx;
@override final  int? slots;
@override final  int? slotsBusy;
/// The last completed run's generation speed, tok/s.
@override final  double? genTps;

/// Create a copy of LlamaInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LlamaInfoCopyWith<_LlamaInfo> get copyWith => __$LlamaInfoCopyWithImpl<_LlamaInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LlamaInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LlamaInfo&&(identical(other.status, status) || other.status == status)&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.since, since) || other.since == since)&&(identical(other.model, model) || other.model == model)&&(identical(other.quant, quant) || other.quant == quant)&&(identical(other.ctx, ctx) || other.ctx == ctx)&&(identical(other.slots, slots) || other.slots == slots)&&(identical(other.slotsBusy, slotsBusy) || other.slotsBusy == slotsBusy)&&(identical(other.genTps, genTps) || other.genTps == genTps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,intent,since,model,quant,ctx,slots,slotsBusy,genTps);

@override
String toString() {
  return 'LlamaInfo(status: $status, intent: $intent, since: $since, model: $model, quant: $quant, ctx: $ctx, slots: $slots, slotsBusy: $slotsBusy, genTps: $genTps)';
}


}

/// @nodoc
abstract mixin class _$LlamaInfoCopyWith<$Res> implements $LlamaInfoCopyWith<$Res> {
  factory _$LlamaInfoCopyWith(_LlamaInfo value, $Res Function(_LlamaInfo) _then) = __$LlamaInfoCopyWithImpl;
@override @useResult
$Res call({
 String status, String? intent, DateTime? since, String? model, String? quant, int? ctx, int? slots, int? slotsBusy, double? genTps
});




}
/// @nodoc
class __$LlamaInfoCopyWithImpl<$Res>
    implements _$LlamaInfoCopyWith<$Res> {
  __$LlamaInfoCopyWithImpl(this._self, this._then);

  final _LlamaInfo _self;
  final $Res Function(_LlamaInfo) _then;

/// Create a copy of LlamaInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? intent = freezed,Object? since = freezed,Object? model = freezed,Object? quant = freezed,Object? ctx = freezed,Object? slots = freezed,Object? slotsBusy = freezed,Object? genTps = freezed,}) {
  return _then(_LlamaInfo(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,intent: freezed == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as String?,since: freezed == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,quant: freezed == quant ? _self.quant : quant // ignore: cast_nullable_to_non_nullable
as String?,ctx: freezed == ctx ? _self.ctx : ctx // ignore: cast_nullable_to_non_nullable
as int?,slots: freezed == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as int?,slotsBusy: freezed == slotsBusy ? _self.slotsBusy : slotsBusy // ignore: cast_nullable_to_non_nullable
as int?,genTps: freezed == genTps ? _self.genTps : genTps // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$QueueInfo {

 int get active; int get queued;
/// Create a copy of QueueInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueInfoCopyWith<QueueInfo> get copyWith => _$QueueInfoCopyWithImpl<QueueInfo>(this as QueueInfo, _$identity);

  /// Serializes this QueueInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueInfo&&(identical(other.active, active) || other.active == active)&&(identical(other.queued, queued) || other.queued == queued));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,active,queued);

@override
String toString() {
  return 'QueueInfo(active: $active, queued: $queued)';
}


}

/// @nodoc
abstract mixin class $QueueInfoCopyWith<$Res>  {
  factory $QueueInfoCopyWith(QueueInfo value, $Res Function(QueueInfo) _then) = _$QueueInfoCopyWithImpl;
@useResult
$Res call({
 int active, int queued
});




}
/// @nodoc
class _$QueueInfoCopyWithImpl<$Res>
    implements $QueueInfoCopyWith<$Res> {
  _$QueueInfoCopyWithImpl(this._self, this._then);

  final QueueInfo _self;
  final $Res Function(QueueInfo) _then;

/// Create a copy of QueueInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? active = null,Object? queued = null,}) {
  return _then(_self.copyWith(
active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,queued: null == queued ? _self.queued : queued // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueInfo].
extension QueueInfoPatterns on QueueInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueInfo value)  $default,){
final _that = this;
switch (_that) {
case _QueueInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueInfo value)?  $default,){
final _that = this;
switch (_that) {
case _QueueInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int active,  int queued)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueInfo() when $default != null:
return $default(_that.active,_that.queued);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int active,  int queued)  $default,) {final _that = this;
switch (_that) {
case _QueueInfo():
return $default(_that.active,_that.queued);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int active,  int queued)?  $default,) {final _that = this;
switch (_that) {
case _QueueInfo() when $default != null:
return $default(_that.active,_that.queued);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueInfo implements QueueInfo {
  const _QueueInfo({required this.active, required this.queued});
  factory _QueueInfo.fromJson(Map<String, dynamic> json) => _$QueueInfoFromJson(json);

@override final  int active;
@override final  int queued;

/// Create a copy of QueueInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueInfoCopyWith<_QueueInfo> get copyWith => __$QueueInfoCopyWithImpl<_QueueInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueInfo&&(identical(other.active, active) || other.active == active)&&(identical(other.queued, queued) || other.queued == queued));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,active,queued);

@override
String toString() {
  return 'QueueInfo(active: $active, queued: $queued)';
}


}

/// @nodoc
abstract mixin class _$QueueInfoCopyWith<$Res> implements $QueueInfoCopyWith<$Res> {
  factory _$QueueInfoCopyWith(_QueueInfo value, $Res Function(_QueueInfo) _then) = __$QueueInfoCopyWithImpl;
@override @useResult
$Res call({
 int active, int queued
});




}
/// @nodoc
class __$QueueInfoCopyWithImpl<$Res>
    implements _$QueueInfoCopyWith<$Res> {
  __$QueueInfoCopyWithImpl(this._self, this._then);

  final _QueueInfo _self;
  final $Res Function(_QueueInfo) _then;

/// Create a copy of QueueInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? active = null,Object? queued = null,}) {
  return _then(_QueueInfo(
active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,queued: null == queued ? _self.queued : queued // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GpuInfo {

 int get index; String get name; double? get tempC; int? get memUsedMib; int? get memTotalMib; double? get utilPct; double? get powerW; double? get powerLimitW;
/// Create a copy of GpuInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GpuInfoCopyWith<GpuInfo> get copyWith => _$GpuInfoCopyWithImpl<GpuInfo>(this as GpuInfo, _$identity);

  /// Serializes this GpuInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GpuInfo&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.tempC, tempC) || other.tempC == tempC)&&(identical(other.memUsedMib, memUsedMib) || other.memUsedMib == memUsedMib)&&(identical(other.memTotalMib, memTotalMib) || other.memTotalMib == memTotalMib)&&(identical(other.utilPct, utilPct) || other.utilPct == utilPct)&&(identical(other.powerW, powerW) || other.powerW == powerW)&&(identical(other.powerLimitW, powerLimitW) || other.powerLimitW == powerLimitW));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,name,tempC,memUsedMib,memTotalMib,utilPct,powerW,powerLimitW);

@override
String toString() {
  return 'GpuInfo(index: $index, name: $name, tempC: $tempC, memUsedMib: $memUsedMib, memTotalMib: $memTotalMib, utilPct: $utilPct, powerW: $powerW, powerLimitW: $powerLimitW)';
}


}

/// @nodoc
abstract mixin class $GpuInfoCopyWith<$Res>  {
  factory $GpuInfoCopyWith(GpuInfo value, $Res Function(GpuInfo) _then) = _$GpuInfoCopyWithImpl;
@useResult
$Res call({
 int index, String name, double? tempC, int? memUsedMib, int? memTotalMib, double? utilPct, double? powerW, double? powerLimitW
});




}
/// @nodoc
class _$GpuInfoCopyWithImpl<$Res>
    implements $GpuInfoCopyWith<$Res> {
  _$GpuInfoCopyWithImpl(this._self, this._then);

  final GpuInfo _self;
  final $Res Function(GpuInfo) _then;

/// Create a copy of GpuInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? name = null,Object? tempC = freezed,Object? memUsedMib = freezed,Object? memTotalMib = freezed,Object? utilPct = freezed,Object? powerW = freezed,Object? powerLimitW = freezed,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tempC: freezed == tempC ? _self.tempC : tempC // ignore: cast_nullable_to_non_nullable
as double?,memUsedMib: freezed == memUsedMib ? _self.memUsedMib : memUsedMib // ignore: cast_nullable_to_non_nullable
as int?,memTotalMib: freezed == memTotalMib ? _self.memTotalMib : memTotalMib // ignore: cast_nullable_to_non_nullable
as int?,utilPct: freezed == utilPct ? _self.utilPct : utilPct // ignore: cast_nullable_to_non_nullable
as double?,powerW: freezed == powerW ? _self.powerW : powerW // ignore: cast_nullable_to_non_nullable
as double?,powerLimitW: freezed == powerLimitW ? _self.powerLimitW : powerLimitW // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [GpuInfo].
extension GpuInfoPatterns on GpuInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GpuInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GpuInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GpuInfo value)  $default,){
final _that = this;
switch (_that) {
case _GpuInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GpuInfo value)?  $default,){
final _that = this;
switch (_that) {
case _GpuInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String name,  double? tempC,  int? memUsedMib,  int? memTotalMib,  double? utilPct,  double? powerW,  double? powerLimitW)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GpuInfo() when $default != null:
return $default(_that.index,_that.name,_that.tempC,_that.memUsedMib,_that.memTotalMib,_that.utilPct,_that.powerW,_that.powerLimitW);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String name,  double? tempC,  int? memUsedMib,  int? memTotalMib,  double? utilPct,  double? powerW,  double? powerLimitW)  $default,) {final _that = this;
switch (_that) {
case _GpuInfo():
return $default(_that.index,_that.name,_that.tempC,_that.memUsedMib,_that.memTotalMib,_that.utilPct,_that.powerW,_that.powerLimitW);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String name,  double? tempC,  int? memUsedMib,  int? memTotalMib,  double? utilPct,  double? powerW,  double? powerLimitW)?  $default,) {final _that = this;
switch (_that) {
case _GpuInfo() when $default != null:
return $default(_that.index,_that.name,_that.tempC,_that.memUsedMib,_that.memTotalMib,_that.utilPct,_that.powerW,_that.powerLimitW);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GpuInfo implements GpuInfo {
  const _GpuInfo({required this.index, required this.name, this.tempC, this.memUsedMib, this.memTotalMib, this.utilPct, this.powerW, this.powerLimitW});
  factory _GpuInfo.fromJson(Map<String, dynamic> json) => _$GpuInfoFromJson(json);

@override final  int index;
@override final  String name;
@override final  double? tempC;
@override final  int? memUsedMib;
@override final  int? memTotalMib;
@override final  double? utilPct;
@override final  double? powerW;
@override final  double? powerLimitW;

/// Create a copy of GpuInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GpuInfoCopyWith<_GpuInfo> get copyWith => __$GpuInfoCopyWithImpl<_GpuInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GpuInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GpuInfo&&(identical(other.index, index) || other.index == index)&&(identical(other.name, name) || other.name == name)&&(identical(other.tempC, tempC) || other.tempC == tempC)&&(identical(other.memUsedMib, memUsedMib) || other.memUsedMib == memUsedMib)&&(identical(other.memTotalMib, memTotalMib) || other.memTotalMib == memTotalMib)&&(identical(other.utilPct, utilPct) || other.utilPct == utilPct)&&(identical(other.powerW, powerW) || other.powerW == powerW)&&(identical(other.powerLimitW, powerLimitW) || other.powerLimitW == powerLimitW));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,name,tempC,memUsedMib,memTotalMib,utilPct,powerW,powerLimitW);

@override
String toString() {
  return 'GpuInfo(index: $index, name: $name, tempC: $tempC, memUsedMib: $memUsedMib, memTotalMib: $memTotalMib, utilPct: $utilPct, powerW: $powerW, powerLimitW: $powerLimitW)';
}


}

/// @nodoc
abstract mixin class _$GpuInfoCopyWith<$Res> implements $GpuInfoCopyWith<$Res> {
  factory _$GpuInfoCopyWith(_GpuInfo value, $Res Function(_GpuInfo) _then) = __$GpuInfoCopyWithImpl;
@override @useResult
$Res call({
 int index, String name, double? tempC, int? memUsedMib, int? memTotalMib, double? utilPct, double? powerW, double? powerLimitW
});




}
/// @nodoc
class __$GpuInfoCopyWithImpl<$Res>
    implements _$GpuInfoCopyWith<$Res> {
  __$GpuInfoCopyWithImpl(this._self, this._then);

  final _GpuInfo _self;
  final $Res Function(_GpuInfo) _then;

/// Create a copy of GpuInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? name = null,Object? tempC = freezed,Object? memUsedMib = freezed,Object? memTotalMib = freezed,Object? utilPct = freezed,Object? powerW = freezed,Object? powerLimitW = freezed,}) {
  return _then(_GpuInfo(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tempC: freezed == tempC ? _self.tempC : tempC // ignore: cast_nullable_to_non_nullable
as double?,memUsedMib: freezed == memUsedMib ? _self.memUsedMib : memUsedMib // ignore: cast_nullable_to_non_nullable
as int?,memTotalMib: freezed == memTotalMib ? _self.memTotalMib : memTotalMib // ignore: cast_nullable_to_non_nullable
as int?,utilPct: freezed == utilPct ? _self.utilPct : utilPct // ignore: cast_nullable_to_non_nullable
as double?,powerW: freezed == powerW ? _self.powerW : powerW // ignore: cast_nullable_to_non_nullable
as double?,powerLimitW: freezed == powerLimitW ? _self.powerLimitW : powerLimitW // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
