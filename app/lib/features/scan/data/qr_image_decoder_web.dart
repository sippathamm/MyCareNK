import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:web/web.dart' as web;

import 'zxing_script.dart';

// Same script tag mobile_scanner uses for live scanning (its
// ZXingBarcodeReader.scriptId), so the library is fetched once.
const _zxingScriptId = 'mobile-scanner-barcode-reader';

// Phone photos are often 12MP+; ZXing is slow and less reliable on them.
const _maxDimension = 1600;

// ZXing enum values: DecodeHintType.POSSIBLE_FORMATS / TRY_HARDER,
// BarcodeFormat.QR_CODE.
const _hintPossibleFormats = 2;
const _hintTryHarder = 3;
const _formatQrCode = 11;

@JS('ZXing.BrowserMultiFormatReader')
extension type _ZXingReader._(JSObject _) implements JSObject {
  external factory _ZXingReader(JSObject? hints);
  external JSPromise<_ZXingResult> decodeFromImageUrl(String url);
}

extension type _ZXingResult._(JSObject _) implements JSObject {
  external String getText();
}

/// Returns the QR payload in [file], or `null` when none is found.
Future<String?> decodeQrFromImage(
  XFile file,
  MobileScannerController controller,
) async {
  await _ensureZXingLoaded();
  final imageUrl = await _downscaledDataUrl(file.path);
  try {
    final result = await _ZXingReader(
      _hints(),
    ).decodeFromImageUrl(imageUrl).toDart;
    return result.getText();
  } catch (_) {
    // ZXing rejects with NotFoundException when the image has no QR code.
    return null;
  }
}

JSObject _hints() {
  final map = (globalContext['Map'] as JSFunction)
      .callAsConstructor<JSObject>();
  map.callMethod(
    'set'.toJS,
    _hintPossibleFormats.toJS,
    [_formatQrCode.toJS].toJS,
  );
  map.callMethod('set'.toJS, _hintTryHarder.toJS, true.toJS);
  return map;
}

Future<void> _ensureZXingLoaded() async {
  if (globalContext.has('ZXing')) return;

  // mobile_scanner may have injected the script already and still be loading it.
  if (web.document.querySelector('script#$_zxingScriptId') != null) {
    for (var i = 0; i < 150 && !globalContext.has('ZXing'); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (globalContext.has('ZXing')) return;
    throw StateError('ZXing failed to load');
  }

  final completer = Completer<void>();
  final script = web.HTMLScriptElement()
    ..id = _zxingScriptId
    ..crossOrigin = 'anonymous'
    ..src = kZxingScriptUrl;
  script.onload = ((web.Event _) => completer.complete()).toJS;
  script.onerror = ((web.Event _) {
    script.remove();
    completer.completeError(StateError('ZXing failed to load'));
  }).toJS;
  web.document.head!.appendChild(script);
  await completer.future;
}

Future<String> _downscaledDataUrl(String src) async {
  final image = web.HTMLImageElement()..src = src;
  await image.decode().toDart;

  final width = image.naturalWidth;
  final height = image.naturalHeight;
  final scale = math.min(1.0, _maxDimension / math.max(width, height));
  final canvas = web.HTMLCanvasElement()
    ..width = (width * scale).round()
    ..height = (height * scale).round();
  (canvas.getContext('2d') as web.CanvasRenderingContext2D).drawImage(
    image,
    0,
    0,
    canvas.width,
    canvas.height,
  );
  return canvas.toDataURL('image/png');
}
