// Installing the web build as a PWA ("Add to Home Screen"). Native builds are
// already installed apps, so the io implementation reports nothing to do.
export 'pwa_install_io.dart'
    if (dart.library.js_interop) 'pwa_install_web.dart';
export 'pwa_platform.dart';
