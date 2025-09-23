import 'package:flutter/services.dart';
import '../models/media_asset.dart';

class GalleryPickerService {
  static const MethodChannel _channel = MethodChannel('custom_photovideo_picker/gallery');


  static Future openGalleryPicker() async {
    try {
      print("Flutter: Calling native openGalleryPicker method");
      final dynamic rawResult = await _channel.invokeMethod('openGalleryPicker');
      print(rawResult);

    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') {
        return null; // User cancelled
      }
      rethrow;
    }
  }

  /// Calculates the total duration of selected media assets
  static int calculateTotalDuration(List<MediaAsset> assets) {
    return assets.fold(0, (total, asset) => total + asset.duration);
  }

  /// Checks if the total duration is within valid limits (5 seconds to 20 minutes)
  static bool isValidDuration(List<MediaAsset> assets) {
    final totalDuration = calculateTotalDuration(assets);
    return totalDuration >= 5 && totalDuration <= 1200; // 5 seconds to 20 minutes
  }

  /// Formats the total duration as mm:ss
  static String formatTotalDuration(List<MediaAsset> assets) {
    final totalDuration = calculateTotalDuration(assets);
    final minutes = totalDuration ~/ 60;
    final seconds = totalDuration % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
