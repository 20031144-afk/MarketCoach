import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Simple live-updating sparkline using random walk data.
class LiveLineChart extends StatefulWidget {
  final Color lineColor;
  final int maxPoints;
  final double start;

  const LiveLineChart({
    super.key,
    required this.lineColor,
    this.maxPoints = 40,
    this.start = 100,
  });

  @override
  State<LiveLineChart> createState() => _LiveLineChartState();
}

class _LiveLineChartState extends State<LiveLineChart> {
  final _random = Random();
  late Timer _timer;
  late List<double> _points;

  @override
  void initState() {
    super.initState();
    _points = List.generate(widget.maxPoints ~/ 2, (_) => widget.start);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() {
      final last = _points.isNotEmpty ? _points.last : widget.start;
      final next = last + (_random.nextDouble() - 0.5) * 2.2; // gentle drift
      _points.add(next);
      if (_points.length > widget.maxPoints) {
        _points.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minY = _points.reduce(min);
    final maxY = _points.reduce(max);
    final range = (maxY - minY).abs() < 0.001 ? 1.0 : maxY - minY;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: CustomPaint(
            painter: _LinePainter(
              points: _points,
              minY: minY,
              range: range,
              color: widget.lineColor,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: widget.lineColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Live demo feed • ${_points.last.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> points;
  final double minY;
  final double range;
  final Color color;

  _LinePainter({
    required this.points,
    required this.minY,
    required this.range,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final normalized = (points[i] - minY) / range;
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final shadow = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
