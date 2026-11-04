import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:pinenacl/ed25519.dart' as nacl;

/// The comment at the end of the phone's public key line.
const kPhoneKeyComment = 'delve-phone';

/// Options in front of the key in `~/.ssh/authorized_keys`: only from the
/// tailnet (CGNAT range), no agent, X11 or port forwarding (infra D-48).
const kAuthorizedKeysOptions =
    'from="100.64.0.0/10",no-agent-forwarding,no-X11-forwarding,'
    'no-port-forwarding';

/// The phone's own ed25519 key for the terminal. Only the 32-byte seed is
/// stored; the private key never leaves secure storage.
class PhoneKey {
  PhoneKey._(this.seed, this.publicKey);

  factory PhoneKey.fromSeed(Uint8List seed) {
    if (seed.length != 32) {
      throw ArgumentError.value(seed.length, 'seed', 'must be 32 bytes');
    }
    final signing = nacl.SigningKey.fromSeed(seed);
    return PhoneKey._(
      Uint8List.fromList(seed),
      Uint8List.fromList(signing.verifyKey.asTypedList),
    );
  }

  factory PhoneKey.generate() => PhoneKey.fromSeed(
    Uint8List.fromList(nacl.SigningKey.generate().seed.asTypedList),
  );

  final Uint8List seed;
  final Uint8List publicKey;

  /// The SSH wire encoding: string "ssh-ed25519", string <32-byte key>.
  Uint8List get publicBlob {
    final type = ascii.encode('ssh-ed25519');
    final out = BytesBuilder(copy: false)
      ..add(_u32(type.length))
      ..add(type)
      ..add(_u32(publicKey.length))
      ..add(publicKey);
    return out.toBytes();
  }

  /// `ssh-ed25519 AAAA… delve-phone`
  String get publicLine =>
      'ssh-ed25519 ${base64.encode(publicBlob)} $kPhoneKeyComment';

  /// The line to add to `~/.ssh/authorized_keys` on the desktop.
  String get authorizedKeysLine => '$kAuthorizedKeysOptions $publicLine';

  /// One command for the desktop that installs [authorizedKeysLine].
  String get installCommand =>
      "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$authorizedKeysLine' "
      '>> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys';

  /// The identity for dartssh2 (private key = seed ‖ public key).
  SSHKeyPair get keyPair => OpenSSHEd25519KeyPair(
    publicKey,
    Uint8List.fromList([...seed, ...publicKey]),
    kPhoneKeyComment,
  );

  static Uint8List _u32(int v) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, v);
}

/// A host key the user trusted, per `host:port`.
class PinnedHostKey {
  const PinnedHostKey({
    required this.type,
    required this.fingerprint,
    this.trustedAt,
  });

  factory PinnedHostKey.fromJson(Map<String, Object?> j) => PinnedHostKey(
    type: j['type']! as String,
    fingerprint: j['fingerprint']! as String,
    trustedAt: DateTime.tryParse(j['trusted_at'] as String? ?? ''),
  );

  final String type;

  /// OpenSSH style, `SHA256:<base64 without padding>`.
  final String fingerprint;

  final DateTime? trustedAt;

  bool matches(String type, String fingerprint) =>
      this.type == type && this.fingerprint == fingerprint;

  Map<String, Object?> toJson() => {
    'type': type,
    'fingerprint': fingerprint,
    'trusted_at': ?trustedAt?.toUtc().toIso8601String(),
  };
}

/// The fingerprint body (after `SHA256:`) in groups of four, for comparing
/// by eye (design 22e1: 43 characters, 6 groups per row).
List<String> fingerprintGroups(String fingerprint) {
  final i = fingerprint.indexOf(':');
  final body = i < 0 ? fingerprint : fingerprint.substring(i + 1);
  return [
    for (var j = 0; j < body.length; j += 4)
      body.substring(j, j + 4 > body.length ? body.length : j + 4),
  ];
}

/// The key type as the design's eyebrow shows it: `ssh-ed25519` → `ED25519`.
String hostKeyTypeLabel(String type) =>
    (type.startsWith('ssh-') ? type.substring(4) : type).toUpperCase();
