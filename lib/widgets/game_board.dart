// lib/widgets/game_board.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/game/logic/game_controller.dart';
import '../features/settings/logic/settings_controller.dart';
import '../utils/responsive_layout.dart';
import '../utils/board_layout_engine.dart';
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
    final responsive = ResponsiveLayout(context);

    return Consumer2<GameController, SettingsController>(
      builder: (context, controller, settings, child) {
        final boards = controller.boards;
        final int count = boards.length;
        if (count == 0) return const SizedBox.shrink();

        final templates = SettingsController.getTemplatesForCount(count);
        final selectedTemplate =
            templates[settings.layoutIndex % templates.length];

        return Stack(
          children: [
            _buildShakeWrapper(
              controller,
              LayoutBuilder(
                builder: (context, constraints) {
                  final EdgeInsets safePadding = responsive.screenPadding;
                  final double rawAvailW =
                      max(0.0, constraints.maxWidth - safePadding.horizontal);
                  final double rawAvailH =
                      max(0.0, constraints.maxHeight - safePadding.vertical);

                  double availW = rawAvailW;
                  double availH = rawAvailH;
                  if (availW > availH * 1.6) {
                    availW = availH * 1.6;
                  }

                  final layoutData = BoardLayoutEngine.calculateLayout(
                    count: count,
                    templatePositions: selectedTemplate.positions,
                    availW: availW,
                    availH: availH,
                  );

                  final double boardSize = layoutData.boardSize;
                  final centers = layoutData.centers;

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
                              key: ValueKey(
                                  'bw_${controller.matchId}_$cellIndex'),
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
