import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';
import 'package:dotted_border/dotted_border.dart';

class MediaUploadService extends StatefulWidget {
  final Function(String, XFile) onPhotoUploaded;
  final Function(String, XFile) onVideoUploaded;


  final Function(bool)? onPhotoUploadingChanged;
  final Function(bool)? onVideoUploadingChanged;

  const MediaUploadService({
    Key? key,
    required this.onPhotoUploaded,
    required this.onVideoUploaded,
    this.onPhotoUploadingChanged,
    this.onVideoUploadingChanged,
  }) : super(key: key);

  @override
  State<MediaUploadService> createState() => _MediaUploadServiceState();
}

class _MediaUploadServiceState extends State<MediaUploadService> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _photoList = [];
  XFile? _video;
  VideoPlayerController? _videoController;
  bool _isUploadingPhoto = false;
  bool _isUploadingVideo = false;
  final int maxPhotos = 5;

  final String cloudName = "dj7uux8yz";
  final String uploadPreset = "profile_upload_preset";

  void _openFullScreenImage(File imageFile) {
    showDialog(
      context: context,
      builder: (_) => FullScreenImageViewer(
        images: [imageFile],
        initialIndex: 0,
      ),
    );
  }

  void _openFullScreenVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setModalState) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () {
                        _videoController!.pause();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                  setModalState(() {}); // 🧠 triggers rebuild to update play/pause icon
                },
                child: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.black,
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            ),
          ),
        ),
      );
    }
  }


  Future<String?> _uploadToCloudinary(File file, {required bool isVideo}) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/${isVideo ? 'video' : 'image'}/upload");

    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = json.decode(await response.stream.bytesToString());
      return responseData["secure_url"];
    } else {
      print("❌ Failed to upload ${isVideo ? 'video' : 'image'}");
      return null;
    }
  }



  Future<void> _pickAndUpload({required bool isPhoto}) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => MediaSourceDialog(isPhoto: isPhoto),
    );

    if (source == null) return;

    final XFile? file = isPhoto
        ? await _picker.pickImage(source: source)
        : await _picker.pickVideo(source: source);

    if (file != null) {
      setState(() {
        if (isPhoto) {
          _isUploadingPhoto = true;
          widget.onPhotoUploadingChanged?.call(true); // notify parent
        } else {
          _isUploadingVideo = true;
          widget.onVideoUploadingChanged?.call(true);
        }
      });

      final url = await _uploadToCloudinary(File(file.path), isVideo: !isPhoto);

      setState(() {
        if (isPhoto) {
          _isUploadingPhoto = false;
          widget.onPhotoUploadingChanged?.call(false);
        } else {
          _isUploadingVideo = false;
          widget.onVideoUploadingChanged?.call(false);
        }
      });

      if (url != null) {
        if (isPhoto) {
          setState(() => _photoList.add(file));
          widget.onPhotoUploaded(url, file);
        } else {
          _videoController?.dispose();
          _videoController = VideoPlayerController.network(url);
          await _videoController!.initialize();
          await _videoController!.setLooping(true);
          setState(() => _video = file);
          widget.onVideoUploaded(url, file);
        }
      }
    }
  }

  Widget _buildPhotoGrid() {
    List<Widget> items = _photoList.map((photo) {
      return Padding(
        padding: const EdgeInsets.only(right: 4.0, bottom: 8.0),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => _openFullScreenImage(File(photo.path)),
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: FileImage(File(photo.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => setState(() => _photoList.remove(photo)),
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    // Upload box with dashed border and internal remaining count
    if (_photoList.length < maxPhotos) {
      final remaining = maxPhotos - _photoList.length;

      items.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
          child: GestureDetector(
            onTap: () => _pickAndUpload(isPhoto: true),
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(10),
              dashPattern: [6, 4],
              color: Colors.grey,
              strokeWidth: 1,
              child: Container(
                width: 85,
                height: 85,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isUploadingPhoto
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Column(
                      children: [
                        const Icon(Icons.add_a_photo, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          "$remaining/$maxPhotos",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      children: items,
      spacing: 4,
      runSpacing: 6,
    );
  }

  Widget _buildVideoTile() {
    final bool hasVideo = _videoController != null && _videoController!.value.isInitialized;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: hasVideo
          ? GestureDetector(
        onTap: _openFullScreenVideo,
        child: Stack(
          alignment: Alignment.center, // Ensure centering works
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 85,
                height: 85,
                decoration: const BoxDecoration(color: Colors.black),
                child: VideoPlayer(_videoController!),
              ),
            ),
            // Overlay with semi-transparent black
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            // ✅ Play icon centered
            const Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Icon(Icons.play_circle_fill, size: 36, color: Colors.white),
              ),
            ),
            // Close icon at top-right
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  _videoController?.pause();
                  _videoController?.dispose();
                  setState(() {
                    _video = null;
                    _videoController = null;
                  });
                },
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      )
          : DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(10),
        dashPattern: [6, 4],
        color: Colors.grey,
        strokeWidth: 1,
        child: GestureDetector(
          onTap: () => _pickAndUpload(isPhoto: false),
          child: Container(
            width: 85,
            height: 85,
            alignment: Alignment.center,
            child: _isUploadingVideo
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.videocam, size: 30, color: Colors.grey),
                Text("1/1", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Add Photo and Video", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // ✅ Wrap photo + video in a horizontal scrollable row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_videoController != null && _videoController!.value.isInitialized)
                _buildVideoTile(),
                _buildPhotoGrid(), // this must return List<Widget>
              if (_videoController == null || !_videoController!.value.isInitialized)
                _buildVideoTile(), // show empty tile last if not uploaded yet
            ],
          ),
        ),


        const SizedBox(height: 10),
      ],
    );
  }

}

class MediaSourceDialog extends StatelessWidget {
  final bool isPhoto;

  const MediaSourceDialog({super.key, required this.isPhoto});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPhoto ? Icons.photo_camera : Icons.videocam,
              size: 60,
              color: const Color(0xFFfb9798),
            ),
            const SizedBox(height: 15),
            Text(
              isPhoto ? "Upload Photo" : "Upload Video",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Choose from:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, ImageSource.camera),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.camera_alt, color: Colors.black87),
                    label: const Text(
                      "Camera",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, ImageSource.gallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfb9798),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text(
                      "Gallery",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
