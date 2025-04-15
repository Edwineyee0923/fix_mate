import 'dart:io';
import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';
import 'package:fix_mate/services/upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';


class RefundEvidenceUpload extends StatefulWidget {
  final DocumentReference? bookingRef;
  final String bookingId;
  final String seekerId;

  const RefundEvidenceUpload({
    super.key,
    required this.bookingId,
    required this.seekerId,
    this.bookingRef, // optional
  });

  @override
  State<RefundEvidenceUpload> createState() => _RefundEvidenceUploadState();
}

class _RefundEvidenceUploadState extends State<RefundEvidenceUpload> {
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  List<String> _imageUrls = [];
  bool _isSubmitting = false;
  final GlobalKey _submitButtonKey = GlobalKey();
  bool _isUploading = false;

  // Future<void> _pickAndUploadImage() async {
  //   final List<XFile>? pickedFiles = await _picker.pickMultiImage();
  //
  //   if (pickedFiles != null && pickedFiles.isNotEmpty) {
  //     List<File> selectedImages = pickedFiles.map((file) => File(file.path))
  //         .toList();
  //     setState(() => _images.addAll(selectedImages));
  //
  //     UploadService uploadService = UploadService();
  //     for (var imageFile in selectedImages) {
  //       String? uploadedImageUrl = await uploadService.uploadImage(imageFile);
  //       if (uploadedImageUrl != null) {
  //         setState(() => _imageUrls.add(uploadedImageUrl));
  //       }
  //     }
  //   }
  // }
  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploading = true); // Start upload flag

    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        List<File> selectedImages = pickedFiles.map((file) => File(file.path)).toList();
        setState(() => _images.addAll(selectedImages));

        UploadService uploadService = UploadService();
        for (var imageFile in selectedImages) {
          String? uploadedImageUrl = await uploadService.uploadImage(imageFile);
          if (uploadedImageUrl != null) {
            setState(() => _imageUrls.add(uploadedImageUrl));
          }
        }
      }
    } finally {
      setState(() => _isUploading = false); // Always reset, even on error or cancel
    }
  }


  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _submitRefundEvidence() async {
    if (_imageUrls.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docRef = snapshot.docs.first.reference;

        await docRef.update({
          'refundEvidencePhotos': _imageUrls,
          'pCancelled': true,
          'status': 'Cancelled',
          'refundIssued': true,
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('s_notifications').add({
          'seekerId': widget.seekerId,
          'bookingId': widget.bookingId,
          'title': 'Cancellation Approved (Refunded) (#${widget.bookingId})',
          'message': 'Provider has approved your cancellation and uploaded refund evidence.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context, true); // ✅ Return success to parent
        }
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking not found.")),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _showPositionedSnackBar(BuildContext context) {
    final RenderBox? renderBox = _submitButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double bottomPosition = MediaQuery.of(context).size.height - offset.dy + 12;

    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: bottomPosition,
        left: 20,
        right: 20,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Upload at least one refund photo before submitting.",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext localContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Upload Refund Evidence",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              SizedBox(
                height: 170,
                child: _images.isEmpty
                    ? GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: DottedBorder(
                    color: const Color(0xFF464E65),
                    strokeWidth: 2,
                    dashPattern: const [8, 4],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: const Icon(Icons.add, size: 40, color: Color(
                          0xFF464E65)),
                    ),
                  ),
                )
                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      FullScreenImageViewer(
                                        images: _images,
                                        initialIndex: index,
                                      ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _images[index],
                                  width: 130,
                                  height: 170,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _pickAndUploadImage,
                child: const Text(
                  "Upload Refund Photo",
                  style: TextStyle(
                      color: Color(0xFF464E65),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600, fontSize: 14
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Opacity(
                  opacity: _images.isEmpty ? 0.4 : 1.0,
                  child: ElevatedButton(
                    key: _submitButtonKey,
                    // onPressed: _isSubmitting
                    //     ? null
                    //     : () {
                    //   if (_images.isEmpty) {
                    //     _showPositionedSnackBar(context);
                    //     return;
                    //   }
                    //    else {
                    //     _submitRefundEvidence();
                    //   }
                    // },
                    onPressed: _isSubmitting || _isUploading
                        ? null
                        : () {
                      final bool isReadyToSubmit = _images.isNotEmpty && _imageUrls.length == _images.length;

                      if (!isReadyToSubmit) {
                        _showPositionedSnackBar(context);
                        return;
                      }

                      _submitRefundEvidence();
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF464E65),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Submit Refund",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_isSubmitting || _isUploading) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }
}
