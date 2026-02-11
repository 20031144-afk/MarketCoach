import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/quote.dart';
import '../../models/stock_summary.dart';
import '../../services/quote_service.dart';
import '../../utils/crypto_helper.dart';
import '../../widgets/glass_card.dart';
import '../stock_detail/stock_detail_screen_enhanced.dart';
import 'market_view_all_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _binanceService = BinanceQuoteService();
  StreamSubscription<Map<String, Quote>>? _cryptoSubscription;
  Map<String, Quote> _cryptoQuotes = {};

  final PageController _coachingPageController = PageController();
  Timer? _coachingTimer;
  int _currentCoachingIndex = 0;

  @override
  void initState() {
    super.initState();

    // Stream quotes for crypto
    final cryptoSymbols = mockCryptoIndices
        .map((idx) => idx.ticker)
        .where((symbol) => isCryptoSymbol(symbol))
        .toSet();

    if (cryptoSymbols.isNotEmpty) {
      _cryptoSubscription = _binanceService.streamQuotes(cryptoSymbols).listen((quotes) {
        if (mounted) {
          setState(() => _cryptoQuotes = quotes);
        }
      });
    }

    // Auto-rotate coaching messages every 8 seconds
    _coachingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_coachingPageController.hasClients) {
        final nextPage = (_currentCoachingIndex + 1) % _coachingMessages.length;
        _coachingPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _cryptoSubscription?.cancel();
    _binanceService.dispose();
    _coachingTimer?.cancel();
    _coachingPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Coaching Message Box
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _CoachingMessageBox(
                  pageController: _coachingPageController,
                  onPageChanged: (index) {
                    setState(() => _currentCoachingIndex = index);
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Top 3 Stocks Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top 3 Stocks',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MarketViewAllScreen(
                              assets: mockWatchlist.where((s) => !s.isCrypto).toList(),
                              isCrypto: false,
                            ),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _AssetCarousel(
                assets: _getTopStocks(),
                isCrypto: false,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Top 3 Crypto Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top 3 Crypto',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MarketViewAllScreen(
                              assets: mockWatchlist.where((s) => s.isCrypto).toList(),
                              isCrypto: true,
                            ),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _AssetCarousel(
                assets: _getTopCrypto(),
                isCrypto: true,
                liveQuotes: _cryptoQuotes,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Quick Market Insights
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _QuickMarketInsights(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  List<StockSummary> _getTopStocks() {
    // Get top 3 stocks from watchlist (non-crypto)
    return mockWatchlist
        .where((s) => !s.isCrypto)
        .take(3)
        .toList();
  }

  List<StockSummary> _getTopCrypto() {
    // Get top 3 crypto from watchlist
    return mockWatchlist
        .where((s) => s.isCrypto)
        .take(3)
        .toList();
  }
}

// Coaching messages for educational tips
const List<Map<String, String>> _coachingMessages = [
  {
    'icon': '💡',
    'message': 'Markets move in cycles - focus on learning patterns, not timing.',
  },
  {
    'icon': '📊',
    'message': 'RSI above 70 often means "overbought" - but understand why first.',
  },
  {
    'icon': '🎯',
    'message': 'Support & Resistance are key levels where price often reacts.',
  },
  {
    'icon': '📈',
    'message': 'Volume confirms trends - rising prices with volume are stronger.',
  },
  {
    'icon': '⚖️',
    'message': 'Position sizing protects your capital - never risk more than 1-2% per trade.',
  },
  {
    'icon': '🔍',
    'message': 'Always check the macro calendar before trading a micro story.',
  },
  {
    'icon': '📉',
    'message': 'Pullbacks in uptrends are opportunities - if the story hasn\'t changed.',
  },
  {
    'icon': '🛡️',
    'message': 'Stop losses go where your idea would be wrong, not just a random percent.',
  },
  {
    'icon': '⏰',
    'message': 'Patience beats prediction - let setups come to you.',
  },
  {
    'icon': '🎓',
    'message': 'Every chart tells a story - learn to read supply and demand zones.',
  },
];

class _CoachingMessageBox extends StatelessWidget {
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _CoachingMessageBox({
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      color: colorScheme.primary.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 80,
        child: PageView.builder(
          controller: pageController,
          onPageChanged: onPageChanged,
          itemCount: _coachingMessages.length,
          itemBuilder: (context, index) {
            final message = _coachingMessages[index];
            return Row(
              children: [
                Text(
                  message['icon']!,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message['message']!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AssetCarousel extends StatelessWidget {
  final List<StockSummary> assets;
  final bool isCrypto;
  final Map<String, Quote>? liveQuotes;

  const _AssetCarousel({
    required this.assets,
    required this.isCrypto,
    this.liveQuotes,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          final quote = liveQuotes?[asset.ticker];

          // Use live quote if available, otherwise use mock data
          final price = quote?.price ?? asset.price;
          final changePercent = quote?.changePercent ?? asset.changePercent;
          final isPositive = changePercent >= 0;

          return _AssetCard(
            asset: asset,
            price: price,
            changePercent: changePercent,
            isPositive: isPositive,
            isCrypto: isCrypto,
            isLive: quote != null,
          );
        },
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final StockSummary asset;
  final double price;
  final double changePercent;
  final bool isPositive;
  final bool isCrypto;
  final bool isLive;

  const _AssetCard({
    required this.asset,
    required this.price,
    required this.changePercent,
    required this.isPositive,
    required this.isCrypto,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final changeColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GlassCard(
        width: 200,
        padding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StockDetailScreenEnhanced(
                stock: asset.copyWith(
                  price: price,
                  changePercent: changePercent,
                ),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  asset.ticker,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                if (isLive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            Text(
              asset.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '\$${price.toStringAsFixed(price < 1 ? 4 : 2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: changeColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
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

class _QuickMarketInsights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Market Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InsightBullet(
            text: 'Major indices holding near all-time highs with breadth improving',
          ),
          const SizedBox(height: 12),
          _InsightBullet(
            text: 'Crypto markets showing resilience above key support levels',
          ),
          const SizedBox(height: 12),
          _InsightBullet(
            text: 'Volatility (VIX) remains subdued - suggests market confidence',
          ),
          const SizedBox(height: 12),
          _InsightBullet(
            text: 'Watch upcoming earnings season for confirmation of trends',
          ),
          const SizedBox(height: 16),
          Text(
            '⚠️ Educational purposes only. Not financial advice.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightBullet extends StatelessWidget {
  final String text;

  const _InsightBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
