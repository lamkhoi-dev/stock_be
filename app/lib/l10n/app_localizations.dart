import 'package:flutter/widgets.dart';

import 'translations_en.dart';
import 'translations_ko.dart';
import 'translations_vi.dart';

/// App localizations — provides translated strings based on current locale.
///
/// Usage:  S.of(context).appName
class S {
  S(this.locale) : _t = _loadTranslations(locale);

  final Locale locale;
  final Map<String, String> _t;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S(const Locale('en'));
  }

  static Map<String, String> _loadTranslations(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return translationsKo;
      case 'vi':
        return translationsVi;
      default:
        return translationsEn;
    }
  }

  String _get(String key) => _t[key] ?? translationsEn[key] ?? key;

  // ─── General ─────────────────────────────────────
  String get appName => _get('appName');
  String get appTagline => _get('appTagline');
  String get retry => _get('retry');
  String get cancel => _get('cancel');
  String get save => _get('save');
  String get or => _get('or');
  String get login => _get('login');
  String get signIn => _get('signIn');
  String get delete => _get('delete');
  String get refresh => _get('refresh');
  String get error => _get('error');

  // ─── Bottom Nav ──────────────────────────────────
  String get navHome => _get('navHome');
  String get navSearch => _get('navSearch');
  String get navWatchlist => _get('navWatchlist');
  String get navSettings => _get('navSettings');

  // ─── Auth ────────────────────────────────────────
  String get loginEmail => _get('loginEmail');
  String get loginPassword => _get('loginPassword');
  String get loginForgot => _get('loginForgot');
  String get loginButton => _get('loginButton');
  String get loginNoAccount => _get('loginNoAccount');
  String get loginSignUp => _get('loginSignUp');
  String get loginGoogle => _get('loginGoogle');
  String get registerTitle => _get('registerTitle');
  String get registerHeading => _get('registerHeading');
  String get registerSubtitle => _get('registerSubtitle');
  String get registerName => _get('registerName');
  String get registerPassword => _get('registerPassword');
  String get registerConfirmPassword => _get('registerConfirmPassword');
  String get registerPasswordHint => _get('registerPasswordHint');
  String get registerPasswordError => _get('registerPasswordError');
  String get registerConfirmError => _get('registerConfirmError');
  String get registerMismatchError => _get('registerMismatchError');
  String get registerButton => _get('registerButton');
  String get registerGoogle => _get('registerGoogle');
  String get registerHasAccount => _get('registerHasAccount');
  String get registerLogin => _get('registerLogin');
  String get forgotTitle => _get('forgotTitle');
  String get forgotHeading => _get('forgotHeading');
  String get forgotDescription => _get('forgotDescription');
  String get forgotButton => _get('forgotButton');
  String get forgotBackToLogin => _get('forgotBackToLogin');
  String get forgotCheckEmail => _get('forgotCheckEmail');
  String forgotEmailSent(String email) =>
      _get('forgotEmailSent').replaceAll('{email}', email);
  String get forgotTryAnother => _get('forgotTryAnother');

  // ─── Home ────────────────────────────────────────
  String get homeConnecting => _get('homeConnecting');
  String get popularStocks => _get('popularStocks');
  String get seeAll => _get('seeAll');
  String get noMarketData => _get('noMarketData');
  String get watchlist => _get('watchlist');
  String get loginToTrack => _get('loginToTrack');
  String get addStocksToWatchlist => _get('addStocksToWatchlist');
  String get topMovers => _get('topMovers');
  String get gainers => _get('gainers');
  String get losers => _get('losers');
  String get noDataAvailable => _get('noDataAvailable');
  String get latestNews => _get('latestNews');
  String get noNewsAvailable => _get('noNewsAvailable');
  String get marketOpen => _get('marketOpen');
  String get marketClosed => _get('marketClosed');

  // ─── Search ──────────────────────────────────────
  String get searchStocks => _get('searchStocks');
  String get recentSearches => _get('recentSearches');
  String get clear => _get('clear');
  String noResults(String query) =>
      _get('noResults').replaceAll('{query}', query);
  String get popularStocksSearch => _get('popularStocksSearch');

  // ─── Stock List ──────────────────────────────────
  String get allStocks => _get('allStocks');
  String get all => _get('all');
  String get sortChangePercent => _get('sortChangePercent');
  String get sortVolume => _get('sortVolume');
  String get sortName => _get('sortName');
  String get failedLoadStocks => _get('failedLoadStocks');
  String get noStocksFound => _get('noStocksFound');

  // ─── Watchlist ───────────────────────────────────
  String get watchlistEmpty => _get('watchlistEmpty');
  String get watchlistEmptySubtitle => _get('watchlistEmptySubtitle');
  String get signInToManageWatchlist => _get('signInToManageWatchlist');
  String get trackFavoriteStocks => _get('trackFavoriteStocks');
  String get dateAdded => _get('dateAdded');
  String get name => _get('name');
  String get changePercent => _get('changePercent');
  String get failedLoadWatchlist => _get('failedLoadWatchlist');
  String get failedRemoveWatchlist => _get('failedRemoveWatchlist');
  String removedFromWatchlist(String stockName) =>
      _get('removedFromWatchlist').replaceAll('{name}', stockName);
  String get undo => _get('undo');

  // ─── Stock Detail ────────────────────────────────
  String get failedLoadStock => _get('failedLoadStock');
  String get loginForWatchlist => _get('loginForWatchlist');
  String get tabChart => _get('tabChart');
  String get tabInfo => _get('tabInfo');
  String get tabAI => _get('tabAI');
  String get tabNews => _get('tabNews');

  // ─── Chart Tab ───────────────────────────────────
  String get minute => _get('minute');
  String get daily => _get('daily');
  String get weekly => _get('weekly');
  String get monthly => _get('monthly');
  String get candle => _get('candle');
  String get line => _get('line');
  String get area => _get('area');
  String loadingCandles(int count) =>
      _get('loadingCandles').replaceAll('{count}', '$count');
  String get noChartData => _get('noChartData');
  String get technicalIndicators => _get('technicalIndicators');
  String get technicalSummary => _get('technicalSummary');
  String get overbought => _get('overbought');
  String get oversold => _get('oversold');
  String get bullish => _get('bullish');
  String get bearish => _get('bearish');
  String get neutral => _get('neutral');
  String get above => _get('above');
  String get below => _get('below');

  // ─── Info Tab ────────────────────────────────────
  String get priceDetails => _get('priceDetails');
  String get dayRange => _get('dayRange');
  String get weekRange52 => _get('weekRange52');
  String get fundamentals => _get('fundamentals');
  String get open => _get('open');
  String get previousClose => _get('previousClose');
  String get dayHigh => _get('dayHigh');
  String get dayLow => _get('dayLow');
  String get volume => _get('volume');
  String get value => _get('value');
  String get marketCap => _get('marketCap');
  String get peRatio => _get('peRatio');
  String get pbRatio => _get('pbRatio');
  String get eps => _get('eps');
  String get divYield => _get('divYield');
  String get week52High => _get('week52High');
  String get week52Low => _get('week52Low');

  // ─── AI Tab ──────────────────────────────────────
  String get freePlan => _get('freePlan');
  String get signInForAI => _get('signInForAI');
  String analysesRemaining(int remaining, int limit) => _get('analysesRemaining')
      .replaceAll('{remaining}', '$remaining')
      .replaceAll('{limit}', '$limit');
  String freeAnalysesPerDay(int limit) =>
      _get('freeAnalysesPerDay').replaceAll('{limit}', '$limit');
  String remainingCredits(int remaining) =>
      _get('remainingCredits').replaceAll('{remaining}', '$remaining');
  String get aiBasicAnalysis => _get('aiBasicAnalysis');
  String get free => _get('free');
  String get aiBasicDescription => _get('aiBasicDescription');
  String get reAnalyze => _get('reAnalyze');
  String get loginForAI => _get('loginForAI');
  String get runBasicAnalysis => _get('runBasicAnalysis');
  String confidence(int value) =>
      _get('confidence').replaceAll('{value}', '$value');
  String get aiProAnalysis => _get('aiProAnalysis');
  String get pro => _get('pro');
  String get aiProDescription => _get('aiProDescription');
  String get proFeature1 => _get('proFeature1');
  String get proFeature2 => _get('proFeature2');
  String get proFeature3 => _get('proFeature3');
  String get proFeature4 => _get('proFeature4');
  String get loginForPro => _get('loginForPro');
  String get rerunPro => _get('rerunPro');
  String get runPro => _get('runPro');
  String get analyzingStock => _get('analyzingStock');
  String get processingIndicators => _get('processingIndicators');

  // ─── AI Terminal Cards & Tabs ─────────────────────
  String get aiMarketSentiment => _get('aiMarketSentiment');
  String get aiActionStrategy => _get('aiActionStrategy');
  String get aiInvestmentTiming => _get('aiInvestmentTiming');
  String get aiFutureForecast => _get('aiFutureForecast');
  String get aiSceScore => _get('aiSceScore');
  String get aiScoreExcellent => _get('aiScoreExcellent');
  String get aiScoreGood => _get('aiScoreGood');
  String get aiScoreNeutral => _get('aiScoreNeutral');
  String get aiScoreWeak => _get('aiScoreWeak');
  String get aiScorePoor => _get('aiScorePoor');
  String get aiTabStrategy => _get('aiTabStrategy');
  String get aiTabRisk => _get('aiTabRisk');
  String get aiTabTrend => _get('aiTabTrend');
  String get aiNoData => _get('aiNoData');
  String get aiSummary => _get('aiSummary');

  // ─── Settings ────────────────────────────────────
  String get settings => _get('settings');
  String get account => _get('account');
  String get planAndCredits => _get('planAndCredits');
  String get preferences => _get('preferences');
  String get theme => _get('theme');
  String get dark => _get('dark');
  String get light => _get('light');
  String get system => _get('system');
  String get language => _get('language');
  String get pushNotifications => _get('pushNotifications');
  String get priceAlerts => _get('priceAlerts');
  String get about => _get('about');
  String get appVersion => _get('appVersion');
  String get termsOfService => _get('termsOfService');
  String get privacyPolicy => _get('privacyPolicy');
  String get helpAndSupport => _get('helpAndSupport');
  String get logOut => _get('logOut');
  String get user => _get('user');
  String get accessFeatures => _get('accessFeatures');
  String credits(int count) =>
      _get('credits').replaceAll('{count}', '$count');
  String get basicPerDay => _get('basicPerDay');
  String get unlimitedBasic => _get('unlimitedBasic');
  String get upgradeToPro => _get('upgradeToPro');
  String get logOutConfirm => _get('logOutConfirm');

  // ─── Profile Edit ────────────────────────────────
  String get editProfile => _get('editProfile');
  String get fullName => _get('fullName');
  String get enterYourName => _get('enterYourName');
  String get email => _get('email');
  String get emailCannotChange => _get('emailCannotChange');
  String get changePassword => _get('changePassword');
  String get currentPassword => _get('currentPassword');
  String get newPassword => _get('newPassword');
  String get passwordMinChars => _get('passwordMinChars');
  String get dangerZone => _get('dangerZone');
  String get deleteAccountDesc => _get('deleteAccountDesc');
  String get deleteAccount => _get('deleteAccount');
  String get deleteAccountConfirm => _get('deleteAccountConfirm');
  String get profileUpdated => _get('profileUpdated');
  String get failedChangePassword => _get('failedChangePassword');
  String get failedDeleteAccount => _get('failedDeleteAccount');

  // ─── Splash ──────────────────────────────────────
  String get loadingMarketData => _get('loadingMarketData');

  /// Localization delegate — register in MaterialApp.
  static const LocalizationsDelegate<S> delegate = _SDelegate();
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ko', 'vi'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async => S(locale);

  @override
  bool shouldReload(_SDelegate old) => false;
}
