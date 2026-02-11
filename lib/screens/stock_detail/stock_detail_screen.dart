import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/candle.dart';
import '../../models/quote.dart';
import '../../models/stock_summary.dart';
import '../../services/candle_service.dart';
import '../../services/quote_service.dart';
import '../../utils/crypto_helper.dart';
import '../../widgets/live_line_chart.dart';

class StockDetailScreen extends StatefulWidget {
  final StockSummary stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final _candleService = BinanceCandleService();
  final _quoteService = BinanceQuoteService();
  Stream<List<Candle>>? _candleStream;
  StreamSubscription<Map<String, Quote>>? _quoteSubscription;
  StreamSubscription<List<Candle>>? _candleStreamSubscription;
  Quote? _liveQuote;
  double? _candlePrice;
  double? _candleChangePercent;
  String _selectedInterval = '1m';

  @override
  void initState() {
    super.initState();
    // Only stream live data for crypto
    if (isCryptoSymbol(widget.stock.ticker)) {
      _updateCandleStream();
      _quoteSubscription = _quoteService.streamQuotes({widget.stock.ticker}).listen((quotes) {
        if (mounted) {
          setState(() => _liveQuote = quotes[widget.stock.ticker]);
        }
      });
    }
  }

  void _updateCandleStream() {
    _candleStreamSubscription?.cancel();
    _candleStream = _candleService.streamCandles(widget.stock.ticker, interval: _selectedInterval);

    // Subscribe to candle stream to extract price and change %
    _candleStreamSubscription = _candleStream!.listen((candles) {
      if (mounted && candles.isNotEmpty) {
        final latestCandle = candles.last;
        final firstCandle = candles.first;

        setState(() {
          _candlePrice = latestCandle.close;
          // Calculate change % from first to last candle in the window
          if (firstCandle.open > 0) {
            _candleChangePercent = ((latestCandle.close - firstCandle.open) / firstCandle.open) * 100;
          }
        });
      }
    });
  }

  void _onIntervalChanged(String interval) {
    setState(() {
      _selectedInterval = interval;
      _updateCandleStream();
    });
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    _candleStreamSubscription?.cancel();
    _candleService.dispose();
    _quoteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.stock.ticker,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.stock.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
              child: IconButton(
                icon: const Icon(Icons.star_border),
                onPressed: () {},
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Insight Score'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StockOverviewTab(
              stock: widget.stock,
              candleStream: _candleStream,
              liveQuote: _liveQuote,
              candlePrice: _candlePrice,
              candleChangePercent: _candleChangePercent,
              selectedInterval: _selectedInterval,
              onIntervalChanged: isCryptoSymbol(widget.stock.ticker) ? _onIntervalChanged : null,
            ),
            StockInsightTab(stock: widget.stock),
          ],
        ),
      ),
    );
  }
}

class StockOverviewTab extends StatelessWidget {
  final StockSummary stock;
  final Stream<List<Candle>>? candleStream;
  final Quote? liveQuote;
  final double? candlePrice;
  final double? candleChangePercent;
  final String? selectedInterval;
  final void Function(String)? onIntervalChanged;

  const StockOverviewTab({
    super.key,
    required this.stock,
    this.candleStream,
    this.liveQuote,
    this.candlePrice,
    this.candleChangePercent,
    this.selectedInterval,
    this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use live quote for crypto if available, fallback to candle data, then stock data
    final isCrypto = isCryptoSymbol(stock.ticker);
    final displayPrice = isCrypto && liveQuote != null
        ? liveQuote!.price
        : (candlePrice ?? stock.price);
    final displayChange = isCrypto && liveQuote != null
        ? liveQuote!.changePercent
        : (candleChangePercent ?? stock.changePercent);
    final isPositive = displayChange >= 0;
    final changeColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    final fundamentals = stock.fundamentals ??
        const {
          'Market Cap': '\$200B',
          'P/E Ratio': '14.2',
          'Yield': '1.9%',
          '52W Range': '\$40 - \$60',
        };
    final technicalNotes = stock.technicalHighlights ??
        const [
          'Price above 50-day, below 200-day: early recovery phase',
          'RSI mid-50s: neutral-to-positive momentum',
          'Watching volume spikes to confirm trend',
        ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '\$${displayPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isCrypto && (liveQuote != null || candlePrice != null)) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${isPositive ? '+' : ''}${displayChange.toStringAsFixed(2)}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: changeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: changeColor,
                            ),
                          ),
                          if (isCrypto && (liveQuote != null || candlePrice != null)) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Live',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stock.sector ?? 'General'} / ${stock.industry ?? 'Mixed'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Chip(
                        label: 'Insight 7.6 / 10',
                        background: colorScheme.primary.withOpacity(0.14),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      _Chip(
                        label: 'Risk: Medium',
                        background: const Color(0xFF2A1B0A),
                        textColor: const Color(0xFFFFCA80),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isCrypto) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[300]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fundamentals below are demo data. Price/change are live from Binance.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: fundamentals.entries
                .map((entry) => MetricCard(
                      title: entry.key,
                      value: entry.value,
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Price chart',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        candleStream != null
                            ? 'Live price (${selectedInterval ?? '1m'} candles)'
                            : 'Live price (demo stream)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _Chip(
                        label: 'Real-time',
                        background: colorScheme.primary.withOpacity(0.1),
                        textColor: colorScheme.primary,
                      ),
                    ],
                  ),
                  if (onIntervalChanged != null) ...[
                    const SizedBox(height: 12),
                    _IntervalSelector(
                      selectedInterval: selectedInterval ?? '1m',
                      onIntervalChanged: onIntervalChanged!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  LiveLineChart(
                    lineColor: isPositive ? Colors.green[600]! : Colors.red[600]!,
                    candleStream: candleStream,
                    symbol: stock.ticker,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    candleStream != null
                        ? 'Real-time 1-minute candles from Binance WebSocket.'
                        : 'Simulated live data to visualize intraday action.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Technical view',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Momentum & levels',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _Chip(
                        label: 'Technical',
                        background: Colors.blueGrey.withOpacity(0.2),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  if (onIntervalChanged != null) ...[
                    const SizedBox(height: 12),
                    _IntervalSelector(
                      selectedInterval: selectedInterval ?? '1m',
                      onIntervalChanged: onIntervalChanged!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (candleStream != null)
                    LiveCandlestickChart(
                      candleStream: candleStream!,
                      symbol: stock.ticker,
                    )
                  else
                    LiveLineChart(lineColor: colorScheme.primary),
                  const SizedBox(height: 10),
                  ...technicalNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(
                              note,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'LLM-friendly breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In plain language',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This page is written so an LLM can summarize it for a brand new investor. '
                    'Fundamentals explain the business health (size, profits, dividends). '
                    'Technicals show the current trend and where price might pause or bounce.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Example prompt: "Explain ${stock.ticker} for a beginner using the fundamentals above and tell me where the next support level might be."',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveCandlestickChart extends StatefulWidget {
  final Stream<List<Candle>> candleStream;
  final String symbol;

  const LiveCandlestickChart({
    super.key,
    required this.candleStream,
    required this.symbol,
  });

  @override
  State<LiveCandlestickChart> createState() => _LiveCandlestickChartState();
}

class _LiveCandlestickChartState extends State<LiveCandlestickChart> {
  List<Candle> _candles = [];
  StreamSubscription<List<Candle>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.candleStream.listen((candles) {
      if (mounted) {
        setState(() {
          _candles = candles;
        });
      }
    });
  }

  @override
  void didUpdateWidget(LiveCandlestickChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candleStream != widget.candleStream) {
      _subscription?.cancel();
      _candles = [];
      _subscription = widget.candleStream.listen((candles) {
        if (mounted) {
          setState(() {
            _candles = candles;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_candles.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            backgroundColor: Colors.transparent,
            primaryXAxis: const NumericAxis(
              isVisible: false,
              majorGridLines: MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              opposedPosition: true,
              axisLine: const AxisLine(width: 0),
              majorGridLines: MajorGridLines(
                width: 0.5,
                color: Colors.white.withOpacity(0.1),
              ),
              labelStyle: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            series: <CartesianSeries>[
              CandleSeries<Candle, int>(
                dataSource: _candles,
                xValueMapper: (Candle candle, index) => index,
                lowValueMapper: (Candle candle, _) => candle.low,
                highValueMapper: (Candle candle, _) => candle.high,
                openValueMapper: (Candle candle, _) => candle.open,
                closeValueMapper: (Candle candle, _) => candle.close,
                bearColor: Colors.red[600]!,
                bullColor: Colors.green[600]!,
                enableSolidCandles: true,
              ),
            ],
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: theme.cardColor,
              textStyle: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Live Binance (${widget.symbol}) • \$${_candles.last.close.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class StockInsightTab extends StatelessWidget {
  final StockSummary stock;

  const StockInsightTab({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insight Score',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 0.76,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          color: colorScheme.primary,
                          backgroundColor: colorScheme.primary.withOpacity(
                            0.15,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '7.6',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '/ 10',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall setup',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Strong fundamentals and solid trend with moderate volatility. Not investment advice - a research starting point.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Score breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              FactorCard(
                title: 'Fundamentals',
                score: 8.2,
                description: 'Earnings growing, strong margins.',
                tone: FactorTone.positive,
              ),
              FactorCard(
                title: 'Technicals',
                score: 7.0,
                description: 'Mild uptrend, healthy momentum.',
                tone: FactorTone.positive,
              ),
              FactorCard(
                title: 'Sentiment',
                score: 5.1,
                description: 'News and social interest are mixed.',
                tone: FactorTone.neutral,
              ),
              FactorCard(
                title: 'Risk / Volatility',
                score: 4.3,
                description: 'Moves more than the overall market.',
                tone: FactorTone.negative,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'What if the price moves?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                          'Scenario: -10% price change',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const Spacer(),
                      _Chip(
                        label: 'Hypothetical',
                        background: colorScheme.primary.withOpacity(0.08),
                        textColor: colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If the price dropped 10% while fundamentals stay strong, the valuation would look more attractive but volatility risk remains.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(value: 0.4, onChanged: (_) {}, min: 0, max: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('-20%', style: theme.textTheme.bodySmall),
                      Text('0%', style: theme.textTheme.bodySmall),
                      Text('+20%', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const MetricCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? textColor;

  const _Chip({required this.label, this.background, this.textColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: background ?? Colors.white.withOpacity(0.08),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum FactorTone { positive, neutral, negative }

class _IntervalSelector extends StatelessWidget {
  final String selectedInterval;
  final void Function(String) onIntervalChanged;

  const _IntervalSelector({
    required this.selectedInterval,
    required this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const intervals = ['1m', '5m', '15m', '1h', '4h', '1d'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: intervals.map((interval) {
          final isSelected = interval == selectedInterval;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onIntervalChanged(interval),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  interval.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FactorCard extends StatelessWidget {
  final String title;
  final double score;
  final String description;
  final FactorTone tone;

  const FactorCard({
    super.key,
    required this.title,
    required this.score,
    required this.description,
    required this.tone,
  });

  Color _backgroundColor() {
    switch (tone) {
      case FactorTone.positive:
        return const Color(0xFFE5F8F1);
      case FactorTone.neutral:
        return const Color(0xFFF5F5FF);
      case FactorTone.negative:
        return const Color(0xFFFFEDEA);
    }
  }

  Color _accentColor() {
    switch (tone) {
      case FactorTone.positive:
        return const Color(0xFF0C9E6A);
      case FactorTone.neutral:
        return const Color(0xFF4D5BD6);
      case FactorTone.negative:
        return const Color(0xFFCF3B2E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2,
      child: Card(
        color: _backgroundColor(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _accentColor(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(),
                      color: Colors.white.withOpacity(0.8),
                    ),
                    child: Text(
                      score.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _accentColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
