part of 'files_service.dart';

/// F3b: the transfers in the background – the foreground service's
/// "Transfers" notification while anything is queued or running (23g2), and
/// one ordinary notification when the queue empties with the app away.
extension FilesNotice on FilesService {
  /// The notification's Cancel all.
  void _noticeCancelAll() {
    cancelAll();
    // nothing left: the tick stops the service
    _noticeTick();
  }

  static final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

  /// The app came back (a refused start may go now) or went away (a waiting
  /// first notification goes at once – Android lets a service start only
  /// while the app is on screen).
  void _noticeForeground() {
    if (_foreground && _noticeRefused) {
      _noticeRefused = false;
      _noticeLast = null;
    }
    _noticeTick();
  }

  /// Called on every change: shows, updates (at most every
  /// [FilesTiming.noticeEvery], a new step at once) or ends the notification.
  void _noticeTick() {
    final s = _noticeState();
    final now = _now();
    if (s == null) {
      _noticeSince = null;
      if (_noticeOn || _noticeTimer != null) _noticeEnd();
      return;
    }
    final since = _noticeSince ??= now;
    if (_noticeRefused) return;
    final last = _noticeLast;
    if (last != null && last.sameAs(s)) return;
    final Duration wait;
    if (!_noticeOn) {
      // away: now, while Android still counts the app as just seen
      wait = _foreground
          ? timing.noticeDelay - now.difference(since)
          : Duration.zero;
    } else if (last != null && last.sameStepAs(s)) {
      wait = timing.noticeEvery - now.difference(_noticeAt);
    } else {
      wait = Duration.zero;
    }
    if (wait > Duration.zero) {
      _noticeTimer ??= Timer(wait, () {
        _noticeTimer = null;
        if (!_disposed) _noticeTick();
      });
      return;
    }
    _noticeTimer?.cancel();
    _noticeTimer = null;
    _noticeLast = s;
    _noticeAt = now;
    _noticeOn = true;
    _noticeChain = _noticeChain.then((_) async {
      // stopped meanwhile: a late start would bring it back
      if (!_noticeOn || _disposed) return;
      final ok = await notice.show(s);
      if (!ok && identical(_noticeLast, s)) _noticeRefused = true;
    });
  }

  void _noticeEnd() {
    _noticeTimer?.cancel();
    _noticeTimer = null;
    final wasOn = _noticeOn;
    _noticeOn = false;
    _noticeLast = null;
    _noticeRefused = false;
    if (!wasOn) return;
    final summary = _foreground && _visible ? null : _noticeSummary();
    _noticeChain = _noticeChain.then((_) async {
      await notice.stop();
      if (summary != null) await notice.finished(summary);
    });
  }

  /// What the ongoing notification says now (null: nothing in the queue).
  TransferNoticeState? _noticeState() {
    final active = _transfers.where((t) => t.active).length;
    if (active == 0) return null;
    final l = _l;
    final place = transferProgress;
    final sub = place != null && place.$2 > 1
        ? l.filesTransferChip(place.$1, place.$2)
        : '';
    // the next one is about to start while connected
    final t =
        runningTransfer ??
        (_phase == FilesPhase.live
            ? _transfers
                  .where((t) => t.state == TransferState.queued)
                  .firstOrNull
            : null);
    if (t == null) {
      // offline: the queue waits for the connection
      return TransferNoticeState(
        title: l.filesNoticeWaiting,
        text: l.filesNoticeQueued(active),
        sub: sub,
        cancelLabel: l.filesNoticeCancelAll,
        openLabel: l.filesOpen,
      );
    }
    final reading = t.folder && t.files == null;
    final total = t.total;
    final files = t.files;
    final text = reading
        ? '${l.filesTransferReading} · ${l.filesTransferFound(t.found)}'
        : [
            if (total == null)
              sizeText(t.bytes)
            else
              l.filesTransferOf(sizeText(t.bytes), sizeText(total)),
            if (files != null) l.filesTransferFiles(t.filesDone, files),
            if (t.speed(_now()) case final v?) '${sizeText(v.round())}/s',
          ].join(' · ');
    return TransferNoticeState(
      title: switch (t.kind) {
        TransferKind.download => l.filesNoticeDownloading(t.name),
        TransferKind.upload => l.filesNoticeUploading(t.name),
        TransferKind.copy => l.filesNoticeCopying(t.name),
        TransferKind.move => l.filesNoticeMoving(t.name),
      },
      text: text,
      sub: sub,
      progress: reading ? null : t.fraction,
      cancelLabel: l.filesNoticeCancelAll,
      openLabel: l.filesOpen,
    );
  }

  /// The batch that just ended, for the notification after it (null: all
  /// cancelled – nothing to say).
  TransferSummary? _noticeSummary() {
    final l = _l;
    final batch = _transfers.where((t) => _batch.contains(t.id) && !t.active);
    final done = batch.where((t) => t.state == TransferState.done).toList();
    final failed = batch.where((t) => t.state == TransferState.failed).toList();
    if (done.isEmpty && failed.isEmpty) return null;
    String where(Transfer t) => tildePath(parentPath(t.remotePath), _home);
    if (failed.isEmpty && done.length == 1) {
      final t = done.single;
      return switch (t.kind) {
        TransferKind.download when t.folder => TransferSummary(
          title: l.filesSaved('$kDownloadFolder/${t.phoneFolder ?? t.name}'),
          text: l.filesTransferFilesDone(t.filesDone),
          openLabel: l.filesOpen,
        ),
        TransferKind.download => TransferSummary(
          title: l.filesSaved(kDownloadFolder),
          text: t.name,
          uri: t.uri,
          mime: mimeOf(t.name),
          openLabel: l.filesOpen,
        ),
        TransferKind.upload => TransferSummary(
          title: l.filesUploaded(where(t)),
          text: t.name,
          openLabel: l.filesOpen,
        ),
        TransferKind.copy => TransferSummary(
          title: l.filesCopiedTo(where(t)),
          text: t.name,
          openLabel: l.filesOpen,
        ),
        TransferKind.move => TransferSummary(
          title: t.warning == null
              ? l.filesMovedTo(where(t))
              : l.filesMovedSourceKept(where(t), t.warning!),
          text: t.name,
          openLabel: l.filesOpen,
        ),
      };
    }
    if (failed.isEmpty) {
      final downloads = done.every((t) => t.kind == TransferKind.download);
      return TransferSummary(
        title: downloads
            ? l.filesSaved(kDownloadFolder)
            : l.filesNoticeFinished,
        text: downloads
            ? l.filesNoticeItems(done.length)
            : l.filesNoticeDone(done.length),
        openLabel: l.filesOpen,
      );
    }
    if (done.isEmpty && failed.length == 1) {
      final t = failed.single;
      final why = t.error ?? '';
      return TransferSummary(
        title: l.filesNoticeAllFailed,
        text: switch (t.kind) {
          TransferKind.download => l.filesDownloadFailed(t.name, why),
          TransferKind.upload => l.filesUploadFailedFile(t.name, why),
          TransferKind.copy ||
          TransferKind.move => l.filesCopyFailed(t.entry.name, why),
        },
        openLabel: l.filesOpen,
      );
    }
    return TransferSummary(
      title: done.isEmpty ? l.filesNoticeAllFailed : l.filesNoticeFinished,
      text: [
        if (done.isNotEmpty) l.filesNoticeDone(done.length),
        l.filesNoticeFailed(failed.length),
      ].join(' · '),
      openLabel: l.filesOpen,
    );
  }
}
