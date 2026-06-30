import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_unified_image_picker/flutter_unified_image_picker.dart';

class CameraView extends StatefulWidget {
  /// Камера на весь экран + кнопка галереи (системный Photo Picker).
  ///
  /// [galleryMultiPick] false (по умолчанию): без шторки, галерея → сразу [path].
  /// [galleryMultiPick] true: шторка с сеткой после multi-picker (другие приложения).
  /// [hideGalleryInSheet] устарел по смыслу — шторки нет; галерея по кнопке.
  const CameraView({
    super.key,
    this.hideGalleryInSheet = false,
    this.galleryMultiPick = false,
  });

  final bool hideGalleryInSheet;
  final bool galleryMultiPick;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late ImagePickerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImagePickerController(
      hideGalleryInSheet: widget.hideGalleryInSheet,
      galleryMultiPick: widget.galleryMultiPick,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onGalleryPressed() async {
    if (_controller.usesGallerySheet) {
      _controller.expandSheetIfCollapsed();
      await _controller.pickGalleryForSheet();
      return;
    }
    final path = await _controller.pickSingleFromGallery();
    if (path != null && mounted) {
      Navigator.pop(context, path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _controller.cameraService.isReady,
            builder: (_, ready, __) {
              if (ready && _controller.cameraService.controller != null) {
                return CameraPreview(_controller.cameraService.controller!);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          Positioned(
            top: 56,
            right: 16,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.cameraService.isFlashOn,
              builder: (_, isFlash, __) => IconButton(
                onPressed: _controller.toggleFlash,
                icon: Icon(
                  isFlash ? Icons.flash_on : Icons.flash_off,
                  size: 20,
                  color: isFlash ? Colors.amber : Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _onGalleryPressed,
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
      bottomSheet: _controller.usesGallerySheet
          ? DraggableSheetWidget(
              controller: _controller,
              onPickFromGallery: _controller.pickGalleryForSheet,
            )
          : null,
    );
  }
}
