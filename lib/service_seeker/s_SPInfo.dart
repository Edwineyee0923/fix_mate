// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class ServiceProviderScreen extends StatefulWidget {
//   final String docId;
//
//   const ServiceProviderScreen({Key? key, required this.docId}) : super(key: key);
//
//   @override
//   _ServiceProviderScreenState createState() => _ServiceProviderScreenState();
// }
// class _ServiceProviderScreenState extends State<ServiceProviderScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   String spName = '';
//   String spImageUrl = '';
//   String spPhone = '';
//   double spRating = 0.0;
//   List<Map<String, dynamic>> promotions = [];
//   List<Map<String, dynamic>> instantBookings = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSPData();
//     _loadPosts();
//   }
//
//   Future<void> _loadSPData() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       DocumentSnapshot snapshot = await _firestore.collection('service_providers').doc(user.uid).get();
//       if (snapshot.exists) {
//         Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//         setState(() {
//           spName = data['name'] ?? '';
//           spImageUrl = data['profilePic'] ?? '';
//           spPhone = data['phone'] ?? '';
//           spRating = (data['rating'] ?? 0).toDouble();
//         });
//       }
//     }
//   }
//
//   Future<void> _loadPosts() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       // Fetch promotions
//       QuerySnapshot promoSnapshot = await _firestore
//           .collection('promotion')
//           .where('userId', isEqualTo: user.uid)
//           .get();
//
//       // Fetch instant bookings
//       QuerySnapshot instantSnapshot = await _firestore
//           .collection('instant_booking')
//           .where('userId', isEqualTo: user.uid)
//           .get();
//
//       setState(() {
//         promotions = promoSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
//         instantBookings = instantSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
//       });
//     }
//   }
//
//   void _openWhatsApp() async {
//     final url = "https://wa.me/$spPhone";
//     if (await canLaunch(url)) {
//       await launch(url);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open WhatsApp")));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(spName)),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Service Provider Details
//             Container(
//               padding: EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   CircleAvatar(radius: 40, backgroundImage: spImageUrl.isNotEmpty ? NetworkImage(spImageUrl) : null),
//                   SizedBox(width: 16),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(spName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                       Row(
//                         children: List.generate(5, (index) => Icon(Icons.star, color: index < spRating ? Colors.orange : Colors.grey)),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: _openWhatsApp,
//                         icon: Icon(Icons.chat),
//                         label: Text("WhatsApp"),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             // Promotions Section
//             if (promotions.isNotEmpty) ...[
//               Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Text("Promotions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               ),
//               Column(
//                 children: promotions.map((promo) {
//                   return ListTile(
//                     leading: promo['PImage'] != null ? Image.network(promo['PImage'][0], width: 60, height: 60, fit: BoxFit.cover) : null,
//                     title: Text(promo['PTitle'] ?? ''),
//                     subtitle: Text("RM${promo['PPrice']} - ${promo['PDiscountPercentage']}% off"),
//                   );
//                 }).toList(),
//               ),
//             ],
//
//             // Instant Booking Section
//             if (instantBookings.isNotEmpty) ...[
//               Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Text("Instant Booking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               ),
//               Column(
//                 children: instantBookings.map((booking) {
//                   return ListTile(
//                     leading: booking['IPImage'] != null ? Image.network(booking['IPImage'][0], width: 60, height: 60, fit: BoxFit.cover) : null,
//                     title: Text(booking['IPTitle'] ?? ''),
//                     subtitle: Text("RM${booking['IPPrice']}"),
//                   );
//                 }).toList(),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:fix_mate/service_seeker/s_SPDetail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceProviderScreen extends StatefulWidget {
  final String docId;

  const ServiceProviderScreen({Key? key, required this.docId}) : super(key: key);

  @override
  _ServiceProviderScreenState createState() => _ServiceProviderScreenState();
}

class _ServiceProviderScreenState extends State<ServiceProviderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? spData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSPDetails();
  }

  Future<void> _fetchSPDetails() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('service_providers').doc(widget.docId).get();

      if (snapshot.exists) {
        setState(() {
          spData = snapshot.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        print("Service Provider Not Found");
      }
    } catch (e) {
      print("Error fetching service provider details: $e");
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Service Provider")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(spData?['name'] ?? "Service Provider")),
      body: Column(
        children: [
          // Service Provider Info Section with tappable navigation
          Card(
            margin: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: InkWell(
              onTap: () {
                // Navigate to SPDetailScreen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SPDetailScreen(
                      docId: widget.docId, // Pass the document ID
                    ),
                  ),
                );
              },
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: spData?['profilePic'] != null
                      ? NetworkImage(spData!['profilePic'])
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                ),
                title: Text(
                  spData?['name'] ?? "Unknown",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(spData?['phone'] ?? "No Contact Info"),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.black54),
              ),
            ),
          ),

          // Promotions Section
          Expanded(child: _buildPromotionsList()), // ✅ Fetch Promotions

          // Instant Booking Section
          Expanded(child: _buildInstantBookingsList()), // ✅ Fetch Instant Bookings
        ],
      ),
    );
  }


  Widget _buildPromotionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('promotion').where('userId', isEqualTo: widget.docId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No Promotions Available"));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: data['PImage'] != null && data['PImage'] is List
                    ? Image.network(data['PImage'][0], width: 50, height: 50, fit: BoxFit.cover)
                    : Icon(Icons.image),
                title: Text(data['PTitle'] ?? "No Title"),
                subtitle: Text("RM ${data['PPrice']}"),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInstantBookingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('instant_booking').where('userId', isEqualTo: widget.docId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No Instant Booking Available"));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: data['IPImage'] != null && data['IPImage'] is List
                    ? Image.network(data['IPImage'][0], width: 50, height: 50, fit: BoxFit.cover)
                    : Icon(Icons.image),
                title: Text(data['IPTitle'] ?? "No Title"),
                subtitle: Text("RM ${data['IPPrice']}"),
              ),
            );
          }).toList(),
        );
      },
    );
  }


  void _launchWhatsApp(String phoneNumber) {
    if (phoneNumber.isNotEmpty) {
      final url = "https://wa.me/$phoneNumber";
      launch(url);
    } else {
      print("Phone number not available");
    }
  }
}

