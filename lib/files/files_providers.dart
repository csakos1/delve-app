import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../terminal/terminal_providers.dart';
import 'device_files.dart';
import 'files_service.dart';
import 'sftp_fs.dart';

/// Opens the SFTP connection (tests: a fake desktop).
final filesDialerProvider = Provider<FilesDialer>(
  (ref) => const SftpFilesDialer(),
);

/// Downloads/Delve and other apps (tests: a fake).
final deviceFilesProvider = Provider<DeviceFiles>(
  (ref) => const ChannelDeviceFiles(),
);

final filesTimingProvider = Provider<FilesTiming>((ref) => const FilesTiming());

/// The app's one Files tab (it shares the terminal's key, host and lock).
final filesServiceProvider = Provider<FilesService>((ref) {
  final service = FilesService(
    terminal: ref.watch(terminalServiceProvider),
    dialer: ref.watch(filesDialerProvider),
    device: ref.watch(deviceFilesProvider),
    timing: ref.watch(filesTimingProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
