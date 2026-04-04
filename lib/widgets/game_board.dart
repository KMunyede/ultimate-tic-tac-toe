// lib/widgets/game_board.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/game/logic/game_controller.dart';
import 'board_widget.dart';
import 'animations/fly_in_wrapper.dart';
import 'animations/confetti_overlay.dart';

class MultiBoardView extends StatelessWidget {
  const MultiBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Approximate physical size calculation
    // Note: devicePixelRatio is used to convert logical pixels to physical pixels
    // Standard PPI for logical pixels is 96 or 160 depending on platform context
    // Here we use 160 as the baseline for "dp" to inches conversion
    final double diagonalInches = sqrt(pow(screenWidth / 160, 2) + pow(screenHeight / 160, 2));

    return Consumer<GameController>(
      builder: (context, controller, child) {
        final boards = controller.boards;
        final int count = boards.length;
        if (count == 0) return const SizedBox.shrink();

        return Stack(
          children: [
            _buildShakeWrapper(
              controller,
              LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape = screenWidth > screenHeight;
                  
                  // Force 3x3 for 9 boards on small landscape devices (< 7 inches)
                  bool forceThreeByThree = count == 9 && isLandscape && diagonalInches < 7.0;

                  int cols, rows;
                  if (forceThreeByThree) {
                    cols = 3;
                    rows = 3;
                  } else {
                    // Default grid logic
                    if (count <= 1) {
                      cols = 1; rows = 1;
                    } else if (count <= 2) {
                      cols = 2; rows = 1;
                    } else if (count <= 4) {
                      cols = 2; rows = 2;
                    } else if (count <= 6) {
                      cols = 3; rows = 2;
                    } else if (count <= 9) {
                      cols = 3; rows = 3;
                    } else if (count <= 12) {
                      cols = 4; rows = 3;
                    } else {
                      cols = 4; rows = 4;
                    }

                    // Adjust layout for landscape aspect ratio if not already forced
                    if (isLandscape && !forceThreeByThree) {
                      if (count == 9) {
                        cols = 3; rows = 3;
                      } else if (count > 4 && count <= 6) {
                        cols = 3; rows = 2;
                      } else if (count > 6 && count <= 8) {
                        cols = 4; rows = 2;
                      } else if (count > 9 && count <= 12) {
                        cols = 4; rows = 3;
                      }
                    }
                  }

                  double spacing = count > 9 ? 4.0 : (count > 4 ? 8.0 : 12.0);
                  double outerPadding = 8.0;

                  // Reduce padding and spacing for smaller screens to maximize tile size
                  if (diagonalInches < 5.5) {
                    spacing = count >= 9 ? 2.0 : 4.0;
                    outerPadding = 4.0;
                  }

                  final double availW = constraints.maxWidth - (outerPadding * 2);
                  final double availH = constraints.maxHeight - (outerPadding * 2);

                  // Tile size flexes to fill available space while maintaining square aspect ratio
                  final double boardSize = min(
                    (availW / cols) - spacing,
                    (availH / rows) - spacing,
                  ).clamp(30.0, 800.0);

                  final double gridWidth = (boardSize + spacing) * cols;
                  final double gridHeight = (boardSize + spacing) * rows;

                  return Center(
                    child: SizedBox(
                      width: gridWidth,
                      height: gridHeight,
                      child: GridView.builder(
                        padding: EdgeInsets.all(spacing / 2),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: count,
                        itemBuilder: (context, index) {
                          return FlyInWrapper(
                            key: ValueKey('bw_${boards[index].hashCode}_$index'),
                            index: index,
                            child: BoardWidget(boardIndex: index),
                          );
                        },
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
