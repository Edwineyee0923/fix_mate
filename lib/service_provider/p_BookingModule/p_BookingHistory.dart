import 'package:fix_mate/service_provider/p_BookingModule/p_AInstantBookingDetail.dart';
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


  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    providerId = user?.uid;
    _selectedIndex = widget.initialTabIndex;
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
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                      final isNew = doc['status'] == 'Pending Confirmation';
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
                                builder: (context) => isActive
                                    ? p_AInstantBookingDetail(
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
                                        color: data['status'] == "Completed"
                                            ? Colors.green                   // ✅ Green for Service Completed
                                            : data['isRescheduling'] == true
                                            ? Colors.amber              // Yellow for Booking Rescheduled
                                            : isActive
                                            ? Colors.green          // Green for Service Confirmed
                                            : const Color(0xFFfb9798), // Pinkish-red for New Order Assigned
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        data['status'] == "Completed"
                                            ? "Service Completed"
                                            : data['isRescheduling'] == true
                                            ? "Booking Rescheduled"
                                            : isActive
                                            ? "Service Confirmed"
                                            : "New Order Assigned",
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
                                ]
                                else ...[
                                  Text("Preferred Schedule: ${data['preferredDate']}, ${data['preferredTime']}"),
                                  if (data['alternativeDate'] != null && data['alternativeTime'] != null)
                                    Text("Alternative Schedule: ${data['alternativeDate']}, ${data['alternativeTime']}"),
                                ],

                                Text(
                                  "Type: ${isInstantBooking ? "Instant Booking" : "Promotion"}",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),


                                const SizedBox(height: 8),

                                if (data['status'] == 'Active' && data['pCompleted'] != true) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check_circle_outline),
                                        label: const Text("Mark as Completed"),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => ConfirmationDialog(
                                              title: "Mark as Completed?",
                                              message:
                                              "Please confirm that the service has been completed.\nThe seeker will be notified to verify.",
                                              confirmText: "Confirm",
                                              cancelText: "Cancel",
                                              icon: Icons.check_circle,
                                              iconColor: Colors.green,
                                              confirmButtonColor: Colors.green,
                                              cancelButtonColor: Colors.grey.shade300,
                                              onConfirm: () async {
                                                Navigator.pop(context); // Close dialog

                                                await doc.reference.update({
                                                  'pCompleted': true,
                                                  'sCompleted': false,
                                                });

                                                await FirebaseFirestore.instance.collection('s_notifications').add({
                                                  'seekerId': data['serviceSeekerId'],
                                                  'providerId': providerId,
                                                  'bookingId': data['bookingId'],
                                                  'postId': data['postId'],
                                                  'title': 'Service Completed',
                                                  'message': 'Provider marked the service as completed. Please confirm or report issue.',
                                                  'isRead': false,
                                                  'createdAt': FieldValue.serverTimestamp(),
                                                });

                                                ReusableSnackBar(
                                                  context,
                                                  "Service marked as completed!",
                                                  icon: Icons.check_circle,
                                                  iconColor: Colors.green,
                                                );
                                              },
                                            ),
                                          );
                                        },
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
