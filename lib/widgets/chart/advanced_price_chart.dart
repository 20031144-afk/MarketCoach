import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../../models/candle.dart';
import '../../services/technical_analysis_service.dart';
import 'chart_type_selector.dart';
import 'advanced_indicator_settings.dart';

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
  late final ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true,
      enableSelectionZooming: true,
      zoomMode: ZoomMode.x,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: const Text('No data available'),
      );
    }

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

    // Compute smart X-axis settings from the actual date range
    final duration =
        widget.candles.last.time.difference(widget.candles.first.time);

    DateTimeIntervalType xIntervalType;
    DateFormat xLabelFormat;
    double xInterval;

    if (duration.inDays <= 3) {
      xIntervalType = DateTimeIntervalType.hours;
      xLabelFormat = DateFormat('HH:mm');
      xInterval = 4;
    } else if (duration.inDays <= 90) {
      xIntervalType = DateTimeIntervalType.days;
      xLabelFormat = DateFormat('MMM dd');
      xInterval = max(7, (duration.inDays / 6).ceilToDouble());
    } else if (duration.inDays <= 400) {
      xIntervalType = DateTimeIntervalType.months;
      xLabelFormat = DateFormat('MMM');
      xInterval = 1;
    } else {
      xIntervalType = DateTimeIntervalType.months;
      xLabelFormat = DateFormat("MMM ''yy");
      xInterval = 3;
    }

    // Y-axis number format — compact for large prices (BTC, etc.)
    final maxPrice =
        widget.candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final yNumberFormat =
        maxPrice >= 10000 ? NumberFormat('#,##0') : NumberFormat('#,##0.##');

    return Column(
      children: [
        // Zoom controls
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in, size: 20),
              onPressed: () => _zoomPanBehavior.zoomIn(),
              tooltip: 'Zoom in',
              color: Colors.white54,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.zoom_out, size: 20),
              onPressed: () => _zoomPanBehavior.zoomOut(),
              tooltip: 'Zoom out',
              color: Colors.white54,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.fit_screen, size: 20),
              onPressed: () => _zoomPanBehavior.reset(),
              tooltip: 'Reset zoom',
              color: Colors.white54,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Main Chart
        SizedBox(
          height: 350,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            plotAreaBorderColor: Colors.transparent,
            primaryXAxis: DateTimeAxis(
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: const AxisLine(width: 0),
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
              dateFormat: xLabelFormat,
              intervalType: xIntervalType,
              interval: xInterval,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              enableAutoIntervalOnZooming: true,
            ),
            primaryYAxis: NumericAxis(
              majorGridLines: MajorGridLines(
                width: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              axisLine: const AxisLine(width: 0),
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
              opposedPosition: true,
              desiredIntervals: 5,
              numberFormat: yNumberFormat,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              enableAutoIntervalOnZooming: true,
            ),
            trackballBehavior: widget.trackballBehavior,
            zoomPanBehavior: _zoomPanBehavior,
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
            bullColor: Colors.green,
            bearColor: Colors.red,
            enableSolidCandles: true,
            spacing: 0.2,
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
            bullColor: Colors.green,
            bearColor: Colors.red,
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
