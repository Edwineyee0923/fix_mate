import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

class ReviewVideoViewer {
  // 📸 Thumbnail generator
  static Future<Uint8List?> getThumbnail(String videoUrl) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.PNG,
        maxWidth: 128,
        quality: 75,
      );
    } catch (e) {
      debugPrint("Thumbnail generation failed: $e");
      return null;
    }
  }

  // 📽 Full-screen video viewer
  static void show(BuildContext context, String videoUrl) {
    final controller = VideoPlayerController.network(videoUrl);
    showDialog(
      context: context,
      builder: (_) => FutureBuilder(
        future: controller.initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          controller.setLooping(true);
          controller.play();

          return StatefulBuilder(
            builder: (context, setModalState) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: EdgeInsets.zero,
              child: Scaffold(
                backgroundColor: Colors.black,
                body: Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () {
                          controller.pause();
                          controller.dispose();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                    setModalState(() {});
                  },
                  child: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                  ),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              ),
            ),
          );
        },
      ),
    );
  }
}

// 🧩 Reusable widget to display thumbnail and handle tap
class ReviewVideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final double width;
  final double height;

  const ReviewVideoThumbnail({
    super.key,
    required this.videoUrl,
    this.width = 120,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: ReviewVideoViewer.getThumbnail(videoUrl),
      builder: (context, snapshot) {
        Widget content;

        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData && snapshot.data != null) {
          content = ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Image.memory(
                  snapshot.data!,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                ),
                const Positioned.fill(
                  child: Center(
                    child: Icon(Icons.play_circle_fill, size: 40, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        } else {
          content = Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.play_circle_fill, size: 40, color: Colors.white),
          );
        }

        return GestureDetector(
          onTap: () => ReviewVideoViewer.show(context, videoUrl),
          child: content,
        );
      },
    );
  }
}


class ReviewVideoPreview extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;

  const ReviewVideoPreview({
    Key? key,
    required this.videoUrl,
    this.width = 90,
    this.height = 90,
  }) : super(key: key);

  @override
  State<ReviewVideoPreview> createState() => _ReviewVideoPreviewState();
}

class _ReviewVideoPreviewState extends State<ReviewVideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ReviewVideoViewer.show(context, widget.videoUrl),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _isInitialized
                ? SizedBox(
              width: widget.width,
              height: widget.height,
              child: VideoPlayer(_controller),
            )
                : Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          const Icon(Icons.play_circle_fill, size: 40, color: Colors.white),
        ],
      ),
    );
  }
}

