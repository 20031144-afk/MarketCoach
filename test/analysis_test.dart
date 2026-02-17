/// Quick test to verify Claude API and stock data fetching works
///
/// Run this with: dart test/analysis_test.dart

import 'package:market_coach/services/claude_analysis_service.dart';
import 'package:market_coach/services/stock_data_service.dart';
import 'package:market_coach/config/api_config.dart';

void main() async {
  print('🔍 Testing MarketCoach Analysis System...\n');

  // Test 1: Check API configuration
  print('1️⃣ Checking API Configuration...');
  print('   API Key configured: ${APIConfig.isConfigured}');
  print('   API Key starts with: ${APIConfig.claudeApiKey.substring(0, 15)}...');
  print('   Model: ${APIConfig.claudeModel}');

  if (!APIConfig.isConfigured) {
    print('   ❌ ERROR: API key not configured!');
    print('   Please set your Claude API key in lib/config/api_config.dart\n');
    return;
  }
  print('   ✅ Configuration OK\n');

  // Test 2: Fetch stock data
  print('2️⃣ Testing Stock Data Fetch...');
  try {
    final stockService = StockDataService();
    print('   Fetching AAPL data from Yahoo Finance...');

    final stockData = await stockService.fetchStockData('AAPL');

    print('   ✅ Stock data received:');
    print('      Symbol: ${stockData.symbol}');
    print('      Current Price: \$${stockData.currentPrice.toStringAsFixed(2)}');
    if (stockData.changePercent != null) {
      print('      Change: ${stockData.changePercent!.toStringAsFixed(2)}%');
    }
    print('      Price History: ${stockData.priceHistory.length} days');
    print('      News Headlines: ${stockData.news.length} items');
    print('');
  } catch (e) {
    print('   ❌ ERROR fetching stock data: $e\n');
    return;
  }

  // Test 3: Test Claude API
  print('3️⃣ Testing Claude API Analysis...');
  try {
    final analysisService = ClaudeAnalysisService();
    print('   Calling Claude API for AAPL analysis...');
    print('   (This may take 10-20 seconds...)\n');

    final analysis = await analysisService.getStructuredAnalysis('AAPL');

    print('   ✅ Analysis received:');
    print('      Symbol: ${analysis.symbol}');
    print('      Timestamp: ${analysis.timestamp}');
    print('      Sentiment Score: ${analysis.sentimentScore}');
    print('      Recommendation: ${analysis.recommendation}');
    print('      Summary: ${analysis.summaryText.substring(0, analysis.summaryText.length.clamp(0, 150))}...');
    print('      Bullish factors: ${analysis.bullishFactors.length}');
    print('      Bearish factors: ${analysis.bearishFactors.length}');
    print('      Risk Level: ${analysis.riskLevel}');
    print('      Price Target: ${analysis.priceTarget?.target}');
    print('');
    print('   🎉 SUCCESS! Everything is working!\n');

  } catch (e) {
    print('   ❌ ERROR calling Claude API: $e');
    print('');
    print('   Common issues:');
    print('   - Invalid API key (check lib/config/api_config.dart)');
    print('   - Network connection problem');
    print('   - Rate limit exceeded (wait a few minutes)');
    print('   - API service temporarily down\n');
    return;
  }

  print('✅ All tests passed! Your app should work correctly.');
  print('📱 Run the app and try the Analysis tab.\n');
}
