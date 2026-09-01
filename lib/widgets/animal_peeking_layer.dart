// lib/widgets/animal_peeking_layer.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../features/settings/logic/settings_controller.dart';
import '../features/game/logic/game_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/jungle_quotes_database.dart';
import '../core/theme/pacific_quotes_database.dart';
import '../core/audio/sound_manager.dart';
import 'painters/animal_painter.dart';

class AnimalPeekingLayer extends StatefulWidget {
  const AnimalPeekingLayer({super.key});

  @override
  State<AnimalPeekingLayer> createState() => _AnimalPeekingLayerState();
}

class _AnimalPeekingLayerState extends State<AnimalPeekingLayer> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  Timer? _cycleTimer;
  Timer? _hideTimer;
  int _activeAnimalIndex = 0; // 0 = Toucan, 1 = Snake, 2 = Tree Frog, 3 = Tiger, 4 = Lion
  int _peekCount = 0; // Sequential counter to cycle peeking animals in perfect rotation
  bool _isPeeking = false;
  String _activeSpeechBubbleText = "";

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Start the peeking cycle timer
    _startPeekingCycle();
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _hideTimer?.cancel();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPeekingCycle() {
    // Cycle every 22 seconds
    _cycleTimer = Timer.periodic(const Duration(seconds: 22), (timer) {
      if (!mounted) return;
      
      final settings = Provider.of<SettingsController>(context, listen: false);
      if (settings.lowDetailMode) return;

      _triggerAnimalPeek();
    });
  }

  void _triggerAnimalPeek() {
    if (_isPeeking) return;

    final game = Provider.of<GameController>(context, listen: false);
    final settings = Provider.of<SettingsController>(context, listen: false);
    
    setState(() {
      _activeAnimalIndex = _peekCount % 5;
      _peekCount++;

      if (settings.currentTheme.name == 'Pacific Waves') {
        _activeSpeechBubbleText = PacificQuotesDatabase.analyzeStateAndGetQuote(game);
      } else {
        _activeSpeechBubbleText = JungleQuotesDatabase.analyzeStateAndGetQuote(game);
      }
      _isPeeking = true;
    });

    context.read<SoundManager>().playAnimalPeekSound(_activeAnimalIndex);

    _slideController.forward().then((_) {
      _hideTimer = Timer(const Duration(seconds: 8), () {
        _dismissAnimal();
      });
    });
  }

  void _dismissAnimal() {
    if (!mounted || !_isPeeking) return;
    if (_slideController.status == AnimationStatus.reverse) return;

    HapticFeedback.lightImpact();
    _hideTimer?.cancel();
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isPeeking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final themeName = settings.currentTheme.name;
    if ((themeName != 'Amazon Jungle' && themeName != 'Pacific Waves') || settings.lowDetailMode) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_slideController, _pulseController]),
            builder: (context, child) {
              final double slideProgress = CurvedAnimation(
                parent: _slideController,
                curve: Curves.elasticOut,
                reverseCurve: Curves.easeInBack,
              ).value;

              return Stack(
                children: [
                  if (_isPeeking) ...[
                    _buildActiveAnimal(w, h, slideProgress, _pulseController.value, settings.currentTheme),
                    _buildSpeechBubble(w, h, slideProgress, settings.currentTheme),
                  ]
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveAnimal(double w, double h, double slide, double pulse, AppTheme theme) {
    final double animalSize = (h * 0.18).clamp(90.0, 160.0);
    
    Offset startOffset;
    Offset targetOffset;
    Alignment alignment;

    switch (_activeAnimalIndex) {
      case 0:
        alignment = Alignment.topLeft;
        startOffset = const Offset(-120.0, -120.0);
        targetOffset = const Offset(-5.0, 45.0);
        break;
      case 1:
        alignment = Alignment.topRight;
        startOffset = const Offset(120.0, -120.0);
        targetOffset = const Offset(5.0, 45.0);
        break;
      case 2:
        alignment = Alignment.bottomLeft;
        startOffset = const Offset(-120.0, 120.0);
        targetOffset = const Offset(-5.0, -45.0);
        break;
      case 3:
        alignment = Alignment.bottomRight;
        startOffset = const Offset(120.0, 120.0);
        targetOffset = const Offset(5.0, -45.0);
        break;
      case 4:
        alignment = Alignment.centerLeft;
        startOffset = const Offset(-120.0, 0.0);
        targetOffset = const Offset(-5.0, 0.0);
        break;
      default:
        return const SizedBox.shrink();
    }

    final double px = startOffset.dx + (targetOffset.dx - startOffset.dx) * slide;
    final double py = startOffset.dy + (targetOffset.dy - startOffset.dy) * slide;

    // Real-time wave bobbing offset
    final double bobbingY = sin(pulse * 2 * pi) * 12.0;

    return Positioned(
      left: alignment.x < 0 ? 0 : null,
      right: alignment.x > 0 ? 0 : null,
      top: alignment.y < 0 ? 0 : (alignment.y == 0 ? h * 0.45 : null),
      bottom: alignment.y > 0 ? 0 : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismissAnimal,
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.distance > 200) {
            _dismissAnimal();
          }
        },
        child: Transform.translate(
          offset: Offset(px, py + bobbingY),
          child: SizedBox(
            width: animalSize,
            height: animalSize,
            child: CustomPaint(
              painter: AnimalPainter(
                animalIndex: _activeAnimalIndex,
                pulse: pulse,
                sizeFactor: animalSize,
                themeName: theme.name,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(double w, double h, double slide, AppTheme theme) {
    if (slide < 0.25) return const SizedBox.shrink();

    double bubbleTop = 0;
    double bubbleLeft = 0;
    
    final double animalSize = (h * 0.18).clamp(90.0, 160.0);
    final double bubbleWidth = (w * 0.52).clamp(160.0, 280.0);
    
    switch (_activeAnimalIndex) {
      case 0:
        bubbleTop = 50.0 + animalSize * 0.35;
        bubbleLeft = animalSize * 0.8;
        break;
      case 1:
        bubbleTop = 50.0 + animalSize * 0.35;
        bubbleLeft = w - bubbleWidth - animalSize * 0.8;
        break;
      case 2:
        bubbleTop = h - animalSize * 0.8 - 60.0;
        bubbleLeft = animalSize * 0.8;
        break;
      case 3:
        bubbleTop = h - animalSize * 0.8 - 60.0;
        bubbleLeft = w - bubbleWidth - animalSize * 0.8;
        break;
      case 4:
        bubbleTop = h * 0.45 - 20.0;
        bubbleLeft = animalSize * 0.8;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      left: bubbleLeft,
      top: bubbleTop,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismissAnimal,
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.distance > 200) {
            _dismissAnimal();
          }
        },
        child: Opacity(
          opacity: ((slide - 0.25) / 0.75).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.5 + 0.5 * slide,
            child: Container(
            width: bubbleWidth,
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: theme.boardBg.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: theme.accentGlow.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Text(
              _activeSpeechBubbleText,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
