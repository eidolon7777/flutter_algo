import 'package:flutter/material.dart';

class StrategyListPage extends StatelessWidget {
  const StrategyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strategies = [
      _StrategyInfo(
        name: 'Moving Average Crossover',
        summary: 'BUY when short MA crosses above long MA; SELL on cross down. Captures trend shifts.',
        params: 'Short MA: 20, Long MA: 50 (typical)'
      ),
      _StrategyInfo(
        name: 'RSI (Relative Strength Index)',
        summary: 'BUY when RSI crosses above oversold (e.g., 30); SELL when RSI crosses below overbought (e.g., 70). Mean-reversion cue.',
        params: 'Period: 14; Oversold: 30; Overbought: 70'
      ),
      _StrategyInfo(
        name: 'Bollinger Bands',
        summary: 'BUY on dips below lower band; SELL on touches above upper band. Volatility-based bands around SMA.',
        params: 'Window: 20; StdDev: 2.0'
      ),
      _StrategyInfo(
        name: 'MACD (12/26, signal 9)',
        summary: 'BUY when MACD crosses above signal; SELL when it crosses below. Momentum trend-following.',
        params: 'Fast EMA: 12; Slow EMA: 26; Signal: 9'
      ),
      _StrategyInfo(
        name: 'Buy-and-Hold',
        summary: 'BUY at first bar and SELL at last bar. Baseline for comparison.',
        params: 'No parameters'
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Available Strategies')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: strategies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final s = strategies[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(s.summary),
                  const SizedBox(height: 6),
                  Text('Typical Params: ${s.params}', style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StrategyInfo {
  final String name;
  final String summary;
  final String params;
  _StrategyInfo({required this.name, required this.summary, required this.params});
}