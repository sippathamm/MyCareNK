import 'pwa_platform.dart';

class PwaInstall {
  static bool get isAvailable => false;
  static PwaPlatform get platform => PwaPlatform.other;
  static bool get isInAppBrowser => false;
  static bool get canPromptInstall => false;
  static Future<bool> promptInstall() async => false;
  static bool get guideDismissed => true;
  static void dismissGuide() {}
}
