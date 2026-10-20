import 'package:flutter/services.dart';

/// Result of checking the server URL typed on the pairing screen.
sealed class ServerUrlCheck {
  const ServerUrlCheck();
}

final class ServerUrlOk extends ServerUrlCheck {
  const ServerUrlOk(this.origin);

  /// Scheme, host and port only, e.g. `https://archlinux.example.ts.net`.
  final Uri origin;
}

/// Why the URL is not usable; the screen shows a matching message.
enum ServerUrlProblem { empty, invalid, notHttps, notTailnet }

final class ServerUrlBad extends ServerUrlCheck {
  const ServerUrlBad(this.problem);
  final ServerUrlProblem problem;
}

/// Accepts `archlinux.x.ts.net`, `https://archlinux.x.ts.net/`, a pasted
/// `…/api/v1/health` link, etc. The server must be HTTPS on a Tailscale
/// MagicDNS name (decision 171): the backend is only served on the tailnet.
ServerUrlCheck checkServerUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) return const ServerUrlBad(ServerUrlProblem.empty);
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty || text.contains(' ')) {
    return const ServerUrlBad(ServerUrlProblem.invalid);
  }
  if (uri.scheme.toLowerCase() != 'https') {
    return const ServerUrlBad(ServerUrlProblem.notHttps);
  }
  final host = uri.host.toLowerCase();
  if (!host.endsWith('.ts.net') || host.split('.').length < 4) {
    return const ServerUrlBad(ServerUrlProblem.notTailnet);
  }
  return ServerUrlOk(
    Uri(scheme: 'https', host: host, port: uri.hasPort ? uri.port : null),
  );
}

/// The 8 digits of a pairing code, or null while incomplete.
String? pairingDigits(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  return digits.length == 8 ? digits : null;
}

/// `####-####` mask for the pairing code field: digits only, the dash is
/// inserted after the fourth digit, at most 8 digits.
class PairingCodeFormatter extends TextInputFormatter {
  const PairingCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    final text = digits.length > 4
        ? '${digits.substring(0, 4)}-${digits.substring(4)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
