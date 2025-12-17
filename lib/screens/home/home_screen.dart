import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/lesson.dart';
import '../../models/market_index.dart';
import '../../models/stock_summary.dart';
import '../lesson_detail/lesson_detail_screen.dart';
import '../stock_detail/stock_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final liveMarkets = [...mockIndices, ...mockCryptoIndices];
    final stockChange = _averageChange(mockIndices);
    final cryptoChange = _averageChange(mockCryptoIndices);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LiveMarketsStrip(
                  markets: liveMarkets,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MarketOverviewCard(
                        title: 'Stocks overview',
                        change: stockChange,
                        accentColor: colorScheme.primary,
                        toneLabel: stockChange >= 0
                            ? 'Leaning bullish'
                            : 'Leaning defensive',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MarketOverviewCard(
                        title: 'Crypto overview',
                        change: cryptoChange,
                        accentColor: Colors.deepPurple,
                        toneLabel: cryptoChange >= 0
                            ? 'Momentum building'
                            : 'Risk-off tone',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Hi, Sandip',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's your market coach for today.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Market overview',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Overall sentiment:',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Neutral',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Volatility: Medium - Keep a balanced approach',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your watchlist',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: mockWatchlist.length,
          itemBuilder: (context, index) {
            final stock = mockWatchlist[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: StockCard(stock: stock),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: TodayLessonCard(lesson: mockLessons.first),
          ),
        ),
      ],
    );
  }
}

class _LiveMarketsStrip extends StatelessWidget {
  final List<MarketIndex> markets;
  final ColorScheme colorScheme;

  const _LiveMarketsStrip({
    required this.markets,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final market = markets[index];
          final changeColor =
              market.isPositive ? Colors.green[600]! : Colors.red[600]!;
          return _LiveMarketCard(
            market: market,
            changeColor: changeColor,
            accent: colorScheme.primary,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: markets.length,
      ),
    );
  }
}

class _LiveMarketCard extends StatelessWidget {
  final MarketIndex market;
  final Color changeColor;
  final Color accent;

  const _LiveMarketCard({
    required this.market,
    required this.changeColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF111925),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: changeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: changeColor.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.show_chart, size: 16, color: accent),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              market.ticker,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              market.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  market.value.toStringAsFixed(2),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${market.isPositive ? '+' : ''}${market.changePercent.toStringAsFixed(2)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketOverviewCard extends StatelessWidget {
  final String title;
  final double change;
  final Color accentColor;
  final String toneLabel;

  const _MarketOverviewCard({
    required this.title,
    required this.change,
    required this.accentColor,
    required this.toneLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeColor =
        change >= 0 ? Colors.green[600]! : Colors.red[600]!;
    final normalized = _normalizedChange(change);

    return Container(
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            toneLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          _ChangeBar(
            normalizedValue: normalized,
            fillColor: changeColor,
          ),
          const SizedBox(height: 8),
          Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}% today',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: changeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeBar extends StatelessWidget {
  final double normalizedValue;
  final Color fillColor;

  const _ChangeBar({
    required this.normalizedValue,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.3),
                  Colors.amber.withOpacity(0.4),
                  Colors.green.withOpacity(0.3),
                ],
              ),
            ),
          ),
          FractionallySizedBox(
            widthFactor: normalizedValue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: fillColor.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StockCard extends StatelessWidget {
  final StockSummary stock;

  const StockCard({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeColor = stock.isPositive ? Colors.green[600] : Colors.red[600];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StockDetailScreen(stock: stock)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.ticker,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                Text(
                  stock.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                    Text(
                      'Tap to see simple analysis',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${stock.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stock.isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TodayLessonCard extends StatelessWidget {
  final Lesson lesson;

  const TodayLessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonDetailScreen(lesson: lesson),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's lesson",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${lesson.minutes} min ${lesson.level}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _averageChange(List<MarketIndex> markets) {
  if (markets.isEmpty) return 0;
  final total =
      markets.fold<double>(0, (sum, item) => sum + item.changePercent);
  return total / markets.length;
}

double _normalizedChange(double changePercent) {
  // Map change from -4%..+4% into 0..1 for the color bar fill.
  return ((changePercent + 4) / 8).clamp(0.0, 1.0);
}
