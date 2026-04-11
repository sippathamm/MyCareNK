abstract final class AppConstants {
  // Authentication
  static const String proxyEmailDomain = '@mycarenk.local';

  // Monthly quota limits (must match DB / business logic)
  static const int maxCondomQuota = 60;
  static const int maxLubricantQuota = 30;

  // Condom sizes offered (mm) — mirrors `condom_quantities` default in DB
  static const List<int> condomSizes = [49, 52, 54, 56];

  // Service centers — mirrors `service_center` enum in DB
  static const List<String> serviceCenters = [
    'รพ.โพนพิสัย',
    'รพ.สต.วัดหลวง',
    'อบต.วัดหลวง',
    'สสจ.หนองคาย',
  ];

  // Available pickup times
  static const List<String> pickupTimes = ['10:00', '14:00'];
}
