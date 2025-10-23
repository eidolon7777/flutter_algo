import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ohlc.dart';

class MarketDataService {
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  static const String _apiKey = 'P2X6GOUBVW4OE29T';

  Future<List<OHLC>> fetchMonthlyData(String symbol) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'function': 'TIME_SERIES_MONTHLY',
        'symbol': symbol,
        'apikey': _apiKey,
      },
    );

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: Failed to fetch data');
    }

    final decoded = json.decode(resp.body) as Map<String, dynamic>;
    final series = decoded['Monthly Time Series'] as Map<String, dynamic>?;
    if (series == null) {
      // Gracefully handle API limit or error responses
      final note =
          decoded['Note'] ?? decoded['Error Message'] ?? 'Unknown API response';
      throw Exception('Alpha Vantage error: $note');
    }

    final entries =
        series.entries.map((e) {
          final m = e.value as Map<String, dynamic>;
          return OHLC(
            date: DateTime.parse(e.key),
            open: double.parse(m['1. open'] as String),
            high: double.parse(m['2. high'] as String),
            low: double.parse(m['3. low'] as String),
            close: double.parse(m['4. close'] as String),
          );
        }).toList();

    // Sort ascending by date so UI charts or logic can consume naturally
    entries.sort((a, b) => a.date.compareTo(b.date));

    return entries;
  }
}
