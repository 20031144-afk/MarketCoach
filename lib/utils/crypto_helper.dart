/// All crypto symbols supported by BinanceCandleService
const _cryptoSymbols = {
  'BTC', 'ETH', 'SOL', 'BNB', 'ADA', 'XRP', 'XLM',
};

bool isCryptoSymbol(String symbol) {
  return _cryptoSymbols.contains(symbol.toUpperCase());
}
