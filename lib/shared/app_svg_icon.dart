import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/assets.dart';

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
    this.filled = false,
  });

  final String name;
  final double size;
  final Color? color;

  /// Relleno del color (como `.ib.fav .i{fill:var(--bad)}`).
  final bool filled;

  static final Map<String, Future<String>> _cache = {};

  @override
  Widget build(BuildContext context) {
    final assetName = name.startsWith('i-') ? name : 'i-$name';
    final path = CaAssets.icon(assetName);

    if (filled && color != null) {
      final hex =
          '#${(color!.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
      final future = _cache.putIfAbsent(path, () => rootBundle.loadString(path));
      return SizedBox(
        width: size,
        height: size,
        child: FutureBuilder<String>(
          future: future,
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final svg = snap.data!
                .replaceAll('currentColor', hex)
                .replaceFirst('fill="none"', 'fill="$hex"');
            return SvgPicture.string(svg, width: size, height: size);
          },
        ),
      );
    }

    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
