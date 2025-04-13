import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';


class FullScreenImageViewer extends StatefulWidget {
  final List<File>? images;         // Local
  final List<String>? imageUrls;    // Network
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    this.images,
    this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  double _scale = 0.0;

  bool get isNetwork => widget.imageUrls != null;

  @override
  void initState() {
    _pageController = PageController(initialPage: widget.initialIndex);
    Future.delayed(Duration.zero, () {
      setState(() => _scale = 1.0);
    });
    super.initState();
  }

  void _showSaveDialog(int index) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.black87),
                title: const Text("Save Image"),
                onTap: () async {
                  Navigator.pop(context);
                  await _saveImage(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.black87),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }



  Future<void> _saveImage(int index) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    bool hasPermission = false;
    if (sdkInt >= 33) {
      hasPermission = await Permission.photos.request().isGranted;
    } else {
      hasPermission = await Permission.storage.request().isGranted;
    }

    if (!hasPermission) {
      if (!mounted) return;
      showFloatingMessage(
        context,
        "Storage permission denied",
        icon: Icons.error_outline,
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/saved_image_$timestamp.jpg';

      if (isNetwork) {
        final url = widget.imageUrls![index];
        await Dio().download(url, filePath);
      } else {
        final originalFile = widget.images![index];
        await File(originalFile.path).copy(filePath);
      }

      await GallerySaver.saveImage(filePath);

      if (!mounted) return;
      showFloatingMessage(
        context,
        "Image saved to your phone gallery!",
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      debugPrint("Save error: $e");

      showFloatingMessage(
        context,
        "Failed to save image.",
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = isNetwork ? widget.imageUrls!.length : widget.images!.length;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: totalItems,
            itemBuilder: (context, index) {
              final imageProvider = isNetwork
                  ? NetworkImage(widget.imageUrls![index])
                  : FileImage(widget.images![index]) as ImageProvider;

              return GestureDetector(
                onLongPress: () => _showSaveDialog(index),
                child: PhotoView(
                  imageProvider: imageProvider,
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: GestureDetector(
                onTap: () {
                  setState(() => _scale = 0.0);
                  Future.delayed(const Duration(milliseconds: 150), () {
                    Navigator.of(context).pop();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.close, color: Colors.black, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

