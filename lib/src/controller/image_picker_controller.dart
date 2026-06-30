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

  final bool hideGalleryInSheet;
  final bool galleryMultiPick;

  final CameraService cameraService = CameraService();
  final GalleryService galleryService = GalleryService();
  final BottomSheetService bottomSheetService = BottomSheetService();

  /// Шторка только в multi-режиме без [hideGalleryInSheet].
  bool get usesGallerySheet => galleryMultiPick && !hideGalleryInSheet;

  Future<void> initialize() async {
    await cameraService.initCamera();
    cameraService.isReady.addListener(notifyListeners);
    cameraService.isFlashOn.addListener(notifyListeners);

    if (usesGallerySheet) {
      galleryService.imagesNotifier.addListener(notifyListeners);
    }
  }

  /// Один файл через системный Photo Picker.
  Future<String?> pickSingleFromGallery() async {
    final paths = await galleryService.pickImages(allowMultiple: false);
    if (paths.isEmpty) return null;
    return paths.first;
  }

  /// Multi: picker → сетка в шторке.
  Future<void> pickGalleryForSheet() async {
    final paths = await galleryService.pickImages(allowMultiple: true);
    if (paths.isEmpty) return;
    galleryService.addImages(paths);
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
