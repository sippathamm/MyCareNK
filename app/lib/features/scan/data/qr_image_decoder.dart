// Decodes a QR code from a picked image. mobile_scanner's analyzeImage() is
// unsupported on web, so the web build decodes with ZXing JS instead.
export 'qr_image_decoder_io.dart'
    if (dart.library.js_interop) 'qr_image_decoder_web.dart';
