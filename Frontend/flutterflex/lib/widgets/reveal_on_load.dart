import 'package:flutter/material.dart';

class RevealOnLoad extends StatelessWidget {
  const RevealOnLoad({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offsetY = 12,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final total = Duration(
      milliseconds: delay.inMilliseconds + duration.inMilliseconds,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Curves.linear,
      child: child,
      builder: (context, value, animatedChild) {
        final delayedProgress = _progressAfterDelay(value);
        final eased = curve.transform(delayedProgress);

        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * offsetY),
            child: animatedChild,
          ),
        );
      },
    );
  }

  double _progressAfterDelay(double value) {
    if (delay.inMilliseconds <= 0) {
      return value;
    }

    final totalMs = delay.inMilliseconds + duration.inMilliseconds;
    if (totalMs <= 0) {
      return 1;
    }

    final elapsedMs = value * totalMs;
    final progress =
        (elapsedMs - delay.inMilliseconds) / duration.inMilliseconds;
    return progress.clamp(0, 1);
  }
}
