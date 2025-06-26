import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
import 'package:fix_mate/service_provider/p_ServiceDirectoryModule/p_InstantPostInfo.dart';
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
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fix_mate/services/AddressMapPreview.dart';

class p_ABookingDetail extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String seekerId;

  const p_ABookingDetail({
    Key? key,
    required this.bookingId,
    required this.postId,
    required this.seekerId,
  }) : super(key: key);

  @override
  State<p_ABookingDetail> createState() => _p_ABookingDetailState();
}

class _p_ABookingDetailState extends State<p_ABookingDetail> {
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

      setState(() {
        isUploading = true; // 🔁 Upload started
        _images.addAll(selectedImages);
      });

      UploadService uploadService = UploadService();
      List<String> newUrls = [];

      // Upload images one by one to ensure stability
      for (var imageFile in selectedImages) {
        final uploadedUrl = await uploadService.uploadImage(imageFile);
        if (uploadedUrl != null) {
          newUrls.add(uploadedUrl);
        }
      }

      setState(() {
        _imageUrls.addAll(newUrls);
        isUploading = false; // ✅ Upload completed
      });
    }
  }


  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageUrls.removeAt(index); // ✅ Removes from the uploaded list
    });
  }


  Future<void> _onServiceCompleted() async {
    if (isUploading) {
      ReusableSnackBar(
        context,
        "Please wait until all images are fully uploaded.",
        icon: Icons.warning,
        iconColor: Colors.orange,
      );
      return;
    }

    if (_imageUrls.length < 3) {
      ReusableSnackBar(
        context,
        "Upload at least 3 service evidence photos to complete the service.",
        icon: Icons.warning,
        iconColor: Colors.orange,
      );
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docRef = snapshot.docs.first.reference;

        await docRef.update({
          'pCompleted': true,
          'sCompleted': false,
          'evidencePhotos': _imageUrls,
          'updatedAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
          // 'autoCompleteAt': Timestamp.fromDate(
          //   DateTime.now().add(Duration(days: 7)), // ⏰ Auto-complete in 7 days
          // ),
          'autoCompleteAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(minutes: 1)),
          ),
        });

        await FirebaseFirestore.instance.collection('s_notifications').add({
          'seekerId': widget.seekerId,
          'providerId': instantPostData!['userId'],
          'bookingId': widget.bookingId,
          'postId': widget.postId,
          'title': 'Service Delivered\n(#${widget.bookingId})',
          'message': 'Provider marked the service as completed. Please check the service evidence uploaded and complete the service.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ReusableSnackBar(
          context,
          "Service marked as completed! Waiting for seeker confirmation or auto-complete after 7 days.",
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

    final ipImages = (instantPostData!["IPImage"] != null && instantPostData!["IPImage"] is List)
        ? List<String>.from(instantPostData!["IPImage"])
        : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF464E65),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Active Booking Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Header Card
            _buildServiceHeaderCard(ipImages),

            const SizedBox(height: 16),

            // Booking Summary Card
            _buildBookingSummaryCard(),

            const SizedBox(height: 16),

            // Contact Section
            if (seekerPhone != null) _buildContactSection(),
            if (bookingData!['status'] == 'Active') ...[
              if ((bookingData!['pCompleted'] ?? false) == false)
                _buildEvidenceUploadCard(),
              if ((bookingData!['pCompleted'] ?? false) == true &&
                  bookingData!['evidencePhotos'] != null &&
                  (bookingData!['evidencePhotos'] as List).isNotEmpty)
                _buildEvidencePreviewCard(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHeaderCard(List<String> ipImages) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          if (ipImages.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => p_InstantPostInfo(docId: widget.postId)),
                );
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(ipImages[0]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instantPostData!["IPTitle"] ?? "Service Title",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF464E65).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bookingData!["serviceCategory"] ?? "Category",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF464E65),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.receipt_long, color: Color(0xFF464E65), size: 24),
                SizedBox(width: 12),
                Text(
                  "Booking Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoRow(
              "Booking ID",
              bookingData!["bookingId"],
              icon: Icons.confirmation_number,
              copyable: true,
              copyMessage: "Booking ID copied to clipboard!",
            ),
            _buildInfoRow(
              "Status",
              bookingData!["status"],
              icon: Icons.info_outline,
              statusBadge: true,
            ),
            _buildScheduleInfoSection(),


            _buildInfoRow(
              "Location",
              bookingData!["location"],
              icon: Icons.location_on,
              copyable: true,
              copyMessage: "Location copied to clipboard!",
            ),

            // 📍 Google Map Preview
            if (bookingData!["location"] != null && bookingData!["location"].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: AddressMapPreview(
                  address: bookingData!["location"],
                  googleApiKey: 'AIzaSyAPpKIogJONJDDFRRCylib63OtTRliSDdc', // replace securely
                ),
              ),


            _buildInfoRow(
              "Total Price",
              "RM ${bookingData!["price"]}",
              icon: Icons.payments,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        IconData? icon,
        bool copyable = false,
        String? copyMessage,
        bool statusBadge = false,
        bool highlight = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: const Color(0xFF464E65)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 4),
                statusBadge
                    ? _buildStatusBadge(value)
                    : Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                    color: highlight
                        ? const Color(0xFF27AE60)
                        : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ReusableSnackBar(
                  context,
                  copyMessage ?? "Copied to clipboard!",
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 2),
                child: Icon(Icons.copy, size: 16, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = const Color(0xFF10B981); // green
        break;
      case 'active':
        backgroundColor = const Color(0xFF3B82F6); // blue
        break;
      case 'pending confirmation':
        backgroundColor = const Color(0xFFF39C12); // orange
        break;
      case 'cancelled':
        backgroundColor = const Color(0xFFE74C3C); // red
        break;
      default:
        backgroundColor = const Color(0xFF95A5A6); // grey
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }


  Widget _buildScheduleInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule, color: Color(0xFF464E65), size: 20),
              SizedBox(width: 8),
              Text(
                "Schedule Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildScheduleItem(
            "Final Schedule",
            "${bookingData!['finalDate']}, ${bookingData!['finalTime']}",
            isConfirmed: true,
          ),
        ],
      ),
    );
  }



  Widget _buildScheduleItem(String label, String dateTime, {bool isConfirmed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConfirmed ? const Color(0xFF464E65) : const Color(0xFF95A5A6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                Text(
                  dateTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF464E65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildContactSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.chat, color: Color(0xFF25D366), size: 24),
                SizedBox(width: 12),
                Text(
                  "Contact Seeker",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = "https://wa.me/$seekerPhone";
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Message via WhatsApp"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceUploadCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF464E65),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Text(
              "Upload Service Evidence Photos \n(At least 3)",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),

          // Upload area
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 40, color: Color(0xFF464E65)),
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Opacity(
              opacity: _images.length < 3 ? 0.4 : 1.0,
              child: ElevatedButton(
                onPressed: isUploading ? null : _onServiceCompleted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF464E65),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isUploading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
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
    );
  }


  Widget _buildEvidencePreviewCard() {
    final List<String> photos = List<String>.from(bookingData!['evidencePhotos']);
    final PageController _pageController = PageController();
    int _currentIndex = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF464E65),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Service Evidence Photos",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              CarouselSlider.builder(
                itemCount: photos.length,
                itemBuilder: (context, index, realIdx) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => FullScreenImageViewer(
                          imageUrls: photos,
                          initialIndex: index,
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        photos[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  onPageChanged: (index, reason) {
                    setState(() => _currentIndex = index);
                  },
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSmoothIndicator(
                    activeIndex: _currentIndex,
                    count: photos.length,
                    effect: const ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 6,
                      activeDotColor: Color(0xFF464E65),
                      dotColor: Colors.black26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${_currentIndex + 1}/${photos.length}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

// @override
  // Widget build(BuildContext context) {
  //   if (bookingData == null || instantPostData == null) {
  //     return const Scaffold(
  //       body: Center(child: CircularProgressIndicator()),
  //     );
  //   }
  //
  //   final ipImages = (instantPostData!["IPImage"] != null && instantPostData!["IPImage"] is List<dynamic>)
  //       ? List<String>.from(instantPostData!["IPImage"])
  //       : [];
  //
  //   return Scaffold(
  //     backgroundColor: const Color(0xFFFFF8F2),
  //     appBar: AppBar(
  //       backgroundColor:  const Color(0xFF464E65),
  //       leading: IconButton(
  //         icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
  //         onPressed: () {
  //           Navigator.pop(context);
  //         },
  //       ),
  //       title: const Text("Booking Summary Detail", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
  //       titleSpacing: 5,
  //     ),
  //     body: ListView(
  //       padding: const EdgeInsets.all(16),
  //       children: [
  //         // Top Section
  //         if (ipImages.isNotEmpty)
  //           GestureDetector(
  //             onTap: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => p_EditInstantPost(docId: widget.postId)),
  //               );
  //             },
  //             child: Column(
  //               children: [
  //                 Image.network(ipImages[0], height: 200, fit: BoxFit.cover),
  //                 const SizedBox(height: 10),
  //                 Text(instantPostData!["IPTitle"],
  //                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  //               ],
  //             ),
  //           ),
  //
  //         const SizedBox(height: 24),
  //
  //         // Details Section
  //         GestureDetector(
  //           onLongPress: () {
  //             Clipboard.setData(ClipboardData(text: bookingData!["bookingId"]));
  //             ReusableSnackBar(
  //               context,
  //               "Booking ID copied to clipboard!",
  //               icon: Icons.check_circle,
  //               iconColor: Colors.green,
  //             );
  //           },
  //           child: Text(
  //             "Booking ID: ${bookingData!["bookingId"]}",
  //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //           ),
  //         ),
  //         Text("Status: ${bookingData!["status"]}"),
  //         Text("Title: ${bookingData!["IPTitle"]}"),
  //         Text("Category: ${bookingData!["serviceCategory"]}"),
  //         Text("Final Schedule: ${bookingData!["finalDate"]}, ${bookingData!["finalTime"]}"),
  //         GestureDetector(
  //           onLongPress: () {
  //             Clipboard.setData(ClipboardData(text: bookingData!["location"]));
  //             ReusableSnackBar(
  //               context,
  //               "Location copied to clipboard!",
  //               icon: Icons.check_circle,
  //               iconColor: Colors.green,
  //             );
  //           },
  //           child: Text(
  //             "Location: ${bookingData!["location"]}",
  //             // style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //           ),
  //         ),
  //
  //         Text("Price: RM ${bookingData!["price"]}"),
  //         const SizedBox(height: 12),
  //         if (seekerPhone != null)
  //           ElevatedButton.icon(
  //             onPressed: () async {
  //               final url = "https://wa.me/$seekerPhone";
  //               if (await canLaunch(url)) {
  //                 await launch(url);
  //               }
  //             },
  //             icon: const Icon(Icons.chat_bubble_outline),
  //             label: const Text("Contact Seeker via WhatsApp"),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green,
  //               foregroundColor: Colors.white,
  //             ),
  //           ),
  //
  //         const SizedBox(height: 5),
  //
  //         if (bookingData!['status'] == 'Active') ...[
  //           if ((bookingData!['pCompleted'] ?? false) == false)Container(
  //             margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(20),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.1),
  //                   blurRadius: 4,
  //                   spreadRadius: 2,
  //                   offset: const Offset(0, 4),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.stretch,
  //               children: [
  //                 // Title bar
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
  //                   decoration: const BoxDecoration(
  //                     color: Color(0xFF464E65),
  //                     borderRadius: BorderRadius.only(
  //                       topLeft: Radius.circular(20),
  //                       topRight: Radius.circular(20),
  //                     ),
  //                   ),
  //                   child: const Text(
  //                     "Upload Service Evidence Photos (At least 3)",
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontWeight: FontWeight.w700,
  //                       fontSize: 15,
  //                       letterSpacing: 0.3,
  //                     ),
  //                   ),
  //                 ),
  //
  //                 // Upload area (dotted box)
  //                 Container(
  //                   margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
  //                   height: 170,
  //                   child: _images.isEmpty
  //                       ? GestureDetector(
  //                     onTap: _pickAndUploadImage,
  //                     child: DottedBorder(
  //                       color: Color(0xFF464E65),
  //                       strokeWidth: 2,
  //                       dashPattern: const [8, 4],
  //                       borderType: BorderType.RRect,
  //                       radius: const Radius.circular(12),
  //                       child: Container(
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(12),
  //                           color: Colors.grey.shade100,
  //                         ),
  //                         width: double.infinity,
  //                         height: 170,
  //                         alignment: Alignment.center,
  //                         child: Icon(Icons.add, size: 40, color: Color(0xFF464E65)),
  //                       ),
  //                     ),
  //                   )
  //                       : ListView.builder(
  //                     scrollDirection: Axis.horizontal,
  //                     itemCount: _images.length,
  //                     itemBuilder: (context, index) => Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 8),
  //                       child: Stack(
  //                         children: [
  //                           GestureDetector(
  //                             onTap: () {
  //                               showDialog(
  //                                 context: context,
  //                                 builder: (_) => FullScreenImageViewer(
  //                                   images: _images,
  //                                   initialIndex: index,
  //                                 ),
  //                               );
  //                             },
  //                             child: ClipRRect(
  //                               borderRadius: BorderRadius.circular(12),
  //                               child: Image.file(
  //                                 _images[index],
  //                                 width: 130,
  //                                 height: 170,
  //                                 fit: BoxFit.cover,
  //                               ),
  //                             ),
  //                           ),
  //
  //                           Positioned(
  //                             top: 6,
  //                             right: 6,
  //                             child: GestureDetector(
  //                               onTap: () => _removeImage(index),
  //                               child: Container(
  //                                 decoration: BoxDecoration(
  //                                   shape: BoxShape.circle,
  //                                   color: Colors.white,
  //                                   boxShadow: [
  //                                     BoxShadow(
  //                                       color: Colors.black26,
  //                                       blurRadius: 4,
  //                                     )
  //                                   ],
  //                                 ),
  //                                 padding: const EdgeInsets.all(4),
  //                                 child: const Icon(Icons.close, size: 16),
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 Center(
  //                   child: TextButton(
  //                     onPressed: _pickAndUploadImage,
  //                     child: const Text(
  //                       "Upload Service Picture",
  //                       style: TextStyle(
  //                         color: Color(0xFF464E65),
  //                         decoration: TextDecoration.underline,
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w800,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //
  //                 // Service Completed button
  //                 Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //                   child: Opacity(
  //                     opacity: _images.length < 3 ? 0.4 : 1.0,
  //                     child:
  //                     // ElevatedButton(
  //                     //   onPressed: () {
  //                     //     if (_images.length < 3) {
  //                     //       ReusableSnackBar(
  //                     //         context,
  //                     //         "Upload at least 3 service evidence photos to complete service.",
  //                     //         icon: Icons.warning_amber_rounded,
  //                     //         iconColor: Colors.orange,
  //                     //       );
  //                     //     } else {
  //                     //       _onServiceCompleted();
  //                     //     }
  //                     //   },
  //                     //   style: ElevatedButton.styleFrom(
  //                     //     backgroundColor: const Color(0xFF464E65),
  //                     //     shape: RoundedRectangleBorder(
  //                     //       borderRadius: BorderRadius.circular(25),
  //                     //     ),
  //                     //     padding: const EdgeInsets.symmetric(vertical: 14),
  //                     //   ),
  //                     //   child: const Text(
  //                     //     "Service Completed",
  //                     //     style: TextStyle(
  //                     //       fontSize: 16,
  //                     //       fontWeight: FontWeight.w600,
  //                     //       color: Colors.white,
  //                     //     ),
  //                     //   ),
  //                     // ),
  //
  //                     ElevatedButton(
  //                       onPressed: isUploading ? null : _onServiceCompleted,
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: const Color(0xFF464E65),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(25),
  //                         ),
  //                         padding: const EdgeInsets.symmetric(vertical: 14),
  //                       ),
  //                       child: isUploading
  //                           ? const SizedBox(
  //                         height: 20,
  //                         width: 20,
  //                         child: CircularProgressIndicator(
  //                           strokeWidth: 2,
  //                           color: Colors.white,
  //                         ),
  //                       )
  //                           : const Text(
  //                         "Service Completed",
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.white,
  //                         ),
  //                       ),
  //                     ),
  //
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           )
  //         ],
  //         if (bookingData!['status'] == 'Active' &&
  //             (bookingData!['pCompleted'] ?? false) == true &&
  //             bookingData!['evidencePhotos'] != null &&
  //             (bookingData!['evidencePhotos'] as List).isNotEmpty)
  //           Builder(
  //             builder: (context) {
  //               final List<String> photos = List<String>.from(bookingData!['evidencePhotos']);
  //               final PageController _pageController = PageController();
  //               int _currentIndex = 0;
  //
  //               return StatefulBuilder(
  //                 builder: (context, setState) {
  //                   return Column(
  //                     crossAxisAlignment: CrossAxisAlignment.stretch,
  //                     children: [
  //                       Container(
  //                         margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
  //                         decoration: BoxDecoration(
  //                           color: Colors.white,
  //                           borderRadius: BorderRadius.circular(20),
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: Colors.black.withOpacity(0.1),
  //                               blurRadius: 4,
  //                               spreadRadius: 2,
  //                               offset: const Offset(0, 4),
  //                             ),
  //                           ],
  //                         ),
  //                         child: Column(
  //                           children: [
  //                             // Header
  //                             Container(
  //                               padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
  //                               decoration: const BoxDecoration(
  //                                 color: Color(0xFF464E65),
  //                                 borderRadius: BorderRadius.only(
  //                                   topLeft: Radius.circular(20),
  //                                   topRight: Radius.circular(20),
  //                                 ),
  //                               ),
  //                               child: const Align(
  //                                 alignment: Alignment.centerLeft,
  //                                 child: Text(
  //                                   "Service Evidence Photos",
  //                                   style: TextStyle(
  //                                     color: Colors.white,
  //                                     fontWeight: FontWeight.w700,
  //                                     fontSize: 15,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                             const SizedBox(height: 10),
  //
  //                             // Carousel
  //                             CarouselSlider.builder(
  //                               itemCount: photos.length,
  //                               itemBuilder: (context, index, realIdx) {
  //                                 return GestureDetector(
  //                                   onTap: () {
  //                                     showDialog(
  //                                       context: context,
  //                                       builder: (_) => FullScreenImageViewer(
  //                                         imageUrls: photos,
  //                                         initialIndex: index,
  //                                       ),
  //                                     );
  //                                   },
  //                                   child: ClipRRect(
  //                                     borderRadius: BorderRadius.circular(16),
  //                                     child: Image.network(
  //                                       photos[index],
  //                                       width: double.infinity,
  //                                       fit: BoxFit.cover,
  //                                     ),
  //                                   ),
  //                                 );
  //                               },
  //                               options: CarouselOptions(
  //                                 height: 200,
  //                                 autoPlay: true,
  //                                 enlargeCenterPage: true,
  //                                 viewportFraction: 0.9,
  //                                 onPageChanged: (index, reason) {
  //                                   setState(() {
  //                                     _currentIndex = index;
  //                                   });
  //                                 },
  //                               ),
  //                             ),
  //
  //                             const SizedBox(height: 10),
  //
  //                             // Dots + Page Indicator
  //                             Row(
  //                               mainAxisAlignment: MainAxisAlignment.center,
  //                               children: [
  //                                 AnimatedSmoothIndicator(
  //                                   activeIndex: _currentIndex,
  //                                   count: photos.length,
  //                                   effect: const ExpandingDotsEffect(
  //                                     dotHeight: 8,
  //                                     dotWidth: 8,
  //                                     spacing: 6,
  //                                     activeDotColor: Color(0xFF464E65),
  //                                     dotColor: Colors.black26,
  //                                   ),
  //                                 ),
  //                                 const SizedBox(width: 10),
  //                                 Text(
  //                                   "${_currentIndex + 1}/${photos.length}",
  //                                   style: const TextStyle(
  //                                     fontSize: 14,
  //                                     color: Colors.black87,
  //                                     fontWeight: FontWeight.w500,
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                             const SizedBox(height: 10),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   );
  //                 },
  //               );
  //             },
  //           ),
  //       ],
  //     ),
  //   );
  // }
}