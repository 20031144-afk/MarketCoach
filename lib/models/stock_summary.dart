class StockSummary {
  final String ticker;
  final String name;
  final double price;
  final double changePercent;
  final bool isCrypto;
  final Map<String, String>? fundamentals;
  final List<String>? technicalHighlights;
  final String? sector;
  final String? industry;

  const StockSummary({
    required this.ticker,
    required this.name,
    required this.price,
    required this.changePercent,
    this.isCrypto = false,
    this.fundamentals,
    this.technicalHighlights,
    this.sector,
    this.industry,
  });

  bool get isPositive => changePercent >= 0;
}
