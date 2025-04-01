// import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class p_PInstantBookingDetail extends StatefulWidget {
//   final String bookingId;
//   final String postId;
//   final String seekerId;
//
//   const p_PInstantBookingDetail({
//     Key? key,
//     required this.bookingId,
//     required this.postId,
//     required this.seekerId,
//   }) : super(key: key);
//
//   @override
//   State<p_PInstantBookingDetail> createState() => _p_PInstantBookingDetailState();
// }
//
// class _p_PInstantBookingDetailState extends State<p_PInstantBookingDetail> {
//   Map<String, dynamic>? bookingData;
//   Map<String, dynamic>? instantPostData;
//   String? seekerPhone;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchBookingDetails();
//   }
//
//   Future<void> _fetchBookingDetails() async {
//     try {
//       // Fetch booking info
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('bookings')
//           .where('bookingId', isEqualTo: widget.bookingId)
//           .limit(1)
//           .get();
//
//       if (snapshot.docs.isNotEmpty) {
//         bookingData = snapshot.docs.first.data() as Map<String, dynamic>;
//       }
//
//
//       // Fetch IP post info
//       DocumentSnapshot postSnap = await FirebaseFirestore.instance.collection('instant_booking').doc(widget.postId).get();
//       if (postSnap.exists) {
//         instantPostData = postSnap.data() as Map<String, dynamic>;
//       }
//
//       // Fetch provider phone
//       DocumentSnapshot seekerSnap = await FirebaseFirestore.instance.collection('service_seekers').doc(widget.seekerId).get();
//       if (seekerSnap.exists) {
//         seekerPhone = seekerSnap['phone'];
//       }
//
//       setState(() {});
//     } catch (e) {
//       print("❌ Error fetching details: $e");
//     }
//   }
//
//   String _formatDate(String date) {
//     try {
//       DateTime dt = DateTime.parse(date);
//       return "${dt.day} ${_monthName(dt.month)} ${dt.year}";
//     } catch (_) {
//       return date;
//     }
//   }
//
//   String _formatTime(String time) {
//     try {
//       TimeOfDay t = TimeOfDay(
//         hour: int.parse(time.split(":")[0]),
//         minute: int.parse(time.split(":")[1]),
//       );
//       final now = DateTime.now();
//       final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
//       return TimeOfDay.fromDateTime(dt).format(context);
//     } catch (_) {
//       return time;
//     }
//   }
//
//   String _monthName(int month) {
//     const months = ["Jan", "Feb", "Mac", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
//     return months[month - 1];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (bookingData == null || instantPostData == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     final ipImages = (instantPostData!["IPImage"] != null && instantPostData!["IPImage"] is List<dynamic>)
//         ? List<String>.from(instantPostData!["IPImage"])
//         : [];
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFFFF8F2),
//       appBar: AppBar(
//         backgroundColor:  const Color(0xFF464E65),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios_new_rounded),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: const Text("Booking History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
//         titleSpacing: 25,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Top Section
//           if (ipImages.isNotEmpty)
//             GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => p_EditInstantPost(docId: widget.postId)),
//                 );
//               },
//               child: Column(
//                 children: [
//                   Image.network(ipImages[0], height: 200, fit: BoxFit.cover),
//                   const SizedBox(height: 10),
//                   Text(instantPostData!["IPTitle"],
//                       style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//             ),
//
//           const SizedBox(height: 24),
//
//           // Details Section
//           Text("Booking ID: ${bookingData!["bookingId"]}"),
//           Text("Status: ${bookingData!["status"]}"),
//           Text("Title: ${bookingData!["IPTitle"]}"),
//           Text("Category: ${bookingData!["serviceCategory"]}"),
//           Text("Preferred Date: ${_formatDate(bookingData!["preferredDate"])}"),
//           Text("Preferred Time: ${_formatTime(bookingData!["preferredTime"])}"),
//           if (bookingData!["alternativeDate"] != null)
//             Text("Alternative Date: ${_formatDate(bookingData!["alternativeDate"])}"),
//           if (bookingData!["alternativeTime"] != null)
//             Text("Alternative Time: ${_formatTime(bookingData!["alternativeTime"])}"),
//           Text("Location: ${bookingData!["location"]}"),
//           Text("Price: RM ${bookingData!["price"]}"),
//           const SizedBox(height: 12),
//           if (seekerPhone != null)
//             ElevatedButton.icon(
//               onPressed: () async {
//                 final url = "https://wa.me/$seekerPhone";
//                 if (await canLaunch(url)) {
//                   await launch(url);
//                 }
//               },
//               icon: const Icon(Icons.chat_bubble_outline),
//               label: const Text("Contact Seeker via WhatsApp"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//
//           const SizedBox(height: 24),
//
//           // Bottom Section: Edit & Cancel
//           ElevatedButton(
//             onPressed: () {},
//             child: const Text("Edit Schedule"),
//           ),
//           const SizedBox(height: 10),
//           ElevatedButton(
//             onPressed: () {},
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text("Request Cancellation", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class p_PInstantBookingDetail extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String seekerId;

  const p_PInstantBookingDetail({
    Key? key,
    required this.bookingId,
    required this.postId,
    required this.seekerId,
  }) : super(key: key);

  @override
  State<p_PInstantBookingDetail> createState() => _p_PInstantBookingDetailState();
}

class _p_PInstantBookingDetailState extends State<p_PInstantBookingDetail> {
  Map<String, dynamic>? bookingData;
  Map<String, dynamic>? instantPostData;
  String? seekerPhone;
  String? selectedSchedule; // 'preferred' or 'alternative'
  bool isSubmitting = false;


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
      DocumentSnapshot seekerSnap = await FirebaseFirestore.instance.collection('service_seekers').doc(widget.seekerId).get();
      if (seekerSnap.exists) {
        seekerPhone = seekerSnap['phone'];
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

  String _monthName(int month) {
    const months = ["Jan", "Feb", "Mac", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }


  Future<void> _confirmSchedule() async {
    if (selectedSchedule == null) return;

    setState(() => isSubmitting = true);

    try {
      String finalDate = selectedSchedule == 'preferred'
          ? bookingData!["preferredDate"]
          : bookingData!["alternativeDate"];
      String finalTime = selectedSchedule == 'preferred'
          ? bookingData!["preferredTime"]
          : bookingData!["alternativeTime"];

      final query = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docRef = query.docs.first.reference;
        await docRef.update({
          'finalDate': finalDate,
          'finalTime': finalTime,
          'status': 'Active',
        });
      }


      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Schedule confirmed successfully.")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const p_BookingHistory(initialTabIndex: 1),
        ),
      );
    } catch (e) {
      print("❌ Failed to confirm schedule: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to confirm schedule.")));
    } finally {
      setState(() => isSubmitting = false);
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
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Booking History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        titleSpacing: 25,
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
          Text("Booking ID: ${bookingData!["bookingId"]}"),
          Text("Status: ${bookingData!["status"]}"),
          Text("Title: ${bookingData!["IPTitle"]}"),
          Text("Category: ${bookingData!["serviceCategory"]}"),
          Text("Preferred Date: ${_formatDate(bookingData!["preferredDate"])}"),
          Text("Preferred Time: ${_formatTime(bookingData!["preferredTime"])}"),
          if (bookingData!["alternativeDate"] != null)
            Text("Alternative Date: ${_formatDate(bookingData!["alternativeDate"])}"),
          if (bookingData!["alternativeTime"] != null)
            Text("Alternative Time: ${_formatTime(bookingData!["alternativeTime"])}"),
          Text("Location: ${bookingData!["location"]}"),
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
          const SizedBox(height: 16),
          Text("Choose Schedule to Confirm:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

          CheckboxListTile(
            title: Text("Preferred: ${_formatDate(bookingData!["preferredDate"])} at ${_formatTime(bookingData!["preferredTime"])}"),
            value: selectedSchedule == 'preferred',
            onChanged: (val) {
              setState(() => selectedSchedule = 'preferred');
            },
          ),

          if (bookingData!["alternativeDate"] != null && bookingData!["alternativeTime"] != null)
            CheckboxListTile(
              title: Text("Alternative: ${_formatDate(bookingData!["alternativeDate"])} at ${_formatTime(bookingData!["alternativeTime"])}"),
              value: selectedSchedule == 'alternative',
              onChanged: (val) {
                setState(() => selectedSchedule = 'alternative');
              },
            ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: isSubmitting ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.check),
            label: Text("Confirm Schedule"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: selectedSchedule == null || isSubmitting
                ? null
                : () async {
              await _confirmSchedule();
            },
          ),


          // Bottom Section: Edit & Cancel
          ElevatedButton(
            onPressed: () {},
            child: const Text("Edit Schedule"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Request Cancellation", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}