import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_ABookingDetail.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_CCBookingDetail.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_CBookingDetail.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_PBookingDetail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class p_Notification extends StatefulWidget {
  const p_Notification({Key? key}) : super(key: key);

  @override
  State<p_Notification> createState() => _p_NotificationState();
}

class _p_NotificationState extends State<p_Notification> {
  String? providerId;

  @override
  void initState() {
    super.initState();
    providerId = FirebaseAuth.instance.currentUser?.uid;
  }

  // String formatTimeAgo(Timestamp timestamp) {
  //   final date = timestamp.toDate();
  //   final now = DateTime.now();
  //   final difference = now.difference(date);
  //
  //   if (difference.inSeconds < 60) return 'just now';
  //   if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  //   if (difference.inHours < 24) return '${difference.inHours}h ago';
  //   return DateFormat('dd MMM, hh:mm a').format(date);
  // }

  String formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Sending...'; // fallback for null timestamps

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('dd MMM, hh:mm a').format(date);
  }


  @override
  Widget build(BuildContext context) {
    if (providerId == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in.")),
      );
    }

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
        title: const Text("Notifications", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        titleSpacing: 5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('p_notifications')
            .where('providerId', isEqualTo: providerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications found."));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final isRead = doc['isRead'] ?? false;
              // final createdAt = doc['createdAt'] as Timestamp?;
              final Timestamp? createdAt = doc['createdAt'];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await doc.reference.update({'isRead': true});

                    final bookingSnapshot = await FirebaseFirestore.instance
                        .collection('bookings')
                        .where('bookingId', isEqualTo: doc['bookingId'])
                        .limit(1)
                        .get();

                    if (bookingSnapshot.docs.isNotEmpty) {
                      final bookingDoc = bookingSnapshot.docs.first;
                      final bookingRef = bookingDoc.reference;
                      final bookingData = bookingDoc.data();

                      // ✅ Mark booking as seen
                      await bookingRef.update({'providerHasSeen': true});

                      final status = bookingData['status'] ?? '';

                      Widget targetScreen;

                      if (status == 'Active') {
                        targetScreen = p_ABookingDetail(
                          bookingId: doc['bookingId'],
                          postId: doc['postId'],
                          seekerId: doc['seekerId'],
                        );
                      } else if (status == 'Completed') {
                        targetScreen = p_CBookingDetail(
                          bookingId: doc['bookingId'],
                          postId: doc['postId'],
                          seekerId: doc['seekerId'],
                        );
                      } else if (status == 'Cancelled') {
                        targetScreen = p_CCBookingDetail(
                          bookingId: doc['bookingId'],
                          postId: doc['postId'],
                          seekerId: doc['seekerId'],
                        );
                      } else {
                        targetScreen = p_PBookingDetail(
                          bookingId: doc['bookingId'],
                          postId: doc['postId'],
                          seekerId: doc['seekerId'],
                        );
                      }

                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (_) => targetScreen),
                      // );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => targetScreen),
                      ).then((_) async {
                        // ✅ After returning from booking detail, check if all are read
                        final unreadSnapshot = await FirebaseFirestore.instance
                            .collection('p_notifications')
                            .where('providerId', isEqualTo: providerId)
                            .where('isRead', isEqualTo: false)
                            .get();

                        if (unreadSnapshot.docs.isEmpty && mounted) {
                          Navigator.pop(context, true); // ✅ Notify p_footer to hide red dot
                        }
                      });
                    } else {
                      ReusableSnackBar(
                          context,
                          "Booking not found.",
                          icon: Icons.error,
                          iconColor: Colors.red // Red icon for error
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : const Color(0xFFEAEAF2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 📢 Icon badge
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF464E65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),

                        // 🔤 Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🧾 Title & Booking ID
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF464E65),
                                    ),
                                  ),
                                  // const SizedBox(height: 4),
                                  // Text(
                                  //   "Booking ID: ${doc['bookingId']}",
                                  //   style: const TextStyle(
                                  //     fontSize: 13,
                                  //     color: Colors.black54,
                                  //     fontWeight: FontWeight.w500,
                                  //   ),
                                  // ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                doc['message'],
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatTimeAgo(doc['createdAt']),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        // 🔴 Red unread dot
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 4, left: 8),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
