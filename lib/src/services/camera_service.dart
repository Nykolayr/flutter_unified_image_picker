import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Service that manages the device camera for the media picker.
///
/// Responsibilities:
/// - Initialize the camera and maintain a preview.
/// - Capture images.
/// - Switch between available cameras (front/back/other lenses).
/// - Toggle flash mode.
/// - Notify listeners about camera readiness and flash state.
class CameraService {
  /// The internal camera controller.
  CameraController? _cameraController;

  /// List of available cameras on the device.
  List<CameraDescription>? _cameras;

  /// Index of the currently selected camera.
  int _selectedCamera = 0;

  /// Notifies when the camera is initialized and ready.
  final ValueNotifier<bool> isReady = ValueNotifier(false);

  /// Notifies the current flash state (on/off).
  final ValueNotifier<bool> isFlashOn = ValueNotifier(false);

  /// Returns the current [CameraController].
  CameraController? get controller => _cameraController;

  /// Initializes the camera.
  ///
  /// - Loads all available cameras.
  /// - Initializes the camera controller for the selected camera.
  /// - Sets [isReady] to true when initialization is complete.
  Future<void> initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) return;

    _cameraController = CameraController(
      _cameras![_selectedCamera],
      ResolutionPreset.high,
      enableAudio: false, // только фото — не запрашиваем микрофон/видео
    );

    await _cameraController!.initialize();
    isReady.value = true;
  }

  /// Switches to the next available camera.
  ///
  /// Supports front, back, or other lenses if available.
  /// Resets [isReady] to false during re-initialization.
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCamera = (_selectedCamera + 1) % _cameras!.length;
    isReady.value = false;
    await initCamera();
  }

  /// Toggles the camera flash between on and off.
  ///
  /// Updates [isFlashOn] and sets the camera flash mode accordingly.
  void toggleFlash() {
    isFlashOn.value = !isFlashOn.value;
    _cameraController?.setFlashMode(
      isFlashOn.value ? FlashMode.torch : FlashMode.off,
    );
  }

  /// Captures an image using the current camera.
  ///
  /// Returns the file path of the captured image or `null` if capture failed.
  Future<String?> captureImage() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return null;
      }
      final imageFile = await _cameraController!.takePicture();
      return imageFile.path;
    } catch (e) {
      debugPrint('Camera capture failed: $e');
      return null;
    }
  }

  /// Disposes the camera controller and all notifiers.
  void dispose() {
    _cameraController?.dispose();
    isReady.dispose();
    isFlashOn.dispose();
  }
}
