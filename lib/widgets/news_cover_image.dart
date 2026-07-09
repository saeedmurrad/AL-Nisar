import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'shimmer_placeholder.dart';

class NewsCoverImage extends StatelessWidget {
  const NewsCoverImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.height,
    this.width,
  });

  final String imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    final child = url.isEmpty
        ? const GoldPatternError()
        : CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            placeholder: (context, url) =>
                ShimmerPlaceholder(borderRadius: borderRadius),
            errorWidget: (context, url, error) => const GoldPatternError(),
          );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(height: height, width: width, child: child),
      );
    }
    return SizedBox(height: height, width: width, child: child);
  }
}
