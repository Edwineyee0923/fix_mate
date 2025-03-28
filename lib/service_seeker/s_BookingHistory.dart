// import 'package:fix_mate/service_seeker/s_layout.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
//
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
//
//
//   @override
//   Widget build(BuildContext context) {
//     return SeekerLayout(
//         selectedIndex: 1,
//         child: Scaffold(
//           backgroundColor: Color(0xFFFFF8F2),
//           appBar: AppBar(
//             backgroundColor: Color(0xFFfb9798),
//             // leading: IconButton(
//             //   icon: Icon(Icons.arrow_back_ios_new_rounded),
//             //   onPressed: () {
//             //     Navigator.pop(context);
//             //   },
//             // ),
//             // centerTitle: true,
//             title: Text(
//               "Booking",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,),
//             ),
//             titleSpacing: 25,
//             automaticallyImplyLeading: false,
//           ),
//
//           body: SingleChildScrollView(
//           ),
//         )
//     );
//   }
// }


import 'package:fix_mate/service_seeker/s_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class s_BookingHistory extends StatefulWidget {
  static String routeName = "/service_seeker/s_BookingHistory";

  const s_BookingHistory({Key? key}) : super(key: key);

  @override
  _s_BookingHistoryState createState() => _s_BookingHistoryState();
}

class _s_BookingHistoryState extends State<s_BookingHistory> {
  @override
  Widget build(BuildContext context) {
    return SeekerLayout(
      selectedIndex: 1,
      child: Scaffold(
        backgroundColor: Color(0xFFFFF8F2),
        appBar: AppBar(
          backgroundColor: Color(0xFFfb9798),
          title: Text(
            "Booking History",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          titleSpacing: 25,
          automaticallyImplyLeading: false,
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No bookings found."));
            }

            return ListView(
              padding: EdgeInsets.all(16),
              children: snapshot.data!.docs.map((doc) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc['IPTitle'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Status: ${doc['status']}", style: TextStyle(fontSize: 16, color: Colors.red)),
                        // Text("Service Category: ${doc['serviceCategory']}"),
                        Text("Booking ID: ${doc['bookingId']}"),
                        Text("Preferred Date: ${doc['preferredDate']}"),
                        Text("Preferred Time: ${doc['preferredTime']}"),
                        if (doc['alternativeDate'] != null) Text("Alternative Date: ${doc['alternativeDate']}"),
                        if (doc['alternativeTime'] != null) Text("Alternative Time: ${doc['alternativeTime']}"),
                        Text("Location: ${doc['location']}"),
                        SizedBox(height: 10),
                        Text(
                          "Type: ${doc['bookingId'].toString().startsWith('BKIB') ? 'Instant Booking' : 'Promotion'}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),

                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
