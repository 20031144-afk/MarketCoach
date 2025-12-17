import 'package:flutter/material.dart';

import '../../models/lesson.dart';

class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Market Indicator: RSI',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The RSI helps identify if an asset is overbought (too expensive) '
                      'or oversold (potentially cheap).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'RSI chart placeholder',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _Chip(
                          label: 'Below 30\nOversold',
                          background: Color(0xFFE5F8F1),
                          textColor: Color(0xFF0C9E6A),
                        ),
                        _Chip(
                          label: '30-70\nNeutral',
                          background: Color(0xFFF3F4FA),
                          textColor: Color(0xFF3F4A79),
                        ),
                        _Chip(
                          label: 'Above 70\nOverbought',
                          background: Color(0xFFFFEDEA),
                          textColor: Color(0xFFCF3B2E),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: colorScheme.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key points',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BulletPoint(
                      text:
                          'Higher P/E usually means higher growth expectations.',
                    ),
                    _BulletPoint(
                      text: 'Lower P/E can mean slower growth or higher risk.',
                    ),
                    _BulletPoint(
                      text: 'Compare P/E ratios between similar companies.',
                    ),
                    _BulletPoint(
                      text:
                          'There is no single good P/E; it depends on the industry and growth path.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Indicator quick guide',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BulletPoint(
                      text:
                          'Moving Average (figure: smooth line over candles) — shows the average price; price above it suggests an uptrend.',
                    ),
                    _BulletPoint(
                      text:
                          'Support/Resistance (figure: horizontal bands) — highlight where price paused before; expect reactions near these bands.',
                    ),
                    _BulletPoint(
                      text:
                          'MACD (figure: two lines crossing) — cross above signal line hints momentum turning up; cross below hints cooling.',
                    ),
                    _BulletPoint(
                      text:
                          'Volume (figure: bars at bottom) — spikes on a breakout add confidence; weak volume can mean a false move.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Show me a real example'),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'See this idea applied to Apple.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
