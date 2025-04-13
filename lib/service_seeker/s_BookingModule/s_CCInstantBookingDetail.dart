import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:flutter/services.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';

class s_CCInstantBookingDetail extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String providerId;

  const s_CCInstantBookingDetail({
    Key? key,
    required this.bookingId,
    required this.postId,
    required this.providerId,
  }) : super(key: key);

  @override
  State<s_CCInstantBookingDetail> createState() => _s_CCInstantBookingDetailState();
}

class _s_CCInstantBookingDetailState extends State<s_CCInstantBookingDetail> {
  Map<String, dynamic>? bookingData;
  Map<String, dynamic>? instantPostData;
  String? providerPhone;
  String? selectedSchedule; // 'preferred' or 'alternative'
  bool isSubmitting = false;
  bool isRescheduling = false;
  bool rescheduleSent = false;


  // Function to format timestamps
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    // DateTime dateTime = timestamp.toDate().add(const Duration(hours: 8));
    DateTime dateTime = timestamp.toDate();
    List<String> monthNames = ["Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ogo", "Sep", "Okt", "Nov", "Dis"];

    String hour = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12).toString(); // No padLeft here
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return "${dateTime.day.toString().padLeft(2, '0')} ${monthNames[dateTime.month - 1]} ${dateTime.year}, "
        "$hour:$minute $period";
  }

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
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
      DocumentSnapshot providerSnap = await FirebaseFirestore.instance.collection('service_providers').doc(widget.providerId).get();
      if (providerSnap.exists) {
        providerPhone = providerSnap['phone'];
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
      appBar: AppBar(
        backgroundColor: Color(0xFFfb9798),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Booking Summary Detail",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
                  MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: widget.postId)),
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
          Text("Preferred Schedule: ${bookingData!['preferredDate']}, ${bookingData!['preferredTime']}"),
          if (bookingData!["alternativeDate"] != null && bookingData!["alternativeTime"] != null) ...[
            Text("Alternative Schedule: ${bookingData!['alternativeDate']}, ${bookingData!['alternativeTime']}"),
          ],
          if (bookingData!['status'] == 'Cancelled')
            Text(
              "Cancelled At: ${formatTimestamp(bookingData!['cancelledAt'])}",
            ),          GestureDetector(
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
          if (providerPhone != null)
            ElevatedButton.icon(
              onPressed: () async {
                final url = "https://wa.me/$providerPhone";
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Contact Seller via WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            if (bookingData?['status'] == 'Cancelled') ...[
              Container(
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
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFfb9798),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Cancellation Details",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Cancellation Reason from Seeker:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              bookingData!["cancellationReason"] ?? "No reason provided.",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (bookingData?['refundIssued'] == true &&
                              bookingData?['refundEvidencePhotos'] != null &&
                              (bookingData!['refundEvidencePhotos'] as List).isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const Text(
                              "Refund Evidence Photos:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final List<String> photos = List<String>.from(bookingData!['refundEvidencePhotos']);
                                int _currentIndex = 0;

                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => FullScreenImageViewer(
                                                imageUrls: photos,
                                                initialIndex: _currentIndex,
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: SizedBox(
                                              height: 200, // fixed display height
                                              width: double.infinity,
                                              child: Image.network(
                                                photos[_currentIndex],
                                                fit: BoxFit.cover, // or BoxFit.contain for full image within bounds
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return const Center(child: CircularProgressIndicator());
                                                },
                                                errorBuilder: (context, error, stackTrace) =>
                                                const Center(child: Icon(Icons.broken_image)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Center(
                                          child: Text(
                                            "${_currentIndex + 1}/${photos.length}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],

                          const SizedBox(height: 18),
                          const Text(
                            "Cancellation Requested At:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              formatTimestamp(bookingData?['cancelledRequestedAt']),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            "Cancellation Completed At:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              formatTimestamp(bookingData?['cancelledAt']),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              )
            ]
          ],
      ),
    );
  }
}
