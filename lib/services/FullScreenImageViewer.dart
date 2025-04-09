// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:photo_view/photo_view.dart';
//
// class FullScreenImageViewer extends StatefulWidget {
//   final List<File> images;
//   final int initialIndex;
//
//   const FullScreenImageViewer({
//     Key? key,
//     required this.images,
//     required this.initialIndex,
//   }) : super(key: key);
//
//   @override
//   State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
// }
//
// class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
//   late PageController _pageController;
//
//   @override
//   void initState() {
//     _pageController = PageController(initialPage: widget.initialIndex);
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.black,
//       insetPadding: EdgeInsets.zero,
//       child: Stack(
//         children: [
//           PageView.builder(
//             controller: _pageController,
//             itemCount: widget.images.length,
//             itemBuilder: (context, index) {
//               return PhotoView(
//                 imageProvider: FileImage(widget.images[index]),
//                 backgroundDecoration: const BoxDecoration(color: Colors.black),
//               );
//             },
//           ),
//           Positioned(
//             top: 40,
//             right: 20,
//             child: GestureDetector(
//               onTap: () => Navigator.of(context).pop(),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 8,
//                       offset: Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.all(6),
//                 child: const Icon(
//                   Icons.close,
//                   color: Colors.black,
//                   size: 22,
//                 ),
//               ),
//             ),
//           ),
//
//         ],
//       ),
//     );
//   }
// }


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<File>? images;         // Local
  final List<String>? imageUrls;    // Network
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    this.images,
    this.imageUrls,
    required this.initialIndex,
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

              return PhotoView(
                imageProvider: imageProvider,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
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

