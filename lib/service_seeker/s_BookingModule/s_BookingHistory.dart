import 'package:fix_mate/service_seeker/s_BookingModule/s_AInstantBookingDetail.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_Notification.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_PInstantBookingDetail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/service_seeker/s_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';


class s_BookingHistory extends StatefulWidget {
  static String routeName = "/service_seeker/s_BookingHistory";

  final int initialTabIndex;

  const s_BookingHistory({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  _s_BookingHistoryState createState() => _s_BookingHistoryState();
}

class _s_BookingHistoryState extends State<s_BookingHistory> {
  String? seekerId;
  int _selectedIndex = 0;
  final List<String> statuses = ["Pending Confirmation", "Active", "Completed", "Cancelled"];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    seekerId = user?.uid;
    _selectedIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return SeekerLayout(
      selectedIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFfb9798),
          title: const Text(
            "Booking History",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          titleSpacing: 25,
          automaticallyImplyLeading: false,
          actions: [
            if (seekerId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('s_notifications')
                    .where('seekerId', isEqualTo: seekerId)
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
                        MaterialPageRoute(builder: (_) => s_Notification()),
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
              padding: const EdgeInsets.only(left: 12, right: 12, top: 15, bottom: 0), // 👈 Less space below buttons
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
                        backgroundColor: isSelected ? Color(0xFFfb9798) : Colors.grey[300],
                        foregroundColor: isSelected ? Colors.white : Colors.black45,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold, // 👈 Make text bold
                        ),
                      ),
                      child: Text(statuses[index].split(" ")[0]),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: seekerId == null
                  ? const Center(child: Text("You must be logged in."))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings')
                    .where('serviceSeekerId', isEqualTo: seekerId)
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
                      final isInstantBooking = data['bookingId'].toString().startsWith('BKIB');
                      final bookingId = data['bookingId'];
                      final seekerId = FirebaseAuth.instance.currentUser?.uid ?? '';

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('s_notifications')
                            .where('seekerId', isEqualTo: seekerId)
                            .where('bookingId', isEqualTo: bookingId)
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, notiSnapshot) {
                          final hasUnread = notiSnapshot.hasData && notiSnapshot.data!.docs.isNotEmpty;

                          return InkWell(
                            onTap: () async {
                              if (hasUnread) {
                                for (var notiDoc in notiSnapshot.data!.docs) {
                                  await notiDoc.reference.update({'isRead': true});
                                }
                              }

                              if (isInstantBooking) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => isActive
                                        ? s_AInstantBookingDetail(
                                      bookingId: bookingId,
                                      postId: data['postId'],
                                      providerId: data['serviceProviderId'],
                                    )
                                        : s_PInstantBookingDetail(
                                      bookingId: bookingId,
                                      postId: data['postId'],
                                      providerId: data['serviceProviderId'],
                                    ),
                                  ),
                                );
                              } else {
                                // TODO: Navigate to promotion booking detail
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 3,
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        if (data['status'] == 'Active') ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: data['pCompleted'] == true
                                                  ? Colors.green  // ✅ Green for Service Delivered
                                                  : Colors.orange, // 🟠 Orange for In Progress
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              data['pCompleted'] == true ? "Service Delivered" : "Service in Progress",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],


                                        Text("Another User", style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        Text("Status: ${data['status']}", style: const TextStyle(color: Colors.red)),
                                        Text("Booking ID: $bookingId"),

                                        Text("Service Category: ${data['serviceCategory']}"),
                                        Text("Price: RM ${data['price']}"),
                                        Text("Location: ${data['location']}"),
                                        if (data['isRescheduling'] == true && data['rescheduleSent'] == false) ...[
                                          Text("Final Schedule (Rescheduled): ${data['finalDate']}, ${data['finalTime']}"),
                                          Text(
                                            "❌ Previous schedule rejected. Please contact the provider via WhatsApp to reschedule or wait for a new suggestion.",
                                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                                          ),
                                        ] else if (data['isRescheduling'] == true && data['rescheduleSent'] == true) ...[
                                          Text("Final Schedule (Rescheduled): ${data['finalDate']}, ${data['finalTime']}"),
                                          Text(
                                            "⚠ The provider has suggested a new schedule. Please review it and confirm or reject accordingly.",
                                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                                          ),
                                        ] else if (isActive || data['status'] == "Completed") ...[
                                          Text("Final Schedule: ${data['finalDate']}, ${data['finalTime']}"),
                                        ] else ...[
                                          Text("Preferred Schedule: ${data['preferredDate']}, ${data['preferredTime']}"),
                                          if (data["alternativeDate"] != null && data["alternativeTime"] != null) ...[
                                            Text("Alternative Schedule: ${data['alternativeDate']}, ${data['alternativeTime']}"),
                                          ],
                                        ],
                                        Text(
                                          "Type: ${isInstantBooking ? "Instant Booking" : "Promotion"}",
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),

                                        if (data['pCompleted'] == true && data['status'] == "Active") ...[
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.sticky_note_2_outlined, color: Colors.green, size: 18),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "You may tap on the card to view the service evidence photos before click on “Service Received”.",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              // ElevatedButton(
                                              //   onPressed: () async {
                                              //     final email = "fixmate1168@gmail.com";
                                              //     final subject = Uri.encodeComponent("Issue with Service: $bookingId");
                                              //     final body = Uri.encodeComponent("Hello FixMate,\n\nI have an issue regarding my booking (ID: $bookingId). Please assist.");
                                              //     final emailUrl = "mailto:$email?subject=$subject&body=$body";
                                              //
                                              //     if (await canLaunch(emailUrl)) {
                                              //       await launch(emailUrl);
                                              //     } else {
                                              //       ScaffoldMessenger.of(context).showSnackBar(
                                              //         SnackBar(content: Text("Could not open the email client.")),
                                              //       );
                                              //     }
                                              //   },
                                              //   child: Text("Report Issue"),
                                              //   style: ElevatedButton.styleFrom(
                                              //     backgroundColor: Colors.redAccent,
                                              //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              //   ),
                                              // ),
                                              const SizedBox(width: 10),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final docRef = FirebaseFirestore.instance.collection('bookings').doc(doc.id);

                                                  // Mark seeker complete
                                                  await docRef.update({'sCompleted': true});

                                                  // 🔁 Re-fetch latest data from Firestore
                                                  final updatedDoc = await docRef.get();
                                                  final updatedData = updatedDoc.data();

                                                  if (updatedData?['pCompleted'] == true) {
                                                    await docRef.update({
                                                      'status': 'Completed',
                                                      'completedAt': FieldValue.serverTimestamp(),
                                                    });

                                                    ReusableSnackBar(
                                                      context,
                                                      "Booking marked as completed!",
                                                      icon: Icons.check_circle,
                                                      iconColor: Colors.green,
                                                    );

                                                    // ✅ Delay before navigating
                                                    await Future.delayed(const Duration(milliseconds: 400));

                                                    // ✅ Switch tab without pushing a new screen
                                                    setState(() {
                                                      _selectedIndex = 2; // ✅ go to Completed tab directly
                                                    });

                                                  }
                                                },


                                                child: Text("Service Received"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (hasUnread)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],




                              ),
                            ),
                          );
                        },
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

