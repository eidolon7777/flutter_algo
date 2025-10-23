import 'package:flutter/material.dart';

class StrategyInfoPage extends StatelessWidget {
  const StrategyInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Strategy: Moving Average Crossover')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'The Moving Average Crossover strategy compares a short-term moving average (e.g., 20 periods) to a long-term moving average (e.g., 50 periods). ' 
            'When the short-term average crosses above the long-term average, it signals potential upward momentum (BUY). ' 
            'When it crosses below, it signals potential downward momentum (SELL).',
          ),
          SizedBox(height: 16),
          Text(
            'Why it works',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Moving averages smooth price noise and highlight trend direction. Crossovers attempt to catch trend reversals and sustained moves.',
          ),
          SizedBox(height: 16),
          Text(
            'Parameters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            '• Short window: number of recent periods used for the fast average.\n'
            '• Long window: number of periods used for the slow average.\n'
            '• Asset: the symbol being tested (e.g., IBM).',
          ),
          SizedBox(height: 16),
          Text(
            'Trade Rules',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            '• BUY when short MA > long MA (after a crossover).\n'
            '• SELL/EXIT when short MA < long MA (after a crossover).',
          ),
          SizedBox(height: 16),
          Text(
            'Notes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'This is a simple, educational strategy. Real-world use should consider risk management, stop-loss, position sizing, and transaction costs.',
          ),
        ],
      ),
    );
  }
}