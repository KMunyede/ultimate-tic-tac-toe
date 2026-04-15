import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveLayout {
  final BuildContext context;
  late final Size size;
  late final double width;
  late final double height;
  late final bool isLandscape;
  late final DeviceType deviceType;

  ResponsiveLayout(this.context) {
    size = MediaQuery.of(context).size;
    width = size.width;
    height = size.height;
    isLandscape = width > height;
    final shortestSide = size.shortestSide;

    if (shortestSide >= 900) {
      deviceType = DeviceType.desktop;
    } else if (shortestSide >= 600) {
      deviceType = DeviceType.tablet;
    } else {
      deviceType = DeviceType.mobile;
    }
  }

  double get diagonalInches {
    if (kIsWeb) return 13.0; // Assume laptop for web (fallback)
    final double ppi = (Platform.isAndroid || Platform.isIOS) ? 160 : 96;
    return sqrt(pow(width / ppi, 2) + pow(height / ppi, 2));
  }

  bool get isSmallLandscape => isLandscape && diagonalInches < 7.0;

  // Spacing based on device
  double get spacing {
    switch (deviceType) {
      case DeviceType.desktop:
        return 32.0;
      case DeviceType.tablet:
        return 24.0;
      case DeviceType.mobile:
        return 16.0;
    }
  }

  // Padding based on device
  EdgeInsets get screenPadding {
    switch (deviceType) {
      case DeviceType.desktop:
        return const EdgeInsets.all(48.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(32.0);
      case DeviceType.mobile:
        return const EdgeInsets.all(16.0);
    }
  }

  // Font sizes
  double get titleSize {
    switch (deviceType) {
      case DeviceType.desktop:
        return 32.0;
      case DeviceType.tablet:
        return 28.0;
      case DeviceType.mobile:
        return 22.0;
    }
  }

  // Board constraints
  double get maxBoardSize {
    if (deviceType == DeviceType.mobile) return 450.0;
    if (deviceType == DeviceType.tablet) return 600.0;
    return 800.0; // Larger board for Desktop/Windows/Web
  }
}
