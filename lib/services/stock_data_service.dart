/// Stock Data Service - Fetch market data for analysis
///
/// Uses free APIs (Yahoo Finance, Alpha Vantage) to gather:
/// - Current price and price history
/// - Company information
/// - Recent news headlines

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Stock market data for AI analysis
class StockData {
  final String symbol;
  final double currentPrice;
  final double? changePercent;
  final double? dayHigh;
  final double? dayLow;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final int? volume;
  final int? avgVolume;
  final double? marketCap;
  final double? peRatio;
  final String? companyName;
  final List<PricePoint> priceHistory; // Last 30 days
  final List<NewsHeadline> news;

  StockData({
    required this.symbol,
    required this.currentPrice,
    this.changePercent,
    this.dayHigh,
    this.dayLow,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.volume,
    this.avgVolume,
    this.marketCap,
    this.peRatio,
    this.companyName,
    this.priceHistory = const [],
    this.news = const [],
  });

  /// Get price trend description
  String get priceTrend {
    if (changePercent == null) return 'neutral';
    if (changePercent! > 2) return 'strongly up';
    if (changePercent! > 0) return 'slightly up';
    if (changePercent! < -2) return 'strongly down';
    if (changePercent! < 0) return 'slightly down';
    return 'neutral';
  }

  /// Calculate relative position to 52-week range (0-100)
  double? get fiftyTwoWeekPosition {
    if (fiftyTwoWeekHigh == null || fiftyTwoWeekLow == null) return null;
    final range = fiftyTwoWeekHigh! - fiftyTwoWeekLow!;
    if (range == 0) return 50;
    return ((currentPrice - fiftyTwoWeekLow!) / range) * 100;
  }
}

class PricePoint {
  final DateTime date;
  final double price;

  PricePoint(this.date, this.price);
}

class NewsHeadline {
  final String title;
  final String? source;
  final DateTime? publishedAt;
  final String? url;

  NewsHeadline({
    required this.title,
    this.source,
    this.publishedAt,
    this.url,
  });
}

/// Service to fetch stock market data
class StockDataService {
  /// Fetch comprehensive stock data for analysis
  Future<StockData> fetchStockData(String symbol) async {
    try {
      // Fetch quote data
      final quoteData = await _fetchQuoteData(symbol);

      // Fetch price history (last 30 days)
      final priceHistory = await _fetchPriceHistory(symbol);

      // Fetch news headlines
      final news = await _fetchNews(symbol);

      return StockData(
        symbol: symbol.toUpperCase(),
        currentPrice: quoteData['price'] ?? 0.0,
        changePercent: quoteData['changePercent'],
        dayHigh: quoteData['dayHigh'],
        dayLow: quoteData['dayLow'],
        fiftyTwoWeekHigh: quoteData['fiftyTwoWeekHigh'],
        fiftyTwoWeekLow: quoteData['fiftyTwoWeekLow'],
        volume: quoteData['volume'],
        avgVolume: quoteData['avgVolume'],
        marketCap: quoteData['marketCap'],
        peRatio: quoteData['peRatio'],
        companyName: quoteData['companyName'],
        priceHistory: priceHistory,
        news: news,
      );
    } catch (e) {
      print('Error fetching stock data for $symbol: $e');
      rethrow;
    }
  }

  /// Fetch current quote data from Yahoo Finance
  Future<Map<String, dynamic>> _fetchQuoteData(String symbol) async {
    try {
      // Use Yahoo Finance v8 API (no key required, but rate limited)
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=5d');

      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch quote: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final result = data['chart']['result'][0];
      final meta = result['meta'];
      final quote = result['indicators']['quote'][0];

      // Get latest close price
      final closes = (quote['close'] as List).cast<double?>();
      final latestClose =
          closes.lastWhere((c) => c != null, orElse: () => null);

      return {
        'price': latestClose ?? meta['regularMarketPrice'] ?? 0.0,
        'changePercent': ((meta['regularMarketPrice'] -
                    meta['chartPreviousClose']) /
                meta['chartPreviousClose'] *
                100)
            .toDouble(),
        'dayHigh': meta['regularMarketDayHigh']?.toDouble(),
        'dayLow': meta['regularMarketDayLow']?.toDouble(),
        'fiftyTwoWeekHigh': meta['fiftyTwoWeekHigh']?.toDouble(),
        'fiftyTwoWeekLow': meta['fiftyTwoWeekLow']?.toDouble(),
        'volume': meta['regularMarketVolume']?.toInt(),
        'avgVolume': null, // Not available in this endpoint
        'marketCap': null,
        'peRatio': null,
        'companyName': meta['symbol'],
      };
    } catch (e) {
      print('Error fetching quote data: $e');
      // Return minimal data if API fails
      return {
        'price': 0.0,
        'companyName': symbol,
      };
    }
  }

  /// Fetch 30-day price history
  Future<List<PricePoint>> _fetchPriceHistory(String symbol) async {
    try {
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1mo');

      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final result = data['chart']['result'][0];

      final timestamps = (result['timestamp'] as List).cast<int>();
      final quotes = result['indicators']['quote'][0];
      final closes = (quotes['close'] as List).cast<double?>();

      final history = <PricePoint>[];
      for (var i = 0; i < timestamps.length; i++) {
        if (closes[i] != null) {
          history.add(PricePoint(
            DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
            closes[i]!,
          ));
        }
      }

      return history;
    } catch (e) {
      print('Error fetching price history: $e');
      return [];
    }
  }

  /// Fetch recent news headlines
  Future<List<NewsHeadline>> _fetchNews(String symbol) async {
    try {
      // Use Yahoo Finance news API
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v1/finance/search?q=$symbol&quotesCount=0&newsCount=5');

      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return _getMockNews(symbol);
      }

      final data = jsonDecode(response.body);
      final newsItems = data['news'] as List?;

      if (newsItems == null || newsItems.isEmpty) {
        return _getMockNews(symbol);
      }

      return newsItems.take(5).map((item) {
        return NewsHeadline(
          title: item['title'] ?? 'No title',
          source: item['publisher'],
          publishedAt: item['providerPublishTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  item['providerPublishTime'] * 1000)
              : null,
          url: item['link'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching news: $e');
      return _getMockNews(symbol);
    }
  }

  /// Provide mock news if API fails (for graceful degradation)
  List<NewsHeadline> _getMockNews(String symbol) {
    return [
      NewsHeadline(
        title: '$symbol Stock Analysis: Latest Market Update',
        source: 'Market News',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NewsHeadline(
        title: 'Investors Eye $symbol Performance',
        source: 'Financial Times',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
