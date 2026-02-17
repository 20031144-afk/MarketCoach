import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../../models/candle.dart';
import '../../services/technical_analysis_service.dart';
import 'chart_type_selector.dart';
import 'advanced_indicator_settings.dart';

/// Returns smart DateTimeAxis settings based on the span of candle data.
/// Short intraday data → HH:mm, multi-day → MMM dd, multi-month → MMM, multi-year → yyyy.
({DateFormat dateFormat, DateTimeIntervalType intervalType, double interval}) _smartXAxis(
    List<Candle> candles) {
  if (candles.length < 2) {
    return (
      dateFormat: DateFormat('MMM dd'),
      intervalType: DateTimeIntervalType.days,
      interval: 1,
    );
  }
  final span = candles.last.time.difference(candles.first.time);
  if (span.inHours <= 24) {
    // Intraday — show HH:mm, tick every hour
    return (
      dateFormat: DateFormat('HH:mm'),
      intervalType: DateTimeIntervalType.hours,
      interval: 1,
    );
  } else if (span.inDays <= 14) {
    // Up to 2 weeks — show "Jan 15", tick every day
    return (
      dateFormat: DateFormat('MMM d'),
      intervalType: DateTimeIntervalType.days,
      interval: 1,
    );
  } else if (span.inDays <= 90) {
    // Up to 3 months — show "Jan 15", tick every week
    return (
      dateFormat: DateFormat('MMM d'),
      intervalType: DateTimeIntervalType.days,
      interval: 7,
    );
  } else if (span.inDays <= 730) {
    // Up to 2 years — show "Jan", tick every month
    return (
      dateFormat: DateFormat('MMM yy'),
      intervalType: DateTimeIntervalType.months,
      interval: 1,
    );
  } else {
    // 2+ years — show year, tick every 6 months
    return (
      dateFormat: DateFormat('MMM yy'),
      intervalType: DateTimeIntervalType.months,
      interval: 6,
    );
  }
}

/// Formats a Y-axis price label cleanly:
/// ≥1M → "1.2M", ≥1K → "1.2K", else 2 decimal places.
String _formatPrice(double value) {
  if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}K';
  if (value >= 100) return '\$${value.toStringAsFixed(0)}';
  return '\$${value.toStringAsFixed(2)}';
}

class AdvancedPriceChart extends StatefulWidget {
  final List<Candle> candles;
  final ChartType chartType;
  final TrackballBehavior trackballBehavior;
  final MAType maType;
  final bool showBollingerBands;
  final SRType srType;

  const AdvancedPriceChart({
    super.key,
    required this.candles,
    required this.chartType,
    required this.trackballBehavior,
    this.maType = MAType.sma,
    this.showBollingerBands = false,
    this.srType = SRType.none,
  });

  @override
  State<AdvancedPriceChart> createState() => _AdvancedPriceChartState();
}

class _AdvancedPriceChartState extends State<AdvancedPriceChart> {

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: const Text('No data available'),
      );
    }

    // --- Y-axis auto-fit: compute price range from candle lows/highs with 3% padding ---
    final allLows  = widget.candles.map((c) => c.low).toList();
    final allHighs = widget.candles.map((c) => c.high).toList();
    final dataMin  = allLows.reduce((a, b) => a < b ? a : b);
    final dataMax  = allHighs.reduce((a, b) => a > b ? a : b);
    final priceRange = dataMax - dataMin;
    final yMin = dataMin - priceRange * 0.03;
    final yMax = dataMax + priceRange * 0.03;

    // Calculate technical indicators based on settings
    // SMA
    final sma20 = (widget.maType == MAType.sma || widget.maType == MAType.both)
        ? TechnicalAnalysisService.calculateSMA(widget.candles, 20)
        : null;
    final sma50 = (widget.maType == MAType.sma || widget.maType == MAType.both)
        ? TechnicalAnalysisService.calculateSMA(widget.candles, 50)
        : null;
    final sma200 = (widget.maType == MAType.sma || widget.maType == MAType.both) && widget.candles.length >= 200
        ? TechnicalAnalysisService.calculateSMA(widget.candles, 200)
        : null;

    // EMA
    final ema12 = (widget.maType == MAType.ema || widget.maType == MAType.both)
        ? TechnicalAnalysisService.calculateEMA(widget.candles, 12)
        : null;
    final ema26 = (widget.maType == MAType.ema || widget.maType == MAType.both)
        ? TechnicalAnalysisService.calculateEMA(widget.candles, 26)
        : null;
    final ema50 = (widget.maType == MAType.ema || widget.maType == MAType.both)
        ? TechnicalAnalysisService.calculateEMA(widget.candles, 50)
        : null;

    // Bollinger Bands
    final bollingerBands = widget.showBollingerBands
        ? TechnicalAnalysisService.calculateBollingerBands(widget.candles)
        : null;

    // Support/Resistance based on type
    double? support;
    double? resistance;
    Map<String, double>? pivotPoints;
    Map<String, double>? fibonacciLevels;

    switch (widget.srType) {
      case SRType.simple:
        support = TechnicalAnalysisService.calculateSupport(widget.candles);
        resistance = TechnicalAnalysisService.calculateResistance(widget.candles);
        break;
      case SRType.pivot:
        pivotPoints = TechnicalAnalysisService.calculatePivotPoints(widget.candles);
        break;
      case SRType.fibonacci:
        fibonacciLevels = TechnicalAnalysisService.calculateFibonacci(widget.candles);
        break;
      case SRType.none:
        break;
    }

    final xAxisSettings = _smartXAxis(widget.candles);

    return Column(
      children: [
        // Main Chart
        SizedBox(
          height: 350,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            plotAreaBorderColor: Colors.transparent,
            primaryXAxis: DateTimeAxis(
              majorGridLines: const MajorGridLines(width: 0),
              minorGridLines: const MinorGridLines(width: 0),
              axisLine: const AxisLine(width: 0),
              labelStyle: const TextStyle(color: Colors.white60, fontSize: 10),
              dateFormat: xAxisSettings.dateFormat,
              intervalType: xAxisSettings.intervalType,
              interval: xAxisSettings.interval,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              enableAutoIntervalOnZooming: true,
            ),
            primaryYAxis: NumericAxis(
              minimum: yMin,
              maximum: yMax,
              majorGridLines: MajorGridLines(
                width: 1,
                color: Colors.white.withValues(alpha: 0.07),
                dashArray: const <double>[3, 5],
              ),
              minorGridLines: const MinorGridLines(width: 0),
              axisLine: const AxisLine(width: 0),
              labelStyle: const TextStyle(color: Colors.white60, fontSize: 10),
              opposedPosition: true,
              desiredIntervals: 5,
              enableAutoIntervalOnZooming: true,
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                return ChartAxisLabel(
                  _formatPrice(details.value.toDouble()),
                  const TextStyle(color: Colors.white60, fontSize: 10),
                );
              },
            ),
            trackballBehavior: widget.trackballBehavior,
            zoomPanBehavior: ZoomPanBehavior(
              enablePinching: true,
              enablePanning: true,
              enableMouseWheelZooming: true,
              zoomMode: ZoomMode.x,
              enableDoubleTapZooming: true,
            ),
            series: <CartesianSeries>[
              // Bollinger Bands (if enabled) - draw first so it's in background
              if (bollingerBands != null) ...[
                // Upper band
                SplineAreaSeries<_BollingerPoint, DateTime>(
                  dataSource: _getBollingerPoints(bollingerBands['upper']!),
                  xValueMapper: (_BollingerPoint point, _) => point.time,
                  yValueMapper: (_BollingerPoint point, _) => point.value,
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderColor: Colors.blue.withValues(alpha: 0.3),
                  borderWidth: 1,
                  markerSettings: const MarkerSettings(isVisible: false),
                ),
                // Lower band
                SplineAreaSeries<_BollingerPoint, DateTime>(
                  dataSource: _getBollingerPoints(bollingerBands['lower']!),
                  xValueMapper: (_BollingerPoint point, _) => point.time,
                  yValueMapper: (_BollingerPoint point, _) => point.value,
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderColor: Colors.blue.withValues(alpha: 0.3),
                  borderWidth: 1,
                  markerSettings: const MarkerSettings(isVisible: false),
                ),
              ],

              // Main price chart based on selected type
              ..._buildPriceChart(widget.chartType),

              // SMA
              if (sma20 != null)
                SplineSeries<_MAPoint, DateTime>(
                  dataSource: _getMAPoints(sma20, 'SMA 20'),
                  xValueMapper: (_MAPoint point, _) => point.time,
                  yValueMapper: (_MAPoint point, _) => point.value,
                  color: const Color(0xFFFFEB3B), // Yellow
                  width: 2,
                  name: 'SMA 20',
                  markerSettings: const MarkerSettings(isVisible: false),
                ),
              if (sma50 != null)
                SplineSeries<_MAPoint, DateTime>(
                  dataSource: _getMAPoints(sma50, 'SMA 50'),
                  xValueMapper: (_MAPoint point, _) => point.time,
                  yValueMapper: (_MAPoint point, _) => point.value,
                  color: const Color(0xFFFF9800), // Orange
                  width: 2,
                  name: 'SMA 50',
                  markerSettings: const MarkerSettings(isVisible: false),
                ),
              if (sma200 != null)
                SplineSeries<_MAPoint, DateTime>(
                  dataSource: _getMAPoints(sma200, 'SMA 200'),
                  xValueMapper: (_MAPoint point, _) => point.time,
                  yValueMapper: (_MAPoint point, _) => point.value,
                  color: const Color(0xFFE91E63), // Pink
                  width: 2,
                  name: 'SMA 200',
                  markerSettings: const MarkerSettings(isVisible: false),
                ),

              // EMA
              if (ema12 != null)
                SplineSeries<_MAPoint, DateTime>(
                  dataSource: _getMAPoints(ema12, 'EMA 12'),
                  xValueMapper: (_MAPoint point, _) => point.time,
                  yValueMapper: (_MAPoint point, _) => point.value,
                  color: const Color(0xFF00BCD4), // Cyan
                  width: 2,
                  name: 'EMA 12',
                  markerSettings: const MarkerSettings(isVisible: false),
                ),
              if (ema26 != null)
                SplineSeries<_MAPoint, DateTime>(
                  dataSource: _getMAPoints(ema26, 'EMA 26'),
                  xValueMapper: (_MAPoint point, _) => point.time,
                  yValueMapper: (_MAPoint point, _) => point.value,
                  color: const Color(0xFF9C27B0), // Purple
                  width: 2,
                  name: 'EMA 26',
                  markerSettings: const MarkerSettings(isVisible: false),
                ),
              if (ema50 != null)
                SplineSeries<_MAPoint, DateTime>(
                  dataSource: _getMAPoints(ema50, 'EMA 50'),
                  xValueMapper: (_MAPoint point, _) => point.time,
                  yValueMapper: (_MAPoint point, _) => point.value,
                  color: const Color(0xFF4CAF50), // Green
                  width: 2,
                  name: 'EMA 50',
                  markerSettings: const MarkerSettings(isVisible: false),
                ),
            ],
            annotations: <CartesianChartAnnotation>[
              // Simple Support/Resistance
              if (support != null)
                CartesianChartAnnotation(
                  widget: Container(
                    height: 1,
                    color: Colors.green.withValues(alpha: 0.8),
                  ),
                  coordinateUnit: CoordinateUnit.point,
                  region: AnnotationRegion.plotArea,
                  x: widget.candles.first.time,
                  y: support,
                ),
              if (support != null)
                CartesianChartAnnotation(
                  widget: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Support: \$${support.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  coordinateUnit: CoordinateUnit.point,
                  region: AnnotationRegion.plotArea,
                  x: widget.candles[widget.candles.length ~/ 2].time,
                  y: support,
                  horizontalAlignment: ChartAlignment.center,
                  verticalAlignment: ChartAlignment.far,
                ),

              // Resistance line
              if (resistance != null)
                CartesianChartAnnotation(
                  widget: Container(
                    height: 1,
                    color: Colors.red.withValues(alpha: 0.8),
                  ),
                  coordinateUnit: CoordinateUnit.point,
                  region: AnnotationRegion.plotArea,
                  x: widget.candles.first.time,
                  y: resistance,
                ),
              if (resistance != null)
                CartesianChartAnnotation(
                  widget: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Resistance: \$${resistance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  coordinateUnit: CoordinateUnit.point,
                  region: AnnotationRegion.plotArea,
                  x: widget.candles[widget.candles.length ~/ 2].time,
                  y: resistance,
                  horizontalAlignment: ChartAlignment.center,
                  verticalAlignment: ChartAlignment.near,
                ),

              // Pivot Points
              ...?_buildPivotAnnotations(pivotPoints),

              // Fibonacci Levels
              ...?_buildFibonacciAnnotations(fibonacciLevels),
            ],
          ),
        ),
      ],
    );
  }

  List<CartesianChartAnnotation>? _buildPivotAnnotations(Map<String, double>? pivots) {
    if (pivots == null || widget.candles.isEmpty) return null;

    final annotations = <CartesianChartAnnotation>[];
    final colors = {
      'r2': Colors.red[700]!,
      'r1': Colors.red[400]!,
      'pivot': Colors.orange,
      's1': Colors.green[400]!,
      's2': Colors.green[700]!,
    };

    pivots.forEach((key, value) {
      final color = colors[key] ?? Colors.grey;
      // Line
      annotations.add(CartesianChartAnnotation(
        widget: Container(height: 1, color: color.withValues(alpha: 0.6)),
        coordinateUnit: CoordinateUnit.point,
        region: AnnotationRegion.plotArea,
        x: widget.candles.first.time,
        y: value,
      ));
      // Label
      annotations.add(CartesianChartAnnotation(
        widget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '${key.toUpperCase()}: \$${value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
        coordinateUnit: CoordinateUnit.point,
        region: AnnotationRegion.plotArea,
        x: widget.candles.last.time,
        y: value,
        horizontalAlignment: ChartAlignment.far,
      ));
    });

    return annotations;
  }

  List<CartesianChartAnnotation>? _buildFibonacciAnnotations(Map<String, double>? fibs) {
    if (fibs == null || widget.candles.isEmpty) return null;

    final annotations = <CartesianChartAnnotation>[];
    final color = Colors.purple;

    fibs.forEach((key, value) {
      // Line
      annotations.add(CartesianChartAnnotation(
        widget: Container(height: 1, color: color.withValues(alpha: 0.5), child: null),
        coordinateUnit: CoordinateUnit.point,
        region: AnnotationRegion.plotArea,
        x: widget.candles.first.time,
        y: value,
      ));
      // Label
      annotations.add(CartesianChartAnnotation(
        widget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '$key: \$${value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
        coordinateUnit: CoordinateUnit.point,
        region: AnnotationRegion.plotArea,
        x: widget.candles.last.time,
        y: value,
        horizontalAlignment: ChartAlignment.far,
      ));
    });

    return annotations;
  }

  List<CartesianSeries> _buildPriceChart(ChartType type) {
    switch (type) {
      case ChartType.candlestick:
        return [
          CandleSeries<Candle, DateTime>(
            dataSource: widget.candles,
            xValueMapper: (Candle candle, _) => candle.time,
            lowValueMapper: (Candle candle, _) => candle.low,
            highValueMapper: (Candle candle, _) => candle.high,
            openValueMapper: (Candle candle, _) => candle.open,
            closeValueMapper: (Candle candle, _) => candle.close,
            bullColor: const Color(0xFF26A69A),   // teal-green — easier on the eye
            bearColor: const Color(0xFFEF5350),   // clear red
            enableSolidCandles: true,
            width: 0.7,
            spacing: 0.15,
            name: 'Price',
          ),
        ];

      case ChartType.line:
        return [
          LineSeries<Candle, DateTime>(
            dataSource: widget.candles,
            xValueMapper: (Candle candle, _) => candle.time,
            yValueMapper: (Candle candle, _) => candle.close,
            color: const Color(0xFF06B6D4), // Cyan
            width: 2,
            name: 'Price',
            markerSettings: const MarkerSettings(isVisible: false),
          ),
        ];

      case ChartType.bar:
        return [
          HiloOpenCloseSeries<Candle, DateTime>(
            dataSource: widget.candles,
            xValueMapper: (Candle candle, _) => candle.time,
            highValueMapper: (Candle candle, _) => candle.high,
            lowValueMapper: (Candle candle, _) => candle.low,
            openValueMapper: (Candle candle, _) => candle.open,
            closeValueMapper: (Candle candle, _) => candle.close,
            bullColor: const Color(0xFF26A69A),
            bearColor: const Color(0xFFEF5350),
            spacing: 0.15,
            name: 'Price',
          ),
        ];

      case ChartType.area:
        return [
          SplineAreaSeries<Candle, DateTime>(
            dataSource: widget.candles,
            xValueMapper: (Candle candle, _) => candle.time,
            yValueMapper: (Candle candle, _) => candle.close,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF06B6D4).withValues(alpha: 0.5),
                const Color(0xFF06B6D4).withValues(alpha: 0.1),
              ],
            ),
            borderColor: const Color(0xFF06B6D4),
            borderWidth: 2,
            name: 'Price',
            markerSettings: const MarkerSettings(isVisible: false),
          ),
        ];
    }
  }

  List<_MAPoint> _getMAPoints(List<double?> maValues, String name) {
    final points = <_MAPoint>[];
    for (int i = 0; i < widget.candles.length; i++) {
      if (maValues[i] != null) {
        points.add(_MAPoint(
          time: widget.candles[i].time,
          value: maValues[i]!,
          name: name,
        ));
      }
    }
    return points;
  }

  List<_BollingerPoint> _getBollingerPoints(List<double?> values) {
    final points = <_BollingerPoint>[];
    for (int i = 0; i < widget.candles.length; i++) {
      if (values[i] != null) {
        points.add(_BollingerPoint(
          time: widget.candles[i].time,
          value: values[i]!,
        ));
      }
    }
    return points;
  }
}

class _MAPoint {
  final DateTime time;
  final double value;
  final String name;

  _MAPoint({required this.time, required this.value, required this.name});
}

class _BollingerPoint {
  final DateTime time;
  final double value;

  _BollingerPoint({required this.time, required this.value});
}
