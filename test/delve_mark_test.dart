import 'package:delve/theme/delve_theme.dart';
import 'package:delve/ui/widgets/delve_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the contours match the icon geometry', () {
    // the outer D of ic_launcher_foreground.xml: x 33–75, y 31–77
    final outer = dContour(33, 31, 52, 23, 3).getBounds();
    expect(outer.left, closeTo(33, 0.01));
    expect(outer.top, closeTo(31, 0.01));
    expect(outer.right, closeTo(75, 0.01));
    expect(outer.bottom, closeTo(77, 0.01));
    // the deepest counter sits inside the outer one
    final inner = dContour(52, 50.5, 55, 6.5, 2).getBounds();
    expect(outer.contains(inner.topLeft), isTrue);
    expect(outer.contains(inner.bottomRight - const Offset(0.1, 0.1)), isTrue);
    // and the mark's box holds them all
    expect(DelveMark.bounds.contains(outer.topLeft), isTrue);
    expect(DelveMark.bounds.contains(outer.bottomRight), isTrue);
  });

  testWidgets('the mark keeps its proportions; decorative unless labelled', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      MaterialApp(
        theme: buildDelveTheme(),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DelveMark(key: Key('plain'), height: 48),
                DelveMark(key: Key('labelled'), semanticLabel: 'Delve'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(t.getSize(find.byKey(const Key('plain'))), const Size(46, 48));
    expect(t.getSize(find.byKey(const Key('labelled'))).height, 32);
    expect(find.bySemanticsLabel('Delve'), findsOneWidget);
    expect(t.takeException(), isNull);
    semantics.dispose();
  });
}
