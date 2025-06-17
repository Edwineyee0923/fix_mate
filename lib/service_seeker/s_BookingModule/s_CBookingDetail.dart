import 'package:fix_mate/service_seeker/s_BookingModule/s_BookingHistory.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:flutter/services.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class s_CBookingDetail extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String providerId;

  const s_CBookingDetail({
    Key? key,
    required this.bookingId,
    required this.postId,
    required this.providerId,
  }) : super(key: key);

  @override
  State<s_CBookingDetail> createState() => _s_CBookingDetailState();
}

class _s_CBookingDetailState extends State<s_CBookingDetail> {
  Map<String, dynamic>? bookingData;
  Map<String, dynamic>? instantPostData;
  String? providerPhone;

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

  String _formatDate(String date) {
    try {
      DateTime dt = DateTime.parse(date);
      return "${dt.day} ${_monthName(dt.month)} ${dt.year}";
    } catch (_) {
      return date;
    }
  }

  String _formatTime(String time) {
    try {
      TimeOfDay t = TimeOfDay(
        hour: int.parse(time.split(":")[0]),
        minute: int.parse(time.split(":")[1]),
      );
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      return TimeOfDay.fromDateTime(dt).format(context);
    } catch (_) {
      return time;
    }
  }

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

  String _monthName(int month) {
    const months = ["Jan", "Feb", "Mac", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
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
  //     appBar: AppBar(
  //       backgroundColor: Color(0xFFfb9798),
  //       leading: IconButton(
  //         icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
  //         onPressed: () => Navigator.pop(context),
  //       ),
  //       title: Text(
  //         "Instant Booking Detail",
  //         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
  //       ),
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
  //                 MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: widget.postId)),
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
  //         if (bookingData!['status'] == 'Completed' && bookingData!['completedAt'] != null)
  //           Text(
  //             "Completed At: ${formatTimestamp(bookingData!['completedAt'])}",
  //           ),
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
  //         Text("Price: RM ${bookingData!["price"]}"),
  //         const SizedBox(height: 12),
  //         if (providerPhone != null)
  //           ElevatedButton.icon(
  //             onPressed: () async {
  //               final url = "https://wa.me/$providerPhone";
  //               if (await canLaunch(url)) {
  //                 await launch(url);
  //               }
  //             },
  //             icon: const Icon(Icons.chat_bubble_outline),
  //             label: const Text("Contact Seller via WhatsApp"),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green,
  //               foregroundColor: Colors.white,
  //             ),
  //           ),
  //
  //           Builder(
  //             builder: (context) {
  //               final List<String> photos = List<String>.from(bookingData!['evidencePhotos']);
  //               final PageController _pageController = PageController();
  //               int _currentIndex = 0;
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
  //                                 color: Color(0xFFfb9798),
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
  //                                     activeDotColor: Color(0xFFfb9798),
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

  @override
  Widget build(BuildContext context) {
    if (bookingData == null || instantPostData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ipImages = (instantPostData!["IPImage"] != null && instantPostData!["IPImage"] is List)
        ? (instantPostData!["IPImage"] as List).map((e) => e.toString()).toList()
        : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfb9798),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Complete Booking Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 2,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceHeaderCard(ipImages),
            const SizedBox(height: 16),
            _buildBookingInfoCard(),
            const SizedBox(height: 16),
            if (providerPhone != null) _buildContactSection(),
            const SizedBox(height: 2),
            _buildViewEvidence(),
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
                  MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: widget.postId)),
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfb9798).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bookingData!["serviceCategory"] ?? "Category",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFfb9798),
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


  Widget _buildBookingInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.receipt_long, color: Color(0xFFfb9798), size: 24),
                SizedBox(width: 12),
                Text(
                  "Booking Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFfb9798),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Booking ID
            _buildInfoRow(
              "Booking ID",
              bookingData!["bookingId"],
              icon: Icons.confirmation_number,
              copyable: true,
              copyMessage: "Booking ID copied to clipboard!",
            ),

            // Status
            _buildInfoRow(
              "Status",
              bookingData!["status"],
              icon: Icons.info_outline,
              statusBadge: true,
            ),

            // Schedule Information
            _buildScheduleInfo(),

            // Location
            _buildInfoRow(
              "Location",
              bookingData!["location"],
              icon: Icons.location_on,
              copyable: true,
              copyMessage: "Location copied to clipboard!",
            ),

            // Price
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
            Icon(icon, size: 20, color: const Color(0xFFfb9798)),
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
                    color: highlight ? const Color(0xFFfb9798) : const Color(0xFF2C3E50),
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


  Widget _buildScheduleInfo() {
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
              Icon(Icons.schedule, color: Color(0xFFfb9798), size: 20),
              SizedBox(width: 8),
              Text(
                "Schedule Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFfb9798),
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

          // Completed at (if available)
          if (bookingData!['completedAt'] != null)
            _buildScheduleItem(
              "Completed At",
              formatTimestamp(bookingData!['completedAt']),
              isConfirmed: true, // ✅ Add this!
            ),
        ],
      ),
    );
  }


  Widget _buildScheduleItem(String label, String dateTime, {bool isPrimary = false, bool isConfirmed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConfirmed ? const Color(0xFFfb9798) :
              isPrimary ? const Color(0xFFfb9798) : const Color(0xFF95A5A6),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isConfirmed ? const Color(0xFFfb9798) : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = const Color(0xFF10B981); // Modern emerald green
        textColor = Colors.white;
        break;
      case 'active':
        backgroundColor = const Color(0xFF3B82F6); // Bright blue
        textColor = Colors.white;
        break;
      case 'pending confirmation':
        backgroundColor = const Color(0xFFF39C12);
        textColor = Colors.white;
        break;
      case 'cancelled':
        backgroundColor = const Color(0xFFE74C3C);
        textColor = Colors.white;
        break;
      default:
        backgroundColor = const Color(0xFF95A5A6);
        textColor = Colors.white;
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
                  "Contact Provider",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = "https://wa.me/$providerPhone";
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

  Widget _buildViewEvidence() {
    if (bookingData!['evidencePhotos'] == null ||
        (bookingData!['evidencePhotos'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    return Builder(
      builder: (context) {
        final List<String> photos = List<String>.from(bookingData!['evidencePhotos']);
        final PageController _pageController = PageController();
        int _currentIndex = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFfb9798),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
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

                      // Carousel
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
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Dots + Page Indicator
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
                              activeDotColor: Color(0xFFfb9798),
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
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


}
