import 'package:flutter/services.dart';

/// The phone's side of the Files tab: a scratch folder, the public
/// Downloads/Delve folder and other apps (tests: a fake).
abstract interface class DeviceFiles {
  /// A folder in the app's cache for downloads in progress and previews.
  Future<String> scratchDir();

  /// Moves the finished download at [path] into Downloads/Delve as [name]
  /// (MediaStore: no storage permission; a name already there gets a
  /// number), or into [folder] under it (`photos/2024`, F3). Returns the new
  /// entry's `content://` URI.
  Future<String> publish(
    String path,
    String name,
    String mime, {
    String? folder,
  });

  /// [name], or `name (2)`, `name (3)`… – the first folder under
  /// Downloads/Delve that holds none of this app's downloads yet (a folder
  /// download goes there).
  Future<String> freeFolder(String name);

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
  Future<String> publish(
    String path,
    String name,
    String mime, {
    String? folder,
  }) async => (await _channel.invokeMethod<String>('publish', {
    'path': path,
    'name': name,
    'mime': mime,
    'folder': ?folder,
  }))!;

  @override
  Future<String> freeFolder(String name) async =>
      (await _channel.invokeMethod<String>('freeFolder', {'name': name}))!;

  @override
  Future<bool> open(String uri, String mime) async =>
      await _channel.invokeMethod<bool>('open', {'uri': uri, 'mime': mime}) ??
      false;
}

/// Where the downloads land, as the user sees it.
const kDownloadFolder = 'Downloads/Delve';
