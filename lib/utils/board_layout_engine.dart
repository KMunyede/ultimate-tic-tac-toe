// lib/utils/board_layout_engine.dart

import 'dart:math';
import 'package:flutter/material.dart';

class BoardLayoutData {
  final double boardSize;
  final List<Offset> centers;

  BoardLayoutData({required this.boardSize, required this.centers});
}

class BoardLayoutEngine {
  /// VISUAL FOOTPRINT CONSTANTS
  static const double visualScaleFactor = 1.02 + 0.05 + 0.03; // Scale + Shake + Tilt Buffer
  static const double visualFixedPadding = 12.0; // Total drift margin (6px each side)

  static BoardLayoutData calculateLayout({
    required int count,
    required List<Offset> templatePositions,
    required double availW,
    required double availH,
  }) {
    // 1. Dynamic Safety Gap Factor
    double gapFactor = 1.16;
    if (count == 5) {
      gapFactor = 1.10;
    } else if (count == 6) {
      gapFactor = 1.08;
    } else if (count >= 7) {
      gapFactor = 1.06;
    }

    // 2. Physics-Aware Binary Search Sizing Engine
    double low = 40.0;
    double high = min(availW, availH);
    double boardSize = low;

    for (int iter = 0; iter < 24; iter++) {
      double mid = (low + high) / 2;
      final double effectiveSize = (mid * visualScaleFactor) + visualFixedPadding;

      // SAFETY: If the board at this size can't physically fit with its visual buffers, it's invalid
      if (effectiveSize > availW || effectiveSize > availH) {
        high = mid;
        continue;
      }

      final double minGap = mid * (gapFactor - 1.0);

      // Generate candidate centers based on normalized layout positions
      List<Offset> candidateCenters = [];
      for (int i = 0; i < count; i++) {
        final pos = templatePositions[i];
        final double cx = pos.dx * (availW - effectiveSize) + effectiveSize / 2;
        final double cy = pos.dy * (availH - effectiveSize) + effectiveSize / 2;
        candidateCenters.add(Offset(cx, cy));
      }

      // Simulate Chebyshev repulsion physics inside search loop
      final double minX = effectiveSize / 2;
      final double maxX = availW - effectiveSize / 2;
      final double minY = effectiveSize / 2;
      final double maxY = availH - effectiveSize / 2;

      for (int step = 0; step < 12; step++) {
        for (int i = 0; i < count; i++) {
          for (int j = i + 1; j < count; j++) {
            final Offset delta = candidateCenters[j] - candidateCenters[i];
            final double dx = delta.dx.abs();
            final double dy = delta.dy.abs();
            final double threshold = mid + minGap;

            if (dx < threshold && dy < threshold) {
              final double overlapX = threshold - dx;
              final double overlapY = threshold - dy;

              final double pushX = (delta.dx == 0 ? 1.0 : delta.dx.sign) * overlapX * 0.5;
              final double pushY = (delta.dy == 0 ? 1.0 : delta.dy.sign) * overlapY * 0.5;

              candidateCenters[i] -= Offset(pushX, pushY);
              candidateCenters[j] += Offset(pushX, pushY);
            }
          }
        }

        // Bound candidate coordinates to EFFECTIVE screen limits
        for (int i = 0; i < count; i++) {
          double cx = candidateCenters[i].dx.clamp(minX, maxX);
          double cy = candidateCenters[i].dy.clamp(minY, maxY);
          candidateCenters[i] = Offset(cx, cy);
        }
      }

      // Evaluate if candidate centers fit on screen without overlap
      bool isValid = true;
      for (int i = 0; i < count; i++) {
        if (candidateCenters[i].dx < minX - 0.5 ||
            candidateCenters[i].dx > maxX + 0.5 ||
            candidateCenters[i].dy < minY - 0.5 ||
            candidateCenters[i].dy > maxY + 0.5) {
          isValid = false;
          break;
        }
        for (int j = i + 1; j < count; j++) {
          final double dx = (candidateCenters[j].dx - candidateCenters[i].dx).abs();
          final double dy = (candidateCenters[j].dy - candidateCenters[i].dy).abs();
          if (dx < mid + minGap - 0.5 && dy < mid + minGap - 0.5) {
            isValid = false;
            break;
          }
        }
        if (!isValid) break;
      }

      if (isValid) {
        boardSize = mid;
        low = mid;
      } else {
        high = mid;
      }
    }

    // 3. Final Absolute Centers Calculation
    final double effectiveSize = (boardSize * visualScaleFactor) + visualFixedPadding;
    final double minGap = boardSize * (gapFactor - 1.0);
    final double minX = effectiveSize / 2;
    final double maxX = availW - effectiveSize / 2;
    final double minY = effectiveSize / 2;
    final double maxY = availH - effectiveSize / 2;

    final List<Offset> centers = [];
    for (int i = 0; i < count; i++) {
      final pos = templatePositions[i];
      final double cx = pos.dx * (availW - effectiveSize) + effectiveSize / 2;
      final double cy = pos.dy * (availH - effectiveSize) + effectiveSize / 2;
      centers.add(Offset(cx, cy));
    }

    // 4. Perform iterative overlap repulsion pass
    for (int step = 0; step < 20; step++) {
      for (int i = 0; i < count; i++) {
        for (int j = i + 1; j < count; j++) {
          final Offset delta = centers[j] - centers[i];
          final double dx = delta.dx.abs();
          final double dy = delta.dy.abs();
          final double threshold = boardSize + minGap;

          if (dx < threshold && dy < threshold) {
            final double overlapX = threshold - dx;
            final double overlapY = threshold - dy;

            final double pushX = (delta.dx == 0 ? 1.0 : delta.dx.sign) * overlapX * 0.5;
            final double pushY = (delta.dy == 0 ? 1.0 : delta.dy.sign) * overlapY * 0.5;

            centers[i] -= Offset(pushX, pushY);
            centers[j] += Offset(pushX, pushY);
          }
        }
      }

      for (int i = 0; i < count; i++) {
        double cx = centers[i].dx;
        double cy = centers[i].dy;

        if (maxX > minX) {
          cx = cx.clamp(minX, maxX);
        } else {
          cx = availW / 2;
        }

        if (maxY > minY) {
          cy = cy.clamp(minY, maxY);
        } else {
          cy = availH / 2;
        }

        centers[i] = Offset(cx, cy);
      }
    }

    return BoardLayoutData(boardSize: boardSize, centers: centers);
  }
}
