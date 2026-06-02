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

  // Exact diagonal display category getters as requested
  bool get isLessThan7Inch => diagonalInches < 7.0;
  bool get is7To8Inch => diagonalInches >= 7.0 && diagonalInches < 8.0;
  bool get is8To10Inch => diagonalInches >= 8.0 && diagonalInches < 10.0;
  bool get is10InchOrLarger => diagonalInches >= 10.0;

  // Spacing based on exact diagonal categories
  double get spacing {
    if (isLessThan7Inch) return 10.0;
    if (is7To8Inch) return 12.0;
    if (is8To10Inch) return 14.0;
    return 18.0;
  }

  // Padding based on exact diagonal categories (Increased for 3D tilt safety)
  EdgeInsets get screenPadding {
    if (isLessThan7Inch) {
      return const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0);
    }
    if (is7To8Inch) {
      return const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0);
    }
    if (is8To10Inch) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
    }
    return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0);
  }

  // Font sizes based on exact diagonal categories
  double get titleSize {
    if (isLessThan7Inch) return 18.0;
    if (is7To8Inch) return 21.0;
    if (is8To10Inch) return 24.0;
    return 28.0;
  }

  // Board constraints based on exact diagonal categories
  double get maxBoardSize {
    if (isLessThan7Inch) return 420.0;
    if (is7To8Inch) return 480.0;
    if (is8To10Inch) return 560.0;
    return 760.0; // Desktop or full 10"+ tablet size
  }
}
