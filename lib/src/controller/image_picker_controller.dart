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

  /// false — один файл в шторке; true — несколько + плитка «+».
  final bool galleryMultiPick;

  final CameraService cameraService = CameraService();
  final GalleryService galleryService = GalleryService();
  final BottomSheetService bottomSheetService = BottomSheetService();

  Future<void> initialize() async {
    await cameraService.initCamera();
    cameraService.isReady.addListener(notifyListeners);
    cameraService.isFlashOn.addListener(notifyListeners);

    if (showGalleryInSheet) {
      galleryService.imagesNotifier.addListener(notifyListeners);
    }
  }

  /// Шторка с сеткой (Photo Picker → превью), без READ_MEDIA.
  bool get showGalleryInSheet => !hideGalleryInSheet;

  /// Системный picker → фото в сетке шторки.
  Future<void> pickGalleryForSheet() async {
    final paths = await galleryService.pickImages(
      allowMultiple: galleryMultiPick,
    );
    if (paths.isEmpty) return;

    if (galleryMultiPick) {
      galleryService.addImages(paths);
    } else {
      galleryService.imagesNotifier.value = <String>[paths.first];
    }
    notifyListeners();
    expandSheetIfCollapsed();
  }

  void expandSheetIfCollapsed() {
    if (!bottomSheetService.isExpanded.value) {
      bottomSheetService.expandSheet();
    }
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
