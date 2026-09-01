// lib/widgets/profile/admin_debug_tab.dart
import 'package:flutter/material.dart';
import '../../services/stats_service.dart';
import '../../models/player_stats.dart';
import '../../core/theme/app_theme.dart';

class AdminDebugTab extends StatelessWidget {
  final StatsService statsService;
  final AppTheme theme;
  final bool isSimulatedAdmin;
  final bool mockDoubleXp;
  final bool mockDevLogs;
  final Function(bool) onSimulatedAdminChanged;
  final Function(bool) onMockDoubleXpChanged;
  final Function(bool) onMockDevLogsChanged;
  final Function(String) showFeedback;

  const AdminDebugTab({
    super.key,
    required this.statsService,
    required this.theme,
    required this.isSimulatedAdmin,
    required this.mockDoubleXp,
    required this.mockDevLogs,
    required this.onSimulatedAdminChanged,
    required this.onMockDoubleXpChanged,
    required this.onMockDevLogsChanged,
    required this.showFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF212121), Color(0xFF000000)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF8F00), width: 1.5),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal_rounded, color: Color(0xFFFF8F00), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Operational Control Center',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time database triggers, mock telemetry displays, and statistics injector overrides.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('System Telemetry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textColor)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.scaffoldBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildTelemetryRow('Server Latency', '24ms (Excellent)', Colors.green),
                const Divider(height: 10),
                _buildTelemetryRow('Firestore Write Queue', '0 / 100 (Idle)', Colors.green),
                const Divider(height: 10),
                _buildTelemetryRow('Mock Online Users', '1,482 active', Colors.blue),
                const Divider(height: 10),
                _buildTelemetryRow('API Connection State', '100% Operational', Colors.teal),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Interactive Statistics Injector', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textColor)),
          const SizedBox(height: 6),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _buildInjectorButton(
                icon: Icons.bolt_rounded,
                label: 'Inject +500 XP',
                color: Colors.purple.shade700,
                onPressed: () async {
                  final s = statsService.stats;
                  await statsService.updateCustomStats(s.copyWith(totalXp: s.totalXp + 500));
                  showFeedback('Injected +500 XP successfully!');
                },
              ),
              _buildInjectorButton(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak +5 wins',
                color: Colors.orange.shade800,
                onPressed: () async {
                  final s = statsService.stats;
                  final nextStreak = s.currentStreak + 5;
                  final nextMax = s.maxStreak < nextStreak ? nextStreak : s.maxStreak;
                  await statsService.updateCustomStats(s.copyWith(currentStreak: nextStreak, maxStreak: nextMax));
                  showFeedback('Streak set to $nextStreak wins!');
                },
              ),
              _buildInjectorButton(
                icon: Icons.smart_toy_rounded,
                label: 'Mock AI Wins (+3)',
                color: Colors.teal.shade800,
                onPressed: () async {
                  final s = statsService.stats;
                  await statsService.updateCustomStats(s.copyWith(
                    winsVsAiMedium: s.winsVsAiMedium + 3,
                    winsVsAiHard: s.winsVsAiHard + 3,
                  ));
                  showFeedback('Injected +6 total AI Wins!');
                },
              ),
              _buildInjectorButton(
                icon: Icons.refresh_rounded,
                label: 'Reset Stats to 0',
                color: Colors.red.shade900,
                onPressed: () async {
                  await statsService.updateCustomStats(const PlayerStats());
                  showFeedback('All statistics reset to clean zeroed slate.');
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('System State Simulation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textColor)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: theme.scaffoldBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  value: mockDoubleXp,
                  onChanged: onMockDoubleXpChanged,
                  title: const Text('Simulate Double XP Boost', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  dense: true,
                  activeThumbColor: const Color(0xFFFF8F00),
                  activeTrackColor: const Color(0xFFFFCC80),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: mockDevLogs,
                  onChanged: onMockDevLogsChanged,
                  title: const Text('Simulate Developer Logs', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  dense: true,
                  activeThumbColor: const Color(0xFFFF8F00),
                  activeTrackColor: const Color(0xFFFFCC80),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: isSimulatedAdmin,
                  onChanged: onSimulatedAdminChanged,
                  title: const Text('Simulation Mode (Admin Active)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  dense: true,
                  activeThumbColor: const Color(0xFFFF8F00),
                  activeTrackColor: const Color(0xFFFFCC80),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(String key, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontSize: 11.5)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInjectorButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }
}
