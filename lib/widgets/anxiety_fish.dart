import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/anxiety_cause.dart';

class AnxietyFish extends StatefulWidget {
  final AnxietyCause anxietyCause;
  final int index;
  final VoidCallback? onLongPress;
  final Function(AnxietyCause)? onUpdate;
  final double initialX;
  final double initialY;
  final Function(TapDownDetails)? onTapDown;
  final VoidCallback? onDoubleTap;

  const AnxietyFish({
    super.key,
    required this.anxietyCause,
    required this.index,
    required this.initialX,
    required this.initialY,
    this.onLongPress,
    this.onUpdate,
    this.onTapDown,
    this.onDoubleTap,
  });

  @override
  State<AnxietyFish> createState() => _AnxietyFishState();
}

class _AnxietyFishState extends State<AnxietyFish> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;

  final _random = math.Random();
  Offset _currentPosition = Offset.zero;
  Offset _targetPosition = Offset.zero;
  Offset _renderedPosition = Offset.zero;
  bool _isMovingLeft = false;
  final double _waveOffset = 0;
  bool _showBubble = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _setNewTarget();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentPosition == Offset.zero) {
      _currentPosition = Offset(widget.initialX, widget.initialY);
      _renderedPosition = _currentPosition;
      _setNewTarget();
      _controller.forward(from: 0.0);
    }
  }

  void _setNewTarget() {
    final screenSize = MediaQuery.of(context).size;
    double newX, newY, distance;
    const minDistance = 100.0;

    do {
      newX = _random.nextDouble() * (screenSize.width - 100);
      newY = _random.nextDouble() * (screenSize.height - 300) + 100;
      distance = (_currentPosition - Offset(newX, newY)).distance;
    } while (distance < minDistance);

    _targetPosition = Offset(newX, newY);
    final durationSeconds = (distance / 30).clamp(2.0, 20.0);
    _controller.duration = Duration(milliseconds: (durationSeconds * 1000).toInt());

    _positionAnimation = Tween<Offset>(
      begin: _currentPosition,
      end: _targetPosition,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _isMovingLeft = newX < _currentPosition.dx;
    _controller.forward(from: 0.0);
  }

  void _showBubbleTemporarily() {
    setState(() {
      _renderedPosition = _positionAnimation.value;
      _showBubble = true;
    });

    _controller.stop();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showBubble = false;
          _setNewTarget();
          _controller.forward(from: 0.0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseScale = 1.0 + (widget.anxietyCause.anxietyLevel - 1) * 0.2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = _positionAnimation.value;
        final breathingScale = 1.0 + math.sin(_controller.value * math.pi * 2) * 0.05;
        final waveX = _showBubble ? 0.0 : math.sin(_controller.value * math.pi * 2 + _waveOffset) * 2;
        final waveY = _showBubble ? 0.0 : math.cos(_controller.value * math.pi * 2 + _waveOffset) * 2;

        if (!_showBubble) {
          _currentPosition = pos;
          _renderedPosition = pos;
        }

        final fishX = _renderedPosition.dx + waveX;
        final fishY = _renderedPosition.dy + waveY;
        const double bubbleWidth = 160;

        return Stack(
          children: [
            if (_showBubble)
              Positioned(
                left: _renderedPosition.dx - bubbleWidth / 2,
                top: _renderedPosition.dy - 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      constraints: const BoxConstraints.tightFor(width: bubbleWidth),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.anxietyCause.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (widget.anxietyCause.selectedEmotions != null &&
                              widget.anxietyCause.selectedEmotions!.isNotEmpty)
                            Column(
                              children: widget.anxietyCause.selectedEmotions!
                                  .map((emotion) => Text(emotion, textAlign: TextAlign.center))
                                  .toList(),
                            )
                          else
                            const Text('없음', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    CustomPaint(
                      painter: BubbleTailPainter(),
                      child: const SizedBox(width: 0, height: 8),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: fishX,
              top: fishY,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(baseScale * breathingScale)
                  ..rotateY(_isMovingLeft ? math.pi : 0)
                  ..rotateZ(math.sin(_controller.value * math.pi * 2) * 0.1),
                child: GestureDetector(
                  onTap: _showBubbleTemporarily,
                  onTapDown: widget.onTapDown,
                  onDoubleTap: widget.onDoubleTap,
                  onLongPress: widget.onLongPress,
                  child: Text(
                    widget.anxietyCause.fishEmoji ?? '🐟',
                    style: const TextStyle(fontSize: 27),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class BubbleTailPainter extends CustomPainter {
  final Color color;
  final double arrowWidth;
  final double arrowHeight;

  BubbleTailPainter({this.color = Colors.white, this.arrowWidth = 20, this.arrowHeight = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(size.width / 2 - arrowWidth / 2, 0);
    path.lineTo(size.width / 2, arrowHeight);
    path.lineTo(size.width / 2 + arrowWidth / 2, 0);
    path.close();

    canvas.drawShadow(path, Colors.black12, 2, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
