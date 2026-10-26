import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Returns the QR payload in [file], or `null` when none is found.
Future<String?> decodeQrFromImage(
  XFile file,
  MobileScannerController controller,
) async {
  final result = await controller.analyzeImage(file.path);
  return result?.barcodes.firstOrNull?.rawValue;
}
