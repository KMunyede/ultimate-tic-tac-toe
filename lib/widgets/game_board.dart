import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_controller.dart';
import 'board_widget.dart';

class MultiBoardView extends StatelessWidget {
  const MultiBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        final boards = controller.boards;

        if (boards.length == 1) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450, maxHeight: 450),
                child: _buildBoard(context, 0, 'Board 1'),
              ),
            ),
          );
        }

        if (boards.length == 2) {
          return OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;
              return Center(
                child: Flex(
                  direction: isLandscape ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: _buildBoard(context, 0, 'Board 1')),
                    Flexible(child: _buildBoard(context, 1, 'Board 2')),
                  ],
                ),
              );
            },
          );
        }

        if (boards.length == 3) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 1),
                      Expanded(
                        flex: 2,
                        child: _buildBoard(context, 0, 'Board 1'),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildBoard(context, 1, 'Board 2'),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildBoard(context, 2, 'Board 3'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        if (boards.length == 4) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _buildBoard(context, 0, 'Board 1')),
                      Expanded(child: _buildBoard(context, 1, 'Board 2')),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _buildBoard(context, 2, 'Board 3')),
                      Expanded(child: _buildBoard(context, 3, 'Board 4')),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return const Center(child: Text("Unsupported Board Count"));
      },
    );
  }

  Widget _buildBoard(BuildContext context, int index, String label) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: BoardWidget(boardIndex: index),
            ),
          ),
        ],
      ),
    );
  }
}
