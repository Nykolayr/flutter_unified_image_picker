import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_unified_image_picker/src/controller/image_picker_controller.dart';

class DraggableSheetWidget extends StatelessWidget {
  final ImagePickerController controller;

  /// Если false — шторка остаётся (ручка, сворачивание), без сетки галереи.
  final bool showGallery;

  const DraggableSheetWidget({
    super.key,
    required this.controller,
    this.showGallery = true,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller.bottomSheetService.dragController,
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsetsDirectional.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showGallery)
                    const Text(
                      'Gallery',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                  else
                    const SizedBox.shrink(),
                  ValueListenableBuilder<bool>(
                    valueListenable: controller.bottomSheetService.isExpanded,
                    builder: (_, expanded, __) {
                      return IconButton(
                        onPressed: controller.toggleBottomSheet,
                        icon: Icon(
                          expanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: showGallery
                    ? ValueListenableBuilder<List<String>>(
                        valueListenable:
                            controller.galleryService.imagesNotifier,
                        builder: (_, images, __) {
                          if (images.isEmpty) {
                            return const Center(
                                child: Text("No images found"));
                          }
                          return GridView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: images.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemBuilder: (_, index) {
                              final path = images[index];
                              return GestureDetector(
                                onTap: () {
                                  if (controller
                                      .bottomSheetService.isExpanded.value) {
                                    Navigator.pop(context);
                                    Navigator.pop(context, path);
                                  } else {
                                    Navigator.pop(context, path);
                                  }
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      Image.file(File(path), fit: BoxFit.cover),
                                ),
                              );
                            },
                          );
                        },
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }
}
