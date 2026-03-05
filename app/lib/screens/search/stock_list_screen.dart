import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/stock_card.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/error_retry_widget.dart';

/// All Stocks list screen — filter by KOSPI/KOSDAQ, sort, fetched from API.
class StockListScreen extends ConsumerStatefulWidget {
  const StockListScreen({super.key});

  @override
  ConsumerState<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends ConsumerState<StockListScreen> {
  int _selectedMarket = 0; // 0=All, 1=KOSPI, 2=KOSDAQ
  String _sortBy = 'change'; // change, volume, name
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allStocks = [];
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStocks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStocks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      // Always fetch ALL stocks once; filter client-side
      final response = await api.getStockList(sort: 'change', market: 'all');
      if (response.data['success'] == true) {
        final rawList = response.data['data'] as List;
        _allStocks = rawList.map((item) {
          final m = item as Map<String, dynamic>;
          return {
            'symbol': m['symbol'] ?? '',
            'nameKo': m['name'] ?? '',
            'nameEn': m['englishName'] ?? '',
            'exchange': m['exchange'] ?? 'KOSPI',
            'price': m['price'] ?? 0,
            'change': m['change'] ?? 0,
            'changePercent': m['changePct'] ?? 0,
            'volume': m['volume'] ?? 0,
            'hasLiveData': m['hasLiveData'] ?? false,
          };
        }).toList();
      }
    } catch (e) {
      _error = S.of(context).failedLoadStocks;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredStocks {
    var list = List<Map<String, dynamic>>.from(_allStocks);

    // Market filter
    if (_selectedMarket == 1) {
      list = list.where((s) => s['exchange'] == 'KOSPI').toList();
    } else if (_selectedMarket == 2) {
      list = list.where((s) => s['exchange'] == 'KOSDAQ').toList();
    }

    // Local search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        final symbol = (s['symbol'] as String).toLowerCase();
        final nameKo = (s['nameKo'] as String).toLowerCase();
        final nameEn = (s['nameEn'] as String).toLowerCase();
        return symbol.contains(q) || nameKo.contains(q) || nameEn.contains(q);
      }).toList();
    }

    // Sort
    if (_sortBy == 'volume') {
      list.sort((a, b) {
        final aLive = a['hasLiveData'] == true ? 1 : 0;
        final bLive = b['hasLiveData'] == true ? 1 : 0;
        if (bLive != aLive) return bLive - aLive;
        return ((b['volume'] as num?) ?? 0).compareTo((a['volume'] as num?) ?? 0);
      });
    } else if (_sortBy == 'name') {
      list.sort((a, b) => (a['nameKo'] as String).compareTo(b['nameKo'] as String));
    } else {
      list.sort((a, b) {
        final aLive = a['hasLiveData'] == true ? 1 : 0;
        final bLive = b['hasLiveData'] == true ? 1 : 0;
        if (bLive != aLive) return bLive - aLive;
        return ((b['changePercent'] as num).abs()).compareTo((a['changePercent'] as num).abs());
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stocks = _filteredStocks;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('${S.of(context).allStocks}${_allStocks.isNotEmpty ? ' (${stocks.length})' : ''}'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              decoration: InputDecoration(
                hintText: S.of(context).searchStocks,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colorScheme.outline)),
            ),
            child: Row(
              children: [
                _FilterPill(label: S.of(context).all, isActive: _selectedMarket == 0, onTap: () {
                  setState(() => _selectedMarket = 0);
                }),
                const SizedBox(width: 8),
                _FilterPill(label: 'KOSPI', isActive: _selectedMarket == 1, onTap: () {
                  setState(() => _selectedMarket = 1);
                }),
                const SizedBox(width: 8),
                _FilterPill(label: 'KOSDAQ', isActive: _selectedMarket == 2, onTap: () {
                  setState(() => _selectedMarket = 2);
                }),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    setState(() => _sortBy = v);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'change', child: Text(S.of(context).sortChangePercent)),
                    PopupMenuItem(value: 'volume', child: Text(S.of(context).sortVolume)),
                    PopupMenuItem(value: 'name', child: Text(S.of(context).sortName)),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _sortBy == 'change' ? S.of(context).sortChangePercent : _sortBy == 'volume' ? S.of(context).sortVolume : S.of(context).sortName,
                          style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.unfold_more, size: 14, color: colorScheme.secondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stock list
          Expanded(
            child: _isLoading
                ? const ShimmerStockList(itemCount: 8)
                : _error != null
                    ? Center(
                        child: ErrorRetryWidget(
                          message: _error!,
                          onRetry: _fetchStocks,
                        ),
                      )
                    : _allStocks.isEmpty
                        ? Center(
                            child: Text(S.of(context).noStocksFound, style: TextStyle(color: colorScheme.secondary)),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchStocks,
                            color: colorScheme.primary,
                            backgroundColor: colorScheme.surface,
                            child: ListView.separated(
                              itemCount: stocks.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                indent: 72,
                                color: colorScheme.outline.withValues(alpha: 0.5),
                              ),
                              itemBuilder: (context, index) {
                                final s = stocks[index];
                                return StockCard(
                                  symbol: s['symbol'] as String,
                                  nameKo: s['nameKo'] as String,
                                  nameEn: s['nameEn'] as String,
                                  exchange: s['exchange'] as String,
                                  price: (s['price'] as num).toDouble(),
                                  change: (s['change'] as num).toDouble(),
                                  changePercent: (s['changePercent'] as num).toDouble(),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
