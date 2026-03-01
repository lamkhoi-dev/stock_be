import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' show NumberFormat, DateFormat;

import '../../../config/theme.dart';
import '../../../services/api_client.dart';

// ═══════════════════════════════════════════════════════════════
//  CHART TAB — Interactive candlestick / line / area chart
//  with volume, MA, BB, RSI, MACD histogram, Stochastic,
//  crosshair, horizontal scroll (pan) and pinch-to-zoom.
// ═══════════════════════════════════════════════════════════════

class ChartTab extends ConsumerStatefulWidget {
  const ChartTab({super.key, required this.symbol, required this.stockData});
  final String symbol;
  final Map<String, dynamic> stockData;

  @override
  ConsumerState<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends ConsumerState<ChartTab>
    with AutomaticKeepAliveClientMixin {
  // ──── Data ────────────────────────────────────────────────
  List<_CandleData> _candles = [];
  bool _isLoading = true;
  String? _error;

  // ──── Chart controls ──────────────────────────────────────
  int _selectedPeriod = 2; // default 1M
  int _chartType = 0; // 0=candle, 1=line, 2=area
  int _candleInterval = 1; // 0=minute, 1=daily, 2=weekly, 3=monthly
  bool _showMA = true;
  bool _showBB = false;
  bool _showVolume = true;
  bool _showIndicators = true;
  final _periods = ['1D', '5D', '1M', '3M', '6M', '1Y', '2Y', '5Y'];
  final _intervals = ['Min', 'Day', 'Week', 'Month'];

  // ──── Interaction state ───────────────────────────────────
  int _visibleCount = 60;
  double _scrollOffset = 0; // 0 = rightmost (latest visible)
  int? _crosshairIndex; // global index into _candles
  int _baseVisibleCount = 60;
  double _prevFocalX = 0;

  // ──── Indicators ──────────────────────────────────────────
  List<double?> _ma5 = [];
  List<double?> _ma20 = [];
  List<double?> _bbUpper = [];
  List<double?> _bbLower = [];
  List<double?> _rsiData = [];
  List<double?> _macdLine = [];
  List<double?> _signalLine = [];
  List<double?> _macdHist = [];
  List<double?> _stochK = [];
  List<double?> _stochD = [];

  // ──── Constants ───────────────────────────────────────────
  static const _kRightAxisW = 62.0;
  static const _kBottomAxisH = 22.0;
  static const _kChartH = 260.0;
  static const _kVolumeH = 50.0;
  static const _kMinVisible = 10;
  static const _kMaxVisible = 300;
  static const _kUp = Color(0xFF22C55E);
  static const _kDown = Color(0xFFEF4444);
  static const _kMA5 = Color(0xFFF97316);
  static const _kBB = Color(0xFF8B5CF6);

  @override
  bool get wantKeepAlive => true;

  // ──── Visible range helpers ───────────────────────────────
  int get _maxScroll => max(0, _candles.length - _visibleCount);
  int get _clampedScroll => _scrollOffset.round().clamp(0, _maxScroll);
  int get _startIdx => max(0, _candles.length - _visibleCount - _clampedScroll);
  int get _endIdx => min(_candles.length, _startIdx + _visibleCount);

  List<_CandleData> get _visibleCandles {
    if (_candles.isEmpty) return [];
    final s = max(0, _startIdx);
    final e = min(_candles.length, _endIdx);
    return s < e ? _candles.sublist(s, e) : [];
  }

  List<double?> _slice(List<double?> data) {
    if (data.isEmpty || _candles.isEmpty) return [];
    final s = max(0, _startIdx);
    final e = min(data.length, _endIdx);
    return s < e ? data.sublist(s, e) : [];
  }

  // ════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  // ════════════════════════════════════════════════════════════
  //  DATA LOADING
  // ════════════════════════════════════════════════════════════

  // period: KIS API period code, isMinute: use minute endpoint,
  // daysBack: calendar days to request from backend
  ({String period, bool isMinute, int daysBack}) _getPeriodParams() {
    // If user explicitly chose minute interval
    if (_candleInterval == 0) {
      return (period: 'minute', isMinute: true, daysBack: 0);
    }

    // Map candle interval to KIS API period code
    final apiPeriod = switch (_candleInterval) {
      2 => 'W',  // Weekly
      3 => 'M',  // Monthly
      _ => 'D',  // Daily (default)
    };

    // Calculate daysBack based on selected time range
    final daysBack = switch (_selectedPeriod) {
      0 => 2,      // 1D
      1 => 10,     // 5D
      2 => 45,     // 1M
      3 => 100,    // 3M
      4 => 200,    // 6M
      5 => 400,    // 1Y
      6 => 800,    // 2Y
      _ => 1900,   // 5Y
    };

    return (period: apiPeriod, isMinute: false, daysBack: daysBack);
  }

  // Max candles to display depends on time range + candle interval
  int _getMaxCandles() {
    if (_candleInterval == 0) return 78; // minute

    // Approximate trading days per period (generous to not truncate real data)
    final tradingDays = switch (_selectedPeriod) {
      0 => 1,
      1 => 5,
      2 => 23,
      3 => 66,
      4 => 135,
      5 => 260,
      6 => 520,
      _ => 1300,
    };

    // Divide by candle interval to get expected count
    return switch (_candleInterval) {
      2 => (tradingDays / 5).ceil(),   // Weekly: ~5 trading days per bar
      3 => (tradingDays / 22).ceil(),  // Monthly: ~22 trading days per bar
      _ => tradingDays,                // Daily: 1:1
    };
  }

  // Which candle intervals are available for the selected period?
  List<int> get _availableIntervals {
    return switch (_selectedPeriod) {
      0 => [0],             // 1D: minute only
      1 => [0, 1],          // 5D: minute, daily
      2 => [1, 2],          // 1M: daily, weekly
      3 => [1, 2],          // 3M: daily, weekly
      4 => [1, 2, 3],       // 6M: daily, weekly, monthly
      5 => [1, 2, 3],       // 1Y: daily, weekly, monthly
      6 => [1, 2, 3],       // 2Y: daily, weekly, monthly
      _ => [2, 3],          // 5Y: weekly, monthly
    };
  }

  // Auto-pick best default candle interval when period changes
  int _defaultIntervalForPeriod(int periodIdx) => switch (periodIdx) {
    0 => 0,  // 1D → minute
    1 => 1,  // 5D → daily
    2 => 1,  // 1M → daily
    3 => 1,  // 3M → daily
    4 => 1,  // 6M → daily
    5 => 1,  // 1Y → daily
    6 => 1,  // 2Y → daily (user can switch to weekly)
    _ => 2,  // 5Y → weekly (user can switch to monthly)
  };

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final params = _getPeriodParams();
      List<Map<String, dynamic>> rawData;

      if (params.isMinute) {
        final r = await api.getMinuteChart(widget.symbol);
        if (r.data['success'] == true) {
          rawData =
              List<Map<String, dynamic>>.from(r.data['data'] as List);
        } else {
          throw Exception('Failed to load minute chart');
        }
      } else {
        // Calculate explicit startDate so backend fetches enough data
        final now = DateTime.now();
        final start = now.subtract(Duration(days: params.daysBack));
        final startDate =
            '${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}';
        final r = await api.getHistory(
          widget.symbol,
          period: params.period,
          startDate: startDate,
        );
        if (r.data['success'] == true) {
          rawData =
              List<Map<String, dynamic>>.from(r.data['data'] as List);
        } else {
          throw Exception('Failed to load chart data');
        }
      }

      final maxC = _getMaxCandles();
      if (rawData.length > maxC) {
        rawData = rawData.sublist(rawData.length - maxC);
      }

      _candles = rawData
          .map((d) => _CandleData(
                date: _parseDate(d),
                open: (d['open'] as num?)?.toDouble() ?? 0,
                high: (d['high'] as num?)?.toDouble() ?? 0,
                low: (d['low'] as num?)?.toDouble() ?? 0,
                close: (d['close'] as num?)?.toDouble() ?? 0,
                volume: (d['volume'] as num?)?.toDouble() ?? 0,
              ))
          .toList();

      if (_candles.isEmpty) throw Exception('No chart data available');

      _computeIndicators();
      _visibleCount = min(_candles.length, 80);
      _scrollOffset = 0;
      _crosshairIndex = null;

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  DateTime _parseDate(Map<String, dynamic> d) {
    // Backend daily chart returns: { time: "2026-03-01", ... }
    // Backend minute chart returns: { time: 1709283600, timeStr: "14:25", ... }
    final timeVal = d['time'];
    final timeStr = d['timeStr']?.toString();

    // 1. Minute chart: time is Unix timestamp (int or num)
    if (timeVal is num && timeVal > 1_000_000_000) {
      return DateTime.fromMillisecondsSinceEpoch(
        timeVal.toInt() * 1000,
        isUtc: true,
      ).toLocal();
    }

    final tStr = timeVal?.toString() ?? '';

    // 2. Daily chart: time is ISO date string "2026-03-01"
    if (tStr.contains('-')) {
      final parsed = DateTime.tryParse(tStr);
      if (parsed != null) return parsed;
    }

    // 3. 8-digit date string "20260301"
    if (tStr.length == 8 && int.tryParse(tStr) != null) {
      return DateTime(
        int.parse(tStr.substring(0, 4)),
        int.parse(tStr.substring(4, 6)),
        int.parse(tStr.substring(6, 8)),
      );
    }

    // 4. Fallback: check legacy 'date' field
    final dateStr = d['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      if (dateStr.length == 8 && int.tryParse(dateStr) != null) {
        final base = DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
        );
        if (timeStr != null && timeStr.length >= 4) {
          final parts = timeStr.contains(':')
              ? timeStr.split(':')
              : [timeStr.substring(0, 2), timeStr.substring(2, 4)];
          return DateTime(
            base.year, base.month, base.day,
            int.tryParse(parts[0]) ?? 0,
            int.tryParse(parts[1]) ?? 0,
          );
        }
        return base;
      }
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) return parsed;
    }

    return DateTime.now();
  }

  // ════════════════════════════════════════════════════════════
  //  INDICATOR CALCULATIONS
  // ════════════════════════════════════════════════════════════

  void _computeIndicators() {
    _ma5 = _calcMA(5);
    _ma20 = _calcMA(20);
    _calcBB();
    _rsiData = _calcRSI(14);
    _calcMACD();
    _calcStochastic();
  }

  List<double?> _calcMA(int period) {
    final closes = _candles.map((c) => c.close).toList();
    return List.generate(closes.length, (i) {
      if (i < period - 1) return null;
      return closes.sublist(i - period + 1, i + 1).reduce((a, b) => a + b) /
          period;
    });
  }

  void _calcBB() {
    _bbUpper = [];
    _bbLower = [];
    for (int i = 0; i < _candles.length; i++) {
      if (i < 19) {
        _bbUpper.add(null);
        _bbLower.add(null);
        continue;
      }
      final s =
          _candles.sublist(i - 19, i + 1).map((c) => c.close).toList();
      final m = s.reduce((a, b) => a + b) / s.length;
      final sd = sqrt(
          s.map((v) => pow(v - m, 2)).reduce((a, b) => a + b) / s.length);
      _bbUpper.add(m + 2 * sd);
      _bbLower.add(m - 2 * sd);
    }
  }

  List<double?> _calcRSI(int period) {
    final closes = _candles.map((c) => c.close).toList();
    if (closes.length < period + 1) return List<double?>.filled(closes.length, null, growable: true);

    final result = List<double?>.generate(period, (_) => null, growable: true);
    double avgGain = 0, avgLoss = 0;
    for (int i = 1; i <= period; i++) {
      final d = closes[i] - closes[i - 1];
      if (d >= 0) {
        avgGain += d;
      } else {
        avgLoss += d.abs();
      }
    }
    avgGain /= period;
    avgLoss /= period;
    result
        .add(avgLoss == 0 ? 100.0 : 100 - (100 / (1 + avgGain / avgLoss)));

    for (int i = period + 1; i < closes.length; i++) {
      final d = closes[i] - closes[i - 1];
      if (d >= 0) {
        avgGain = (avgGain * (period - 1) + d) / period;
        avgLoss = (avgLoss * (period - 1)) / period;
      } else {
        avgGain = (avgGain * (period - 1)) / period;
        avgLoss = (avgLoss * (period - 1) + d.abs()) / period;
      }
      result.add(
          avgLoss == 0 ? 100.0 : 100 - (100 / (1 + avgGain / avgLoss)));
    }
    return result;
  }

  void _calcMACD() {
    final closes = _candles.map((c) => c.close).toList();
    _macdLine = [];
    _signalLine = [];
    _macdHist = [];

    List<double?> ema(int p) {
      final e = <double?>[];
      if (closes.length < p) return List.filled(closes.length, null);
      double s = 0;
      for (int i = 0; i < p; i++) {
        s += closes[i];
        e.add(null);
      }
      e[p - 1] = s / p;
      final m = 2.0 / (p + 1);
      for (int i = p; i < closes.length; i++) {
        e.add(closes[i] * m + e[i - 1]! * (1 - m));
      }
      return e;
    }

    final e12 = ema(12), e26 = ema(26);
    for (int i = 0; i < closes.length; i++) {
      if (e12[i] == null || e26[i] == null) {
        _macdLine.add(null);
      } else {
        _macdLine.add(e12[i]! - e26[i]!);
      }
    }

    final nn = _macdLine.whereType<double>().toList();
    if (nn.length < 9) {
      _signalLine = List.filled(closes.length, null);
      _macdHist = List.filled(closes.length, null);
      return;
    }

    double sig = nn.take(9).reduce((a, b) => a + b) / 9;
    final m = 2.0 / 10;
    _signalLine = List.filled(closes.length, null);
    _macdHist = List.filled(closes.length, null);
    int ni = 0;
    for (int i = 0; i < closes.length; i++) {
      if (_macdLine[i] != null) {
        if (ni < 8) {
          // not enough for signal
        } else if (ni == 8) {
          _signalLine[i] = sig;
          _macdHist[i] = _macdLine[i]! - sig;
        } else {
          sig = _macdLine[i]! * m + sig * (1 - m);
          _signalLine[i] = sig;
          _macdHist[i] = _macdLine[i]! - sig;
        }
        ni++;
      }
    }
  }

  void _calcStochastic() {
    const kP = 5, kS = 3, dP = 3;
    final rawK = <double?>[];
    for (int i = 0; i < _candles.length; i++) {
      if (i < kP - 1) {
        rawK.add(null);
        continue;
      }
      final s = _candles.sublist(i - kP + 1, i + 1);
      final ll = s.map((c) => c.low).reduce(min);
      final hh = s.map((c) => c.high).reduce(max);
      final range = hh - ll;
      rawK.add(range > 0 ? ((_candles[i].close - ll) / range) * 100 : 50);
    }
    _stochK = _smoothSMA(rawK, kS);
    _stochD = _smoothSMA(_stochK, dP);
  }

  List<double?> _smoothSMA(List<double?> data, int period) =>
      List.generate(data.length, (i) {
        if (i < period - 1 || data[i] == null) return null;
        double s = 0;
        int c = 0;
        for (int j = i - period + 1; j <= i; j++) {
          if (j >= 0 && j < data.length && data[j] != null) {
            s += data[j]!;
            c++;
          }
        }
        return c > 0 ? s / c : null;
      });

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    if (_error != null || _candles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.show_chart,
                size: 48, color: cs.onSurface.withValues(alpha: 0.38)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'No chart data',
              style: TextStyle(color: cs.secondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadChartData,
              child: const Text('Retry'),
            ),
          ]),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildPeriodSelector(),
          const SizedBox(height: 6),
          _buildIntervalSelector(),
          const SizedBox(height: 8),
          _buildChartTypeSelector(),
          const SizedBox(height: 4),
          _buildOHLCVInfoBar(),
          _buildInteractiveChart(),
          const SizedBox(height: 8),
          _buildOverlayToggles(),
          const SizedBox(height: 16),
          _buildIndicatorsSection(),
          const SizedBox(height: 16),
          _buildTechnicalSummary(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  PERIOD SELECTOR
  // ════════════════════════════════════════════════════════════

  Widget _buildPeriodSelector() {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final active = _selectedPeriod == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = index;
                // Auto-set best interval for this period
                final def = _defaultIntervalForPeriod(index);
                _candleInterval = def;
              });
              _loadChartData();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? cs.primary : cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: active ? cs.primary : cs.outline),
              ),
              child: Text(
                _periods[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : cs.secondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CANDLE INTERVAL SELECTOR
  // ════════════════════════════════════════════════════════════

  Widget _buildIntervalSelector() {
    final cs = Theme.of(context).colorScheme;
    final available = _availableIntervals;
    // If only one option, no need to show selector
    if (available.length <= 1) return const SizedBox.shrink();

    final icons = [
      Icons.access_time,           // Minute
      Icons.calendar_view_day,     // Daily
      Icons.calendar_view_week,    // Weekly
      Icons.calendar_month,        // Monthly
    ];

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: available.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, idx) {
          final intervalIdx = available[idx];
          final active = _candleInterval == intervalIdx;
          return GestureDetector(
            onTap: () {
              if (_candleInterval == intervalIdx) return;
              setState(() => _candleInterval = intervalIdx);
              _loadChartData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? cs.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active
                      ? cs.primary
                      : cs.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[intervalIdx],
                    size: 14,
                    color: active ? cs.primary : cs.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _intervals[intervalIdx],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? cs.primary : cs.secondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CHART TYPE SELECTOR
  // ════════════════════════════════════════════════════════════

  Widget _buildChartTypeSelector() {
    final cs = Theme.of(context).colorScheme;
    final types = [
      (Icons.candlestick_chart_outlined, 'Candle'),
      (Icons.show_chart, 'Line'),
      (Icons.area_chart_outlined, 'Area'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: types.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, label) = entry.value;
          final active = _chartType == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _chartType = i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: active
                      ? cs.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: active ? cs.primary : cs.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 14,
                        color:
                            active ? cs.primary : cs.secondary),
                    const SizedBox(width: 4),
                    Text(label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              active ? cs.primary : cs.secondary,
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  OHLCV INFO BAR
  // ════════════════════════════════════════════════════════════

  Widget _buildOHLCVInfoBar() {
    final c = (_crosshairIndex != null &&
            _crosshairIndex! >= 0 &&
            _crosshairIndex! < _candles.length)
        ? _candles[_crosshairIndex!]
        : _candles.last;
    final cs = Theme.of(context).colorScheme;
    final isUp = c.close >= c.open;
    final color = isUp ? _kUp : _kDown;
    final fmt = NumberFormat('#,##0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _ohlcvLabel('O', fmt.format(c.open), color),
          const SizedBox(width: 8),
          _ohlcvLabel('H', fmt.format(c.high), color),
          const SizedBox(width: 8),
          _ohlcvLabel('L', fmt.format(c.low), color),
          const SizedBox(width: 8),
          _ohlcvLabel('C', fmt.format(c.close), color),
          const SizedBox(width: 8),
          _ohlcvLabel('V', _fmtVol(c.volume), cs.secondary),
          const Spacer(),
          if (_crosshairIndex != null)
            Text(
              _fmtDateFull(c.date),
              style: TextStyle(fontSize: 10, color: cs.secondary),
            ),
        ],
      ),
    );
  }

  Widget _ohlcvLabel(String key, String val, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(key,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: cs.secondary)),
        const SizedBox(width: 2),
        Text(val,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  //  INTERACTIVE CHART (pan / zoom / crosshair)
  // ════════════════════════════════════════════════════════════

  Widget _buildInteractiveChart() {
    final cs = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final currentPrice =
        (widget.stockData['price'] as num?)?.toDouble();

    final visCand = _visibleCandles;
    final visMA5 = _slice(_ma5);
    final visMA20 = _slice(_ma20);
    final visBBU = _slice(_bbUpper);
    final visBBL = _slice(_bbLower);

    // Convert crosshair to visible index
    int? visCrossIdx;
    if (_crosshairIndex != null) {
      visCrossIdx = _crosshairIndex! - _startIdx;
      if (visCrossIdx < 0 || visCrossIdx >= visCand.length) {
        visCrossIdx = null;
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      final chartW = constraints.maxWidth;
      final drawW = chartW - _kRightAxisW;

      return GestureDetector(
        // ── Pan & Zoom ──
        onScaleStart: (d) {
          _baseVisibleCount = _visibleCount;
          _prevFocalX = d.localFocalPoint.dx;
        },
        onScaleUpdate: (d) {
          setState(() {
            if (d.pointerCount >= 2) {
              // Pinch zoom
              _visibleCount = (_baseVisibleCount / d.scale)
                  .round()
                  .clamp(_kMinVisible, min(_kMaxVisible, _candles.length));
            } else {
              // Single-finger pan
              final dx = d.localFocalPoint.dx - _prevFocalX;
              _prevFocalX = d.localFocalPoint.dx;
              final candleW =
                  drawW / max(1, _visibleCount);
              _scrollOffset =
                  (_scrollOffset + dx / candleW).clamp(0.0, _maxScroll.toDouble());
            }
          });
        },
        onScaleEnd: (_) {},

        // ── Crosshair ──
        onLongPressStart: (d) =>
            _updateCrosshair(d.localPosition.dx, drawW),
        onLongPressMoveUpdate: (d) =>
            _updateCrosshair(d.localPosition.dx, drawW),
        onLongPressEnd: (_) => setState(() => _crosshairIndex = null),

        child: Column(
          children: [
            // ── Main Chart ──
            SizedBox(
              height: _kChartH,
              width: chartW,
              child: CustomPaint(
                painter: _MainChartPainter(
                  candles: visCand,
                  chartType: _chartType,
                  ma5: visMA5,
                  ma20: visMA20,
                  bbUpper: visBBU,
                  bbLower: visBBL,
                  showMA: _showMA,
                  showBB: _showBB,
                  currentPrice: currentPrice,
                  crosshairIdx: visCrossIdx,
                  gridColor: appColors.surfaceHover,
                  textColor:
                      cs.onSurface.withValues(alpha: 0.5),
                  accentColor: cs.primary,
                  periodIndex: _selectedPeriod,
                  candleInterval: _candleInterval,
                ),
              ),
            ),
            // ── Volume Chart ──
            if (_showVolume)
              SizedBox(
                height: _kVolumeH,
                width: chartW,
                child: CustomPaint(
                  painter: _VolumePainter(
                    candles: visCand,
                    crosshairIdx: visCrossIdx,
                    gridColor: appColors.surfaceHover,
                    textColor:
                        cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _updateCrosshair(double localX, double drawW) {
    if (_visibleCandles.isEmpty) return;
    final candleW = drawW / _visibleCandles.length;
    final visIdx = (localX / candleW).floor().clamp(0, _visibleCandles.length - 1);
    setState(() => _crosshairIndex = _startIdx + visIdx);
  }

  // ════════════════════════════════════════════════════════════
  //  OVERLAY TOGGLES
  // ════════════════════════════════════════════════════════════

  Widget _buildOverlayToggles() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ToggleChip(
            label: 'MA',
            isActive: _showMA,
            onTap: () => setState(() => _showMA = !_showMA),
            color: _kMA5,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'BB',
            isActive: _showBB,
            onTap: () => setState(() => _showBB = !_showBB),
            color: _kBB,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'VOL',
            isActive: _showVolume,
            onTap: () => setState(() => _showVolume = !_showVolume),
            color: cs.primary,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  INDICATORS SECTION
  // ════════════════════════════════════════════════════════════

  Widget _buildIndicatorsSection() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _showIndicators = !_showIndicators),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Technical Indicators',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                Icon(
                  _showIndicators
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: cs.secondary,
                ),
              ],
            ),
          ),
        ),
        if (_showIndicators) ...[
          const SizedBox(height: 12),
          _buildRSIChart(),
          const SizedBox(height: 12),
          _buildMACDChart(),
          const SizedBox(height: 12),
          _buildStochasticChart(),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  //  RSI CHART (fl_chart)
  // ════════════════════════════════════════════════════════════

  Widget _buildRSIChart() {
    final cs = Theme.of(context).colorScheme;
    final spots = _rsiData
        .asMap()
        .entries
        .where((e) => e.value != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value!))
        .toList();
    if (spots.isEmpty) return const SizedBox.shrink();

    final cur = spots.last.y;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RSI (14)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.secondary)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _rsiColor(cur).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(cur.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _rsiColor(cur))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: LineChart(LineChartData(
                minY: 0,
                maxY: 100,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                      y: 70,
                      color:
                          const Color(0xFFEF4444).withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4]),
                  HorizontalLine(
                      y: 30,
                      color:
                          const Color(0xFF22C55E).withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4]),
                ]),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _kBB,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Color _rsiColor(double rsi) {
    if (rsi >= 70) return const Color(0xFFEF4444);
    if (rsi <= 30) return const Color(0xFF22C55E);
    return _kBB;
  }

  // ════════════════════════════════════════════════════════════
  //  MACD CHART (CustomPaint — histogram + lines)
  // ════════════════════════════════════════════════════════════

  Widget _buildMACDChart() {
    final cs = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final curMACD = _macdLine.whereType<double>().lastOrNull;
    if (curMACD == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MACD (12,26,9)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.secondary)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (curMACD >= 0 ? _kUp : _kDown)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(curMACD.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: curMACD >= 0 ? _kUp : _kDown,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: CustomPaint(
                size: const Size(double.infinity, 80),
                painter: _MACDPainter(
                  macd: _macdLine,
                  signal: _signalLine,
                  histogram: _macdHist,
                  lineColor: cs.primary,
                  signalColor: _kMA5,
                  gridColor: appColors.surfaceHover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  STOCHASTIC CHART (fl_chart)
  // ════════════════════════════════════════════════════════════

  Widget _buildStochasticChart() {
    final cs = Theme.of(context).colorScheme;
    final kSpots = _stochK
        .asMap()
        .entries
        .where((e) => e.value != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value!))
        .toList();
    final dSpots = _stochD
        .asMap()
        .entries
        .where((e) => e.value != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value!))
        .toList();
    if (kSpots.isEmpty) return const SizedBox.shrink();

    final curK = kSpots.last.y;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stochastic (5,3,3)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.secondary)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _stochColor(curK).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(curK.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _stochColor(curK))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: LineChart(LineChartData(
                minY: 0,
                maxY: 100,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                      y: 80,
                      color:
                          const Color(0xFFEF4444).withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4]),
                  HorizontalLine(
                      y: 20,
                      color:
                          const Color(0xFF22C55E).withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4]),
                ]),
                lineBarsData: [
                  LineChartBarData(
                    spots: kSpots,
                    isCurved: true,
                    color: cs.primary,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                  if (dSpots.isNotEmpty)
                    LineChartBarData(
                      spots: dSpots,
                      isCurved: true,
                      color: const Color(0xFFEF4444),
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    ),
                ],
              )),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(width: 12, height: 2, color: cs.primary),
                  const SizedBox(width: 4),
                  Text('%K',
                      style:
                          TextStyle(fontSize: 10, color: cs.secondary)),
                  const SizedBox(width: 12),
                  Container(
                      width: 12,
                      height: 2,
                      color: const Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Text('%D',
                      style:
                          TextStyle(fontSize: 10, color: cs.secondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _stochColor(double v) {
    if (v >= 80) return const Color(0xFFEF4444);
    if (v <= 20) return const Color(0xFF22C55E);
    return Theme.of(context).colorScheme.primary;
  }

  // ════════════════════════════════════════════════════════════
  //  TECHNICAL SUMMARY
  // ════════════════════════════════════════════════════════════

  Widget _buildTechnicalSummary() {
    final cs = Theme.of(context).colorScheme;
    final rsi = _rsiData.whereType<double>().lastOrNull ?? 50;
    final macdVal = _macdLine.whereType<double>().lastOrNull ?? 0;
    final stochVal = _stochK.whereType<double>().lastOrNull ?? 50;
    final ma5Val = _ma5.whereType<double>().lastOrNull;
    final ma20Val = _ma20.whereType<double>().lastOrNull;
    final price =
        (widget.stockData['price'] as num?)?.toDouble() ?? 0;

    String signal(double val, double t1, double t2, bool invert) {
      if (invert) {
        if (val > t1) return 'Overbought';
        if (val < t2) return 'Oversold';
      } else {
        if (val > 0) return 'Bullish';
        if (val < 0) return 'Bearish';
      }
      return 'Neutral';
    }

    final items = [
      _SummaryItem(
          'RSI(14)', rsi.toStringAsFixed(1), signal(rsi, 70, 30, true)),
      _SummaryItem('MACD', macdVal.toStringAsFixed(1),
          signal(macdVal, 0, 0, false)),
      _SummaryItem('Stoch %K', stochVal.toStringAsFixed(1),
          signal(stochVal, 80, 20, true)),
      if (ma5Val != null)
        _SummaryItem('SMA 5', price > ma5Val ? 'Above' : 'Below',
            price > ma5Val ? 'Bullish' : 'Bearish'),
      if (ma20Val != null)
        _SummaryItem('SMA 20', price > ma20Val ? 'Above' : 'Below',
            price > ma20Val ? 'Bullish' : 'Bearish'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Technical Summary',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 10),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    SizedBox(
                      width: 80,
                      child: Text(item.name,
                          style: TextStyle(
                              fontSize: 12, color: cs.secondary)),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(item.value,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sigColor(item.signal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item.signal,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _sigColor(item.signal))),
                  ]),
                )),
          ],
        ),
      ),
    );
  }

  Color _sigColor(String s) => switch (s) {
        'Bullish' => _kUp,
        'Bearish' || 'Overbought' => _kDown,
        'Oversold' => _kUp,
        _ => Theme.of(context).colorScheme.secondary,
      };

  // ──── Format helpers ────────────────────────────────────────
  String _fmtVol(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtDateFull(DateTime d) {
    if (_candleInterval == 0) {
      // Minute: show full datetime
      return DateFormat('yyyy-MM-dd HH:mm').format(d);
    }
    // Daily/Weekly/Monthly: show date only
    return DateFormat('yyyy-MM-dd').format(d);
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN CHART PAINTER — candles / line / area + overlays
// ═══════════════════════════════════════════════════════════════

class _MainChartPainter extends CustomPainter {
  _MainChartPainter({
    required this.candles,
    required this.chartType,
    required this.ma5,
    required this.ma20,
    required this.bbUpper,
    required this.bbLower,
    required this.showMA,
    required this.showBB,
    required this.currentPrice,
    required this.crosshairIdx,
    required this.gridColor,
    required this.textColor,
    required this.accentColor,
    required this.periodIndex,
    required this.candleInterval,
  });

  final List<_CandleData> candles;
  final int chartType;
  final List<double?> ma5, ma20, bbUpper, bbLower;
  final bool showMA, showBB;
  final double? currentPrice;
  final int? crosshairIdx;
  final Color gridColor, textColor, accentColor;
  final int periodIndex;
  final int candleInterval; // 0=minute, 1=daily, 2=weekly, 3=monthly

  static const _upC = Color(0xFF22C55E);
  static const _downC = Color(0xFFEF4444);
  static const _ma5C = Color(0xFFF97316);
  static const _bbC = Color(0xFF8B5CF6);
  static const _rightW = _ChartTabState._kRightAxisW;
  static const _bottomH = _ChartTabState._kBottomAxisH;
  static const _topPad = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final drawW = size.width - _rightW;
    final drawH = size.height - _bottomH;
    if (drawW <= 0 || drawH <= 0) return;

    // Price range from visible candles + overlays
    double minP = candles.map((c) => c.low).reduce(min);
    double maxP = candles.map((c) => c.high).reduce(max);
    if (showMA) {
      for (final v in ma5) {
        if (v != null) {
          minP = min(minP, v);
          maxP = max(maxP, v);
        }
      }
      for (final v in ma20) {
        if (v != null) {
          minP = min(minP, v);
          maxP = max(maxP, v);
        }
      }
    }
    if (showBB) {
      for (final v in bbUpper) {
        if (v != null) maxP = max(maxP, v);
      }
      for (final v in bbLower) {
        if (v != null) minP = min(minP, v);
      }
    }
    final pad = (maxP - minP) * 0.06;
    minP -= pad;
    maxP += pad;
    if (maxP <= minP) maxP = minP + 1;

    final candleW = drawW / candles.length;

    double toY(double p) =>
        _topPad + (maxP - p) / (maxP - minP) * (drawH - _topPad);
    double toX(int i) => i * candleW + candleW / 2;

    // ── Grid ──
    _paintGrid(canvas, drawW, drawH, minP, maxP, toY);

    // Clip chart drawing area
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, drawW, drawH));

    // ── BB bands ──
    if (showBB) _paintBB(canvas, toX, toY);

    // ── Chart content ──
    switch (chartType) {
      case 0:
        _paintCandles(canvas, candleW, toY);
      case 1:
        _paintLineArea(canvas, toX, toY, false);
      case 2:
        _paintLineArea(canvas, toX, toY, true);
    }

    // ── MA lines (on all chart types) ──
    if (showMA) {
      _paintOverlayLine(canvas, ma5, _ma5C, toX, toY);
      _paintOverlayLine(canvas, ma20, accentColor, toX, toY);
    }

    // ── Current price line ──
    if (currentPrice != null &&
        currentPrice! >= minP &&
        currentPrice! <= maxP) {
      _paintDashedH(canvas, 0, drawW, toY(currentPrice!),
          accentColor.withValues(alpha: 0.7), 1.0);
    }

    // ── Crosshair ──
    if (crosshairIdx != null &&
        crosshairIdx! >= 0 &&
        crosshairIdx! < candles.length) {
      _paintCrosshair(canvas, crosshairIdx!, drawW, drawH, toX, toY);
    }

    canvas.restore();

    // ── Right axis ──
    _paintRightAxis(canvas, size, drawW, drawH, minP, maxP, toY);

    // ── Current price label on axis ──
    if (currentPrice != null &&
        currentPrice! >= minP &&
        currentPrice! <= maxP) {
      _paintPriceLabel(
          canvas, drawW, toY(currentPrice!), currentPrice!, accentColor);
    }

    // ── Crosshair price label ──
    if (crosshairIdx != null &&
        crosshairIdx! >= 0 &&
        crosshairIdx! < candles.length) {
      final c = candles[crosshairIdx!];
      _paintPriceLabel(canvas, drawW, toY(c.close), c.close,
          textColor.withValues(alpha: 0.8));
    }

    // ── Bottom axis ──
    _paintBottomAxis(canvas, drawW, drawH, toX);
  }

  // ──── Grid ────
  void _paintGrid(Canvas canvas, double w, double h, double minP,
      double maxP, double Function(double) toY) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    final count = 5;
    final step = (maxP - minP) / (count + 1);
    for (int i = 1; i <= count; i++) {
      final y = toY(minP + step * i);
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }
  }

  // ──── Candles ────
  void _paintCandles(
      Canvas canvas, double candleW, double Function(double) toY) {
    final bodyW = (candleW * 0.65).clamp(2.0, 20.0);
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * candleW + candleW / 2;
      final color = c.isUp ? _upC : _downC;
      final paint = Paint()..color = color;

      // Wick
      canvas.drawLine(
        Offset(x, toY(c.high)),
        Offset(x, toY(c.low)),
        paint..strokeWidth = 1.0,
      );

      // Body
      final top = toY(max(c.open, c.close));
      final bot = toY(min(c.open, c.close));
      canvas.drawRect(
        Rect.fromLTRB(
            x - bodyW / 2, top, x + bodyW / 2, max(bot, top + 1)),
        paint..style = PaintingStyle.fill,
      );
    }
  }

  // ──── Line / Area ────
  void _paintLineArea(Canvas canvas, double Function(int) toX,
      double Function(double) toY, bool fill) {
    if (candles.isEmpty) return;
    final path = Path();
    for (int i = 0; i < candles.length; i++) {
      final x = toX(i);
      final y = toY(candles[i].close);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final isUp = candles.last.close >= candles.first.close;
    final color = isUp ? _upC : _downC;

    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);

    if (fill) {
      final fillPath = Path.from(path);
      final lastX = toX(candles.length - 1);
      final firstX = toX(0);
      // Use the actual bottom of the drawing area
      final bottomY = toY(candles.map((c) => c.low).reduce(min)) + 20;
      fillPath.lineTo(lastX, bottomY);
      fillPath.lineTo(firstX, bottomY);
      fillPath.close();

      canvas.drawPath(
          fillPath,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, toY(candles.map((c) => c.high).reduce(max))),
              Offset(0, bottomY),
              [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
            ));
    }
  }

  // ──── BB bands ────
  void _paintBB(Canvas canvas, double Function(int) toX,
      double Function(double) toY) {
    final upper = Path();
    final lower = Path();
    bool started = false;
    for (int i = 0; i < bbUpper.length && i < candles.length; i++) {
      if (bbUpper[i] == null || bbLower[i] == null) {
        started = false;
        continue;
      }
      if (!started) {
        upper.moveTo(toX(i), toY(bbUpper[i]!));
        lower.moveTo(toX(i), toY(bbLower[i]!));
        started = true;
      } else {
        upper.lineTo(toX(i), toY(bbUpper[i]!));
        lower.lineTo(toX(i), toY(bbLower[i]!));
      }
    }
    final bbPaint = Paint()
      ..color = _bbC.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    bbPaint.style = PaintingStyle.stroke;
    canvas.drawPath(upper, bbPaint);
    canvas.drawPath(lower, bbPaint);

    // Fill between BB bands
    if (started) {
      final fillPath = Path();
      bool first = true;
      final validIndices = <int>[];
      for (int i = 0; i < bbUpper.length && i < candles.length; i++) {
        if (bbUpper[i] != null && bbLower[i] != null) {
          validIndices.add(i);
        }
      }
      if (validIndices.length >= 2) {
        for (final i in validIndices) {
          if (first) {
            fillPath.moveTo(toX(i), toY(bbUpper[i]!));
            first = false;
          } else {
            fillPath.lineTo(toX(i), toY(bbUpper[i]!));
          }
        }
        for (final i in validIndices.reversed) {
          fillPath.lineTo(toX(i), toY(bbLower[i]!));
        }
        fillPath.close();
        canvas.drawPath(
            fillPath,
            Paint()
              ..color = _bbC.withValues(alpha: 0.06)
              ..style = PaintingStyle.fill);
      }
    }
  }

  // ──── Overlay line (MA) ────
  void _paintOverlayLine(Canvas canvas, List<double?> data, Color color,
      double Function(int) toX, double Function(double) toY) {
    final path = Path();
    bool started = false;
    for (int i = 0; i < data.length && i < candles.length; i++) {
      if (data[i] == null) {
        started = false;
        continue;
      }
      if (!started) {
        path.moveTo(toX(i), toY(data[i]!));
        started = true;
      } else {
        path.lineTo(toX(i), toY(data[i]!));
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  // ──── Dashed horizontal line ────
  void _paintDashedH(
      Canvas canvas, double x1, double x2, double y, Color color, double w) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = w;
    const dash = 4.0, gap = 3.0;
    double x = x1;
    while (x < x2) {
      canvas.drawLine(
          Offset(x, y), Offset(min(x + dash, x2), y), paint);
      x += dash + gap;
    }
  }

  // ──── Crosshair ────
  void _paintCrosshair(Canvas canvas, int idx, double w, double h,
      double Function(int) toX, double Function(double) toY) {
    final c = candles[idx];
    final x = toX(idx);
    final y = toY(c.close);
    final paint = Paint()
      ..color = textColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    // Vertical dashed line
    const dash = 3.0, gap = 3.0;
    double cy = 0;
    while (cy < h) {
      canvas.drawLine(
          Offset(x, cy), Offset(x, min(cy + dash, h)), paint);
      cy += dash + gap;
    }

    // Horizontal dashed line
    double cx = 0;
    while (cx < w) {
      canvas.drawLine(
          Offset(cx, y), Offset(min(cx + dash, w), y), paint);
      cx += dash + gap;
    }

    // Dot at intersection
    canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  // ──── Right axis ────
  void _paintRightAxis(Canvas canvas, Size size, double drawW, double drawH,
      double minP, double maxP, double Function(double) toY) {
    // Separator line
    canvas.drawLine(
      Offset(drawW, 0),
      Offset(drawW, drawH),
      Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );

    final count = 5;
    final step = (maxP - minP) / (count + 1);
    for (int i = 1; i <= count; i++) {
      final p = minP + step * i;
      final y = toY(p);
      _drawText(canvas, _fmtPrice(p), Offset(drawW + 4, y - 5),
          fontSize: 9, color: textColor);
    }
  }

  // ──── Price label on right axis ────
  void _paintPriceLabel(
      Canvas canvas, double drawW, double y, double price, Color bgColor) {
    final text = _fmtPrice(price);
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(drawW + 2, y - 8, tp.width + 8, 16),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, Paint()..color = bgColor);
    tp.paint(canvas, Offset(drawW + 6, y - 6));
  }

  // ──── Bottom axis ────
  void _paintBottomAxis(
      Canvas canvas, double drawW, double drawH, double Function(int) toX) {
    // Separator line
    canvas.drawLine(
      Offset(0, drawH),
      Offset(drawW, drawH),
      Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );

    if (candles.isEmpty) return;
    // Show 4-6 evenly spaced labels, skip first/last to avoid clipping
    final labelCount = candles.length <= 10 ? min(candles.length, 4) : 5;
    final step = max(1, candles.length ~/ labelCount);
    // Start from offset to avoid edge clipping
    final startOff = max(1, step ~/ 2);
    for (int i = startOff; i < candles.length; i += step) {
      final x = toX(i);
      if (x < 20 || x > drawW - 20) continue; // skip if too close to edge
      final label = _fmtAxisDate(candles[i].date);
      _drawText(canvas, label, Offset(x, drawH + 4),
          fontSize: 9, color: textColor, center: true);
    }
  }

  String _fmtAxisDate(DateTime d) {
    if (candleInterval == 0) {
      // Minute candles: show HH:mm
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } else if (candleInterval == 1) {
      // Daily candles
      if (periodIndex >= 5) {
        // 1Y+: year context needed → YY/M/D
        return '${d.year.toString().substring(2)}/${d.month}/${d.day}';
      }
      return '${d.month}/${d.day}';
    } else if (candleInterval == 2) {
      // Weekly candles: show YY/M/D
      return '${d.year.toString().substring(2)}/${d.month}/${d.day}';
    } else {
      // Monthly candles: show YY/M
      return '${d.year.toString().substring(2)}/${d.month}';
    }
  }

  String _fmtPrice(double p) {
    if (p.abs() >= 1000) return NumberFormat('#,##0').format(p);
    return p.toStringAsFixed(p.abs() >= 100 ? 0 : 1);
  }

  void _drawText(Canvas canvas, String text, Offset pos,
      {double fontSize = 9,
      Color color = Colors.grey,
      bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text, style: TextStyle(fontSize: fontSize, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  bool shouldRepaint(covariant _MainChartPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════
//  VOLUME PAINTER — synced with main chart scroll
// ═══════════════════════════════════════════════════════════════

class _VolumePainter extends CustomPainter {
  _VolumePainter({
    required this.candles,
    required this.crosshairIdx,
    required this.gridColor,
    required this.textColor,
  });

  final List<_CandleData> candles;
  final int? crosshairIdx;
  final Color gridColor, textColor;

  static const _upC = Color(0xFF22C55E);
  static const _downC = Color(0xFFEF4444);
  static const _rightW = _ChartTabState._kRightAxisW;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    final drawW = size.width - _rightW;
    final drawH = size.height;
    if (drawW <= 0) return;

    final maxVol =
        candles.map((c) => c.volume).reduce(max) * 1.15;
    if (maxVol <= 0) return;

    final candleW = drawW / candles.length;
    final barW = (candleW * 0.65).clamp(1.5, 20.0);

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * candleW + candleW / 2;
      final h = (c.volume / maxVol) * drawH;
      final color = c.isUp
          ? _upC.withValues(alpha: 0.4)
          : _downC.withValues(alpha: 0.4);
      canvas.drawRect(
        Rect.fromLTRB(x - barW / 2, drawH - h, x + barW / 2, drawH),
        Paint()..color = color,
      );
    }

    // Crosshair vertical
    if (crosshairIdx != null &&
        crosshairIdx! >= 0 &&
        crosshairIdx! < candles.length) {
      final x = crosshairIdx! * candleW + candleW / 2;
      const dash = 3.0, gap = 3.0;
      double cy = 0;
      final paint = Paint()
        ..color = textColor.withValues(alpha: 0.5)
        ..strokeWidth = 0.5;
      while (cy < drawH) {
        canvas.drawLine(
            Offset(x, cy), Offset(x, min(cy + dash, drawH)), paint);
        cy += dash + gap;
      }
    }

    // Right axis separator
    canvas.drawLine(
      Offset(drawW, 0),
      Offset(drawW, drawH),
      Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _VolumePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════
//  MACD PAINTER — histogram bars + MACD / Signal lines
// ═══════════════════════════════════════════════════════════════

class _MACDPainter extends CustomPainter {
  _MACDPainter({
    required this.macd,
    required this.signal,
    required this.histogram,
    required this.lineColor,
    required this.signalColor,
    required this.gridColor,
  });

  final List<double?> macd, signal, histogram;
  final Color lineColor, signalColor, gridColor;

  static const _upC = Color(0xFF22C55E);
  static const _downC = Color(0xFFEF4444);

  @override
  void paint(Canvas canvas, Size size) {
    if (histogram.isEmpty) return;

    final all = [
      ...macd.whereType<double>(),
      ...signal.whereType<double>(),
      ...histogram.whereType<double>(),
    ];
    if (all.isEmpty) return;

    double minV = all.reduce(min);
    double maxV = all.reduce(max);
    final pad = (maxV - minV) * 0.1;
    minV -= pad;
    maxV += pad;
    if (maxV <= minV) maxV = minV + 1;

    double toY(double v) => size.height * (1 - (v - minV) / (maxV - minV));
    double toX(int i) =>
        i * size.width / histogram.length +
        size.width / (2 * histogram.length);

    // Zero line
    final zeroY = toY(0);
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY),
        Paint()..color = gridColor..strokeWidth = 0.5);

    // Histogram bars
    final barW =
        (size.width / histogram.length * 0.6).clamp(1.0, 20.0);
    for (int i = 0; i < histogram.length; i++) {
      final v = histogram[i];
      if (v == null) continue;
      final x = toX(i);
      final y = toY(v);
      canvas.drawRect(
        Rect.fromLTRB(
            x - barW / 2, min(y, zeroY), x + barW / 2, max(y, zeroY)),
        Paint()
          ..color = v >= 0
              ? _upC.withValues(alpha: 0.6)
              : _downC.withValues(alpha: 0.6),
      );
    }

    // MACD line
    _drawLine(canvas, macd, lineColor, toX, toY);

    // Signal line
    _drawLine(canvas, signal, signalColor, toX, toY);
  }

  void _drawLine(Canvas canvas, List<double?> data, Color color,
      double Function(int) toX, double Function(double) toY) {
    final path = Path();
    bool started = false;
    for (int i = 0; i < data.length; i++) {
      if (data[i] == null) {
        started = false;
        continue;
      }
      if (!started) {
        path.moveTo(toX(i), toY(data[i]!));
        started = true;
      } else {
        path.lineTo(toX(i), toY(data[i]!));
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _MACDPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════

class _CandleData {
  final DateTime date;
  final double open, high, low, close, volume;
  const _CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
  bool get isUp => close >= open;
}

// ═══════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.color,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : cs.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              Icon(Icons.check, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : cs.secondary,
                )),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final String name, value, signal;
  const _SummaryItem(this.name, this.value, this.signal);
}
