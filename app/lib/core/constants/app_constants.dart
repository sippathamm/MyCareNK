abstract final class AppConstants {
  // Authentication
  static const String proxyEmailDomain = '@mycarenk.local';

  // Monthly quota limits (must match DB / business logic)
  static const int maxCondomQuota = 60;
  static const int maxLubricantQuota = 30;

  // Condom sizes offered (mm) — mirrors `condom_quantities` default in DB
  static const List<int> condomSizes = [49, 52, 54, 56];
}
