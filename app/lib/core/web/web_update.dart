// Detects a newer deployment of the web build. Native builds update through
// AppVersionService (APK) instead.
export 'web_update_io.dart' if (dart.library.js_interop) 'web_update_web.dart';
