// lib/widgets/game_board.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/game/logic/game_controller.dart';
import '../features/settings/logic/settings_controller.dart';
import 'board_widget.dart';
import 'animations/fly_in_wrapper.dart';
import 'animations/confetti_overlay.dart';

class GridPattern {
  final int cols;
  final int rows;
  final List<int?> cells;

  GridPattern({required this.cols, required this.rows, required this.cells});
}

class MultiBoardView extends StatelessWidget {
  const MultiBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final double diagonalInches = sqrt(pow(screenWidth / 160, 2) + pow(screenHeight / 160, 2));

    return Consumer2<GameController, SettingsController>(
      builder: (context, controller, settings, child) {
        final boards = controller.boards;
        final int count = boards.length;
        if (count == 0) return const SizedBox.shrink();

        final templates = SettingsController.getTemplatesForCount(count);
        final selectedTemplate = templates[settings.layoutIndex % templates.length];
        final positions = selectedTemplate.positions;

        return Stack(
          children: [
            _buildShakeWrapper(
              controller,
              LayoutBuilder(
                builder: (context, constraints) {
                  double outerPadding = 16.0;
                  if (diagonalInches < 5.5) {
                    outerPadding = 8.0; // Phone
                  } else if (diagonalInches >= 8.0) {
                    outerPadding = 32.0; // Tablet
                  }

                  final double rawAvailW = constraints.maxWidth - (outerPadding * 2);
                  final double rawAvailH = constraints.maxHeight - (outerPadding * 2);

                  // Keep layout clustered elegantly on extremely wide screens
                  double availW = rawAvailW;
                  double availH = rawAvailH;
                  if (availW > availH * 1.6) {
                    availW = availH * 1.6;
                  }

                  // 1. Physics-Aware Binary Search Sizing Engine:
                  // Automatically tests and stretches board sizes vertically/horizontally
                  // to utilize wide tablets and tall phones to the absolute maximum.
                  double low = 40.0;
                  double high = min(availW, availH) * 0.92; // Max size clamps to 92% of smaller dimension to look elegant
                  double boardSize = low;

                  for (int iter = 0; iter < 24; iter++) {
                    double mid = (low + high) / 2;
                    
                    // Generate candidate centers based on normalized layout positions
                    List<Offset> candidateCenters = [];
                    for (int i = 0; i < count; i++) {
                      final pos = positions[i];
                      final double cx = pos.dx * (availW - mid) + mid / 2;
                      final double cy = pos.dy * (availH - mid) + mid / 2;
                      candidateCenters.add(Offset(cx, cy));
                    }
                    
                    // Simulate repulsion physics inside search loop to see if they fit after relaxation!
                    final double minDistance = mid * 1.16; // 16% safety gap
                    final double minX = mid / 2;
                    final double maxX = availW - mid / 2;
                    final double minY = mid / 2;
                    final double maxY = availH - mid / 2;
                    
                    for (int step = 0; step < 8; step++) {
                      for (int i = 0; i < count; i++) {
                        for (int j = i + 1; j < count; j++) {
                          final Offset delta = candidateCenters[j] - candidateCenters[i];
                          final double dist = delta.distance;
                          if (dist < minDistance) {
                            final Offset dir = dist > 0.001 
                                ? delta / dist 
                                : Offset(sin(i * 3.0), cos(i * 3.0));
                            final double overlap = minDistance - dist;
                            final Offset push = dir * (overlap * 0.5);
                            candidateCenters[i] -= push;
                            candidateCenters[j] += push;
                          }
                        }
                      }
                      
                      // Bound candidate coordinates to screen limits during evaluation
                      for (int i = 0; i < count; i++) {
                        double cx = candidateCenters[i].dx.clamp(minX, maxX);
                        double cy = candidateCenters[i].dy.clamp(minY, maxY);
                        candidateCenters[i] = Offset(cx, cy);
                      }
                    }
                    
                    // Evaluate if candidate centers fit on screen and don't overlap after relaxation
                    bool isValid = true;
                    for (int i = 0; i < count; i++) {
                      if (candidateCenters[i].dx < minX - 1.0 || 
                          candidateCenters[i].dx > maxX + 1.0 ||
                          candidateCenters[i].dy < minY - 1.0 || 
                          candidateCenters[i].dy > maxY + 1.0) {
                        isValid = false;
                        break;
                      }
                      for (int j = i + 1; j < count; j++) {
                        if ((candidateCenters[j] - candidateCenters[i]).distance < minDistance - 1.0) {
                          isValid = false;
                          break;
                        }
                      }
                      if (!isValid) break;
                    }
                    
                    if (isValid) {
                      boardSize = mid;
                      low = mid; // Try larger
                    } else {
                      high = mid; // Try smaller
                    }
                  }

                  // Clamp defensively
                  boardSize = boardSize.clamp(40.0, 750.0);

                  // 2. Convert normalized positions to absolute centers using the optimized boardSize
                  final List<Offset> centers = [];
                  for (int i = 0; i < count; i++) {
                    final pos = positions[i];
                    final double cx = pos.dx * (availW - boardSize) + boardSize / 2;
                    final double cy = pos.dy * (availH - boardSize) + boardSize / 2;
                    centers.add(Offset(cx, cy));
                  }

                  // 3. Perform iterative overlap repulsion pass to maintain clear gaps
                  final double minDistance = boardSize * 1.16; // 16% safety gap margin
                  final double minX = boardSize / 2;
                  final double maxX = availW - boardSize / 2;
                  final double minY = boardSize / 2;
                  final double maxY = availH - boardSize / 2;

                  for (int step = 0; step < 15; step++) {
                    for (int i = 0; i < count; i++) {
                      for (int j = i + 1; j < count; j++) {
                        final Offset delta = centers[j] - centers[i];
                        final double dist = delta.distance;
                        if (dist < minDistance) {
                          final Offset dir = dist > 0.001 
                              ? delta / dist 
                              : Offset(sin(i * 3.0), cos(i * 3.0));
                          final double overlap = minDistance - dist;
                          final Offset push = dir * (overlap * 0.5);
                          centers[i] -= push;
                          centers[j] += push;
                        }
                      }
                    }
                    
                    // Soft elastic boundary repulsion (keeps them safely inside constraints)
                    for (int i = 0; i < count; i++) {
                      double cx = centers[i].dx;
                      double cy = centers[i].dy;

                      if (maxX > minX) {
                        if (cx < minX) {
                          cx += (minX - cx) * 0.42;
                        } else if (cx > maxX) {
                          cx -= (cx - maxX) * 0.42;
                        }
                      } else {
                        cx = availW / 2;
                      }

                      if (maxY > minY) {
                        if (cy < minY) {
                          cy += (minY - cy) * 0.42;
                        } else if (cy > maxY) {
                          cy -= (cy - maxY) * 0.42;
                        }
                      } else {
                        cy = availH / 2;
                      }

                      centers[i] = Offset(cx, cy);
                    }
                  }

                  return Center(
                    child: SizedBox(
                      width: availW,
                      height: availH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: List.generate(count, (cellIndex) {
                          final center = centers[cellIndex];
                          final double left = center.dx - boardSize / 2;
                          final double top = center.dy - boardSize / 2;

                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutBack,
                            left: left,
                            top: top,
                            width: boardSize,
                            height: boardSize,
                            child: FlyInWrapper(
                              key: ValueKey('bw_${controller.matchId}_$cellIndex'),
                              index: cellIndex,
                              child: BoardWidget(boardIndex: cellIndex),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (controller.isOverallGameOver && controller.matchWinner != null)
              const Positioned.fill(child: ConfettiOverlay()),
          ],
        );
      },
    );
  }

  Widget _buildShakeWrapper(GameController controller, Widget child) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(controller.shakeCounter),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticIn,
      builder: (context, value, child) {
        final double shake =
            (value > 0 && value < 1.0) ? sin(value * pi * 4) * 12.0 : 0.0;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: child,
    );
  }
}
