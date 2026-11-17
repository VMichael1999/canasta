import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/assets.dart';

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
  });

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final assetName = name.startsWith('i-') ? name : 'i-$name';
    final path = CaAssets.icon(assetName);

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
