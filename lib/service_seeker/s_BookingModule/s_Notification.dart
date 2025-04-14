import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_AInstantBookingDetail.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_CCInstantBookingDetail.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_CInstantBookingDetail.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_PInstantBookingDetail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class s_Notification extends StatefulWidget {
  const s_Notification({Key? key}) : super(key: key);

  @override
  State<s_Notification> createState() => _s_NotificationState();
}

class _s_NotificationState extends State<s_Notification> {
  String? seekerId;

  @override
  void initState() {
    super.initState();
    seekerId = FirebaseAuth.instance.currentUser?.uid;
  }


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
    if (seekerId == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor:  const Color(0xFFfb9798),
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
            .collection('s_notifications')
            .where('seekerId', isEqualTo: seekerId)
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

              // return Card(
              //   elevation: 2,
              //   child: ListTile(
              //     title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              //     // subtitle: Column(
              //     //   crossAxisAlignment: CrossAxisAlignment.start,
              //     //   children: [
              //     //     Text(doc['message']),
              //     //     if (createdAt != null)
              //     //       Text(formatTimeAgo(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              //     //   ],
              //     // ),
              //
              //     subtitle: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(doc['message']),
              //         Text(
              //           formatTimeAgo(createdAt),
              //           style: const TextStyle(fontSize: 12, color: Colors.grey),
              //         ),
              //       ],
              //     ),
              //     trailing: !isRead ? const Icon(Icons.circle, color: Colors.red, size: 10) : null,
              //     onTap: () async {
              //       await doc.reference.update({'isRead': true});
              //
              //       // 🔍 Fetch the latest booking status from Firestore
              //       final bookingSnapshot = await FirebaseFirestore.instance
              //           .collection('bookings')
              //           .where('bookingId', isEqualTo: doc['bookingId'])
              //           .limit(1)
              //           .get();
              //
              //       if (bookingSnapshot.docs.isNotEmpty) {
              //         final bookingData = bookingSnapshot.docs.first.data();
              //         final status = bookingData['status'] ?? '';
              //
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => status == 'Active'
              //                 ? s_AInstantBookingDetail(
              //               bookingId: doc['bookingId'],
              //               postId: doc['postId'],
              //               providerId: doc['providerId'],
              //             )
              //                 : s_PInstantBookingDetail(
              //               bookingId: doc['bookingId'],
              //               postId: doc['postId'],
              //               providerId: doc['providerId'],
              //             ),
              //           ),
              //         );
              //       } else {
              //         ReusableSnackBar(
              //             context,
              //             "Booking not found.",
              //             icon: Icons.error,
              //             iconColor: Colors.red // Red icon for error
              //         );
              //       }
              //     },
              //
              //   ),
              // );
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
                      final bookingData = bookingSnapshot.docs.first.data();
                      final status = bookingData['status'] ?? '';

                      Widget targetScreen;

                      if (status == 'Active') {
                        targetScreen = s_AInstantBookingDetail(
                          bookingId: doc['bookingId'],
                          postId: doc['postId'],
                          providerId: doc['providerId'],
                        );
                      } else if (status == 'Completed') {
                        targetScreen = s_CInstantBookingDetail(
                          bookingId: doc['bookingId'],
                          postId: doc['postId'],
                          providerId: doc['providerId'],
                        );
                      } else if (status == 'Cancelled') {
                        targetScreen = s_CCInstantBookingDetail(
                          bookingId: doc['bookingId'],
                          postId: doc['postId'],
                          providerId: doc['providerId'],
                        );
                      } else {
                        targetScreen = s_PInstantBookingDetail(
                          bookingId: doc['bookingId'],
                          postId: doc['postId'],
                          providerId: doc['providerId'],
                        );
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => targetScreen),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking not found.')),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : const Color(0xFFFDEDEE),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfb9798),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications, color: Colors.white, size: 20),
                        ),

                        const SizedBox(width: 12),

                        // Notification content
                        Expanded(
                          child: Column(
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
                              const SizedBox(height: 4),
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

                        // Red dot for unread
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


