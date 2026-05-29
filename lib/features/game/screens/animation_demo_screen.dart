import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart' hide LinearGradient;

class AnimationDemoScreen extends StatefulWidget {
  const AnimationDemoScreen({super.key});

  @override
  State<AnimationDemoScreen> createState() => _AnimationDemoScreenState();
}

class _AnimationDemoScreenState extends State<AnimationDemoScreen> {
  bool _playLottieCelebration = false;
  
  // Rive Controller properties
  SMIBool? _hoverInput;
  SMITrigger? _pressInput;

  void _onRiveInit(Artboard artboard) {
    // We are using a public Rive file containing a button state machine
    // This state machine has "Hover" (boolean) and "Press" (trigger) inputs
    final controller = StateMachineController.fromArtboard(artboard, 'Button');
    if (controller != null) {
      artboard.addController(controller);
      _hoverInput = controller.findInput<bool>('Hover') as SMIBool?;
      _pressInput = controller.findInput<bool>('Press') as SMITrigger?;
    }
  }

  void _triggerCelebration() {
    setState(() {
      _playLottieCelebration = true;
    });
    // Reset celebration after 4.5 seconds
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        setState(() {
          _playLottieCelebration = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Graphics Lab'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF0F1016) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 1,
      ),
      body: Stack(
        children: [
          // Background soft ambient mesh
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0A0B10), const Color(0xFF161928)]
                    : [const Color(0xFFF3F5F9), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main contents
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Test Lottie & Rive animations live in your app! Sourced from official CDN repositories.',
                          style: TextStyle(
                            color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 1: Interactive Rive Controller
                _buildCard(
                  title: '1. Rive State-Machine Tile Button',
                  description: 'This button uses a vector state machine. Hover to breathe, press to trigger elastic expansion waves!',
                  isDark: isDark,
                  child: MouseRegion(
                    onEnter: (_) => _hoverInput?.value = true,
                    onExit: (_) => _hoverInput?.value = false,
                    child: GestureDetector(
                      onTap: () {
                        _pressInput?.fire();
                        _triggerCelebration();
                      },
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: RiveAnimation.network(
                              'https://cdn.rive.app/animations/skills.riv',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              onInit: _onRiveInit,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 2: Lottie Vector HUD Animation
                _buildCard(
                  title: '2. Lottie Vector HUD Particle Loop',
                  description: 'Predefined animated star particles matching your high-score, level-up milestones, or tile clears.',
                  isDark: isDark,
                  child: Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.yellow.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
                      ),
                      child: ClipOval(
                        child: Lottie.network(
                          'https://raw.githubusercontent.com/lottie-react/lottie-react/master/stories/glowing-star.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Developer Splicing Notes
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E212E) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 How to splice this into your active grid:',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletPoint('1. Swap RiveAnimation.network with RiveAnimation.asset(\'assets/...\') once local assets are downloaded.'),
                      _buildBulletPoint('2. Wrap each BoardWidget tile with Rive to have them physically stretch, bounce, or react on tap.'),
                      _buildBulletPoint('3. Use Lottie.asset inside custom Stack overlays on game completion to paint fireworks/match victories.'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lottie celebration overlay triggered by Rive button tap
          if (_playLottieCelebration)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.network(
                  'https://lottie.host/933a39e8-466d-4749-9dfb-f06b6b7cf95e/GqLgWkPlv3.json',
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151821) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
