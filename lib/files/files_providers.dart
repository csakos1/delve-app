import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/platform.dart';
import '../terminal/terminal_providers.dart';
import '../ui/links.dart';
import 'device_files.dart';
import 'files_service.dart';
import 'linux_device_files.dart';
import 'pdf_pages.dart';
import 'sftp_fs.dart';
import 'transfer_notice.dart';

/// Opens the SFTP connection (tests: a fake desktop).
final filesDialerProvider = Provider<FilesDialer>(
  (ref) => const SftpFilesDialer(),
);

/// Downloads/Delve and other apps (tests: a fake). The phone: MediaStore;
/// the Linux app: the folder itself.
final deviceFilesProvider = Provider<DeviceFiles>(
  (ref) => ref.watch(platformCapsProvider).phone
      ? const ChannelDeviceFiles()
      : LinuxDeviceFiles(open: ref.watch(linkOpenerProvider)),
);

/// The PDF preview's pages (tests: a fake).
final pdfPagesProvider = Provider<PdfPages>(
  (ref) => ref.watch(platformCapsProvider).pdfPreview
      ? const ChannelPdfPages()
      : const NoPdfPages(),
);

/// The transfers' background service and notification (F3b; tests: a fake).
final transferNoticeProvider = Provider<TransferNotice>(
  (ref) => ref.watch(platformCapsProvider).backgroundService
      ? ChannelTransferNotice()
      : const NoTransferNotice(),
);

/// The transfers notification's Open asked for the Transfers sheet:
/// TransfersHost sets it, the Files tab shows the sheet and clears it.
final transfersWantedProvider = Provider<ValueNotifier<bool>>((ref) {
  final wanted = ValueNotifier(false);
  ref.onDispose(wanted.dispose);
  return wanted;
});

final filesTimingProvider = Provider<FilesTiming>((ref) => const FilesTiming());

/// The app's one Files tab (it shares the terminal's key, host and lock).
final filesServiceProvider = Provider<FilesService>((ref) {
  final service = FilesService(
    terminal: ref.watch(terminalServiceProvider),
    dialer: ref.watch(filesDialerProvider),
    device: ref.watch(deviceFilesProvider),
    timing: ref.watch(filesTimingProvider),
    notice: ref.watch(transferNoticeProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
