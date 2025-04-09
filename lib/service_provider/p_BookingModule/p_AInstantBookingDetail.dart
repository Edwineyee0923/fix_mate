import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:fix_mate/services/upload_service.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';

class p_AInstantBookingDetail extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String seekerId;

  const p_AInstantBookingDetail({
    Key? key,
    required this.bookingId,
    required this.postId,
    required this.seekerId,
  }) : super(key: key);

  @override
  State<p_AInstantBookingDetail> createState() => _p_AInstantBookingDetailState();
}

class _p_AInstantBookingDetailState extends State<p_AInstantBookingDetail> {
  Map<String, dynamic>? bookingData;
  Map<String, dynamic>? instantPostData;
  String? seekerPhone;
  String? selectedSchedule; // 'preferred' or 'alternative'
  bool isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  List<String> _imageUrls = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _pickAndUploadImage() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      List<File> selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      setState(() => _images.addAll(selectedImages)); // ✅ Stores images

      UploadService uploadService = UploadService();
      for (var imageFile in selectedImages) {
        String? uploadedImageUrl = await uploadService.uploadImage(imageFile);
        if (uploadedImageUrl != null) {
          setState(() => _imageUrls.add(uploadedImageUrl));
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageUrls.removeAt(index); // ✅ Removes from the uploaded list
    });
  }

  Future<void> _onServiceCompleted() async {
    try {
      // Step 1: Find the booking doc by field
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docRef = snapshot.docs.first.reference;

        // Step 2: Update the document
        await docRef.update({
          'pCompleted': true,
          'sCompleted': false,
          'evidencePhotos': _imageUrls,
        });

        // Step 3: Notify the seeker
        await FirebaseFirestore.instance.collection('s_notifications').add({
          'seekerId': widget.seekerId,
          'providerId': instantPostData!['userId'],
          'bookingId': widget.bookingId,
          'postId': widget.postId,
          'title': 'Service Delivered',
          'message': 'Provider marked the service as completed. Please check the service evidence uploaded and complete the service.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ReusableSnackBar(
          context,
          "Service marked as completed! Waiting for seerker confirmation or auto-complete after three days ",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );

        Navigator.pop(context);
      } else {
        ReusableSnackBar(
          context,
          "Booking not found.",
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
        );
      }
    } catch (e) {
      ReusableSnackBar(
        context,
        "Failed to mark as completed. Please try again.",
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
      );
    }
  }

  Future<void> _fetchBookingDetails() async {
    try {
      // Fetch booking info
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        bookingData = snapshot.docs.first.data() as Map<String, dynamic>;
      }


      // Fetch IP post info
      DocumentSnapshot postSnap = await FirebaseFirestore.instance.collection('instant_booking').doc(widget.postId).get();
      if (postSnap.exists) {
        instantPostData = postSnap.data() as Map<String, dynamic>;
      }

      // Fetch provider phone
      DocumentSnapshot seekerSnap = await FirebaseFirestore.instance.collection('service_seekers').doc(widget.seekerId).get();
      if (seekerSnap.exists) {
        seekerPhone = seekerSnap['phone'];
      }

      setState(() {});
    } catch (e) {
      print("❌ Error fetching details: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    if (bookingData == null || instantPostData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ipImages = (instantPostData!["IPImage"] != null && instantPostData!["IPImage"] is List<dynamic>)
        ? List<String>.from(instantPostData!["IPImage"])
        : [];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor:  const Color(0xFF464E65),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Booking Summary Detail", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        titleSpacing: 5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Section
          if (ipImages.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => p_EditInstantPost(docId: widget.postId)),
                );
              },
              child: Column(
                children: [
                  Image.network(ipImages[0], height: 200, fit: BoxFit.cover),
                  const SizedBox(height: 10),
                  Text(instantPostData!["IPTitle"],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Details Section
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: bookingData!["bookingId"]));
              ReusableSnackBar(
                context,
                "Booking ID copied to clipboard!",
                icon: Icons.check_circle,
                iconColor: Colors.green,
              );
            },
            child: Text(
              "Booking ID: ${bookingData!["bookingId"]}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Text("Status: ${bookingData!["status"]}"),
          Text("Title: ${bookingData!["IPTitle"]}"),
          Text("Category: ${bookingData!["serviceCategory"]}"),
          Text("Final Schedule: ${bookingData!["finalDate"]}, ${bookingData!["finalTime"]}"),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: bookingData!["location"]));
              ReusableSnackBar(
                context,
                "Location copied to clipboard!",
                icon: Icons.check_circle,
                iconColor: Colors.green,
              );
            },
            child: Text(
              "Location: ${bookingData!["location"]}",
              // style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          Text("Price: RM ${bookingData!["price"]}"),
          const SizedBox(height: 12),
          if (seekerPhone != null)
            ElevatedButton.icon(
              onPressed: () async {
                final url = "https://wa.me/$seekerPhone";
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Contact Seeker via WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

          const SizedBox(height: 24),

          if (bookingData!['status'] == 'Active') ...[
            if ((bookingData!['pCompleted'] ?? false) == false)Container(
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF464E65),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Upload Service Evidence Photos (At least 3)",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // Upload area (dotted box)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    height: 170,
                    child: _images.isEmpty
                        ? GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: DottedBorder(
                        color: Color(0xFF464E65),
                        strokeWidth: 2,
                        dashPattern: const [8, 4],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade100,
                          ),
                          width: double.infinity,
                          height: 170,
                          alignment: Alignment.center,
                          child: Icon(Icons.add, size: 40, color: Color(0xFF464E65)),
                        ),
                      ),
                    )
                        : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => FullScreenImageViewer(
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _pickAndUploadImage,
                      child: const Text(
                        "Upload Service Picture",
                        style: TextStyle(
                          color: Color(0xFF464E65),
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  // Service Completed button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Opacity(
                      opacity: _images.length < 3 ? 0.4 : 1.0,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_images.length < 3) {
                            ReusableSnackBar(
                              context,
                              "Upload at least 3 service evidence photos to complete service.",
                              icon: Icons.warning_amber_rounded,
                              iconColor: Colors.orange,
                            );
                          } else {
                            _onServiceCompleted();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF464E65),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Service Completed",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            )
                else
                  const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                "✅ You have marked this service as completed.\nWaiting for seeker confirmation or auto-complete after three days.",
                style: TextStyle(
                  color: Colors.green,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ]

        ],
      ),
    );
  }
}