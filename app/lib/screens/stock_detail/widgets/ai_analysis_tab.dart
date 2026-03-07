import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ai_analysis.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ai_provider.dart';
import '../../../providers/settings_provider.dart';

// ═══════════════════════════════════════════════════════════════
//  AI ANALYSIS TAB — Terminal-style layout
//  Top: Credits → 4 Summary Cards → SCE Score → 3-Tab Detail
// ═══════════════════════════════════════════════════════════════

class AiAnalysisTab extends ConsumerStatefulWidget {
  const AiAnalysisTab({
    super.key,
    required this.symbol,
    required this.stockData,
  });
  final String symbol;
  final Map<String, dynamic> stockData;

  @override
  ConsumerState<AiAnalysisTab> createState() => _AiAnalysisTabState();
}

class _AiAnalysisTabState extends ConsumerState<AiAnalysisTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  // Typing animation
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _typingTimer;
  bool _typingDone = false;

  // Detail tabs: Strategy / Risk / Trend
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        ref.read(aiProvider.notifier).loadCredits();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runBasicAnalysis() async {
    setState(() {
      _displayedText = '';
      _charIndex = 0;
      _typingDone = false;
    });
    _typingTimer?.cancel();

    final lang = ref.read(settingsProvider).language;
    final result =
        await ref.read(aiProvider.notifier).analyzeBasic(widget.symbol, language: lang);
    if (result != null && mounted) {
      _startTypingAnimation(result.sections?.summary ?? result.signal);
    }
  }

  Future<void> _runProAnalysis({String model = 'gemini'}) async {
    setState(() {
      _displayedText = '';
      _charIndex = 0;
      _typingDone = false;
    });
    _typingTimer?.cancel();

    final lang = ref.read(settingsProvider).language;
    final result = await ref
        .read(aiProvider.notifier)
        .analyzePro(widget.symbol, model: model, language: lang);
    if (result != null && mounted) {
      _startTypingAnimation(result.sections?.summary ?? result.signal);
    }
  }

  void _startTypingAnimation(String text) {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (_charIndex < text.length) {
        setState(() {
          _displayedText = text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
        setState(() => _typingDone = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = ref.watch(authProvider);
    final aiState = ref.watch(aiProvider);
    final s = S.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Credits / Plan info ──
          _buildCreditsInfo(authState, aiState, s),
          const SizedBox(height: 16),

          // ── Error ──
          if (aiState.error != null && !aiState.isAnalyzing) ...[
            _buildErrorBanner(aiState.error!),
            const SizedBox(height: 12),
          ],

          // ── Analyzing spinner ──
          if (aiState.isAnalyzing) ...[
            const _AnalyzingIndicator(),
            const SizedBox(height: 16),
          ],

          // ── Analysis results (basic or pro) ──
          if (!aiState.isAnalyzing && _hasAnalysis(aiState)) ...[
            _buildAnalysisResults(aiState, s),
          ],

          // ── Analyze buttons ──
          if (!aiState.isAnalyzing) ...[
            const SizedBox(height: 16),
            _buildBasicButton(authState, aiState, s),
            const SizedBox(height: 10),
            _buildProButton(authState, aiState, s),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  bool _hasAnalysis(AIState aiState) {
    return aiState.basicAnalysis != null || aiState.proAnalysis != null;
  }

  AIAnalysis? _activeAnalysis(AIState aiState) {
    return aiState.proAnalysis ?? aiState.basicAnalysis;
  }

  // ════════════════════════════════════════════════════════════
  //  CREDITS INFO BAR
  // ════════════════════════════════════════════════════════════

  Widget _buildCreditsInfo(AuthState authState, AIState aiState, S s) {
    final cs = Theme.of(context).colorScheme;
    final credits = aiState.credits;
    final isPro = credits?.plan == 'pro';
    final remaining = credits?.remaining ?? 0;
    final limit = credits?.dailyLimit ?? 3;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isPro ? const Color(0xFFF59E0B) : cs.primary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPro ? Icons.workspace_premium : Icons.auto_awesome,
              size: 18,
              color: isPro ? const Color(0xFFF59E0B) : cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.isAuthenticated
                      ? (isPro ? s.proPlan : s.freePlan)
                      : s.signInForAI,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  authState.isAuthenticated
                      ? (isPro
                          ? s.proUnlimited
                          : s.analysesRemaining(remaining, limit))
                      : s.freeAnalysesPerDay(limit),
                  style: TextStyle(fontSize: 11, color: cs.secondary),
                ),
              ],
            ),
          ),
          if (authState.isAuthenticated && credits != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isPro
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPro ? 'PRO' : s.remainingCredits(remaining),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ERROR BANNER
  // ════════════════════════════════════════════════════════════

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ANALYSIS RESULTS — full terminal-style
  // ════════════════════════════════════════════════════════════

  Widget _buildAnalysisResults(AIState aiState, S s) {
    final analysis = _activeAnalysis(aiState)!;
    final sections = analysis.sections;
    final cs = Theme.of(context).colorScheme;
    final isPro = aiState.proAnalysis != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Signal badge + confidence ──
        _buildSignalBadge(analysis.signal, analysis.confidence.toInt()),
        const SizedBox(height: 16),

        // ── 4 Summary cards (2x2 grid) ──
        _buildSummaryCards(sections, s),
        const SizedBox(height: 16),

        // ── SCE Score ──
        _buildSceScore(analysis.sceScore, cs),
        const SizedBox(height: 16),

        // ── Summary text with typing animation (Pro only) ──
        if (isPro &&
            (_displayedText.isNotEmpty ||
                (sections?.summary ?? '').isNotEmpty))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.summarize_outlined,
                        size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      s.aiSummary,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _displayedText.isNotEmpty
                      ? _displayedText
                      : sections?.summary ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface,
                    height: 1.6,
                  ),
                ),
                if (!_typingDone && _displayedText.isNotEmpty)
                  Container(
                    width: 8,
                    height: 16,
                    margin: const EdgeInsets.only(top: 2),
                    color: cs.primary,
                  ),
              ],
            ),
          ),

        // ── 3-Tab detail section (Pro only) ──
        if (isPro && _typingDone) ...[
          const SizedBox(height: 16),
          _buildDetailTabs(sections, cs, s),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SIGNAL BADGE
  // ════════════════════════════════════════════════════════════

  Widget _buildSignalBadge(String signal, int confidence) {
    final cs = Theme.of(context).colorScheme;
    final normalized = signal.toUpperCase();
    final isPositive = normalized == 'BUY' || normalized == 'STRONG_BUY';
    final isNegative = normalized == 'SELL' || normalized == 'STRONG_SELL';
    final color = isPositive
        ? const Color(0xFF22C55E)
        : isNegative
            ? const Color(0xFFEF4444)
            : cs.secondary;

    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up
                    : isNegative
                        ? Icons.trending_down
                        : Icons.trending_flat,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                normalized.replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          S.of(context).confidence(confidence),
          style: TextStyle(fontSize: 12, color: cs.secondary),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  //  4 SUMMARY CARDS (2x2 grid)
  // ════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(AIAnalysisSections? sections, S s) {
    final cards = [
      _CardData(
        icon: Icons.psychology_outlined,
        label: s.aiMarketSentiment,
        value: sections?.marketSentiment ?? '—',
        color: const Color(0xFF3B82F6),
      ),
      _CardData(
        icon: Icons.flag_outlined,
        label: s.aiActionStrategy,
        value: sections?.actionStrategy ?? '—',
        color: const Color(0xFF22C55E),
      ),
      _CardData(
        icon: Icons.schedule_outlined,
        label: s.aiInvestmentTiming,
        value: sections?.investmentTiming ?? '—',
        color: const Color(0xFFF59E0B),
      ),
      _CardData(
        icon: Icons.auto_graph_outlined,
        label: s.aiFutureForecast,
        value: sections?.futureForecast ?? '—',
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMiniCard(cards[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildMiniCard(cards[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMiniCard(cards[2])),
            const SizedBox(width: 10),
            Expanded(child: _buildMiniCard(cards[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard(_CardData data) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(data.icon, size: 14, color: data.color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SCE SCORE — circular gauge
  // ════════════════════════════════════════════════════════════

  Widget _buildSceScore(int score, ColorScheme cs) {
    final s = S.of(context);
    final scoreColor = score >= 70
        ? const Color(0xFF22C55E)
        : score >= 40
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          // Circular score
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(
                    painter: _SceGaugePainter(
                      score: score / 100,
                      color: scoreColor,
                      bgColor: cs.outline,
                    ),
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.aiSceScore,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock Comprehensive Evaluation',
                  style: TextStyle(fontSize: 11, color: cs.secondary),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: cs.outline,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0',
                        style:
                            TextStyle(fontSize: 9, color: cs.secondary)),
                    Text(
                      _scoreLabel(score, s),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: scoreColor,
                      ),
                    ),
                    Text('100',
                        style:
                            TextStyle(fontSize: 9, color: cs.secondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scoreLabel(int score, S s) {
    if (score >= 80) return s.aiScoreExcellent;
    if (score >= 60) return s.aiScoreGood;
    if (score >= 40) return s.aiScoreNeutral;
    if (score >= 20) return s.aiScoreWeak;
    return s.aiScorePoor;
  }

  // ════════════════════════════════════════════════════════════
  //  3-TAB DETAIL SECTION (Strategy / Risk / Trend)
  // ════════════════════════════════════════════════════════════

  Widget _buildDetailTabs(
      AIAnalysisSections? sections, ColorScheme cs, S s) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outline)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: cs.primary,
              unselectedLabelColor: cs.secondary,
              indicatorColor: cs.primary,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(s.aiTabStrategy),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(s.aiTabRisk),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.show_chart, size: 14),
                      const SizedBox(width: 4),
                      Text(s.aiTabTrend),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          SizedBox(
            height: 220,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  sections?.strategy ?? s.aiNoData,
                  const Color(0xFF22C55E),
                ),
                _buildTabContent(
                  sections?.risk ?? s.aiNoData,
                  const Color(0xFFEF4444),
                ),
                _buildTabContent(
                  sections?.trend ?? s.aiNoData,
                  const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String text, Color accent) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ANALYZE BUTTONS
  // ════════════════════════════════════════════════════════════

  Widget _buildBasicButton(
      AuthState authState, AIState aiState, S s) {
    final cs = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final hasBasic = aiState.basicAnalysis != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (!authState.isAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.loginForAI),
                backgroundColor: appColors.surfaceHover,
              ),
            );
            return;
          }
          _runBasicAnalysis();
        },
        icon: Icon(
            hasBasic ? Icons.refresh : Icons.auto_awesome, size: 16),
        label: Text(hasBasic ? s.reAnalyze : s.runBasicAnalysis),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildProButton(
      AuthState authState, AIState aiState, S s) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final hasPro = aiState.proAnalysis != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (!authState.isAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.loginForPro),
                backgroundColor: appColors.surfaceHover,
              ),
            );
            return;
          }
          _runProAnalysis();
        },
        icon: Icon(
            hasPro ? Icons.refresh : Icons.workspace_premium, size: 16),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hasPro ? s.rerunPro : s.runPro),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELPER DATA CLASS
// ═══════════════════════════════════════════════════════════════

class _CardData {
  const _CardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

// ═══════════════════════════════════════════════════════════════
//  SCE GAUGE PAINTER
// ═══════════════════════════════════════════════════════════════

class _SceGaugePainter extends CustomPainter {
  _SceGaugePainter({
    required this.score,
    required this.color,
    required this.bgColor,
  });
  final double score; // 0.0 – 1.0
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const startAngle = -pi * 0.75;
    const sweepTotal = pi * 1.5;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * score,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_SceGaugePainter old) =>
      old.score != score || old.color != color;
}

// ═══════════════════════════════════════════════════════════════
//  ANALYZING INDICATOR
// ═══════════════════════════════════════════════════════════════

class _AnalyzingIndicator extends StatelessWidget {
  const _AnalyzingIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: cs.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).analyzingStock,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context).processingIndicators,
            style: TextStyle(
              fontSize: 12,
              color: cs.secondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
