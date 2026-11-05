import 'package:flutter/services.dart';

/// The phone's side of the Files tab: a scratch folder, the public
/// Downloads/Delve folder and other apps (tests: a fake).
abstract interface class DeviceFiles {
  /// A folder in the app's cache for downloads in progress and previews.
  Future<String> scratchDir();

  /// Moves the finished download at [path] into Downloads/Delve as [name]
  /// (MediaStore: no storage permission; a name already there gets a
  /// number). Returns the new entry's `content://` URI.
  Future<String> publish(String path, String name, String mime);

  /// Opens [uri] in another app; false when none can.
  Future<bool> open(String uri, String mime);
}

/// MainActivity's `hu.csakos.delve/files` channel.
class ChannelDeviceFiles implements DeviceFiles {
  const ChannelDeviceFiles();

  static const _channel = MethodChannel('hu.csakos.delve/files');

  @override
  Future<String> scratchDir() async =>
      (await _channel.invokeMethod<String>('scratchDir'))!;

  @override
  Future<String> publish(String path, String name, String mime) async =>
      (await _channel.invokeMethod<String>('publish', {
        'path': path,
        'name': name,
        'mime': mime,
      }))!;

  @override
  Future<bool> open(String uri, String mime) async =>
      await _channel.invokeMethod<bool>('open', {'uri': uri, 'mime': mime}) ??
      false;
}

/// Where the downloads land, as the user sees it.
const kDownloadFolder = 'Downloads/Delve';
