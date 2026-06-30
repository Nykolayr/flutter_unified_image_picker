import 'package:flutter/foundation.dart';
import 'package:flutter_unified_image_picker/src/services/bottom_sheet_service.dart';
import 'package:flutter_unified_image_picker/src/services/camera_service.dart';
import 'package:flutter_unified_image_picker/src/services/gallery_service.dart';

/// Controller that manages camera, gallery, and bottom sheet for the
/// image picker plugin.
class ImagePickerController extends ChangeNotifier {
  ImagePickerController({
    this.hideGalleryInSheet = false,
    this.galleryMultiPick = false,
  });

  /// Не показывать сетку галереи в шторке (только камера).
  final bool hideGalleryInSheet;

  /// false — один файл через системный picker; true — multi + сетка в шторке.
  final bool galleryMultiPick;

  final CameraService cameraService = CameraService();
  final GalleryService galleryService = GalleryService();
  final BottomSheetService bottomSheetService = BottomSheetService();

  Future<void> initialize() async {
    await cameraService.initCamera();
    cameraService.isReady.addListener(notifyListeners);
    cameraService.isFlashOn.addListener(notifyListeners);

    if (showGalleryGrid) {
      galleryService.imagesNotifier.addListener(notifyListeners);
    }
  }

  bool get showGalleryGrid => !hideGalleryInSheet && galleryMultiPick;

  /// Single: системный picker → первый path или null.
  Future<String?> pickSingleGalleryImage() async {
    final paths = await galleryService.pickImages(allowMultiple: false);
    if (paths.isEmpty) return null;
    return paths.first;
  }

  /// Multi: picker → добавить в сетку шторки.
  Future<void> pickMoreGalleryImages() async {
    final paths = await galleryService.pickImages(allowMultiple: true);
    galleryService.addImages(paths);
    notifyListeners();
  }

  Future<String?> captureImage() async {
    return cameraService.captureImage();
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
