import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double? width;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);
    final effectiveColor = color ?? const Color(0xFF1E293B); // Navy blue

    final cardContent = Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveColor.withOpacity(0.7),
            effectiveColor.withOpacity(0.5),
          ],
        ),
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.15), // Deep blue border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.08), // Blue glow
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    return onTap != null
        ? Material(
            color: Colors.transparent,
            borderRadius: effectiveBorderRadius,
            child: InkWell(
              borderRadius: effectiveBorderRadius,
              onTap: onTap,
              splashColor: const Color(0xFF2563EB).withOpacity(0.15), // Blue splash
              highlightColor: const Color(0xFF2563EB).withOpacity(0.08), // Blue highlight
              child: cardContent,
            ),
          )
        : cardContent;
  }
}
