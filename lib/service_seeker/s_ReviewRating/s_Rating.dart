import 'package:fix_mate/services/MediaUploadService.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class s_Rating extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String providerId;

  const s_Rating({
    Key? key,
    required this.bookingId,
    required this.postId,
    required this.providerId,
  }) : super(key: key);

  @override
  State<s_Rating> createState() => _s_RatingState();
}

class _s_RatingState extends State<s_Rating> {
  int _rating = 5;
  int _quality = 5;
  int _responsiveness = 5;
  int _punctuality = 5;
  final TextEditingController _commentController = TextEditingController();
  Map<String, dynamic>? bookingData;
  Map<String, dynamic>? providerData;
  String? seekerName;
  String? seekerProfilePic;
  XFile? _selectedVideo;
  List<XFile> _photoList = [];
  List<String> _uploadedPhotoUrls = [];
  String? _uploadedVideoUrl;


  bool _isUploadingPhoto = false;
  bool _isUploadingVideo = false;



  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadSeekerData();
  }

  Future<void> _fetchData() async {
    try {
      final bookingQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (bookingQuery.docs.isNotEmpty) {
        bookingData = bookingQuery.docs.first.data() as Map<String, dynamic>;
      }

      final providerSnap = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.providerId)
          .get();

      if (providerSnap.exists) {
        providerData = providerSnap.data() as Map<String, dynamic>;
      }

      setState(() {});
    } catch (e) {
      print("❌ Error loading review data: $e");
    }
  }

  Future<void> _loadSeekerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final seekerDoc = await FirebaseFirestore.instance
          .collection('service_seekers')
          .doc(user.uid)
          .get();

      if (seekerDoc.exists) {
        final data = seekerDoc.data() as Map<String, dynamic>;
        setState(() {
          seekerName = data['name'];
          seekerProfilePic = data['profilePic'];
        });
      }
    }
  }

  Future<bool> _showLeaveDialog() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: "Leave this page?",
          message: "If you leave now, the changes you've made will be lost.",
          confirmText: "Leave",
          cancelText: "Stay",
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          confirmButtonColor: Colors.red,
          cancelButtonColor: Colors.grey.shade200,
          onConfirm: () {
            Navigator.of(context).pop(true); // Return true to indicate user confirmed
          },
        );
      },
    );

    return shouldLeave ?? false; // Return false by default if dialog is dismissed
  }



  Future<void> _submitReview() async {

    final wordCount = _commentController.text.trim().split(RegExp(r"\s+")).length;

    // Check for uploading state
    if (_isUploadingPhoto || _isUploadingVideo) {
      ReusableSnackBar(
          context,
          "Photo or video is still uploading. Please wait until finish uploading.",
          icon: Icons.warning,
          iconColor: Colors.orange);
      return;
    }

    // Check comment length
    if (wordCount > 50) {
      ReusableSnackBar(
          context,
          "Your feedback should not exceed 50 words.",
          icon: Icons.warning,
          iconColor: Colors.orange);
      return;
    }


    setState(() {
    });
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final serviceTitle = bookingData?['IPTitle'] ?? 'Service';
      final providerName = providerData?['name'] ?? 'Provider';

      final review = {
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'providerId': widget.providerId,
        'postId': widget.postId,
        'bookingId': widget.bookingId,
        'userId': userId,
        'userName': seekerName,
        'userProfilePic': seekerProfilePic,
        'providerName': providerName,
        'serviceTitle': serviceTitle,
        'reviewPhotoUrls': _uploadedPhotoUrls,
        'reviewVideoUrl': _uploadedVideoUrl,
        'quality': _quality,
        'responsiveness': _responsiveness,
        'punctuality': _punctuality,
      };

      await FirebaseFirestore.instance
          .collection('reviews')
          .add(review);

      Navigator.pop(context);
    } catch (e) {
      print("❌ Error submitting review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit review.")),
      );
    }
  }

  Widget _buildCriteria(String title, int value, Function(int) onRate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < value ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 30,
              ),
              onPressed: () => setState(() => onRate(index + 1)),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceTitle = bookingData?['IPTitle'] ?? 'Service';
    final providerName = providerData?['name'] ?? 'Provider';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfb9798),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () async {
            final shouldExit = await _showLeaveDialog();
            if (shouldExit) Navigator.pop(context);
          },
        ),
        title: const Text("Rate Service", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        titleSpacing: 5,
      ),
      body: bookingData == null || providerData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Service", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(serviceTitle, style: TextStyle(fontSize: 15)),
            const SizedBox(height: 15),
            Text("Provided by:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(providerName, style: TextStyle(fontSize: 15)),
            const SizedBox(height: 15),

            const Text("Overall Satisfaction", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),

            const SizedBox(height: 15),
            const Text("Upload Media", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            MediaUploadService(
              onPhotoUploaded: (url, file) {
                setState(() {
                  _photoList.add(file);
                  _uploadedPhotoUrls.add(url);
                });
              },
              onVideoUploaded: (url, file) {
                setState(() {
                  _uploadedVideoUrl = url;
                  _selectedVideo = file;
                });
              },
              onPhotoUploadingChanged: (uploading) {
                setState(() => _isUploadingPhoto = uploading);
              },
              onVideoUploadingChanged: (uploading) {
                setState(() => _isUploadingVideo = uploading);
              },
            ),
            const SizedBox(height: 10),
            const Text("Your Feedback", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              "(Maximum 50 words is allowed.)",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            LongInputContainer(
              controller: _commentController,
              placeholder: "Share thoughts on service to help other buyers.",
              maxWords: 50,
              height: 120,
              isRequired: false,
              width: double.infinity,
            ),

            const SizedBox(height: 24),
            const Text("Other Criteria (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildCriteria("Quality of Service", _quality, (val) => _quality = val),
            _buildCriteria("Responsiveness", _responsiveness, (val) => _responsiveness = val),
            _buildCriteria("Punctuality", _punctuality, (val) => _punctuality = val),

            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0), // Optional horizontal margin
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _rating > 0 ? _submitReview : null,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFfb9798),
                    side: const BorderSide(color: Color(0xFFfb9798), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
