import 'package:fix_mate/service_provider/p_BookingModule/p_AInstantBookingDetail.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_CCInstantBookingDetail.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_CInstantBookingDetail.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_Notification.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_PInstantBookingDetail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/service_provider/p_layout.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class p_BookingHistory extends StatefulWidget {
  static String routeName = "/provider/p_BookingHistory";

  final int initialTabIndex;

  const p_BookingHistory({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  _p_BookingHistoryState createState() => _p_BookingHistoryState();
}

class _p_BookingHistoryState extends State<p_BookingHistory> {
  String? providerId;
  int _selectedIndex = 0;
  final List<String> statuses = ["Pending Confirmation", "Active", "Completed", "Cancelled"];
  final ScrollController _tabScrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    providerId = user?.uid;
    _selectedIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Estimate the width of each button + padding (adjust if needed)
      final buttonWidth = 120.0;
      _tabScrollController.animateTo(
        _selectedIndex * buttonWidth,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });

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

  Color getStatusColor(Map<String, dynamic> data, bool isActive) {
    if (data['status'] == "Completed") return Colors.green;

    // Cancelled - Refunded
    if (data['status'] == "Cancelled" && (data['refundIssued'] ?? false) == true) {
      return Colors.redAccent; // or another color indicating success
    }

    // Cancelled - Rejected (no refund)
    if (data['status'] == "Cancelled" && (data['refundIssued'] ?? false) == false) {
      return Colors.redAccent;
    }

    // Cancellation Requested
    if (data['status'] == "Pending Confirmation" &&
        (data['sCancelled'] ?? false) == true &&
        (data['isRescheduling'] ?? false) == false) {
      return Colors.redAccent;
    }

    if (data['isRescheduling'] == true) return Colors.amber;

    if (data['pCompleted'] == true && data['status'] != "Completed") return Colors.orange;

    if (isActive) return Colors.green;

    return const Color(0xFFfb9798); // Fallback
  }


  String getStatusLabel(Map<String, dynamic> data, bool isActive) {
    if (data['status'] == "Completed") return "Service Completed";

    // Cancelled - Refunded
    if (data['status'] == "Cancelled" && (data['refundIssued'] ?? false) == true) {
      return "Cancelled - Refunded";
    }

    // Cancelled - No refund
    if (data['status'] == "Cancelled" && (data['refundIssued'] ?? false) == false) {
      return "Cancelled - Refund Rejected";
    }

    // Cancellation Requested
    if (data['status'] == "Pending Confirmation" &&
        (data['sCancelled'] ?? false) == true &&
        (data['isRescheduling'] ?? false) == false) {
      return "Cancellation Requested";
    }

    if (data['isRescheduling'] == true) return "Booking Rescheduled";

    if (data['pCompleted'] == true && data['status'] != "Completed") return "Awaiting Service Completion";

    if (isActive) return "Service Schedule Confirmed";

    return "New Order Assigned";
  }



  @override
  Widget build(BuildContext context) {
    return ProviderLayout(
      selectedIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFF464E65),
          title: const Text(
            "Booking History",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          titleSpacing: 25,
          automaticallyImplyLeading: false,
          actions: [
            if (providerId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('p_notifications')
                    .where('providerId', isEqualTo: providerId)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = snapshot.data?.docs.length ?? 0;
                  return IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications, color: Colors.white), // ✅ White icon
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const p_Notification()),
                      );
                    },
                  );
                },
              ),
          ],
        ),
        body: Column(
          children: [
            SingleChildScrollView(
              controller: _tabScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12, right: 12, top: 15, bottom: 0),
              child: Row(
                children: List.generate(statuses.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _selectedIndex = index);

                        // 👇 Auto-scroll to bring selected tab into view
                        final buttonWidth = 120.0; // Approximate width of each button
                        _tabScrollController.animateTo(
                          index * buttonWidth,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Color(0xFF464E65) : Colors.grey[300],
                        foregroundColor: isSelected ? Colors.white : Colors.black45,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: Text(statuses[index].split(" ")[0]),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: providerId == null
                  ? const Center(child: Text("You must be logged in."))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('serviceProviderId', isEqualTo: providerId)
                    .where('status', isEqualTo: statuses[_selectedIndex])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No bookings found."));
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isActive = data['status'] == 'Active';
                      final isCompleted = data['status'] == 'Completed';
                      final isCancelled = data['status'] == 'Cancelled';
                      final isInstantBooking = data['bookingId'].toString().startsWith('BKIB');
                      return GestureDetector(
                        onTap: () async {
                          final bookingId = doc['bookingId'];

                          if (!(doc['providerHasSeen'] ?? true)) {
                            await doc.reference.update({'providerHasSeen': true});
                          }

                          // Mark booking as seen
                          if (!(doc['providerHasSeen'] ?? true)) {
                            await doc.reference.update({'providerHasSeen': true});

                            // Also mark the related notification as read
                            final notiSnap = await FirebaseFirestore.instance
                                .collection('p_notifications')
                                .where('bookingId', isEqualTo: bookingId)
                                .limit(1)
                                .get();

                            if (notiSnap.docs.isNotEmpty) {
                              await notiSnap.docs.first.reference.update({'isRead': true});
                            }
                          }

                          if (isInstantBooking) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                isCompleted
                                    ? p_CInstantBookingDetail(
                                  bookingId: data['bookingId'],
                                  postId: data['postId'],
                                  seekerId: data['serviceSeekerId'],
                                )
                                : isActive
                                    ? p_AInstantBookingDetail(
                                  bookingId: data['bookingId'],
                                  postId: data['postId'],
                                  seekerId: data['serviceSeekerId'],
                                )
                                : isCancelled
                                    ? p_CCInstantBookingDetail(
                                  bookingId: data['bookingId'],
                                  postId: data['postId'],
                                  seekerId: data['serviceSeekerId'],
                                )
                                    : p_PInstantBookingDetail(
                                  bookingId: data['bookingId'],
                                  postId: data['postId'],
                                  seekerId: data['serviceSeekerId'],
                                ),
                              ),
                            );
                          } else {
                            // TODO: Add redirect to PromotionBookingDetail if needed
                          }

                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(data, isActive),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        getStatusLabel(data, isActive),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (!(doc['providerHasSeen'] ?? true))
                                      Container(
                                        margin: const EdgeInsets.only(left: 5),
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 5),
                                Text("Service Title: ${doc['IPTitle']}"),
                                Text("Booking ID: ${doc['bookingId']}"),
                                Text("Status: ${doc['status']}", style: const TextStyle(color: Colors.red)),
                                Text("Service Category: ${data['serviceCategory']}"),
                                Text("Price: RM ${doc['price']}",),
                                Text("Location: ${doc['location']}",),
                                if (data['isRescheduling'] == true && data['rescheduleSent'] == false) ...[
                                  Text("Final Schedule (Rescheduled): ${data['finalDate']}, ${data['finalTime']}"),
                                  Text("❌ Reschedule rejected by seeker. Please suggest a new schedule based on your WhatsApp discussion.", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                                ] else if (data['isRescheduling'] == true && data['rescheduleSent'] == true) ...[
                                  Text("Final Schedule (Rescheduled): ${data['finalDate']}, ${data['finalTime']}"),
                                  Text("⚠ Awaiting confirmation from seeker", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                                ] else if (isActive || data['status'] == "Completed") ...[
                                  Text("Final Schedule: ${data['finalDate']}, ${data['finalTime']}"),
                                ] else if (data['status'] == 'Cancelled')...[
                                  Text(
                                  "Cancelled At: ${formatTimestamp(data['cancelledAt'])}",
                                  ),
                                ]
                                else ...[
                                  Text("Preferred Schedule: ${data['preferredDate']}, ${data['preferredTime']}"),
                                  if (data['alternativeDate'] != null && data['alternativeTime'] != null)
                                    Text("Alternative Schedule: ${data['alternativeDate']}, ${data['alternativeTime']}"),
                                ],
                                if (data['status'] == 'Completed' && data['completedAt'] != null)
                                  Text(
                                    "Completed At: ${formatTimestamp(data['completedAt'])}",
                                  ),


                                Text(
                                  "Type: ${isInstantBooking ? "Instant Booking" : "Promotion"}",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),


                                const SizedBox(height: 8),

                                if (data['status'] == 'Active' && data['pCompleted'] != true) ...[
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Don’t forget to upload at least 3 service photos before clicking “Service Completed” — tap the card to begin!",
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                ] else if (data['pCompleted'] == true && data['status'] != 'Completed') ...[
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text(
                                      "✅ You have marked this service as completed.\nWaiting for seeker confirmation or auto-complete after three days.",
                                      style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
