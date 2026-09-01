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

                  if (rawAvailW <= 0 || rawAvailH <= 0) {
                    return const SizedBox.shrink();
                  }

                  double availW = rawAvailW;
                  double availH = rawAvailH;
                  if (availW > availH * 1.6) {
                    availW = availH * 1.6;
                  }

                  // 1. Removed zoomFactor override to constrain boards strictly to physical screen!
                  final double virtualW = availW;
                  final double virtualH = availH;

                  final layoutData = BoardLayoutEngine.calculateLayout(
                    count: count,
                    templatePositions: selectedTemplate.positions,
                    availW: virtualW,
                    availH: virtualH,
                  );

                  final double boardSize = layoutData.boardSize;
                  final centers = layoutData.centers;

                  Widget boardStack = SizedBox(
                    width: virtualW,
                    height: virtualH,
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
                          child: FloatingPhysicsWrapper(
                            index: cellIndex,
                            isLowDetail: settings.lowDetailMode,
                            child: FlyInWrapper(
                              key: ValueKey(
                                  'bw_${controller.matchId}_$cellIndex'),
                              index: cellIndex,
                              child: BoardWidget(boardIndex: cellIndex),
                            ),
                          ),
                        );
                      }),
                    ),
                  );

                  return Center(child: boardStack);
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

class FloatingPhysicsWrapper extends StatefulWidget {
  final Widget child;
  final int index;
  final bool isLowDetail;
  
  const FloatingPhysicsWrapper({super.key, required this.child, required this.index, this.isLowDetail = false});

  @override
  State<FloatingPhysicsWrapper> createState() => _FloatingPhysicsWrapperState();
}

class _FloatingPhysicsWrapperState extends State<FloatingPhysicsWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLowDetail) return widget.child;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Use a continuous sine wave based on time and index offset
        final double phase = (widget.index * 1.8) + (_controller.value * 2 * pi);
        final double offsetY = sin(phase) * 5.0; // gentle 5px bobbing
        final double rotZ = cos(phase * 0.9) * 0.012; // very subtle sway
        
        return Transform(
          transform: Matrix4.translationValues(0.0, offsetY, 0.0)
            ..rotateZ(rotZ),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

