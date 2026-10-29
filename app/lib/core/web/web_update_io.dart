class WebUpdate {
  static bool get isSupported => false;
  static Future<void> init() async {}
  static Future<bool> hasNewVersion() async => false;
  static void reload() {}
}
