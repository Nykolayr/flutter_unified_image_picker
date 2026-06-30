import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Системный Photo Picker / SAF — без READ_MEDIA и без permission_handler.
class GalleryService {
  static const MethodChannel _platform = MethodChannel('app.gallery/images');

  /// Пути выбранных в текущей сессии изображений (режим multi).
  final ValueNotifier<List<String>> imagesNotifier = ValueNotifier([]);

  /// Открывает системный picker. [allowMultiple] — один или несколько файлов.
  Future<List<String>> pickImages({required bool allowMultiple}) async {
    try {
      final List<dynamic> paths = await _platform.invokeMethod(
        'pickImages',
        <String, dynamic>{'allowMultiple': allowMultiple},
      );
      return paths.cast<String>();
    } on PlatformException catch (e) {
      debugPrint('GalleryService: pickImages failed: ${e.message}');
      return <String>[];
    }
  }

  void addImages(List<String> paths) {
    if (paths.isEmpty) return;
    imagesNotifier.value = <String>[...imagesNotifier.value, ...paths];
  }

  void dispose() {
    imagesNotifier.dispose();
  }
}
