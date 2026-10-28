import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'pwa_platform.dart';

const _dismissedKey = 'mycare.installGuideDismissed';

extension type _InstallPromptEvent._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> prompt();
  external JSPromise<_UserChoice> get userChoice;
}

extension type _UserChoice._(JSObject _) implements JSObject {
  external String get outcome;
}

class PwaInstall {
  /// True when running in a browser tab rather than from the home screen.
  static bool get isAvailable => !_isStandalone;

  static bool get _isStandalone {
    if (web.window.matchMedia('(display-mode: standalone)').matches) {
      return true;
    }
    // iOS Safari exposes only the legacy navigator.standalone flag.
    final standalone = web.window.navigator.getProperty<JSAny?>(
      'standalone'.toJS,
    );
    return standalone.isA<JSBoolean>() && (standalone as JSBoolean).toDart;
  }

  static PwaPlatform get platform {
    final ua = web.window.navigator.userAgent;
    if (RegExp('iPhone|iPad|iPod').hasMatch(ua)) return PwaPlatform.ios;
    // iPadOS reports a desktop Mac user agent; touch support gives it away.
    if (ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1) {
      return PwaPlatform.ios;
    }
    if (ua.contains('Android')) return PwaPlatform.android;
    return PwaPlatform.other;
  }

  /// In-app browsers (LINE, Facebook, Instagram) cannot add to home screen.
  static bool get isInAppBrowser => RegExp(
    r'Line/|FBAN|FBAV|Instagram',
  ).hasMatch(web.window.navigator.userAgent);

  // Captured by the beforeinstallprompt listener in web/index.html.
  static _InstallPromptEvent? get _deferredPrompt =>
      web.window.getProperty<JSObject?>('mycareInstallPrompt'.toJS)
          as _InstallPromptEvent?;

  static bool get canPromptInstall => _deferredPrompt != null;

  /// Shows the browser's install dialog. Returns true if the user accepted.
  static Future<bool> promptInstall() async {
    final event = _deferredPrompt;
    if (event == null) return false;
    await event.prompt().toDart;
    final choice = await event.userChoice.toDart;
    // A prompt event can only be used once.
    web.window.setProperty('mycareInstallPrompt'.toJS, null);
    return choice.outcome == 'accepted';
  }

  static bool get guideDismissed {
    try {
      return web.window.localStorage.getItem(_dismissedKey) == '1';
    } catch (_) {
      return false;
    }
  }

  static void dismissGuide() {
    try {
      web.window.localStorage.setItem(_dismissedKey, '1');
    } catch (_) {}
  }
}
