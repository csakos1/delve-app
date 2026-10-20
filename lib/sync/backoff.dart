import 'dart:math';

/// Reconnect delay before attempt [attempt] (1, 2, …): doubling from [min] up
/// to [max], with jitter over the upper half so phones that lost the server
/// together do not come back in lockstep (decision 169: 1 → 30 s).
Duration backoffDelay(
  int attempt, {
  required Random random,
  Duration min = const Duration(seconds: 1),
  Duration max = const Duration(seconds: 30),
}) {
  final step = attempt < 1 ? 0 : (attempt - 1).clamp(0, 30);
  final ceiling = min.inMicroseconds * pow(2, step);
  final base = ceiling > max.inMicroseconds
      ? max.inMicroseconds
      : ceiling.toInt();
  final half = base ~/ 2;
  return Duration(microseconds: half + random.nextInt(base - half + 1));
}
