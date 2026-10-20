import 'package:delve/app/pairing_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('checkServerUrl', () {
    String? ok(String input) => switch (checkServerUrl(input)) {
      ServerUrlOk(:final origin) => origin.toString(),
      ServerUrlBad() => null,
    };
    ServerUrlProblem? bad(String input) => switch (checkServerUrl(input)) {
      ServerUrlBad(:final problem) => problem,
      ServerUrlOk() => null,
    };

    test('accepts the tailnet name in any common form', () {
      const want = 'https://archlinux.example.ts.net';
      expect(ok('archlinux.example.ts.net'), want);
      expect(ok('  https://archlinux.example.ts.net/  '), want);
      expect(ok('HTTPS://ArchLinux.Example.TS.net'), want);
      expect(ok('https://archlinux.example.ts.net/api/v1/health?x=1#y'), want);
      expect(
        ok('https://archlinux.example.ts.net:8443'),
        'https://archlinux.example.ts.net:8443',
      );
    });

    test('rejects what cannot be the server', () {
      expect(bad(''), ServerUrlProblem.empty);
      expect(bad('   '), ServerUrlProblem.empty);
      expect(bad('http://archlinux.example.ts.net'), ServerUrlProblem.notHttps);
      expect(bad('https://example.com'), ServerUrlProblem.notTailnet);
      expect(bad('https://ts.net'), ServerUrlProblem.notTailnet);
      expect(bad('https://100.64.0.1'), ServerUrlProblem.notTailnet);
      expect(bad('https://arch linux.ts.net'), ServerUrlProblem.invalid);
    });
  });

  group('pairing code', () {
    TextEditingValue type(String old, String next) =>
        const PairingCodeFormatter().formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(text: next),
        );

    test('masks as ####-####, digits only, at most 8', () {
      expect(type('', '4821').text, '4821');
      expect(type('4821', '48210').text, '4821-0');
      expect(type('', '4821 0937').text, '4821-0937');
      expect(type('', 'abc48-21x0937999').text, '4821-0937');
      expect(type('4821-0', '4821-').text, '4821');
      expect(type('', '48210937').selection.baseOffset, 9);
    });

    test('digits only when complete', () {
      expect(pairingDigits('4821-0937'), '48210937');
      expect(pairingDigits('4821 0937'), '48210937');
      expect(pairingDigits('4821-093'), isNull);
      expect(pairingDigits('4821-09371'), isNull);
    });
  });
}
