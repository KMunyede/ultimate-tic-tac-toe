import 'dart:math';
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
        final int count = boards.length;

        if (count == 0) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            const double spacing = 16.0;
            const double padding = 12.0;
            // Height reserved for the "Board X" label and spacing
            const double labelAreaHeight = 28.0; 

            // Determine layout based on board count and screen orientation
            final int itemsPerRow;
            if (count == 1) {
              itemsPerRow = 1;
            } else if (count == 2) {
              // For 2 boards, adapt to screen aspect ratio to maximize space usage
              if (constraints.maxWidth > constraints.maxHeight) {
                itemsPerRow = 2; // Horizontal for landscape
              } else {
                itemsPerRow = 1; // Vertical for portrait
              }
            } else if (count > 6) {
              itemsPerRow = 3;
            } else {
              itemsPerRow = 2;
            }

            final int rowCount = (count / itemsPerRow).ceil();

            // Calculate max width possible for a board to fit in the row
            final double maxBoardWidth =
                (constraints.maxWidth - (padding * 2) - (spacing * (itemsPerRow - 1))) / itemsPerRow;

            // Calculate max height possible for a board to fit in the column (accounting for labels)
            final double maxBoardHeight =
                (constraints.maxHeight - (padding * 2) - (spacing * (rowCount - 1)) - (labelAreaHeight * rowCount)) / rowCount;

            // Use the smaller dimension to ensure the square board fits both ways.
            // Increased the upper clamp to 600.0 to allow growth on tablets/desktops.
            final double boardSize = min(maxBoardWidth, maxBoardHeight).clamp(100.0, 600.0);

            List<Widget> rows = [];
            for (int i = 0; i < count; i += itemsPerRow) {
              List<Widget> rowChildren = [];

              for (int j = 0; j < itemsPerRow; j++) {
                final int boardIndex = i + j;
                if (boardIndex < count) {
                  rowChildren.add(
                    _buildBoard(context, boardIndex, 'Board ${boardIndex + 1}', boardSize),
                  );
                }
              }

              List<Widget> spacedRowChildren = [];
              if (rowChildren.isNotEmpty) {
                spacedRowChildren.add(rowChildren.first);
                for (int k = 1; k < rowChildren.length; k++) {
                  spacedRowChildren.add(const SizedBox(width: spacing));
                  spacedRowChildren.add(rowChildren[k]);
                }
              }

              rows.add(
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: spacedRowChildren,
                ),
              );

              if (i + itemsPerRow < count) {
                rows.add(const SizedBox(height: spacing));
              }
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: rows,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBoard(BuildContext context, int index, String label, double size) {
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 4),
          AspectRatio(
            aspectRatio: 1,
            child: BoardWidget(boardIndex: index),
          ),
        ],
      ),
    );
  }
}
