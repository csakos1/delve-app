import 'package:delve/theme/delve_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// [target] ends on the inner right edge of [card] (a surface card with
/// 16 dp padding): a value, note or chip meant for the right side must not
/// stop short of it, whatever the label left of it.
void expectOnRightEdge(WidgetTester t, Finder target, Finder card) {
  expect(target, findsOneWidget);
  expect(
    t.getTopRight(target).dx,
    t.getTopRight(card).dx - DelveTokens.space4,
    reason: 'right edge of $target',
  );
}
