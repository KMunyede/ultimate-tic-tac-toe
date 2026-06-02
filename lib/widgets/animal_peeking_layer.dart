// lib/widgets/animal_peeking_layer.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../features/settings/logic/settings_controller.dart';
import '../features/game/logic/game_controller.dart';
import '../core/theme/jungle_quotes_database.dart';
import '../core/audio/sound_manager.dart';

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
      if (settings.currentTheme.name != 'Amazon Jungle' || settings.lowDetailMode) {
        return;
      }

      _triggerAnimalPeek();
    });
  }

  void _triggerAnimalPeek() {
    if (_isPeeking) return;

    final game = Provider.of<GameController>(context, listen: false);
    
    setState(() {
      // 1. Cycle active peeking animal sequentially to ensure perfect balanced rotation
      _activeAnimalIndex = _peekCount % 5;
      _peekCount++;

      // 2. Fetch a short, sweet game phrase from the database
      _activeSpeechBubbleText = JungleQuotesDatabase.analyzeStateAndGetQuote(game);
      _isPeeking = true;
    });

    // Play animal peeking sound!
    context.read<SoundManager>().playAnimalPeekSound(_activeAnimalIndex);

    // Slide in
    _slideController.forward().then((_) {
      // Keep animal in view for 8 seconds, then slide out
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
    if (settings.currentTheme.name != 'Amazon Jungle' || settings.lowDetailMode) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        return AnimatedBuilder(
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
                  _buildActiveAnimal(w, h, slideProgress, _pulseController.value),
                  _buildSpeechBubble(w, h, slideProgress),
                ]
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActiveAnimal(double w, double h, double slide, double pulse) {
    final double animalSize = (h * 0.18).clamp(90.0, 160.0);
    
    Offset startOffset;
    Offset targetOffset;
    Alignment alignment;

    switch (_activeAnimalIndex) {
      case 0: // Toucan - Top Left
        alignment = Alignment.topLeft;
        startOffset = const Offset(-120.0, -120.0);
        targetOffset = const Offset(-5.0, 45.0);
        break;
      case 1: // Snake - Top Right
        alignment = Alignment.topRight;
        startOffset = const Offset(120.0, -120.0);
        targetOffset = const Offset(5.0, 45.0);
        break;
      case 2: // Tree Frog - Bottom Left
        alignment = Alignment.bottomLeft;
        startOffset = const Offset(-120.0, 120.0);
        targetOffset = const Offset(-5.0, -45.0);
        break;
      case 3: // Tiger - Bottom Right
        alignment = Alignment.bottomRight;
        startOffset = const Offset(120.0, 120.0);
        targetOffset = const Offset(5.0, -45.0);
        break;
      case 4: // Lion - Middle Left
        alignment = Alignment.centerLeft;
        startOffset = const Offset(-120.0, 0.0);
        targetOffset = const Offset(-5.0, 0.0);
        break;
      default:
        return const SizedBox.shrink();
    }

    final double px = startOffset.dx + (targetOffset.dx - startOffset.dx) * slide;
    final double py = startOffset.dy + (targetOffset.dy - startOffset.dy) * slide;

    return Positioned(
      left: alignment.x < 0 ? 0 : null,
      right: alignment.x > 0 ? 0 : null,
      top: alignment.y < 0 ? 0 : (alignment.y == 0 ? h * 0.45 : null),
      bottom: alignment.y > 0 ? 0 : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismissAnimal,
        onPanEnd: (details) {
          // If swipe velocity is high enough, dismiss
          if (details.velocity.pixelsPerSecond.distance > 200) {
            _dismissAnimal();
          }
        },
        child: Transform.translate(
          offset: Offset(px, py),
          child: SizedBox(
            width: animalSize,
            height: animalSize,
            child: CustomPaint(
              painter: AnimalPainter(
                animalIndex: _activeAnimalIndex,
                pulse: pulse,
                sizeFactor: animalSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(double w, double h, double slide) {
    if (slide < 0.25) return const SizedBox.shrink();

    double bubbleTop = 0;
    double bubbleLeft = 0;
    
    final double animalSize = (h * 0.18).clamp(90.0, 160.0);
    final double bubbleWidth = (w * 0.52).clamp(160.0, 280.0);
    
    switch (_activeAnimalIndex) {
      case 0: // Toucan - Top Left
        bubbleTop = 50.0 + animalSize * 0.35;
        bubbleLeft = animalSize * 0.8;
        break;
      case 1: // Snake - Top Right
        bubbleTop = 50.0 + animalSize * 0.35;
        bubbleLeft = w - bubbleWidth - animalSize * 0.8;
        break;
      case 2: // Tree Frog - Bottom Left
        bubbleTop = h - animalSize * 0.8 - 60.0;
        bubbleLeft = animalSize * 0.8;
        break;
      case 3: // Tiger - Bottom Right
        bubbleTop = h - animalSize * 0.8 - 60.0;
        bubbleLeft = w - bubbleWidth - animalSize * 0.8;
        break;
      case 4: // Lion - Middle Left
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
              color: const Color(0xFF3E2723).withValues(alpha: 0.95), // mahogany bark theme card
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color(0xFFFFB300).withValues(alpha: 0.6), // golden sheen border
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
              style: const TextStyle(
                color: Color(0xFFFFFDF4), // pale forest mist text
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

class AnimalPainter extends CustomPainter {
  final int animalIndex;
  final double pulse;
  final double sizeFactor;

  AnimalPainter({
    required this.animalIndex,
    required this.pulse,
    required this.sizeFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (animalIndex) {
      case 0:
        _drawToucan(canvas, size);
        break;
      case 1:
        _drawSnake(canvas, size);
        break;
      case 2:
        _drawTreeFrog(canvas, size);
        break;
      case 3:
        _drawTiger(canvas, size);
        break;
      case 4:
        _drawLion(canvas, size);
        break;
    }
  }

  void _drawToucan(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Draw wood bark-textured branch
    final paintBranch = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = h * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-10, h * 0.85), Offset(w * 0.85, h * 0.85), paintBranch);
    
    // Branch bark details (fine dark ridges)
    final paintBranchBark = Paint()
      ..color = const Color(0xFF27120E)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h * 0.83), Offset(w * 0.75, h * 0.83), paintBranchBark);
    canvas.drawLine(Offset(w * 0.2, h * 0.87), Offset(w * 0.8, h * 0.87), paintBranchBark);

    // Dynamic warm golden grain highlights
    final paintBranchHighlight = Paint()
      ..color = const Color(0x28FFD54F)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h * 0.88), Offset(w * 0.7, h * 0.88), paintBranchHighlight);

    // Toucan Body (layered feathers / black plumage)
    final paintPlumage = Paint()..color = const Color(0xFF0F200C);
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.25, w * 0.45, h * 0.60), paintPlumage);

    // Overlapping realistic black feather scales strokes for rich texture
    final paintFeatherAccent = Paint()
      ..color = const Color(0xFF060B05)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (double fy = h * 0.35; fy < h * 0.75; fy += h * 0.07) {
      canvas.drawArc(Rect.fromLTWH(w * 0.2, fy, w * 0.15, h * 0.05), 0.2, pi - 0.4, false, paintFeatherAccent);
    }

    // Multi-layered back feather wings with colorful neon tips
    final paintWing = Paint()..color = const Color(0xFF071105);
    canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.35, w * 0.22, h * 0.45), paintWing);
    
    final paintWingTip = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromLTWH(w * 0.06, h * 0.4, w * 0.18, h * 0.35), 0.5, pi - 1.0, false, paintWingTip);
    
    // Creamy white breast chest bib
    final paintBib = Paint()..color = const Color(0xFFFFFDE7);
    canvas.drawOval(Rect.fromLTWH(w * 0.18, h * 0.28, w * 0.32, h * 0.36), paintBib);
    
    // Detailed fine feathers on chest bib (texture lines)
    final paintBibFeather = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.15, h * 0.1), 0.3, pi - 0.6, false, paintBibFeather);
    canvas.drawArc(Rect.fromLTWH(w * 0.26, h * 0.44, w * 0.15, h * 0.1), 0.3, pi - 0.6, false, paintBibFeather);
    
    // Orange-red accent plumage under the bib
    final paintAccentPlumage = Paint()..color = const Color(0xFFFF3D00);
    canvas.drawOval(Rect.fromLTWH(w * 0.26, h * 0.58, w * 0.15, h * 0.08), paintAccentPlumage);

    // Beak Animation (swinging on pivot based on pulse)
    final double beakWiggle = sin(pulse * 4.0 * pi) * 0.06;
    canvas.save();
    canvas.translate(w * 0.33, h * 0.45);
    canvas.rotate(beakWiggle);

    // Shaded giant yellow bill (rich yellow to orange-red gradient)
    final paintBill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEE58), Color(0xFFFF9800), Color(0xFFD84315)],
        stops: [0.2, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, -h * 0.22, w * 0.56, h * 0.36));
    
    final pathBill = Path()
      ..moveTo(0, -h * 0.13)
      ..quadraticBezierTo(w * 0.32, -h * 0.26, w * 0.54, -h * 0.06) // giant curved upper bill
      ..quadraticBezierTo(w * 0.22, h * 0.09, 0, h * 0.09)
      ..close();
    canvas.drawPath(pathBill, paintBill);

    // Realistic beak dividing crease line
    final paintCrease = Paint()
      ..color = const Color(0xFF2E1C0C).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, -h * 0.03), Offset(w * 0.45, -h * 0.05), paintCrease);

    // Black tip on bill
    final paintTip = Paint()..color = const Color(0xFF0F200C);
    final pathTip = Path()
      ..moveTo(w * 0.42, -h * 0.11)
      ..quadraticBezierTo(w * 0.46, -h * 0.13, w * 0.54, -h * 0.06)
      ..quadraticBezierTo(w * 0.44, h * 0.05, w * 0.40, 0)
      ..close();
    canvas.drawPath(pathTip, paintTip);

    canvas.restore();

    // Friendly bright blue eye skin ring
    final paintEyeRing = Paint()..color = const Color(0xFF00B0FF);
    canvas.drawCircle(Offset(w * 0.28, h * 0.38), h * 0.072, paintEyeRing);

    // Premium gold eye ring
    final paintGoldRing = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.28, h * 0.38), h * 0.052, paintGoldRing);

    final bool isBlinking = sin(pulse * 2.0 * pi) > 0.95;
    if (!isBlinking) {
      canvas.drawCircle(Offset(w * 0.28, h * 0.38), h * 0.040, Paint()..color = const Color(0xFFFFCC80));
      canvas.drawCircle(Offset(w * 0.28, h * 0.38), h * 0.028, Paint()..color = Colors.black);
      // Dual white specular highlights
      canvas.drawCircle(Offset(w * 0.295, h * 0.365), h * 0.012, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w * 0.265, h * 0.395), h * 0.006, Paint()..color = Colors.white);
    } else {
      final paintSlit = Paint()
        ..color = const Color(0xFF0F200C)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.24, h * 0.38), Offset(w * 0.32, h * 0.38), paintSlit);
    }

    // Textured claws gripping the branch
    final paintClaws = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.32, h * 0.8), Offset(w * 0.30, h * 0.88), paintClaws);
    canvas.drawLine(Offset(w * 0.35, h * 0.8), Offset(w * 0.34, h * 0.88), paintClaws);
    canvas.drawLine(Offset(w * 0.38, h * 0.8), Offset(w * 0.38, h * 0.88), paintClaws);
  }

  void _drawSnake(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Draw hanging vine
    final paintVine = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = h * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final pathVine = Path()
      ..moveTo(w * 0.8, -10)
      ..cubicTo(w * 0.65, h * 0.25, w * 0.72, h * 0.6, w * 0.55, h * 0.85);
    canvas.drawPath(pathVine, paintVine);

    // Green leaves on vine with sharp defined borders
    final paintLeaf = Paint()..color = const Color(0xFF1B5E20);
    final paintLeafBorder = Paint()
      ..color = const Color(0xFF0F3813)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final rectLeaf1 = Rect.fromLTWH(w * 0.71, h * 0.18, w * 0.12, h * 0.06);
    final rectLeaf2 = Rect.fromLTWH(w * 0.60, h * 0.42, w * 0.10, h * 0.05);
    
    canvas.drawOval(rectLeaf1, paintLeaf);
    canvas.drawOval(rectLeaf1, paintLeafBorder);
    canvas.drawOval(rectLeaf2, paintLeaf);
    canvas.drawOval(rectLeaf2, paintLeafBorder);

    // 2. Coiled Emerald Green Boa Snake
    final paintSnake = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = h * 0.11
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pathSnake = Path()
      ..moveTo(w * 0.76, -5)
      ..cubicTo(w * 0.61, h * 0.22, w * 0.68, h * 0.58, w * 0.52, h * 0.72);
    canvas.drawPath(pathSnake, paintSnake);

    // Scale cross-lines ridges along body for highly realistic texture
    final paintScaleSpine = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (double st = 0.1; st < 0.95; st += 0.08) {
      final double sx = w * 0.76 + (w * 0.52 - w * 0.76) * st;
      final double sy = -5 + (h * 0.72 - (-5)) * st;
      canvas.drawLine(Offset(sx - 4, sy), Offset(sx + 4, sy + 3), paintScaleSpine);
    }

    // Alternating Scale patterns (Yellow/Lime Green diamonds on back)
    final paintScaleYellow = Paint()..color = const Color(0xFFFFEE58).withValues(alpha: 0.85);
    final paintScaleLime = Paint()..color = const Color(0xFFCBE346).withValues(alpha: 0.85);
    
    // Draw beautiful geometric scales along spine
    canvas.drawCircle(Offset(w * 0.67, h * 0.18), 3.5, paintScaleYellow);
    canvas.drawCircle(Offset(w * 0.69, h * 0.25), 3.0, paintScaleLime);
    canvas.drawCircle(Offset(w * 0.65, h * 0.32), 3.2, paintScaleYellow);
    canvas.drawCircle(Offset(w * 0.66, h * 0.39), 2.8, paintScaleLime);
    canvas.drawCircle(Offset(w * 0.63, h * 0.46), 3.0, paintScaleYellow);
    canvas.drawCircle(Offset(w * 0.61, h * 0.53), 2.6, paintScaleLime);

    // 3. Snake Head (peeking, animated pivot)
    final double headTilt = sin(pulse * 3 * pi) * 0.08;
    canvas.save();
    canvas.translate(w * 0.52, h * 0.74);
    canvas.rotate(headTilt);

    final paintHead = Paint()..color = const Color(0xFF2E7D32);
    final pathHead = Path()
      ..moveTo(-w * 0.08, -h * 0.05)
      ..quadraticBezierTo(0, -h * 0.14, w * 0.08, -h * 0.05)
      ..quadraticBezierTo(w * 0.1, h * 0.05, 0, h * 0.08)
      ..quadraticBezierTo(-w * 0.1, h * 0.05, -w * 0.08, -h * 0.05)
      ..close();
    canvas.drawPath(pathHead, paintHead);

    // Scale highlights under head chin (ivory yellow)
    final paintChin = Paint()..color = const Color(0xFFFFF9C4);
    canvas.drawOval(Rect.fromLTWH(-w * 0.04, h * 0.01, w * 0.08, h * 0.06), paintChin);

    // Blinking Golden slit-eyes with inner iris sheens
    final bool isBlinking = sin(pulse * 1.5 * pi) > 0.93;
    if (!isBlinking) {
      final Paint eyeGlow = Paint()
        ..color = const Color(0xFFFFD54F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(-w * 0.04, -h * 0.04), 4.8, eyeGlow);
      canvas.drawCircle(Offset(w * 0.04, -h * 0.04), 4.8, eyeGlow);

      canvas.drawCircle(Offset(-w * 0.04, -h * 0.04), 4.2, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawCircle(Offset(w * 0.04, -h * 0.04), 4.2, Paint()..color = const Color(0xFFFFD54F));
      
      // Slit pupils
      canvas.drawOval(Rect.fromLTWH(-w * 0.045, -h * 0.06, 1.2, 4.0), Paint()..color = Colors.black);
      canvas.drawOval(Rect.fromLTWH(w * 0.035, -h * 0.06, 1.2, 4.0), Paint()..color = Colors.black);
      
      // Specular glare reflection dots
      canvas.drawCircle(Offset(-w * 0.035, -h * 0.05), 0.8, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w * 0.045, -h * 0.05), 0.8, Paint()..color = Colors.white);
    } else {
      final paintEyeSlit = Paint()
        ..color = const Color(0xFF1B5E20)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(-w * 0.06, -h * 0.04), Offset(-w * 0.02, -h * 0.04), paintEyeSlit);
      canvas.drawLine(Offset(w * 0.02, -h * 0.04), Offset(w * 0.06, -h * 0.04), paintEyeSlit);
    }

    // Flicking cute red fork tongue
    final double tongueLength = sin(pulse * 15 * pi) > 0.4 ? 12.0 : 0.0;
    if (tongueLength > 0) {
      final paintTongue = Paint()
        ..color = const Color(0xFFE53935)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, h * 0.075), Offset(0, h * 0.075 + tongueLength), paintTongue);
      canvas.drawLine(Offset(0, h * 0.075 + tongueLength), Offset(-3, h * 0.075 + tongueLength + 3), paintTongue);
      canvas.drawLine(Offset(0, h * 0.075 + tongueLength), Offset(3, h * 0.075 + tongueLength + 3), paintTongue);
    }

    canvas.restore();
  }

  void _drawTreeFrog(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Hyper-realistic giant jungle leaf with detailed branching leaf veins (painted first as background)
    final paintLeaf = Paint()..color = const Color(0xFF1B5E20);
    final pathLeaf = Path()
      ..moveTo(-10, h)
      ..quadraticBezierTo(w * 0.45, h * 0.30, w * 1.1, h * 0.92)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(pathLeaf, paintLeaf);

    // Sharp outer border outline for defined leaf edges
    final paintLeafBorder = Paint()
      ..color = const Color(0xFF0F3813)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pathLeaf, paintLeafBorder);
    
    // Leaf vein paths (beautiful branching structure)
    final paintVein = Paint()
      ..color = const Color(0xFF388E3C).withValues(alpha: 0.8)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final paintVeinThin = Paint()
      ..color = const Color(0xFF388E3C).withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(-10, h), Offset(w * 0.55, h * 0.65), paintVein); // main stem
    // side veins
    canvas.drawLine(Offset(w * 0.15, h * 0.88), Offset(w * 0.25, h * 0.75), paintVein);
    canvas.drawLine(Offset(w * 0.25, h * 0.75), Offset(w * 0.15, h * 0.70), paintVeinThin);
    canvas.drawLine(Offset(w * 0.25, h * 0.75), Offset(w * 0.32, h * 0.68), paintVeinThin);

    canvas.drawLine(Offset(w * 0.32, h * 0.78), Offset(w * 0.42, h * 0.68), paintVein);
    canvas.drawLine(Offset(w * 0.42, h * 0.68), Offset(w * 0.35, h * 0.60), paintVeinThin);
    canvas.drawLine(Offset(w * 0.42, h * 0.68), Offset(w * 0.50, h * 0.65), paintVeinThin);

    // 2. Vocal sac croaking expansion (glowing orange-yellow bubble under the neck)
    final double croakExpansion = 0.5 + 0.5 * sin(pulse * 3.5 * pi);
    final paintVocal = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.32, h * 0.68), h * (0.04 + croakExpansion * 0.08), paintVocal);

    // 3. Frog Snout & Head Base (vibrant lime green skin)
    final paintFrog = Paint()..color = const Color(0xFF4CAF50);
    final paintShadow = Paint()..color = const Color(0xFF1B5E20)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    // Face / head base peeking out
    canvas.drawOval(Rect.fromLTWH(w * 0.14, h * 0.45, w * 0.38, h * 0.25), paintFrog);

    // Spotted skin texture details (clusters of green and gold spots)
    final Paint spottedPaintGold = Paint()..color = const Color(0xFF8BC34A).withValues(alpha: 0.85);
    final Paint spottedPaintDark = Paint()..color = const Color(0xFF33691E).withValues(alpha: 0.65);
    
    canvas.drawCircle(Offset(w * 0.22, h * 0.58), 2.2, spottedPaintGold);
    canvas.drawCircle(Offset(w * 0.24, h * 0.59), 1.2, spottedPaintDark);
    canvas.drawCircle(Offset(w * 0.26, h * 0.61), 1.8, spottedPaintGold);
    canvas.drawCircle(Offset(w * 0.38, h * 0.59), 2.5, spottedPaintGold);
    canvas.drawCircle(Offset(w * 0.39, h * 0.57), 1.4, spottedPaintDark);
    canvas.drawCircle(Offset(w * 0.42, h * 0.63), 1.6, spottedPaintGold);

    // Bulging flanks with signature Blue-and-Yellow stripes!
    final paintBlueStripe = Paint()..color = const Color(0xFF0D47A1);
    final paintYellowStripe = Paint()..color = const Color(0xFFFFEB3B);
    final double flankX = w * 0.46;
    final double flankY = h * 0.62;
    canvas.drawRect(Rect.fromLTWH(flankX, flankY, w * 0.07, h * 0.08), paintBlueStripe);
    canvas.drawRect(Rect.fromLTWH(flankX + w * 0.02, flankY, w * 0.012, h * 0.08), paintYellowStripe);
    canvas.drawRect(Rect.fromLTWH(flankX + w * 0.04, flankY, w * 0.012, h * 0.08), paintYellowStripe);

    // Snout contours & smile line
    final Paint mouthPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromLTWH(w * 0.24, h * 0.55, w * 0.18, h * 0.08), 0.2, pi - 0.4, false, mouthPaint);

    // Nostril dots
    canvas.drawCircle(Offset(w * 0.30, h * 0.53), 1.2, Paint()..color = const Color(0xFF1B5E20));
    canvas.drawCircle(Offset(w * 0.36, h * 0.53), 1.2, Paint()..color = const Color(0xFF1B5E20));

    // 4. Two Bulging Red Eyes (ruby red with gold inner borders and horizontal slit pupils)
    final paintEyeRed = Paint()..color = const Color(0xFFD50000);
    final paintEyeGold = Paint()..color = const Color(0xFFFFC107);
    final paintEyePupil = Paint()..color = Colors.black;

    final bool isBlinking = sin(pulse * 1.8 * pi) > 0.92;

    // Draw Left Bulging Eye
    canvas.drawCircle(Offset(w * 0.20, h * 0.44), h * 0.11, paintEyeRed);
    
    // Gold thin outline border around eye rim for added premium detail
    final Paint eyeRimBorder = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(w * 0.20, h * 0.44), h * 0.11, eyeRimBorder);

    if (!isBlinking) {
      canvas.drawCircle(Offset(w * 0.20, h * 0.44), h * 0.078, paintEyeGold);
      // Horizontal cat slit pupil
      canvas.drawOval(Rect.fromLTWH(w * 0.145, h * 0.422, w * 0.11, h * 0.035), paintEyePupil);
      // Specular reflections
      canvas.drawCircle(Offset(w * 0.185, h * 0.41), 2.2, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w * 0.215, h * 0.45), 1.0, Paint()..color = Colors.white);
    } else {
      canvas.drawCircle(Offset(w * 0.20, h * 0.44), h * 0.11, paintFrog);
      canvas.drawCircle(Offset(w * 0.20, h * 0.44), h * 0.11, paintShadow);
    }

    // Draw Right Bulging Eye (slightly smaller for depth)
    canvas.drawCircle(Offset(w * 0.44, h * 0.46), h * 0.09, paintEyeRed);
    canvas.drawCircle(Offset(w * 0.44, h * 0.46), h * 0.09, eyeRimBorder);

    if (!isBlinking) {
      canvas.drawCircle(Offset(w * 0.44, h * 0.46), h * 0.064, paintEyeGold);
      // Horizontal cat slit pupil
      canvas.drawOval(Rect.fromLTWH(w * 0.395, h * 0.445, w * 0.09, h * 0.028), paintEyePupil);
      // Specular highlights
      canvas.drawCircle(Offset(w * 0.428, h * 0.435), 1.8, Paint()..color = Colors.white);
    } else {
      canvas.drawCircle(Offset(w * 0.44, h * 0.46), h * 0.09, paintFrog);
      canvas.drawCircle(Offset(w * 0.44, h * 0.46), h * 0.09, paintShadow);
    }

    // 5. Realistic Webbed Frog Hands with Orange Suction-cup Toe Pads clutching leaf edge!
    final Paint armPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = h * 0.038
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final Paint fingerPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint padPaint = Paint()
      ..color = const Color(0xFFFF5722) // bright orange toe pads
      ..style = PaintingStyle.fill;

    // Helper to draw a clutching frog hand
    void drawClutchingHand(Offset wrist, Offset kn1, Offset kn2, Offset kn3) {
      canvas.drawLine(wrist, kn2, armPaint);
      canvas.drawLine(kn2, kn1, fingerPaint);
      canvas.drawLine(kn2, kn2 + const Offset(0, -6), fingerPaint);
      canvas.drawLine(kn2, kn3, fingerPaint);
      canvas.drawCircle(kn1, 3.5, padPaint);
      canvas.drawCircle(kn2 + const Offset(0, -6), 3.5, padPaint);
      canvas.drawCircle(kn3, 3.5, padPaint);
    }

    // Left clutching hand gripping the leaf edge at (w * 0.14, h * 0.65)
    drawClutchingHand(
      Offset(w * 0.08, h * 0.72),
      Offset(w * 0.12, h * 0.61),
      Offset(w * 0.17, h * 0.63),
      Offset(w * 0.22, h * 0.62),
    );

    // Right clutching hand gripping the leaf edge at (w * 0.46, h * 0.70)
    drawClutchingHand(
      Offset(w * 0.52, h * 0.76),
      Offset(w * 0.44, h * 0.67),
      Offset(w * 0.48, h * 0.66),
      Offset(w * 0.52, h * 0.68),
    );
  }

  void _drawTiger(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Draw Tiger ears and face base
    final double earTwitch = sin(pulse * 6 * pi) > 0.90 ? sin(pulse * 40) * 0.08 : 0.0;
    
    canvas.save();
    canvas.translate(w * 0.5, h * 0.55);

    // Left ear
    canvas.save();
    canvas.translate(-w * 0.22, -h * 0.2);
    canvas.rotate(earTwitch);
    final paintFur = Paint()..color = const Color(0xFFEF6C00); // Tiger bright orange base
    canvas.drawCircle(Offset.zero, h * 0.12, paintFur);
    canvas.drawCircle(Offset.zero, h * 0.075, Paint()..color = const Color(0xFF212121)); // Inner ear black
    
    // SIGNATURE TIGER WHITE patches on back of ears (natural mimic spots)
    canvas.drawCircle(Offset(-w * 0.03, -h * 0.02), h * 0.028, Paint()..color = const Color(0xFFFFFDF4));
    canvas.drawCircle(Offset(-2, 2), h * 0.038, Paint()..color = const Color(0xFFFFE0B2)); // Inner cream fluff
    canvas.restore();

    // Right ear
    canvas.save();
    canvas.translate(w * 0.22, -h * 0.2);
    canvas.rotate(-earTwitch);
    canvas.drawCircle(Offset.zero, h * 0.12, paintFur);
    canvas.drawCircle(Offset.zero, h * 0.075, Paint()..color = const Color(0xFF212121));
    
    // SIGNATURE TIGER WHITE patches on back of ears (natural mimic spots)
    canvas.drawCircle(Offset(w * 0.03, -h * 0.02), h * 0.028, Paint()..color = const Color(0xFFFFFDF4));
    canvas.drawCircle(Offset(2, 2), h * 0.038, Paint()..color = const Color(0xFFFFE0B2));
    canvas.restore();

    // Main tiger face base
    canvas.drawCircle(Offset.zero, h * 0.28, paintFur);

    // Soft white/cream cheek fur highlights (feathered strokes)
    final Paint paintFurStroke = Paint()
      ..color = const Color(0xFFFFFDF4).withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (double fy = -h * 0.1; fy < h * 0.15; fy += 8) {
      canvas.drawLine(Offset(-w * 0.22, fy), Offset(-w * 0.26, fy + 4), paintFurStroke);
      canvas.drawLine(Offset(w * 0.22, fy), Offset(w * 0.26, fy + 4), paintFurStroke);
    }

    // Snout cream highlights
    final Paint paintSnout = Paint()..color = const Color(0xFFFFF8E1);
    canvas.drawCircle(Offset(-w * 0.055, h * 0.10), h * 0.085, paintSnout);
    canvas.drawCircle(Offset(w * 0.055, h * 0.10), h * 0.085, paintSnout);
    
    // Nose bridge white blend
    canvas.drawOval(Rect.fromLTWH(-w * 0.04, -h * 0.04, w * 0.08, h * 0.11), Paint()..color = const Color(0xFFFFFDF4));

    // Cute pink nose
    final Paint paintNose = Paint()..color = const Color(0xFFF48FB1);
    final pathNose = Path()
      ..moveTo(-w * 0.04, h * 0.03)
      ..lineTo(w * 0.04, h * 0.03)
      ..lineTo(0, h * 0.095)
      ..close();
    canvas.drawPath(pathNose, paintNose);

    // 2. Realistic curved black Tiger Stripes!
    final Paint stripePaint = Paint()
      ..color = const Color(0xFF151515)
      ..style = PaintingStyle.fill;

    void drawCurvedStripe(double cx, double cy, double sw, double sh, double angle) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final Path stripe = Path()
        ..moveTo(-sw / 2, 0)
        ..quadraticBezierTo(0, -sh * 0.4, sw / 2, 0)
        ..quadraticBezierTo(0, sh * 0.4, -sw / 2, 0)
        ..close();
      canvas.drawPath(stripe, stripePaint);
      canvas.restore();
    }

    // Forehead stripes
    drawCurvedStripe(0, -h * 0.18, w * 0.03, h * 0.09, 0);
    drawCurvedStripe(-w * 0.04, -h * 0.15, w * 0.02, h * 0.08, 0.2);
    drawCurvedStripe(w * 0.04, -h * 0.15, w * 0.02, h * 0.08, -0.2);

    // Cheek stripes (left side)
    drawCurvedStripe(-w * 0.18, -h * 0.04, w * 0.08, h * 0.03, -0.15);
    drawCurvedStripe(-w * 0.20, h * 0.02, w * 0.10, h * 0.03, -0.05);
    drawCurvedStripe(-w * 0.18, h * 0.08, w * 0.07, h * 0.025, 0.05);

    // Cheek stripes (right side)
    drawCurvedStripe(w * 0.18, -h * 0.04, w * 0.08, h * 0.03, 0.15);
    drawCurvedStripe(w * 0.20, h * 0.02, w * 0.10, h * 0.03, 0.05);
    drawCurvedStripe(w * 0.18, h * 0.08, w * 0.07, h * 0.025, -0.05);

    // 3. Glowing amber/gold realistic tiger eyes with double highlight dots
    final double eyeNarrow = 0.5 + 0.5 * sin(pulse * pi);
    final paintEye = Paint()..color = const Color(0xFFFFD54F);
    
    // Left eye
    canvas.drawOval(Rect.fromLTWH(-w * 0.15, -h * 0.06, w * 0.08, h * 0.05 * eyeNarrow), paintEye);
    canvas.drawOval(Rect.fromLTWH(-w * 0.12, -h * 0.055, w * 0.02, h * 0.04 * eyeNarrow), Paint()..color = Colors.black);
    // Double Specular glares
    canvas.drawCircle(Offset(-w * 0.12, -h * 0.052), 1.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(-w * 0.13, -h * 0.040), 0.6, Paint()..color = Colors.white);

    // Right eye
    canvas.drawOval(Rect.fromLTWH(w * 0.07, -h * 0.06, w * 0.08, h * 0.05 * eyeNarrow), paintEye);
    canvas.drawOval(Rect.fromLTWH(w * 0.10, -h * 0.055, w * 0.02, h * 0.04 * eyeNarrow), Paint()..color = Colors.black);
    // Double Specular glares
    canvas.drawCircle(Offset(w * 0.10, -h * 0.052), 1.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.09, -h * 0.040), 0.6, Paint()..color = Colors.white);

    // 4. White whiskers and snout freckles
    final Paint paintWhisker = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
      
    final Paint paintFreckle = Paint()..color = const Color(0xFFEF6C00).withValues(alpha: 0.6);
    
    // Snout freckles
    canvas.drawCircle(Offset(-w * 0.055, h * 0.06), 1.2, paintFreckle);
    canvas.drawCircle(Offset(-w * 0.035, h * 0.07), 1.0, paintFreckle);
    canvas.drawCircle(Offset(w * 0.035, h * 0.06), 1.2, paintFreckle);
    canvas.drawCircle(Offset(w * 0.055, h * 0.07), 1.0, paintFreckle);

    // Left whiskers
    canvas.drawLine(Offset(-w * 0.06, h * 0.09), Offset(-w * 0.28, h * 0.06), paintWhisker);
    canvas.drawLine(Offset(-w * 0.06, h * 0.11), Offset(-w * 0.30, h * 0.13), paintWhisker);
    
    // Right whiskers
    canvas.drawLine(Offset(w * 0.06, h * 0.09), Offset(w * 0.28, h * 0.06), paintWhisker);
    canvas.drawLine(Offset(w * 0.06, h * 0.11), Offset(w * 0.30, h * 0.13), paintWhisker);

    canvas.restore();

    // 5. Draw highly detailed vector jungle leaves masking the tiger's chest
    final Paint paintJungleLeaf = Paint()..color = const Color(0xFF1B5E20);
    final Paint paintJungleVein = Paint()
      ..color = const Color(0xFF388E3C)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Sharp leaf outline paint for defined edges
    final Paint paintJungleBorder = Paint()
      ..color = const Color(0xFF0F3813)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw palm fronds (bottom left mask)
    final Path palmFrond = Path()
      ..moveTo(-10, h)
      ..quadraticBezierTo(w * 0.15, h * 0.65, w * 0.40, h * 0.95)
      ..lineTo(-10, h)
      ..close();
    canvas.drawPath(palmFrond, paintJungleLeaf);
    canvas.drawPath(palmFrond, paintJungleBorder);
    canvas.drawLine(Offset(-10, h), Offset(w * 0.25, h * 0.78), paintJungleVein);

    // Draw split-leaf monstera (bottom right mask)
    final Path monsteraLeaf = Path()
      ..moveTo(w * 0.5, h * 1.1)
      ..cubicTo(w * 0.45, h * 0.8, w * 0.65, h * 0.65, w * 1.1, h * 0.85)
      ..lineTo(w * 1.1, h * 1.1)
      ..close();
    canvas.drawPath(monsteraLeaf, paintJungleLeaf);
    canvas.drawPath(monsteraLeaf, paintJungleBorder);
    canvas.drawLine(Offset(w * 0.7, h * 0.95), Offset(w * 0.6, h * 0.75), paintJungleVein);
    canvas.drawLine(Offset(w * 0.7, h * 0.95), Offset(w * 0.85, h * 0.72), paintJungleVein);
    canvas.drawLine(Offset(w * 0.7, h * 0.95), Offset(w * 0.95, h * 0.90), paintJungleVein);
  }

  void _drawLion(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.save();
    canvas.translate(w * 0.55, h * 0.5);

    // 1. Lush, shaggy furry golden-brown Lion Mane (multi-color layered concentric tufts)
    final Paint paintManeBase = Paint()..color = const Color(0xFF3E2723); // Dark chocolate brown mane core
    final Paint paintManeMid = Paint()..color = const Color(0xFFD84315); // Rich burnt orange
    final Paint paintManeLight = Paint()..color = const Color(0xFFFFB74D); // Soft sand gold

    // Giant shaggy path representing thick mane base
    final Path manePath = Path();
    for (int deg = 0; deg <= 360; deg += 10) {
      final double rad = deg * pi / 180;
      final double r = h * 0.38 + (sin(rad * 14) * 12.0) + (cos(rad * 6) * 6.0);
      final double px = cos(rad) * r;
      final double py = sin(rad) * r;
      if (deg == 0) {
        manePath.moveTo(px, py);
      } else {
        manePath.lineTo(px, py);
      }
    }
    manePath.close();
    canvas.drawPath(manePath, paintManeBase);

    // Burnt orange middle mane highlights
    final Path midManePath = Path();
    for (int deg = 0; deg <= 360; deg += 15) {
      final double rad = deg * pi / 180;
      final double r = h * 0.33 + (cos(rad * 12) * 8.0);
      final double px = cos(rad) * r;
      final double py = sin(rad) * r;
      if (deg == 0) {
        midManePath.moveTo(px, py);
      } else {
        midManePath.lineTo(px, py);
      }
    }
    midManePath.close();
    canvas.drawPath(midManePath, paintManeMid);

    // Sand gold inner mane highlights
    final Path innerManePath = Path();
    for (int deg = 0; deg <= 360; deg += 20) {
      final double rad = deg * pi / 180;
      final double r = h * 0.28 + (sin(rad * 10) * 6.0);
      final double px = cos(rad) * r;
      final double py = sin(rad) * r;
      if (deg == 0) {
        innerManePath.moveTo(px, py);
      } else {
        innerManePath.lineTo(px, py);
      }
    }
    innerManePath.close();
    canvas.drawPath(innerManePath, paintManeLight);

    // Highly realistic shaggy mane hair strokes (fine gold/tan lines)
    final Paint maneHairPaint1 = Paint()
      ..color = const Color(0xFFFFB74D).withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    final Paint maneHairPaint2 = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
      
    for (int deg = 0; deg <= 360; deg += 6) {
      final double rad = deg * pi / 180;
      final double rStart = h * 0.22;
      final double rEnd = h * 0.35 + sin(rad * 18) * 8;
      canvas.drawLine(
        Offset(cos(rad) * rStart, sin(rad) * rStart),
        Offset(cos(rad) * rEnd, sin(rad) * rEnd),
        maneHairPaint1,
      );
      canvas.drawLine(
        Offset(cos(rad) * (rStart + 10), sin(rad) * (rStart + 10)),
        Offset(cos(rad) * (rEnd - 5), sin(rad) * (rEnd - 5)),
        maneHairPaint2,
      );
    }

    // 2. Lion Face (glorious tan base)
    final Paint facePaint = Paint()..color = const Color(0xFFFFB74D); // tan orange
    canvas.drawCircle(Offset.zero, h * 0.24, facePaint);

    // Cute ears peeking out of mane
    canvas.drawCircle(Offset(-w * 0.15, -h * 0.16), h * 0.08, facePaint);
    canvas.drawCircle(Offset(w * 0.15, -h * 0.16), h * 0.08, facePaint);
    canvas.drawCircle(Offset(-w * 0.15, -h * 0.16), h * 0.05, Paint()..color = const Color(0xFFD84315));
    canvas.drawCircle(Offset(w * 0.15, -h * 0.16), h * 0.05, Paint()..color = const Color(0xFFD84315));

    // Snout / cheek white fluffs (ivory color)
    final Paint snoutPaint = Paint()..color = const Color(0xFFFFF3E0);
    canvas.drawCircle(Offset(-w * 0.055, h * 0.07), h * 0.075, snoutPaint);
    canvas.drawCircle(Offset(w * 0.055, h * 0.07), h * 0.075, snoutPaint);

    // White chin fluff highlight
    canvas.drawOval(Rect.fromLTWH(-w * 0.06, h * 0.13, w * 0.12, h * 0.06), Paint()..color = const Color(0xFFFFFDF4));

    // Pinkish-brown wise nose with nostrils
    final Paint nosePaint = Paint()..color = const Color(0xFF8D6E63);
    final Path pathNose = Path()
      ..moveTo(-w * 0.04, h * 0.015)
      ..lineTo(w * 0.04, h * 0.015)
      ..lineTo(0, h * 0.07)
      ..close();
    canvas.drawPath(pathNose, nosePaint);

    // 3. Expressive yellow blinking eyes with dark outlines and specular glares
    final bool isBlinking = sin(pulse * 2.0 * pi) > 0.94;
    if (!isBlinking) {
      // Mascara-like dark eyes outlines
      final Paint mascara = Paint()
        ..color = const Color(0xFF27120E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(-w * 0.08, -h * 0.04), 6.5, mascara);
      canvas.drawCircle(Offset(w * 0.08, -h * 0.04), 6.5, mascara);
      
      canvas.drawCircle(Offset(-w * 0.08, -h * 0.04), 5.5, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawCircle(Offset(w * 0.08, -h * 0.04), 5.5, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawCircle(Offset(-w * 0.08, -h * 0.04), 3.0, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(w * 0.08, -h * 0.04), 3.0, Paint()..color = Colors.black);
      
      // Specular highlight reflections
      canvas.drawCircle(Offset(-w * 0.07, -h * 0.048), 1.2, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w * 0.09, -h * 0.048), 1.2, Paint()..color = Colors.white);
    } else {
      final slit = Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(-w * 0.12, -h * 0.04), Offset(-w * 0.04, -h * 0.04), slit);
      canvas.drawLine(Offset(w * 0.04, -h * 0.04), Offset(w * 0.12, -h * 0.04), slit);
    }

    // 4. Snout whisker freckle clusters & white whiskers
    final whisker = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 0.95;
    
    // Snout freckles
    final Paint paintLionFreckle = Paint()..color = const Color(0xFFD84315).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(-w * 0.05, h * 0.06), 1.0, paintLionFreckle);
    canvas.drawCircle(Offset(-w * 0.065, h * 0.075), 0.8, paintLionFreckle);
    canvas.drawCircle(Offset(w * 0.05, h * 0.06), 1.0, paintLionFreckle);
    canvas.drawCircle(Offset(w * 0.065, h * 0.075), 0.8, paintLionFreckle);

    // Whiskers
    canvas.drawLine(Offset(-w * 0.05, h * 0.08), Offset(-w * 0.24, h * 0.06), whisker);
    canvas.drawLine(Offset(-w * 0.05, h * 0.10), Offset(-w * 0.26, h * 0.11), whisker);
    canvas.drawLine(Offset(w * 0.05, h * 0.08), Offset(w * 0.22, h * 0.06), whisker);
    canvas.drawLine(Offset(w * 0.05, h * 0.10), Offset(w * 0.24, h * 0.11), whisker);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AnimalPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.animalIndex != animalIndex ||
      oldDelegate.sizeFactor != sizeFactor;
}
