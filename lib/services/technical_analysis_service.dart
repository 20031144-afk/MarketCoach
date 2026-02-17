import '../models/candle.dart';

class TechnicalAnalysisService {
  /// Calculate Exponential Moving Average
  static List<double?> calculateEMA(List<Candle> candles, int period) {
    final ema = <double?>[];
    if (candles.isEmpty) return ema;

    // First EMA is SMA
    double? prevEMA;
    final multiplier = 2.0 / (period + 1);

    for (int i = 0; i < candles.length; i++) {
      if (i < period - 1) {
        ema.add(null);
      } else if (i == period - 1) {
        // Calculate first EMA as SMA
        double sum = 0;
        for (int j = 0; j < period; j++) {
          sum += candles[i - j].close;
        }
        prevEMA = sum / period;
        ema.add(prevEMA);
      } else {
        // EMA = (Close - EMA(previous)) * multiplier + EMA(previous)
        prevEMA = (candles[i].close - prevEMA!) * multiplier + prevEMA;
        ema.add(prevEMA);
      }
    }

    return ema;
  }

  /// Calculate Simple Moving Average
  static List<double?> calculateSMA(List<Candle> candles, int period) {
    final sma = <double?>[];

    for (int i = 0; i < candles.length; i++) {
      if (i < period - 1) {
        sma.add(null); // Not enough data yet
      } else {
        double sum = 0;
        for (int j = 0; j < period; j++) {
          sum += candles[i - j].close;
        }
        sma.add(sum / period);
      }
    }

    return sma;
  }

  /// Calculate Support level using swing lows.
  ///
  /// Finds local swing lows (candles where the low is lower than [window]
  /// candles on each side) and returns the most significant cluster near
  /// the current price — i.e. the strongest floor the price has bounced off.
  static double calculateSupport(List<Candle> candles, {int window = 5}) {
    if (candles.length < window * 2 + 1) {
      // Not enough data — fall back to lowest low in entire dataset
      return candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    }

    final currentPrice = candles.last.close;
    final swingLows = <double>[];

    for (int i = window; i < candles.length - window; i++) {
      final low = candles[i].low;
      bool isSwing = true;
      for (int j = i - window; j <= i + window; j++) {
        if (j != i && candles[j].low <= low) {
          isSwing = false;
          break;
        }
      }
      if (isSwing) swingLows.add(low);
    }

    if (swingLows.isEmpty) {
      return candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    }

    // Return the highest swing low that is still below current price
    // (closest floor beneath price = strongest support)
    final belowPrice = swingLows.where((v) => v < currentPrice).toList()
      ..sort();
    if (belowPrice.isNotEmpty) return belowPrice.last;

    // All swing lows are above current price — return the absolute lowest
    return swingLows.reduce((a, b) => a < b ? a : b);
  }

  /// Calculate Resistance level using swing highs.
  ///
  /// Finds local swing highs and returns the most significant ceiling above
  /// the current price — the level where price has previously reversed.
  static double calculateResistance(List<Candle> candles, {int window = 5}) {
    if (candles.length < window * 2 + 1) {
      return candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    }

    final currentPrice = candles.last.close;
    final swingHighs = <double>[];

    for (int i = window; i < candles.length - window; i++) {
      final high = candles[i].high;
      bool isSwing = true;
      for (int j = i - window; j <= i + window; j++) {
        if (j != i && candles[j].high >= high) {
          isSwing = false;
          break;
        }
      }
      if (isSwing) swingHighs.add(high);
    }

    if (swingHighs.isEmpty) {
      return candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    }

    // Return the lowest swing high that is still above current price
    // (closest ceiling = strongest resistance)
    final abovePrice = swingHighs.where((v) => v > currentPrice).toList()
      ..sort();
    if (abovePrice.isNotEmpty) return abovePrice.first;

    return swingHighs.reduce((a, b) => a > b ? a : b);
  }

  /// Calculate Pivot Points
  static Map<String, double> calculatePivotPoints(List<Candle> candles) {
    if (candles.isEmpty) return {};

    final lastCandle = candles.last;
    final pivot = (lastCandle.high + lastCandle.low + lastCandle.close) / 3;

    return {
      'pivot': pivot,
      'r1': 2 * pivot - lastCandle.low,
      'r2': pivot + (lastCandle.high - lastCandle.low),
      's1': 2 * pivot - lastCandle.high,
      's2': pivot - (lastCandle.high - lastCandle.low),
    };
  }

  /// Calculate Bollinger Bands
  static Map<String, List<double?>> calculateBollingerBands(
    List<Candle> candles,
    {int period = 20, double stdDev = 2.0}
  ) {
    final sma = calculateSMA(candles, period);
    final upper = <double?>[];
    final lower = <double?>[];

    for (int i = 0; i < candles.length; i++) {
      if (sma[i] == null) {
        upper.add(null);
        lower.add(null);
      } else {
        // Calculate standard deviation
        double sumSquares = 0;
        for (int j = 0; j < period; j++) {
          final diff = candles[i - j].close - sma[i]!;
          sumSquares += diff * diff;
        }
        final std = Math.sqrt(sumSquares / period);

        upper.add(sma[i]! + (stdDev * std));
        lower.add(sma[i]! - (stdDev * std));
      }
    }

    return {
      'upper': upper,
      'middle': sma,
      'lower': lower,
    };
  }

  /// Detect swing highs (potential resistance points)
  static List<int> detectSwingHighs(List<Candle> candles, {int window = 5}) {
    final swingHighs = <int>[];

    for (int i = window; i < candles.length - window; i++) {
      bool isSwingHigh = true;

      // Check if this is the highest point in the window
      for (int j = i - window; j <= i + window; j++) {
        if (j != i && candles[j].high >= candles[i].high) {
          isSwingHigh = false;
          break;
        }
      }

      if (isSwingHigh) {
        swingHighs.add(i);
      }
    }

    return swingHighs;
  }

  /// Detect swing lows (potential support points)
  static List<int> detectSwingLows(List<Candle> candles, {int window = 5}) {
    final swingLows = <int>[];

    for (int i = window; i < candles.length - window; i++) {
      bool isSwingLow = true;

      // Check if this is the lowest point in the window
      for (int j = i - window; j <= i + window; j++) {
        if (j != i && candles[j].low <= candles[i].low) {
          isSwingLow = false;
          break;
        }
      }

      if (isSwingLow) {
        swingLows.add(i);
      }
    }

    return swingLows;
  }

  /// Calculate Fibonacci Retracement Levels
  static Map<String, double> calculateFibonacci(List<Candle> candles) {
    if (candles.isEmpty) return {};

    // Find highest and lowest points
    double highest = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double lowest = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    double diff = highest - lowest;

    return {
      '0%': highest,
      '23.6%': highest - (diff * 0.236),
      '38.2%': highest - (diff * 0.382),
      '50%': highest - (diff * 0.5),
      '61.8%': highest - (diff * 0.618),
      '78.6%': highest - (diff * 0.786),
      '100%': lowest,
    };
  }

  /// Calculate RSI (Relative Strength Index) historical values
  static List<double?> calculateRSIHistory(List<Candle> candles, {int period = 14}) {
    final rsi = <double?>[];
    if (candles.length < period + 1) {
      return List.filled(candles.length, null);
    }

    List<double> gains = [];
    List<double> losses = [];

    // Calculate price changes
    for (int i = 1; i < candles.length; i++) {
      double change = candles[i].close - candles[i - 1].close;
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    // Calculate first average gain and loss
    double avgGain = gains.take(period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.take(period).reduce((a, b) => a + b) / period;

    rsi.add(null); // First candle has no RSI

    for (int i = 0; i < period; i++) {
      rsi.add(null); // Not enough data
    }

    // Calculate RSI for each period
    for (int i = period; i < gains.length; i++) {
      avgGain = (avgGain * (period - 1) + gains[i]) / period;
      avgLoss = (avgLoss * (period - 1) + losses[i]) / period;

      if (avgLoss == 0) {
        rsi.add(100);
      } else {
        double rs = avgGain / avgLoss;
        rsi.add(100 - (100 / (1 + rs)));
      }
    }

    return rsi;
  }

  /// Calculate MACD (Moving Average Convergence Divergence) historical values
  static Map<String, List<double?>> calculateMACDHistory(
    List<Candle> candles,
    {int fastPeriod = 12, int slowPeriod = 26, int signalPeriod = 9}
  ) {
    final emaFast = calculateEMA(candles, fastPeriod);
    final emaSlow = calculateEMA(candles, slowPeriod);

    // Calculate MACD line
    final macdLine = <double?>[];
    for (int i = 0; i < candles.length; i++) {
      if (emaFast[i] == null || emaSlow[i] == null) {
        macdLine.add(null);
      } else {
        macdLine.add(emaFast[i]! - emaSlow[i]!);
      }
    }

    // Calculate signal line (EMA of MACD)
    final signalLine = <double?>[];
    double? prevSignal;
    final multiplier = 2.0 / (signalPeriod + 1);

    int firstValidIndex = -1;
    for (int i = 0; i < macdLine.length; i++) {
      if (macdLine[i] != null) {
        if (firstValidIndex == -1) firstValidIndex = i;

        if (i < firstValidIndex + signalPeriod - 1) {
          signalLine.add(null);
        } else if (i == firstValidIndex + signalPeriod - 1) {
          // First signal is SMA of MACD
          double sum = 0;
          for (int j = 0; j < signalPeriod; j++) {
            sum += macdLine[i - j]!;
          }
          prevSignal = sum / signalPeriod;
          signalLine.add(prevSignal);
        } else {
          // EMA calculation
          prevSignal = (macdLine[i]! - prevSignal!) * multiplier + prevSignal;
          signalLine.add(prevSignal);
        }
      } else {
        signalLine.add(null);
      }
    }

    // Calculate histogram
    final histogram = <double?>[];
    for (int i = 0; i < candles.length; i++) {
      if (macdLine[i] == null || signalLine[i] == null) {
        histogram.add(null);
      } else {
        histogram.add(macdLine[i]! - signalLine[i]!);
      }
    }

    return {
      'macd': macdLine,
      'signal': signalLine,
      'histogram': histogram,
    };
  }
}

// Simple Math helper
class Math {
  static double sqrt(double x) {
    if (x < 0) return 0;
    double result = x / 2;
    double prev;

    do {
      prev = result;
      result = (result + x / result) / 2;
    } while ((result - prev).abs() > 0.00001);

    return result;
  }
}
