import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/candle.dart';

class BinanceCandleService {
  static const _wsBaseUrl = 'wss://stream.binance.com:9443/stream';
  static const _restBaseUrl = 'https://api.binance.com/api/v3/klines';

  static const _symbolMapping = {
    'BTC': 'BTCUSDT',
    'ETH': 'ETHUSDT',
    'SOL': 'SOLUSDT',
    'BNB': 'BNBUSDT',
    'ADA': 'ADAUSDT',
    'XRP': 'XRPUSDT',
    'XLM': 'XLMUSDT',
  };

  static const _maxCandles = 120;

  WebSocketChannel? _channel;

  final Map<String, StreamController<List<Candle>>> _controllers = {};
  final Map<String, List<Candle>> _candleHistory = {};

  // Track active streams as keys: "BTC-1m", "BTC-5m", etc.
  final Set<String> _activeKeys = {};

  // Prevent duplicate REST seed calls for same key
  final Set<String> _seedingKeys = {};

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  Stream<List<Candle>> streamCandles(String symbol, {String interval = '1m'}) {
    final key = '$symbol-$interval';

    if (!_controllers.containsKey(key)) {
      _controllers[key] = StreamController<List<Candle>>.broadcast(
        onListen: () async {
          _activeKeys.add(key);

          // Seed history immediately (REST) so chart renders instantly
          await _seedHistoryIfNeeded(symbol, interval);

          // Then connect websocket for live updates
          _reconnect();
        },
        onCancel: () {
          _activeKeys.remove(key);
          _controllers.remove(key);
          _candleHistory.remove(key);
          _seedingKeys.remove(key);

          if (_activeKeys.isEmpty) {
            _disconnect();
          } else {
            _reconnect();
          }
        },
      );

      _candleHistory[key] = <Candle>[];
    }

    return _controllers[key]!.stream;
  }

  Future<void> _seedHistoryIfNeeded(String symbol, String interval) async {
    final key = '$symbol-$interval';
    if (_seedingKeys.contains(key)) return;
    _seedingKeys.add(key);

    try {
      final mapped = _symbolMapping[symbol];
      if (mapped == null) return;

      final uri = Uri.parse(
        '$_restBaseUrl?symbol=$mapped&interval=$interval&limit=$_maxCandles',
      );
      _log('Seeding candles via REST: $uri');

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        _log('REST seed failed (${res.statusCode}): ${res.body}');
        return;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) return;

      final candles = <Candle>[];
      for (final row in decoded) {
        // Binance kline REST row format:
        // [ openTime, open, high, low, close, volume, closeTime, ... ]
        if (row is List && row.length >= 6) {
          final openTime = row[0] as int;
          final open = double.tryParse('${row[1]}') ?? 0.0;
          final high = double.tryParse('${row[2]}') ?? 0.0;
          final low = double.tryParse('${row[3]}') ?? 0.0;
          final close = double.tryParse('${row[4]}') ?? 0.0;
          final volume = double.tryParse('${row[5]}') ?? 0.0;

          candles.add(
            Candle(
              time: DateTime.fromMillisecondsSinceEpoch(openTime),
              open: open,
              high: high,
              low: low,
              close: close,
              volume: volume,
            ),
          );
        }
      }

      if (candles.isEmpty) return;

      // Save + emit immediately
      _candleHistory[key] = candles.take(_maxCandles).toList();
      _controllers[key]?.add(List<Candle>.from(_candleHistory[key]!));

      _log('Seeded ${candles.length} candles for $symbol $interval');
    } catch (e) {
      _log('REST seed error: $e');
    } finally {
      // keep _seedingKeys entry to avoid reseeding repeatedly
    }
  }

  void _reconnect() {
    _disconnect();
    _connect();
  }

  void _connect() {
    try {
      if (_activeKeys.isEmpty) return;

      final streams = _activeKeys
          .map((key) {
            final parts = key.split('-'); // ["BTC", "1m"]
            if (parts.length != 2) return null;

            final symbol = parts[0];
            final interval = parts[1];

            final mapped = _symbolMapping[symbol];
            if (mapped == null) return null;

            return '${mapped.toLowerCase()}@kline_$interval';
          })
          .whereType<String>()
          .join('/');

      if (streams.isEmpty) return;

      _log('Connecting to Binance WS...');
      final uri = Uri.parse('$_wsBaseUrl?streams=$streams');
      _channel = WebSocketChannel.connect(uri);

      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      _log('Connected. Streaming: $streams');

      _channel!.stream.listen(
        (message) {
          try {
            _handleMessage(message);
          } catch (e) {
            _log('WS parse error: $e');
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } catch (e) {
      _log('WS connection error: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    final data = jsonDecode(message as String);
    if (data is! Map || data['data'] == null) return;

    final klineData = data['data'];
    final k = klineData['k'];
    if (k == null) return;

    final binanceSymbol = (k['s'] as String).toUpperCase();
    final interval = k['i'] as String;

    final displaySymbol = _symbolMapping.entries
        .firstWhere(
          (e) => e.value == binanceSymbol,
          orElse: () => const MapEntry('', ''),
        )
        .key;

    if (displaySymbol.isEmpty) return;

    final key = '$displaySymbol-$interval';
    if (!_controllers.containsKey(key)) return;

    final candle = Candle(
      time: DateTime.fromMillisecondsSinceEpoch(k['t'] as int),
      open: double.tryParse('${k['o']}') ?? 0.0,
      high: double.tryParse('${k['h']}') ?? 0.0,
      low: double.tryParse('${k['l']}') ?? 0.0,
      close: double.tryParse('${k['c']}') ?? 0.0,
      volume: double.tryParse('${k['v']}') ?? 0.0,
    );

    final history = _candleHistory[key] ?? <Candle>[];
    final isClosed = k['x'] as bool;

    // Update last candle if same openTime, else append
    if (history.isNotEmpty &&
        history.last.time.millisecondsSinceEpoch ==
            candle.time.millisecondsSinceEpoch) {
      history[history.length - 1] = candle;
    } else {
      history.add(candle);
      if (history.length > _maxCandles) history.removeAt(0);
    }

    if (isClosed) {
      _log(
        '$displaySymbol ($interval) candle closed: ${candle.close.toStringAsFixed(2)}',
      );
    }

    _candleHistory[key] = history;
    _controllers[key]?.add(List<Candle>.from(history));
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    final delaySeconds = min(pow(2, _reconnectAttempts).toInt(), 30);
    _reconnectAttempts++;

    _log('Reconnecting in ${delaySeconds}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _disconnect();
      _connect();
    });
  }

  void _disconnect() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void dispose() {
    _log('Disposing candle service');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _disconnect();

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _candleHistory.clear();
    _activeKeys.clear();
    _seedingKeys.clear();
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[BinanceCandleService] $msg');
  }
}
