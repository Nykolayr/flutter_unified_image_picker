import 'package:flutter/foundation.dart';
import 'package:flutter_unified_image_picker/src/services/bottom_sheet_service.dart';
import 'package:flutter_unified_image_picker/src/services/camera_service.dart';
import 'package:flutter_unified_image_picker/src/services/gallery_service.dart';

/// Controller that manages camera, gallery, and bottom sheet for the
/// image picker plugin.
class ImagePickerController extends ChangeNotifier {
  ImagePickerController({this.hideGalleryInSheet = false});

  /// Не грузить галерею; в шторке без сетки (режим фото «после»).
  final bool hideGalleryInSheet;

  final CameraService cameraService = CameraService();
  final GalleryService galleryService = GalleryService();
  final BottomSheetService bottomSheetService = BottomSheetService();

  Future<void> initialize() async {
    await cameraService.initCamera();
    cameraService.isReady.addListener(notifyListeners);
    cameraService.isFlashOn.addListener(notifyListeners);

    if (!hideGalleryInSheet) {
      await galleryService.loadGallery();
      galleryService.imagesNotifier.addListener(notifyListeners);
    }
  }

  Future<String?> captureImage() async {
    return await cameraService.captureImage();
  }

  Future<void> switchCamera() async {
    await cameraService.switchCamera();
  }

  void toggleFlash() {
    cameraService.toggleFlash();
  }

  void toggleBottomSheet() {
    bottomSheetService.toggleSheet();
    notifyListeners();
  }

  @override
  void dispose() {
    cameraService.dispose();
    galleryService.dispose();
    bottomSheetService.dispose();
    super.dispose();
  }
}
