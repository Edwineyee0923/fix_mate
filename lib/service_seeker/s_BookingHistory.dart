

// import 'package:fix_mate/service_seeker/s_layout.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class s_BookingHistory extends StatefulWidget {
//   static String routeName = "/service_seeker/s_BookingHistory";
//
//   const s_BookingHistory({Key? key}) : super(key: key);
//
//   @override
//   _s_BookingHistoryState createState() => _s_BookingHistoryState();
// }
//
// class _s_BookingHistoryState extends State<s_BookingHistory> {
//   @override
//   Widget build(BuildContext context) {
//     return SeekerLayout(
//       selectedIndex: 1,
//       child: Scaffold(
//         backgroundColor: Color(0xFFFFF8F2),
//         appBar: AppBar(
//           backgroundColor: Color(0xFFfb9798),
//           title: Text(
//             "Booking History",
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
//           ),
//           titleSpacing: 25,
//           automaticallyImplyLeading: false,
//         ),
//         body: StreamBuilder(
//           stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
//           builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Center(child: CircularProgressIndicator());
//             }
//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return Center(child: Text("No bookings found."));
//             }
//
//             return ListView(
//               padding: EdgeInsets.all(16),
//               children: snapshot.data!.docs.map((doc) {
//                 return Card(
//                   margin: EdgeInsets.symmetric(vertical: 10),
//                   elevation: 3,
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(doc['IPTitle'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                         SizedBox(height: 5),
//                         Text("Status: ${doc['status']}", style: TextStyle(fontSize: 16, color: Colors.red)),
//                         // Text("Service Category: ${doc['serviceCategory']}"),
//                         Text("Booking ID: ${doc['bookingId']}"),
//                         Text("Preferred Date: ${doc['preferredDate']}"),
//                         Text("Preferred Time: ${doc['preferredTime']}"),
//                         if (doc['alternativeDate'] != null) Text("Alternative Date: ${doc['alternativeDate']}"),
//                         if (doc['alternativeTime'] != null) Text("Alternative Time: ${doc['alternativeTime']}"),
//                         Text("Service Category: ${doc['serviceCategory']}"),
//                         Text("Location: ${doc['location']}"),
//                         SizedBox(height: 10),
//                         Text(
//                           "Type: ${doc['bookingId'].toString().startsWith('BKIB') ? 'Instant Booking' : 'Promotion'}",
//                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                         ),
//
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/service_seeker/s_layout.dart';


class s_BookingHistory extends StatefulWidget {
  static String routeName = "/service_seeker/s_BookingHistory";

  final int initialTabIndex;

  const s_BookingHistory({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  _s_BookingHistoryState createState() => _s_BookingHistoryState();
}

class _s_BookingHistoryState extends State<s_BookingHistory> {
  int _selectedIndex = 0;
  final List<String> statuses = ["Pending Confirmation", "Active", "Completed", "Cancelled"];

  @override
  void initState() {
    super.initState();
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings')
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
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc['IPTitle'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text("Status: ${doc['status']}", style: const TextStyle(fontSize: 16, color: Colors.red)),
                              Text("Booking ID: ${doc['bookingId']}"),
                              Text("Preferred Date: ${doc['preferredDate']}"),
                              Text("Preferred Time: ${doc['preferredTime']}"),
                              if (doc['alternativeDate'] != null) Text("Alternative Date: ${doc['alternativeDate']}"),
                              if (doc['alternativeTime'] != null) Text("Alternative Time: ${doc['alternativeTime']}"),
                              Text("Service Category: ${doc['serviceCategory']}"),
                              Text("Price: RM ${doc['price']}"),
                              Text("Location: ${doc['location']}"),
                              const SizedBox(height: 10),
                              if (doc['bookingId'].toString().startsWith('BKIB'))
                                const Text("Type: Instant Booking", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
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


//   /// 🔹 Fetch and show contact details when the button is tapped
//   Future<void> _fetchAndShowProviderSeekerPhones(BuildContext context, String providerId, String seekerId) async {
//     String? providerPhone;
//     String? seekerPhone;
//
//     try {
//       var providerSnapshot = await FirebaseFirestore.instance
//           .collection('service_providers')
//           .doc(providerId)
//           .get();
//
//       if (providerSnapshot.exists) {
//         providerPhone = providerSnapshot['phone'];
//       }
//
//       var seekerSnapshot = await FirebaseFirestore.instance
//           .collection('service_seekers')
//           .doc(seekerId)
//           .get();
//
//       if (seekerSnapshot.exists) {
//         seekerPhone = seekerSnapshot['phone'];
//       }
//     } catch (e) {
//       print("Error fetching phone numbers: $e");
//     }
//
//     // Show phone numbers in a dialog
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Contact Details"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text("Service Provider Phone: ${providerPhone ?? 'N/A'}"),
//               Text("Your Phone: ${seekerPhone ?? 'N/A'}"),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text("Close"),
//             ),
//           ],
//         );
//       },
//     );
//   }