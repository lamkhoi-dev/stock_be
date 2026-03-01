import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ai_provider.dart';

/// AI Analysis tab — Basic analysis + Pro analysis (locked) + Typing animation.
class AiAnalysisTab extends ConsumerStatefulWidget {
  const AiAnalysisTab(
      {super.key, required this.symbol, required this.stockData});
  final String symbol;
  final Map<String, dynamic> stockData;

  @override
  ConsumerState<AiAnalysisTab> createState() => _AiAnalysisTabState();
}

class _AiAnalysisTabState extends ConsumerState<AiAnalysisTab>
    with AutomaticKeepAliveClientMixin {
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _typingTimer;
  bool _typingDone = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load credits on init if authenticated
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
    super.dispose();
  }

  Future<void> _runBasicAnalysis() async {
    setState(() {
      _displayedText = '';
      _charIndex = 0;
      _typingDone = false;
    });
    _typingTimer?.cancel();

    final result =
        await ref.read(aiProvider.notifier).analyzeBasic(widget.symbol);
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

    final result = await ref
        .read(aiProvider.notifier)
        .analyzePro(widget.symbol, model: model);
    if (result != null && mounted) {
      _startTypingAnimation(result.sections?.summary ?? result.signal);
    }
  }

  void _startTypingAnimation(String text) {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCreditsInfo(authState, aiState),
          const SizedBox(height: 16),
          _buildBasicAnalysisCard(authState, aiState),
          const SizedBox(height: 16),
          _buildProAnalysisCard(authState, aiState),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCreditsInfo(AuthState authState, AIState aiState) {
    final colorScheme = Theme.of(context).colorScheme;
    final credits = aiState.credits;
    final remaining = credits?.remaining ?? 0;
    final limit = credits?.dailyLimit ?? 3;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.auto_awesome,
                size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.isAuthenticated
                      ? 'Free Plan'
                      : 'Sign in for AI Analysis',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  authState.isAuthenticated
                      ? '$remaining / $limit basic analyses remaining today'
                      : 'Get $limit free basic analyses per day',
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.secondary),
                ),
              ],
            ),
          ),
          if (authState.isAuthenticated && credits != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$remaining credits',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicAnalysisCard(AuthState authState, AIState aiState) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final analysis = aiState.basicAnalysis;
    final hasResult = analysis != null;
    final summary = analysis?.sections?.summary ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'AI Basic Analysis',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Free',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Powered by Gemini 2.0 Flash — Quick overview of technical signals',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.38)),
          ),
          const SizedBox(height: 14),

          // Error message
          if (aiState.error != null && !aiState.isAnalyzing) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        const Color(0xFFEF4444).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiState.error!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (aiState.isAnalyzing) ...[
            const _AnalyzingIndicator(),
          ] else if (hasResult) ...[
            // Signal badge
            _buildSignalBadge(
                analysis.signal, analysis.confidence.toInt()),
            const SizedBox(height: 12),
            // Typing text
            Text(
              _displayedText.isNotEmpty ? _displayedText : summary,
              style: TextStyle(
                  fontSize: 14, color: colorScheme.onSurface, height: 1.6),
            ),
            if (_typingDone) ...[
              if (analysis.sections?.recommendation != null) ...[
                const SizedBox(height: 14),
                // Recommendation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF22C55E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF22C55E)
                            .withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: Color(0xFF22C55E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          analysis.sections!.recommendation!,
                          style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Re-analyze button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _runBasicAnalysis,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-analyze'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Analyze button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (!authState.isAuthenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Please login to use AI analysis'),
                        backgroundColor: appColors.surfaceHover,
                      ),
                    );
                    return;
                  }
                  _runBasicAnalysis();
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Run Basic Analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignalBadge(String signal, int confidence) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = signal.toUpperCase();
    final isPositive =
        normalized == 'BUY' || normalized == 'STRONG_BUY';
    final color =
        isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

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
                      : Icons.trending_down,
                  size: 16,
                  color: color),
              const SizedBox(width: 4),
              Text(
                normalized.replaceAll('_', ' '),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Confidence: $confidence%',
          style:
              TextStyle(fontSize: 12, color: colorScheme.secondary),
        ),
      ],
    );
  }

  Widget _buildProAnalysisCard(AuthState authState, AIState aiState) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final proAnalysis = aiState.proAnalysis;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.08),
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AI Pro Analysis',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium,
                        size: 10, color: Color(0xFFF59E0B)),
                    SizedBox(width: 2),
                    Text('PRO',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Powered by Gemini 2.0 Pro / GPT-4 — Comprehensive analysis with strategy',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.38)),
          ),
          const SizedBox(height: 12),

          // Show pro result if available
          if (proAnalysis != null) ...[
            _buildSignalBadge(
                proAnalysis.signal, proAnalysis.confidence.toInt()),
            const SizedBox(height: 12),
            Text(
              proAnalysis.sections?.summary ?? '',
              style: TextStyle(
                  fontSize: 14, color: colorScheme.onSurface, height: 1.6),
            ),
            if (proAnalysis.sections?.recommendation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFF59E0B)
                          .withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        proAnalysis.sections!.recommendation!,
                        style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // Features list
          ...[
            'Detailed technical & fundamental analysis',
            'Key support/resistance levels',
            'Trading strategy with entry/exit points',
            'Risk assessment & timeframe',
          ].map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(feature,
                        style: TextStyle(
                            fontSize: 12, color: colorScheme.secondary)),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (!authState.isAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please login to use Pro analysis'),
                        backgroundColor: appColors.surfaceHover,
                    ),
                  );
                  return;
                }
                _runProAnalysis();
              },
              icon: Icon(
                  proAnalysis != null ? Icons.refresh : Icons.lock,
                  size: 16),
              label: Text(proAnalysis != null
                  ? 'Re-run Pro Analysis (10 credits)'
                  : 'Run Pro Analysis (10 credits)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzingIndicator extends StatelessWidget {
  const _AnalyzingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing stock data...',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Processing indicators, price action & patterns',
            style: TextStyle(
                fontSize: 12,
                color:
                    colorScheme.secondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
