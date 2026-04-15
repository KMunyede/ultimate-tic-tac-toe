import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return DefaultTabController(
      length: 3,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SelectionArea(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Help & About', style: textTheme.headlineSmall),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Standard'),
                    Tab(text: 'Majority'),
                    Tab(text: 'Ultimate'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildStandardTab(textTheme),
                      _buildMajorityTab(textTheme),
                      _buildUltimateTab(textTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardTab(TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Classic Rules', textTheme),
          _buildBulletPoint('Get 3 symbols in a row, column, or diagonal to win a board.'),
          _buildBulletPoint('Standard Tic-Tac-Toe rules apply to each 3x3 grid.'),
          _buildBulletPoint('In Standard mode, you can play with 1 or 2 boards.'),
          const SizedBox(height: 16),
          _buildSectionTitle('Winning & Draws', textTheme),
          _buildBulletPoint('Win (1 Board): Achieve 3-in-a-row on the single board.'),
          _buildBulletPoint('Win (2 Boards): You MUST win BOTH boards to win the match.'),
          _buildBulletPoint('Draw (2 Boards): A draw occurs if no player wins both boards (e.g., if each player wins one board, or if any board is a draw).'),
        ],
      ),
    );
  }

  Widget _buildMajorityTab(TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Majority Wins Mode', textTheme),
          _buildBulletPoint('Total victory is determined by how many small boards you win.'),
          _buildBulletPoint('Play with 1 to 9 boards.'),
          const SizedBox(height: 16),
          _buildSectionTitle('Win Conditions by Board Count', textTheme),
          _buildBulletPoint('2 Boards: Must win BOTH boards to win match (follows Standard Rules).'),
          _buildBulletPoint('3 Boards: Must win at least 2 boards to win match.'),
          _buildBulletPoint('4-9 Boards: Must win more than half of the boards (e.g., 5 out of 9).'),
          const SizedBox(height: 16),
          _buildSectionTitle('Status Messages (3 Boards)', textTheme),
          _buildBulletPoint('"Player X/O Wins": Won 2 or 3 boards.'),
          _buildBulletPoint('"Nice Effort. No overall wins": Only 1 board won out of 3.'),
          _buildBulletPoint('"No wins. Try again": 0 out of 3 boards won.'),
        ],
      ),
    );
  }

  Widget _buildUltimateTab(TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('The Forcing Mechanic', textTheme),
          _buildBulletPoint('Where you play in a small board determines where your opponent MUST play next.'),
          const SizedBox(height: 8),
          const Text(
            'Example: If you play on the top right cell of the top right board then opponent has to play on the top right board of the BIG board.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          const Text('The BIG board has the layout below:'),
          _buildGridLayout('1', '2', '3', '4', '5', '6', '7', '8', '9'),
          const Text('And each of the smaller boards also has the same layout:'),
          _buildGridLayout('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'),
          const SizedBox(height: 8),
          const Text(
            'If a player plays tile [h] in the top right board number [3] (as seen on the bigger board), then the opponent is forced to play the smaller board [9] (as seen by the bigger board).',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Visual Guide', textTheme),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/3/30/Ultimate_Tic_Tac_Toe_Rules.gif',
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) => const Text('Could not load animation.'),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Winning & Draws', textTheme),
          _buildBulletPoint('Win: Get 3-in-a-row of WON sub-boards on the BIG board (horizontal, vertical, or diagonal).'),
          _buildBulletPoint('Draw: The BIG board is full and neither player has achieved 3-in-a-row of won sub-boards.'),
        ],
      ),
    );
  }

  Widget _buildGridLayout(String a, String b, String c, String d, String e, String f, String g, String h, String i) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text('[$a][$b][$c]', style: const TextStyle(fontFamily: 'monospace')),
          Text('[$d][$e][$f]', style: const TextStyle(fontFamily: 'monospace')),
          Text('[$g][$h][$i]', style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
