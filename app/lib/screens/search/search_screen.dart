import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/common/company_icon.dart';
import '../../widgets/common/exchange_badge.dart';
import '../../widgets/common/shimmer_loading.dart';

/// Search screen — search bar + recent searches + popular + search results.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _isSearching = false;
  List<Map<String, dynamic>> _results = [];

  // Popular stocks — static list of well-known Korean stocks
  final List<Map<String, dynamic>> _popular = [
    {'symbol': '005930', 'nameKo': '삼성전자', 'nameEn': 'Samsung Electronics', 'exchange': 'KOSPI'},
    {'symbol': '000660', 'nameKo': 'SK하이닉스', 'nameEn': 'SK Hynix', 'exchange': 'KOSPI'},
    {'symbol': '035420', 'nameKo': 'NAVER', 'nameEn': 'NAVER Corp', 'exchange': 'KOSPI'},
    {'symbol': '035720', 'nameKo': '카카오', 'nameEn': 'Kakao Corp', 'exchange': 'KOSPI'},
    {'symbol': '005380', 'nameKo': '현대차', 'nameEn': 'Hyundai Motor', 'exchange': 'KOSPI'},
    {'symbol': '051910', 'nameKo': 'LG화학', 'nameEn': 'LG Chem', 'exchange': 'KOSPI'},
  ];

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('recent_searches');
    if (saved != null && mounted) {
      setState(() => _recentSearches = saved);
    }
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    // Call real search API via backend (Yahoo Finance search)
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.searchStocks(query);
      if (!mounted) return;

      if (response.data['success'] == true) {
        final data = response.data['data'];
        List items;
        if (data is List) {
          items = data;
        } else if (data is Map && data['results'] is List) {
          items = data['results'] as List;
        } else {
          items = [];
        }

        setState(() {
          _results = items.map((s) {
            final item = s as Map<String, dynamic>;
            // Map Yahoo search results to our format
            String symbol = item['symbol'] ?? '';
            String exchange = 'KOSPI';
            // Yahoo returns symbols like 005930.KS (KOSPI) or 263750.KQ (KOSDAQ)
            if (symbol.endsWith('.KQ')) {
              exchange = 'KOSDAQ';
              symbol = symbol.replaceAll('.KQ', '');
            } else if (symbol.endsWith('.KS')) {
              symbol = symbol.replaceAll('.KS', '');
            }
            return <String, dynamic>{
              'symbol': symbol,
              'nameKo': item['shortname'] ?? item['name'] ?? item['nameKo'] ?? '',
              'nameEn': item['longname'] ?? item['shortname'] ?? item['nameEn'] ?? item['name'] ?? '',
              'exchange': item['exchange'] ?? exchange,
            };
          }).toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
      });
    }
  }

  void _selectStock(String symbol) {
    // Save to recent
    final name = _searchController.text.trim();
    if (name.isNotEmpty && !_recentSearches.contains(name)) {
      setState(() {
        _recentSearches.insert(0, name);
        if (_recentSearches.length > 10) _recentSearches = _recentSearches.take(10).toList();
      });
      _saveRecentSearches();
    }
    context.push('/stock/$symbol');
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildSearchBar(),
      ),
      body: hasQuery ? _buildSearchResults() : _buildDefaultContent(),
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search stocks...',
            hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.38)),
            prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.secondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, size: 18, color: colorScheme.secondary),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.secondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _recentSearches.clear());
                      _saveRecentSearches();
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(fontSize: 13, color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((term) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = term;
                      _onSearchChanged(term);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.38)),
                          const SizedBox(width: 6),
                          Text(term, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          // Popular stocks
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Popular Stocks',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _popular.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: appColors.surfaceHover),
            itemBuilder: (context, index) {
              final s = _popular[index];
              return _SearchResultItem(
                symbol: s['symbol'] as String,
                nameKo: s['nameKo'] as String,
                nameEn: s['nameEn'] as String,
                exchange: s['exchange'] as String,
                onTap: () => _selectStock(s['symbol'] as String),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    if (_isSearching) {
      return const ShimmerStockList(itemCount: 5);
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.38)),
            const SizedBox(height: 12),
            Text(
              'No results for "${_searchController.text}"',
              style: TextStyle(color: colorScheme.secondary, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: appColors.surfaceHover),
      itemBuilder: (context, index) {
        final s = _results[index];
        return _SearchResultItem(
          symbol: s['symbol'] as String,
          nameKo: s['nameKo'] as String,
          nameEn: s['nameEn'] as String,
          exchange: s['exchange'] as String,
          onTap: () => _selectStock(s['symbol'] as String),
        );
      },
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({
    required this.symbol,
    required this.nameKo,
    required this.nameEn,
    required this.exchange,
    required this.onTap,
  });

  final String symbol;
  final String nameKo;
  final String nameEn;
  final String exchange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CompanyIcon(name: nameKo, size: 44, fontSize: 18),
      title: Text(
        nameKo,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Row(
        children: [
          ExchangeBadge(exchange: exchange, small: true),
          const SizedBox(width: 6),
          Text(
            '$nameEn · $symbol',
            style: TextStyle(fontSize: 12, color: colorScheme.secondary),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.38), size: 20),
    );
  }
}
