import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class WebUpdate {
  static String? _runningVersion;

  static bool get isSupported => true;

  /// Records the version of the bundle that is running now. Must be called at
  /// startup, before a newer deployment could replace version.json.
  static Future<void> init() async {
    _runningVersion ??= await _fetchDeployedVersion();
  }

  static Future<bool> hasNewVersion() async {
    final running = _runningVersion;
    if (running == null) return false;
    final deployed = await _fetchDeployedVersion();
    return deployed != null && deployed != running;
  }

  static void reload() => web.window.location.reload();

  static Future<String?> _fetchDeployedVersion() async {
    try {
      final url = 'version.json?t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await web.window
          .fetch(url.toJS, web.RequestInit(cache: 'no-store'))
          .toDart;
      if (!response.ok) return null;
      final body = (await response.text().toDart).toDart;
      final json = jsonDecode(body) as Map<String, dynamic>;
      return '${json['version']}+${json['build_number']}';
    } catch (_) {
      // Offline or mid-deploy: try again on the next check.
      return null;
    }
  }
}
