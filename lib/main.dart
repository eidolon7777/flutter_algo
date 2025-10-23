import 'package:flutter/material.dart';
import 'services/market_data_service.dart';
import 'models/ohlc.dart';
import 'pages/strategy_info_page.dart';
import 'pages/strategy_list_page.dart';
import 'services/backtester.dart';
import 'strategies/moving_average_crossover.dart';
import 'strategies/trading_strategy.dart';
import 'strategies/rsi_strategy.dart';
import 'strategies/bollinger_bands_strategy.dart';
import 'strategies/macd_strategy.dart';
import 'strategies/buy_and_hold_strategy.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Algo Trading Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = MarketDataService();
  final _symbolCtrl = TextEditingController(text: 'IBM');
  final _capitalCtrl = TextEditingController(text: '10000');
  final _shortCtrl = TextEditingController(text: '20');
  final _longCtrl = TextEditingController(text: '50');
  // Strategy-specific controllers
  final _rsiPeriodCtrl = TextEditingController(text: '14');
  final _rsiOversoldCtrl = TextEditingController(text: '30');
  final _rsiOverboughtCtrl = TextEditingController(text: '70');
  final _bbWindowCtrl = TextEditingController(text: '20');
  final _bbKCtrl = TextEditingController(text: '2.0');
  final _macdFastCtrl = TextEditingController(text: '12');
  final _macdSlowCtrl = TextEditingController(text: '26');
  final _macdSignalCtrl = TextEditingController(text: '9');
  
  String _selectedStrategy = 'Moving Average Crossover';
  bool _loading = false;
  String? _error;
  List<OHLC>? _monthly;
  BacktestResult? _result;

  Future<void> _runBacktest() async {
    FocusScope.of(context).unfocus();
    final symbol = _symbolCtrl.text.trim().isEmpty ? 'IBM' : _symbolCtrl.text.trim();
    final cap = double.tryParse(_capitalCtrl.text.trim());
    final sw = int.tryParse(_shortCtrl.text.trim());
    final lw = int.tryParse(_longCtrl.text.trim());
    if (cap == null) {
      setState(() { _error = 'Please enter a valid initial capital.'; });
      return;
    }
    // Strategy-specific validation
    if (_selectedStrategy == 'Moving Average Crossover') {
      if (sw == null || lw == null || lw <= sw) {
        setState(() { _error = 'Please enter valid MA windows. Long > Short.'; });
        return;
      }
    } else if (_selectedStrategy == 'RSI') {
      final rsiPeriod = int.tryParse(_rsiPeriodCtrl.text.trim());
      final rsiOversold = double.tryParse(_rsiOversoldCtrl.text.trim());
      final rsiOverbought = double.tryParse(_rsiOverboughtCtrl.text.trim());
      final valid = rsiPeriod != null && rsiPeriod > 1 &&
        rsiOversold != null && rsiOverbought != null &&
        rsiOversold < rsiOverbought &&
        rsiOversold >= 0 && rsiOverbought <= 100;
      if (!valid) {
        setState(() { _error = 'RSI params invalid. Period>1, 0<=Oversold<Overbought<=100.'; });
        return;
      }
    } else if (_selectedStrategy == 'Bollinger Bands') {
      final w = int.tryParse(_bbWindowCtrl.text.trim());
      final k = double.tryParse(_bbKCtrl.text.trim());
      if (w == null || w <= 1 || k == null || k <= 0) {
        setState(() { _error = 'Bollinger params invalid. Window>1 and k>0.'; });
        return;
      }
    } else if (_selectedStrategy == 'MACD') {
      final f = int.tryParse(_macdFastCtrl.text.trim());
      final s = int.tryParse(_macdSlowCtrl.text.trim());
      final sig = int.tryParse(_macdSignalCtrl.text.trim());
      if (f == null || f <= 0 || s == null || s <= f || sig == null || sig <= 0) {
        setState(() { _error = 'MACD params invalid. slow>fast>0 and signal>0.'; });
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await _service.fetchMonthlyData(symbol);
      TradingStrategy strat;
      switch (_selectedStrategy) {
        case 'Moving Average Crossover':
          strat = MovingAverageCrossoverStrategy(sw!, lw!);
          break;
        case 'RSI': {
          final rsiPeriod = int.tryParse(_rsiPeriodCtrl.text.trim()) ?? 14;
          final rsiOversold = double.tryParse(_rsiOversoldCtrl.text.trim()) ?? 30;
          final rsiOverbought = double.tryParse(_rsiOverboughtCtrl.text.trim()) ?? 70;
          strat = RsiStrategy(period: rsiPeriod, oversold: rsiOversold, overbought: rsiOverbought);
          break;
        }
        case 'Bollinger Bands': {
          final w = int.tryParse(_bbWindowCtrl.text.trim()) ?? 20;
          final k = double.tryParse(_bbKCtrl.text.trim()) ?? 2.0;
          strat = BollingerBandsStrategy(window: w, k: k);
          break;
        }
        case 'MACD': {
          final f = int.tryParse(_macdFastCtrl.text.trim()) ?? 12;
          final s = int.tryParse(_macdSlowCtrl.text.trim()) ?? 26;
          final sig = int.tryParse(_macdSignalCtrl.text.trim()) ?? 9;
          strat = MacdStrategy(fast: f, slow: s, signal: sig);
          break;
        }
        case 'Buy-and-Hold':
          strat = BuyAndHoldStrategy();
          break;
        default:
          strat = MovingAverageCrossoverStrategy(sw ?? 20, lw ?? 50);
      }
      final bt = Backtester(initialBalance: cap);
      final res = bt.run(data, strat);
      setState(() {
        _monthly = data;
        _result = res;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Algo Trading Home')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Parameters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _symbolCtrl,
                          decoration: const InputDecoration(labelText: 'Symbol', hintText: 'e.g., IBM'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _capitalCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Initial Capital', hintText: 'e.g., 10000'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _shortCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Short MA Window', hintText: 'e.g., 20'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _longCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Long MA Window', hintText: 'e.g., 50'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStrategy,
                          decoration: const InputDecoration(labelText: 'Strategy'),
                          items: const [
                            DropdownMenuItem(value: 'Moving Average Crossover', child: Text('Moving Average Crossover')),
                            DropdownMenuItem(value: 'RSI', child: Text('RSI')),
                            DropdownMenuItem(value: 'Bollinger Bands', child: Text('Bollinger Bands')),
                            DropdownMenuItem(value: 'MACD', child: Text('MACD')),
                            DropdownMenuItem(value: 'Buy-and-Hold', child: Text('Buy-and-Hold')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() { _selectedStrategy = v; });
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    if (_selectedStrategy == 'RSI') ...[
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _rsiPeriodCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'RSI Period', hintText: 'e.g., 14'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _rsiOversoldCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Oversold', hintText: 'e.g., 30'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _rsiOverboughtCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Overbought', hintText: 'e.g., 70'),
                          ),
                        ),
                      ]),
                    ] else if (_selectedStrategy == 'Bollinger Bands') ...[
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _bbWindowCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Window', hintText: 'e.g., 20'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _bbKCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Std Dev (k)', hintText: 'e.g., 2.0'),
                          ),
                        ),
                      ]),
                    ] else if (_selectedStrategy == 'MACD') ...[
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _macdFastCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Fast EMA', hintText: 'e.g., 12'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _macdSlowCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Slow EMA', hintText: 'e.g., 26'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _macdSignalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Signal', hintText: 'e.g., 9'),
                          ),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _runBacktest,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Run Backtest'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StrategyInfoPage()),
                        ),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Strategy Info'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StrategyListPage()),
                        ),
                        icon: const Icon(Icons.list),
                        label: const Text('All Strategies'),
                      ),
                    ]),
                    if (_loading) const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Backtest Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 24, runSpacing: 8, children: [
                        _metric('Initial', _currency(_result!.initialBalance)),
                        _metric('Final', _currency(_result!.finalBalance)),
                        _metric('Profit', _currency(_result!.profit)),
                        _metric('ROI', '${_result!.roiPercent.toStringAsFixed(2)}%'),
                        _metric('Trades', _result!.trades.toString()),
                        _metric('Win Rate', '${_result!.winRatePercent.toStringAsFixed(2)}%'),
                        _metric('Max Drawdown', '${_result!.maxDrawdownPercent.toStringAsFixed(2)}%'),
                      ]),
                      const Divider(height: 20),
                      const Text('Baseline: Buy & Hold', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 24, runSpacing: 8, children: [
                        _metric('Final', _currency(_result!.buyAndHoldFinalBalance)),
                        _metric('ROI', '${_result!.buyAndHoldRoiPercent.toStringAsFixed(2)}%'),
                      ]),
                      const Divider(height: 20),
                      const Text('Trades (latest first)'),
                      const SizedBox(height: 6),
                      ..._result!.tradeResults.reversed.take(5).map((t) => ListTile(
                            dense: true,
                            title: Text('BUY ${_date(t.buyTime)} @ ${t.buyPrice.toStringAsFixed(2)} → SELL ${_date(t.sellTime)} @ ${t.sellPrice.toStringAsFixed(2)}'),
                            subtitle: Text('Return: ${(t.returnRatio * 100 - 100).toStringAsFixed(2)}%'),
                          )),
                    ],
                  ),
                ),
              ),
            if (_monthly != null && _result == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Loaded'),
                      Text('Monthly points: ${_monthly!.length} (e.g., ${_date(_monthly!.last.date)})'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _currency(double v) => v.toStringAsFixed(2);
  String _date(DateTime d) => d.toIso8601String().split('T').first;

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
