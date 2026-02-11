const _cryptoSymbols = {'BTC', 'ETH', 'SOL', 'BNB'};

bool isCryptoSymbol(String symbol) {
  return _cryptoSymbols.contains(symbol.toUpperCase());
}
