class AppConstants {
  static const String appName = 'KanavuMeipada';
  static const String appVersion = '1.0.0';

  // API
  static const String apiBaseUrl = 'https://kanavumeipada-production.up.railway.app/api';
  static const String apiTimeoutSeconds = 30;

  // Firebase
  static const String firebaseProjectId = 'kanavumeipada';
  static const String firebaseAndroidApiKey = '';
  static const String firebaseWebApiKey = '';

  // Feature Flags
  static const bool enableAI = true;
  static const bool enableChallenges = true;
  static const bool enablePayments = false; // Until Razorpay integration

  // Limits
  static const int maxQuestionsPerTest = 50;
  static const int minQuestionsPerChallenge = 5;
  static const int maxChallengeEntryFee = 10000;
  static const int minChallengeEntryFee = 10;

  // Timings
  static const int sessionTimeout = 3600; // 1 hour
  static const int refreshTokenExpiry = 604800; // 7 days
  static const int streakResetHour = 23; // 11 PM IST

  // Monetization
  static const double platformCutPercentage = 0.15; // 15%
  static const double creatorRewardPercentage = 0.10; // 10%
  static const double creatorRatingBonusPercentage = 0.05; // Up to 5%
}
