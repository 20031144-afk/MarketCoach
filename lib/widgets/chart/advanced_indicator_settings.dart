import 'package:flutter/material.dart';

enum MAType { none, sma, ema, both }
enum SRType { none, simple, pivot, fibonacci }
enum SubChartType { none, rsi, macd }

class AdvancedIndicatorSettings extends StatelessWidget {
  final MAType movingAverageType;
  final bool showBollingerBands;
  final SRType supportResistanceType;
  final SubChartType subChartType;
  final Function(MAType) onMATypeChanged;
  final Function(bool) onBollingerBandsChanged;
  final Function(SRType) onSRTypeChanged;
  final Function(SubChartType) onSubChartChanged;

  const AdvancedIndicatorSettings({
    super.key,
    required this.movingAverageType,
    required this.showBollingerBands,
    required this.supportResistanceType,
    required this.subChartType,
    required this.onMATypeChanged,
    required this.onBollingerBandsChanged,
    required this.onSRTypeChanged,
    required this.onSubChartChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Chart Indicators',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid of dropdowns
          Row(
            children: [
              // Moving Averages Dropdown
              Expanded(
                child: _DropdownOption(
                  label: 'Moving Avg',
                  icon: Icons.trending_up,
                  value: _getMALabel(movingAverageType),
                  onTap: () => _showMADialog(context),
                ),
              ),
              const SizedBox(width: 8),

              // Support/Resistance Dropdown
              Expanded(
                child: _DropdownOption(
                  label: 'S/R Levels',
                  icon: Icons.horizontal_rule,
                  value: _getSRLabel(supportResistanceType),
                  onTap: () => _showSRDialog(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              // Sub-chart Dropdown
              Expanded(
                child: _DropdownOption(
                  label: 'Oscillator',
                  icon: Icons.show_chart,
                  value: _getSubChartLabel(subChartType),
                  onTap: () => _showSubChartDialog(context),
                ),
              ),
              const SizedBox(width: 8),

              // Bollinger Bands Toggle
              Expanded(
                child: _ToggleOption(
                  label: 'Bollinger',
                  icon: Icons.analytics,
                  isActive: showBollingerBands,
                  onChanged: onBollingerBandsChanged,
                ),
              ),
            ],
          ),

          // Active indicators legend
          if (movingAverageType != MAType.none ||
              showBollingerBands ||
              supportResistanceType != SRType.none) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _IndicatorLegend(
              maType: movingAverageType,
              showBollinger: showBollingerBands,
              srType: supportResistanceType,
            ),
          ],
        ],
      ),
    );
  }

  String _getMALabel(MAType type) {
    switch (type) {
      case MAType.none:
        return 'None';
      case MAType.sma:
        return 'SMA';
      case MAType.ema:
        return 'EMA';
      case MAType.both:
        return 'SMA+EMA';
    }
  }

  String _getSRLabel(SRType type) {
    switch (type) {
      case SRType.none:
        return 'None';
      case SRType.simple:
        return 'Simple';
      case SRType.pivot:
        return 'Pivot Points';
      case SRType.fibonacci:
        return 'Fibonacci';
    }
  }

  String _getSubChartLabel(SubChartType type) {
    switch (type) {
      case SubChartType.none:
        return 'None';
      case SubChartType.rsi:
        return 'RSI';
      case SubChartType.macd:
        return 'MACD';
    }
  }

  void _showMADialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moving Averages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('None'),
              leading: Radio<MAType>(
                value: MAType.none,
                groupValue: movingAverageType,
                onChanged: (value) {
                  onMATypeChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('SMA (20, 50, 200)'),
              subtitle: const Text('Simple Moving Average'),
              leading: Radio<MAType>(
                value: MAType.sma,
                groupValue: movingAverageType,
                onChanged: (value) {
                  onMATypeChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('EMA (12, 26, 50)'),
              subtitle: const Text('Exponential Moving Average'),
              leading: Radio<MAType>(
                value: MAType.ema,
                groupValue: movingAverageType,
                onChanged: (value) {
                  onMATypeChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Both SMA + EMA'),
              leading: Radio<MAType>(
                value: MAType.both,
                groupValue: movingAverageType,
                onChanged: (value) {
                  onMATypeChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support/Resistance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('None'),
              leading: Radio<SRType>(
                value: SRType.none,
                groupValue: supportResistanceType,
                onChanged: (value) {
                  onSRTypeChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Simple S/R'),
              subtitle: const Text('Recent high/low'),
              leading: Radio<SRType>(
                value: SRType.simple,
                groupValue: supportResistanceType,
                onChanged: (value) {
                  onSRTypeChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Pivot Points'),
              subtitle: const Text('P, R1, R2, S1, S2'),
              leading: Radio<SRType>(
                value: SRType.pivot,
                groupValue: supportResistanceType,
                onChanged: (value) {
                  onSRTypeChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Fibonacci'),
              subtitle: const Text('Retracement levels'),
              leading: Radio<SRType>(
                value: SRType.fibonacci,
                groupValue: supportResistanceType,
                onChanged: (value) {
                  onSRTypeChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubChartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oscillator Chart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('None'),
              leading: Radio<SubChartType>(
                value: SubChartType.none,
                groupValue: subChartType,
                onChanged: (value) {
                  onSubChartChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('RSI'),
              subtitle: const Text('Relative Strength Index'),
              leading: Radio<SubChartType>(
                value: SubChartType.rsi,
                groupValue: subChartType,
                onChanged: (value) {
                  onSubChartChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('MACD'),
              subtitle: const Text('Moving Average Convergence Divergence'),
              leading: Radio<SubChartType>(
                value: SubChartType.macd,
                groupValue: subChartType,
                onChanged: (value) {
                  onSubChartChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _DropdownOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Function(bool) onChanged;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onChanged(!isActive),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? theme.colorScheme.primary : Colors.white54,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? theme.colorScheme.primary : Colors.white54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? 'ON' : 'OFF',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? theme.colorScheme.primary : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorLegend extends StatelessWidget {
  final MAType maType;
  final bool showBollinger;
  final SRType srType;

  const _IndicatorLegend({
    required this.maType,
    required this.showBollinger,
    required this.srType,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        if (maType == MAType.sma || maType == MAType.both) ...[
          _LegendItem(color: Color(0xFFFFEB3B), label: 'SMA20'),
          _LegendItem(color: Color(0xFFFF9800), label: 'SMA50'),
          _LegendItem(color: Color(0xFFE91E63), label: 'SMA200'),
        ],
        if (maType == MAType.ema || maType == MAType.both) ...[
          _LegendItem(color: Color(0xFF00BCD4), label: 'EMA12'),
          _LegendItem(color: Color(0xFF9C27B0), label: 'EMA26'),
          _LegendItem(color: Color(0xFF4CAF50), label: 'EMA50'),
        ],
        if (showBollinger)
          _LegendItem(color: Colors.blue, label: 'Bollinger'),
        if (srType == SRType.simple) ...[
          _LegendItem(color: Colors.green, label: 'Support'),
          _LegendItem(color: Colors.red, label: 'Resistance'),
        ],
        if (srType == SRType.pivot)
          _LegendItem(color: Colors.orange, label: 'Pivot Points'),
        if (srType == SRType.fibonacci)
          _LegendItem(color: Colors.purple, label: 'Fibonacci'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
