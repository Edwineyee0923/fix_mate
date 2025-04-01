import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_PInstantBookingDetail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(
        backgroundColor: const Color(0xFF464E65),
        title: const Text("Notifications", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('p_notifications')
            .where('spId', isEqualTo: providerId)
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

              return Card(
                elevation: 2,
                child: ListTile(
                  title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  // subtitle: Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Text(doc['message']),
                  //     if (createdAt != null)
                  //       Text(formatTimeAgo(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  //   ],
                  // ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc['message']),
                      Text(
                        formatTimeAgo(createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: !isRead ? const Icon(Icons.circle, color: Colors.red, size: 10) : null,
                  onTap: () async {
                    await doc.reference.update({'isRead': true});
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => p_PInstantBookingDetail(
                          bookingId: doc['bookingId'],
                          postId: doc['postId'],
                          seekerId: doc['serviceSeekerId'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}


