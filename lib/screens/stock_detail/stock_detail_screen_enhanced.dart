import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/candle.dart';
import '../../models/quote.dart';
import '../../models/stock_summary.dart';
import '../../services/candle_service.dart';
import '../../services/quote_service.dart';
import '../../services/technical_analysis_service.dart';
import '../../services/pattern_recognition_service.dart';
import '../../utils/crypto_helper.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/chart/advanced_price_chart.dart';
import '../../widgets/chart/chart_type_selector.dart';
import '../../widgets/chart/rsi_sub_chart.dart';
import '../../widgets/chart/macd_sub_chart.dart';
import '../../widgets/chart/advanced_indicator_settings.dart';
import '../../widgets/educational_bottom_sheet.dart';

class StockDetailScreenEnhanced extends ConsumerStatefulWidget {
  final StockSummary stock;

  const StockDetailScreenEnhanced({super.key, required this.stock});

  @override
  ConsumerState<StockDetailScreenEnhanced> createState() => _StockDetailScreenEnhancedState();
}

class _StockDetailScreenEnhancedState extends ConsumerState<StockDetailScreenEnhanced> {
  final _candleService = BinanceCandleService();
  final _quoteService = BinanceQuoteService();
  final _yahooService = YahooFinanceCandleService();

  StreamSubscription<List<Candle>>? _candleSubscription;
  StreamSubscription<Map<String, Quote>>? _quoteSubscription;

  List<Candle> _candles = [];
  Quote? _liveQuote;
  bool _isWatchlisted = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  // Chart controls — default differs by asset type (set in initState)
  ChartType _chartType = ChartType.candlestick;
  String _timeframe = '1D';
  bool _showRSI = true;
  bool _showMACD = true;

  // Indicator settings
  MAType _maType = MAType.sma;
  bool _showBollingerBands = false;
  SRType _srType = SRType.none;
  SubChartType _subChartType = SubChartType.rsi;

  bool get _isCrypto => isCryptoSymbol(widget.stock.ticker);

  @override
  void initState() {
    super.initState();
    // Set sensible default timeframe per asset type
    _timeframe = _isCrypto ? '1h' : '1D';
    _loadData();
  }

  void _loadData() {
    if (_isCrypto) {
      _subscribeToCandles();
      _subscribeToQuotes();
    } else {
      _fetchStockCandles();
    }
  }

  /// Maps stock timeframe labels to Yahoo Finance interval + range params.
  ({String interval, String range}) _yahooParamsForTimeframe(String tf) {
    switch (tf) {
      case '1D': return (interval: '1d', range: '1y');
      case '1W': return (interval: '1d', range: '2y');
      case '1M': return (interval: '1wk', range: '1y');
      case '3M': return (interval: '1d', range: '3mo');
      case '1Y': return (interval: '1mo', range: '5y');
      default:   return (interval: '1d', range: '1y');
    }
  }

  Future<void> _fetchStockCandles() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _candles = [];
    });

    final params = _yahooParamsForTimeframe(_timeframe);
    final candles = await _yahooService.fetchCandles(
      widget.stock.ticker,
      interval: params.interval,
      range: params.range,
    );

    if (!mounted) return;
    if (candles.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Could not load chart data for ${widget.stock.ticker}.\nCheck your internet connection and try again.';
      });
    } else {
      setState(() {
        _candles = candles;
        _isLoading = false;
      });
    }
  }

  void _subscribeToCandles() {
    _candleSubscription?.cancel();

    _candleSubscription = _candleService
        .streamCandles(widget.stock.ticker, interval: _timeframe)
        .listen(
      (candles) {
        if (mounted) {
          setState(() {
            _candles = candles;
            _hasError = false;
            _errorMessage = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Failed to load chart data. Please try again.';
          });
        }
      },
    );
  }

  void _subscribeToQuotes() {
    _quoteSubscription?.cancel();

    _quoteSubscription = _quoteService
        .streamQuotes({widget.stock.ticker})
        .listen(
      (quotes) {
        if (mounted) {
          setState(() => _liveQuote = quotes[widget.stock.ticker]);
        }
      },
      onError: (error) {
        // Quote errors are non-critical, just log them
        debugPrint('Quote stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _candleSubscription?.cancel();
    _quoteSubscription?.cancel();
    _candleService.dispose();
    _quoteService.dispose();
    super.dispose();
  }

  void _onTimeframeChanged(String timeframe) {
    setState(() => _timeframe = timeframe);
    if (_isCrypto) {
      _subscribeToCandles();
    } else {
      _fetchStockCandles();
    }
  }

  void _toggleWatchlist() {
    setState(() => _isWatchlisted = !_isWatchlisted);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isWatchlisted
              ? 'Added to watchlist'
              : 'Removed from watchlist',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use live quote if available, otherwise use stock data
    final displayPrice = _liveQuote?.price ?? widget.stock.price;
    final displayChange = _liveQuote?.changePercent ?? widget.stock.changePercent;
    final isPositive = displayChange >= 0;
    final changeColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.stock.ticker),
        centerTitle: false,
        actions: [
          // Watchlist button
          IconButton(
            icon: Icon(
              _isWatchlisted ? Icons.bookmark : Icons.bookmark_border,
              color: _isWatchlisted ? colorScheme.primary : Colors.white70,
            ),
            onPressed: _toggleWatchlist,
            tooltip: _isWatchlisted ? 'Remove from watchlist' : 'Add to watchlist',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Asset Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _AssetHeaderSection(
                stock: widget.stock,
                price: displayPrice,
                changePercent: displayChange,
                isPositive: isPositive,
                changeColor: changeColor,
                isLive: _liveQuote != null,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Chart Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart Controls Row
                  Row(
                    children: [
                      Expanded(
                        child: _TimeframeSelector(
                          selectedTimeframe: _timeframe,
                          onChanged: _onTimeframeChanged,
                          isCrypto: _isCrypto,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.settings),
                        onPressed: _showIndicatorSettings,
                        tooltip: 'Indicator Settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Chart Type Selector with help button
                  Row(
                    children: [
                      Expanded(
                        child: ChartTypeSelector(
                          selectedType: _chartType,
                          onChanged: (type) {
                            setState(() => _chartType = type);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        icon: const Icon(Icons.help_outline, size: 20),
                        onPressed: () {
                          EducationalBottomSheet.show(
                            context,
                            EducationalContent.chartTypes,
                          );
                        },
                        tooltip: 'Learn about chart types',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Main Chart
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: _hasError
                        ? _buildErrorChart()
                        : (_isLoading || _candles.isEmpty)
                            ? _buildLoadingChart()
                            : AdvancedPriceChart(
                            candles: _candles,
                            chartType: _chartType,
                            trackballBehavior: TrackballBehavior(
                              enable: true,
                              activationMode: ActivationMode.singleTap,
                            ),
                            maType: _maType,
                            showBollingerBands: _showBollingerBands,
                            srType: _srType,
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Coaching Tip for Chart Interpretation
          if (_candles.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CoachingTip(
                  message: _getChartCoachingTip(),
                  icon: Icons.lightbulb_outline,
                ),
              ),
            ),

          if (_candles.isNotEmpty) const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Technical Indicators Section
          if (_candles.isNotEmpty) ...[
            // RSI Subchart with help button
            if (_showRSI)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Stack(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(8),
                        child: RsiSubChart(
                          candles: _candles,
                          rsiValues: TechnicalAnalysisService.calculateRSIHistory(_candles),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            Icons.help_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            EducationalBottomSheet.show(
                              context,
                              EducationalContent.rsi,
                            );
                          },
                          tooltip: 'What is RSI?',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_showRSI) const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // MACD Subchart with help button
            if (_showMACD)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Stack(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(8),
                        child: Builder(
                          builder: (context) {
                            final macd = TechnicalAnalysisService.calculateMACDHistory(_candles);
                            return MacdSubChart(
                              candles: _candles,
                              macdLine: macd['macd']!,
                              signalLine: macd['signal']!,
                              histogram: macd['histogram']!,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            Icons.help_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            EducationalBottomSheet.show(
                              context,
                              EducationalContent.macd,
                            );
                          },
                          tooltip: 'What is MACD?',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_showMACD) const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Indicator Toggle Buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _showRSI = !_showRSI);
                        },
                        icon: Icon(_showRSI ? Icons.visibility : Icons.visibility_off),
                        label: const Text('RSI'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _showRSI ? colorScheme.primary : Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _showMACD = !_showMACD);
                        },
                        icon: Icon(_showMACD ? Icons.visibility : Icons.visibility_off),
                        label: const Text('MACD'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _showMACD ? colorScheme.primary : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Educational Insights Panel
          if (_candles.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EducationalInsightsPanel(
                  candles: _candles,
                  rsi: TechnicalAnalysisService.calculateRSIHistory(_candles),
                  macd: TechnicalAnalysisService.calculateMACDHistory(_candles),
                ),
              ),
            ),

          if (_candles.isNotEmpty) const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Fundamentals Section (if available)
          if (widget.stock.fundamentals != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FundamentalsSection(
                  fundamentals: widget.stock.fundamentals!,
                ),
              ),
            ),

          if (widget.stock.fundamentals == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _NoFundamentalsMessage(),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Technical Highlights
          if (widget.stock.technicalHighlights != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TechnicalHighlightsSection(
                  highlights: widget.stock.technicalHighlights!,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Educational Disclaimer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _EducationalDisclaimer(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 350,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading chart data...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connecting to market data',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChart() {
    return Container(
      height: 350,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.redAccent.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Failed to load chart',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  String _getChartCoachingTip() {
    switch (_chartType) {
      case ChartType.candlestick:
        return 'Candlestick charts show the battle between buyers and sellers. Green candles = buyers won, red = sellers won.';
      case ChartType.line:
        return 'Line charts connect closing prices to show the clean trend without noise. Great for seeing the big picture.';
      case ChartType.area:
        return 'Area charts emphasize trend direction visually. The filled area helps you quickly identify bull vs bear markets.';
      case ChartType.bar:
        return 'Bar charts show OHLC data like candlesticks but without filled bodies. A traditional way to view price action.';
    }
  }

  void _showIndicatorSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdvancedIndicatorSettings(
        movingAverageType: _maType,
        showBollingerBands: _showBollingerBands,
        supportResistanceType: _srType,
        subChartType: _subChartType,
        onMATypeChanged: (maType) {
          setState(() => _maType = maType);
        },
        onBollingerBandsChanged: (showBB) {
          setState(() => _showBollingerBands = showBB);
        },
        onSRTypeChanged: (srType) {
          setState(() => _srType = srType);
        },
        onSubChartChanged: (subChartType) {
          setState(() => _subChartType = subChartType);
        },
      ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Moving Averages'),
                    onPressed: () {
                      Navigator.pop(context);
                      EducationalBottomSheet.show(
                        context,
                        EducationalContent.movingAverages,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Support/Resistance'),
                    onPressed: () {
                      Navigator.pop(context);
                      EducationalBottomSheet.show(
                        context,
                        EducationalContent.supportResistance,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_showBollingerBands)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Bollinger Bands Explained'),
                onPressed: () {
                  Navigator.pop(context);
                  EducationalBottomSheet.show(
                    context,
                    EducationalContent.bollingerBands,
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// Asset Header Section Widget
class _AssetHeaderSection extends StatelessWidget {
  final StockSummary stock;
  final double price;
  final double changePercent;
  final bool isPositive;
  final Color changeColor;
  final bool isLive;

  const _AssetHeaderSection({
    required this.stock,
    required this.price,
    required this.changePercent,
    required this.isPositive,
    required this.changeColor,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Live Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  stock.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // Sector + Industry
          if (stock.sector != null)
            Text(
              '${stock.sector}${stock.industry != null ? ' • ${stock.industry}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),

          const SizedBox(height: 16),

          // Price + Change
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.toStringAsFixed(price < 1 ? 4 : 2)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: changeColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Fundamentals Preview (if available)
          if (stock.fundamentals != null) ...[
            const Divider(height: 1),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: stock.fundamentals!.entries.take(4).map((entry) {
                return _FundamentalChip(
                  label: entry.key,
                  value: entry.value,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FundamentalChip extends StatelessWidget {
  final String label;
  final String value;

  const _FundamentalChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Timeframe Selector Widget
class _TimeframeSelector extends StatelessWidget {
  final String selectedTimeframe;
  final ValueChanged<String> onChanged;
  final bool isCrypto;

  const _TimeframeSelector({
    required this.selectedTimeframe,
    required this.onChanged,
    this.isCrypto = false,
  });

  static const cryptoTimeframes = ['1h', '4h', '1d', '1w', '1M'];
  static const stockTimeframes  = ['1D', '1W', '1M', '3M', '1Y'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeframes = isCrypto ? cryptoTimeframes : stockTimeframes;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: timeframes.map((tf) {
          final isSelected = tf == selectedTimeframe;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tf),
              selected: isSelected,
              onSelected: (_) => onChanged(tf),
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.3),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Fundamentals Section Widget
class _FundamentalsSection extends StatelessWidget {
  final Map<String, String> fundamentals;

  const _FundamentalsSection({required this.fundamentals});

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
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Fundamentals',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...fundamentals.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    entry.value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// No Fundamentals Message Widget
class _NoFundamentalsMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            'Fundamental data not available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Focus on technical analysis and price action instead',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Technical Highlights Section Widget
class _TechnicalHighlightsSection extends StatelessWidget {
  final List<String> highlights;

  const _TechnicalHighlightsSection({required this.highlights});

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
                'Technical Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...highlights.map((highlight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
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
                      highlight,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Educational Insights Panel Widget
class _EducationalInsightsPanel extends StatelessWidget {
  final List<Candle> candles;
  final List<double?> rsi;
  final Map<String, List<double?>> macd;

  const _EducationalInsightsPanel({
    required this.candles,
    required this.rsi,
    required this.macd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = PatternRecognitionService.generateInsights(candles, rsi, macd);

    if (insights.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.white38,
            ),
            const SizedBox(height: 12),
            Text(
              'No notable patterns detected',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Charts are in a neutral state. Continue monitoring for new patterns.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Market Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${insights.length} ${insights.length == 1 ? 'insight' : 'insights'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => _InsightCard(insight: insight)),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final MarketInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getInsightColor(insight.type).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  insight.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getInsightColor(insight.type),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            if (insight.relatedLessonId != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.school_outlined, size: 16),
                label: const Text('Learn More'),
                onPressed: () {
                  // TODO: Navigate to lesson detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening lesson: ${insight.relatedLessonId}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.technical:
        return Colors.blueAccent;
      case InsightType.pattern:
        return Colors.purpleAccent;
      case InsightType.supportResistance:
        return Colors.orangeAccent;
      case InsightType.divergence:
        return Colors.greenAccent;
    }
  }
}

// Educational Disclaimer Widget
class _EducationalDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      color: Colors.orange.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.school_outlined,
            color: Colors.orangeAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Educational Resource',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This information is for learning purposes only. Not financial advice.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
