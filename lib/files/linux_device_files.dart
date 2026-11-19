import 'dart:io';

import 'package:flutter/foundation.dart';

import 'device_files.dart';

/// The Linux app's side of downloads (L1): the same `Downloads/Delve` as on
/// the phone, but a plain folder – the XDG download directory, `~/Downloads`
/// when it is not set. "Open" and "Share" go to the desktop's default apps
/// through [open] (url_launcher: xdg-open / the portal).
class LinuxDeviceFiles implements DeviceFiles {
  LinuxDeviceFiles({
    required Future<bool> Function(Uri uri) open,
    Map<String, String>? environment,
  }) : _open = open,
       _env = environment ?? Platform.environment;

  final Future<bool> Function(Uri uri) _open;
  final Map<String, String> _env;

  String get _home => _env['HOME'] ?? '/tmp';

  /// `$XDG_CACHE_HOME/delve/scratch` (`~/.cache/delve/scratch`).
  @override
  Future<String> scratchDir() async {
    final cache = _env['XDG_CACHE_HOME'];
    final base = cache != null && cache.startsWith('/')
        ? cache
        : '$_home/.cache';
    final dir = Directory('$base/delve/scratch');
    await dir.create(recursive: true);
    return dir.path;
  }

  /// `~/Downloads/Delve` (or the XDG download directory's `Delve`).
  Future<Directory> _root() async =>
      Directory('${linuxDownloadDir(_home, await _userDirs())}/Delve');

  Future<String?> _userDirs() async {
    final config = _env['XDG_CONFIG_HOME'];
    final base = config != null && config.startsWith('/')
        ? config
        : '$_home/.config';
    try {
      return await File('$base/user-dirs.dirs').readAsString();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<String> publish(
    String path,
    String name,
    String mime, {
    String? folder,
  }) async {
    var dir = await _root();
    if (folder != null && folder.isNotEmpty) {
      dir = Directory('${dir.path}/$folder');
    }
    await dir.create(recursive: true);
    final target = await _freeFile(dir, name);
    try {
      await File(path).rename(target);
    } on FileSystemException {
      // another file system: copy, then remove the scratch copy
      await File(path).copy(target);
      await File(path).delete();
    }
    return Uri.file(target).toString();
  }

  @override
  Future<String> freeFolder(String name) async {
    final root = await _root();
    for (var i = 1; ; i++) {
      final candidate = i == 1 ? name : '$name ($i)';
      if (!await Directory('${root.path}/$candidate').exists() &&
          !await File('${root.path}/$candidate').exists()) {
        return candidate;
      }
    }
  }

  @override
  Future<bool> open(String uri, String mime) async {
    final u = Uri.tryParse(uri);
    return u != null && await _open(u);
  }

  /// No share sheet on the desktop: the folder the file is in.
  @override
  Future<void> share(String uri, String mime) async {
    final u = Uri.tryParse(uri);
    if (u == null || !u.isScheme('file')) return;
    await _open(Directory(File(u.toFilePath()).parent.path).uri);
  }

  static Future<String> _freeFile(Directory dir, String name) async {
    for (var i = 1; ; i++) {
      final candidate = '${dir.path}/${numberedName(name, i)}';
      if (!await File(candidate).exists() &&
          !await Directory(candidate).exists()) {
        return candidate;
      }
    }
  }
}

/// `report.pdf`, then `report (2).pdf`, `report (3).pdf`…
@visibleForTesting
String numberedName(String name, int n) {
  if (n <= 1) return name;
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return '$name ($n)';
  return '${name.substring(0, dot)} ($n)${name.substring(dot)}';
}

/// The XDG download directory from `user-dirs.dirs` (`$HOME` expanded), or
/// `~/Downloads`.
@visibleForTesting
String linuxDownloadDir(String home, String? userDirs) {
  final m = RegExp(
    r'^\s*XDG_DOWNLOAD_DIR\s*=\s*"([^"]*)"',
    multiLine: true,
  ).firstMatch(userDirs ?? '');
  final raw = m?.group(1)?.replaceAll(r'$HOME', home).trim();
  if (raw == null || !raw.startsWith('/') || raw == home || raw == '$home/') {
    return '$home/Downloads';
  }
  return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
}
