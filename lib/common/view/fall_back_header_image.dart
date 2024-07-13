import '../../extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

class FallBackHeaderImage extends StatelessWidget {
  const FallBackHeaderImage({
    super.key,
    this.color,
    required this.child,
  });

  final Color? color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? context.t.colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.scale(lightness: 0.1).withOpacity(0.4),
            baseColor.scale(lightness: 0.6).withOpacity(0.4),
          ],
        ),
      ),
      width: 200,
      height: 200,
      child: child,
    );
  }
}
