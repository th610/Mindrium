import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageBanner extends StatelessWidget {
  final String? imageSource;
  final double borderRadius;
  final double? height;
  final BoxFit fit;

  const ImageBanner({
    super.key,
    this.imageSource,
    this.borderRadius = 6,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageSource == null || imageSource!.isEmpty) {
      imageWidget = const Center(
        child: Text(
          '이미지 영역 (예: week1.png)',
          style: TextStyle(color: AppColors.grey),
        ),
      );
    } else if (imageSource!.startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageSource!,
        width: double.infinity,
        fit: fit,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const Center(child: Text('이미지 불러오기 실패')),
      );
    } else if (File(imageSource!).existsSync()) {
      imageWidget = Image.file(
        File(imageSource!),
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Text('로컬 이미지가 없습니다')),
      );
    } else {
      imageWidget = Image.asset(
        imageSource!,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Text('에셋 이미지가 없습니다')),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      ),
    );
  }
}