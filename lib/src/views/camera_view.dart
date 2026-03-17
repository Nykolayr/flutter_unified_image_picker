import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_unified_image_picker/flutter_unified_image_picker.dart';

class CameraView extends StatefulWidget {
  /// A full-screen camera view with integrated gallery bottom sheet.
  ///
  /// Responsibilities:
  /// - Display camera preview.
  /// - Toggle flash on/off.
  /// - Switch between available cameras.
  /// - Capture images.
  /// - Open the gallery bottom sheet to select existing images.
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late ImagePickerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImagePickerController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Camera Preview
          ValueListenableBuilder<bool>(
            valueListenable: _controller.cameraService.isReady,
            builder: (_, ready, __) {
              if (ready && _controller.cameraService.controller != null) {
                return CameraPreview(_controller.cameraService.controller!);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),

          // Flash button
          Positioned(
            top: 56,
            right: 16,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.cameraService.isFlashOn,
              builder:
                  (_, isFlash, __) => IconButton(
                    onPressed: _controller.toggleFlash,
                    icon: Icon(
                      isFlash ? Icons.flash_on : Icons.flash_off,
                      size: 20,
                      color: isFlash ? Colors.amber : Colors.white,
                    ),
                  ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Open Gallery Sheet
                IconButton(
                  onPressed: _controller.toggleBottomSheet,
                  icon: Container(
                    height: 48,
                    width: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Capture Image — серый круг, синий круг и белая иконка затвора в одном Stack по центру
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final path = await _controller.captureImage();
                      if (path != null && context.mounted) {
                        Navigator.pop(context, path);
                      }
                    },
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(
                            width: 64,
                            height: 64,
                            child: Center(
                              child: Icon(
                                Icons.camera,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Switch Camera
                IconButton(
                  onPressed: _controller.switchCamera,
                  icon: Container(
                    height: 48,
                    width: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cameraswitch,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 🖼️ Gallery Bottom Sheet
      bottomSheet: DraggableSheetWidget(controller: _controller),
    );
  }
}
