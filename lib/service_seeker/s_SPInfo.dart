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

// import 'package:fix_mate/service_seeker/s_SPDetail.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:url_launcher/url_launcher.dart';
//
//
// class ServiceProviderScreen extends StatefulWidget {
//   final String docId;
//
//   const ServiceProviderScreen({Key? key, required this.docId}) : super(key: key);
//
//   @override
//   _ServiceProviderScreenState createState() => _ServiceProviderScreenState();
// }
//
// class _ServiceProviderScreenState extends State<ServiceProviderScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   Map<String, dynamic>? spData;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchSPDetails();
//   }
//
//   Future<void> _fetchSPDetails() async {
//     try {
//       DocumentSnapshot snapshot = await _firestore.collection('service_providers').doc(widget.docId).get();
//
//       if (snapshot.exists) {
//         setState(() {
//           spData = snapshot.data() as Map<String, dynamic>;
//           isLoading = false;
//         });
//       } else {
//         print("Service Provider Not Found");
//       }
//     } catch (e) {
//       print("Error fetching service provider details: $e");
//     }
//   }
//
//   @override
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: Text("Service Provider")),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: Text(spData?['name'] ?? "Service Provider")),
//       body: Column(
//         children: [
//           // Service Provider Info Section with tappable navigation
//           Card(
//             margin: EdgeInsets.all(10),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             elevation: 3,
//             child: InkWell(
//               onTap: () {
//                 // Navigate to SPDetailScreen when tapped
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => SPDetailScreen(
//                       docId: widget.docId, // Pass the document ID
//                     ),
//                   ),
//                 );
//               },

//               child: ListTile(
//                 contentPadding: EdgeInsets.all(12),
//                 leading: CircleAvatar(
//                   radius: 30,
//                   backgroundImage: spData?['profilePic'] != null
//                       ? NetworkImage(spData!['profilePic'])
//                       : AssetImage('assets/default_profile.png') as ImageProvider,
//                 ),
//                 title: Text(
//                   spData?['name'] ?? "Unknown",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text(spData?['phone'] ?? "No Contact Info"),
//                 trailing: Icon(Icons.arrow_forward_ios, color: Colors.black54),
//               ),
//             ),
//           ),
//           if (spData?['phone'] != null && spData!['phone'].toString().isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 10),
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   final phone = spData!['phone'].toString();
//                   final url = Uri.parse("https://wa.me/$phone");
//                   launchUrl(url, mode: LaunchMode.externalApplication);
//                 },
//                 icon: Icon(Icons.chat, color: Colors.white),
//                 label: Text("Chat on WhatsApp"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
//             ),
//           // Promotions Section
//           Expanded(child: _buildPromotionsList()), // ✅ Fetch Promotions
//
//           // Instant Booking Section
//           Expanded(child: _buildInstantBookingsList()), // ✅ Fetch Instant Bookings
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildPromotionsList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore.collection('promotion').where('userId', isEqualTo: widget.docId).snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return Center(child: CircularProgressIndicator());
//         }
//
//         if (snapshot.data!.docs.isEmpty) {
//           return Center(child: Text("No Promotions Available"));
//         }
//
//         return ListView(
//           children: snapshot.data!.docs.map((doc) {
//             Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//
//             return Card(
//               margin: EdgeInsets.all(8),
//               child: ListTile(
//                 leading: data['PImage'] != null && data['PImage'] is List
//                     ? Image.network(data['PImage'][0], width: 50, height: 50, fit: BoxFit.cover)
//                     : Icon(Icons.image),
//                 title: Text(data['PTitle'] ?? "No Title"),
//                 subtitle: Text("RM ${data['PPrice']}"),
//               ),
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
//
//   Widget _buildInstantBookingsList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore.collection('instant_booking').where('userId', isEqualTo: widget.docId).snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return Center(child: CircularProgressIndicator());
//         }
//
//         if (snapshot.data!.docs.isEmpty) {
//           return Center(child: Text("No Instant Booking Available"));
//         }
//
//         return ListView(
//           children: snapshot.data!.docs.map((doc) {
//             Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//
//             return Card(
//               margin: EdgeInsets.all(8),
//               child: ListTile(
//                 leading: data['IPImage'] != null && data['IPImage'] is List
//                     ? Image.network(data['IPImage'][0], width: 50, height: 50, fit: BoxFit.cover)
//                     : Icon(Icons.image),
//                 title: Text(data['IPTitle'] ?? "No Title"),
//                 subtitle: Text("RM ${data['IPPrice']}"),
//               ),
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
//
// }

import 'package:fix_mate/service_seeker/s_SPDetail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:fix_mate/service_seeker/s_PromotionPostInfo.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';



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
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Color(0xFFFFF8F2),
        appBar: AppBar(
          backgroundColor: Color(0xFFfb9798),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Service Provider Info",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          titleSpacing: 5,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Container(
            //   color: Colors.white,
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            //   child: Row(
            //     children: [
            //       CircleAvatar(
            //         radius: 35,
            //         backgroundImage: spData?['profilePic'] != null
            //             ? NetworkImage(spData!['profilePic'])
            //             : const AssetImage('assets/default_profile.png') as ImageProvider,
            //       ),
            //       const SizedBox(width: 16),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(spData?['name'] ?? "Unknown",
            //                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            //             const SizedBox(height: 2),
            //             Row(
            //               children: [
            //                 Text(
            //                   (spData?['rating']?.toStringAsFixed(1) ?? "0.0"),
            //                   style: const TextStyle(
            //                     fontSize: 16,
            //                     color: Colors.redAccent,
            //                     fontWeight: FontWeight.bold,
            //                   ),
            //                 ),
            //                 const SizedBox(width: 6), // spacing between rating text and stars
            //                 Row(
            //                   children: List.generate(5, (index) => Icon(
            //                     index < (spData?['rating'] ?? 0)
            //                         ? Icons.star
            //                         : Icons.star_border,
            //                     size: 18,
            //                     color: Colors.orange,
            //                   )),
            //                 ),
            //               ],
            //             ),
            //
            //             const SizedBox(height: 2),
            //             ElevatedButton.icon(
            //               onPressed: () {
            //                 final phone = spData!['phone'].toString();
            //                 final url = Uri.parse("https://wa.me/$phone");
            //                 launchUrl(url, mode: LaunchMode.externalApplication);
            //               },
            //               icon: const Icon(Icons.chat, color: Colors.white),
            //               label: const Text("Chat on WhatsApp"),
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: Colors.green,
            //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            //               ),
            //             ),
            //           ],
            //         ),
            //       )
            //     ],
            //   ),
            // ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SPDetailScreen(docId: widget.docId),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main Row Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: spData?['profilePic'] != null
                                ? NetworkImage(spData!['profilePic'])
                                : const AssetImage('assets/default_profile.png') as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  spData?['name'] ?? "Unknown",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      (spData?['rating']?.toStringAsFixed(1) ?? "0.0"),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Row(
                                      children: List.generate(5, (index) => Icon(
                                        index < (spData?['rating'] ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 18,
                                        color: Colors.orange,
                                      )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 50), // spacing to avoid overlap with WhatsApp
                        ],
                      ),
                    ),

                    // WhatsApp button - vertically centered
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Row(
                          children: [
                            // WhatsApp button (larger)
                            GestureDetector(
                              onTap: () {
                                final phone = spData!['phone'].toString();
                                final url = Uri.parse("https://wa.me/$phone");
                                launchUrl(url, mode: LaunchMode.externalApplication);
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.green, Colors.teal],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Grey arrow
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),


            const SizedBox(height: 10),
            // const TabBar(
            //   tabs: [
            //     Tab(text: 'Instant Booking'),
            //     Tab(text: 'Promotions'),
            //     Tab(text: 'Ratings'),
            //   ],
            //   labelColor: Color(0xFFfb9798),
            //   indicatorColor: Color(0xFFfb9798),
            // ),
            // Expanded(
            //   child: TabBarView(
            //     children: [
            //       _buildInstantBookingsList(),
            //       _buildPromotionsList(),
            //       _buildRatingsComingSoon(),
            //     ],
            //   ),
            // ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -4), // Top shadow to separate from upper content
                    ),
                  ],
                ),
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Instant Booking'),
                          Tab(text: 'Promotions'),
                          Tab(text: 'Ratings'),
                        ],
                        labelColor: Color(0xFFfb9798),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFFfb9798),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: TabBarView(
                            children: [
                              _buildInstantBookingsList(),
                              _buildPromotionsList(),
                              _buildRatingsComingSoon(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }



  Widget _buildPromotionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('promotion')
          .where('userId', isEqualTo: widget.docId)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No Promotions Available"));

        return GridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 12,
          childAspectRatio: 0.70, // Adjust this to control card height
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final postPrice = (data['PPrice'] as num?)?.toInt() ?? 0;
            final postDiscount = (data['PDiscountPercentage'] as num?)?.toDouble() ?? 0.0;

            return buildPromotionCard(
              PTitle: data['PTitle'] ?? "Unknown",
              ServiceStates: (data['ServiceStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
              ServiceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? "No services listed",
              imageUrls: (data['PImage'] != null && data['PImage'] is List<dynamic>) ? List<String>.from(data['PImage']) : [],
              PPrice: postPrice,
              PAPrice: (data['PAPrice'] as num?)?.toInt() ?? 0,
              PDiscountPercentage: postDiscount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => s_PromotionPostInfo(docId: doc.id)),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }


  Widget _buildInstantBookingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('instant_booking')
          .where('userId', isEqualTo: widget.docId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No Instant Bookings Available"));

        return GridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 12,
          childAspectRatio: 0.70, // Adjust based on visual preference
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final postPrice = (data['IPPrice'] as num?)?.toInt() ?? 0;

            return buildInstantBookingCard(
              IPTitle: data['IPTitle'] ?? "Unknown",
              ServiceStates: (data['ServiceStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
              ServiceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? "No services listed",
              imageUrls: (data['IPImage'] != null && data['IPImage'] is List<dynamic>)
                  ? List<String>.from(data['IPImage'])
                  : [],
              IPPrice: postPrice,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => s_InstantPostInfo(docId: doc.id),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }




  Widget _buildRatingsComingSoon() {
    return const Center(
      child: Text(
        "⭐ Ratings feature coming soon!",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFfb9798)),
      ),
    );
  }



  Widget buildPromotionCard({
    required String PTitle,
    required String ServiceStates,
    required String ServiceCategory,
    required List<String> imageUrls,
    required int PPrice,
    required int PAPrice,
    required double PDiscountPercentage,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      (imageUrls.isNotEmpty) ? imageUrls.first : "https://via.placeholder.com/150",
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ServiceStates,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.build, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ServiceCategory,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${PDiscountPercentage.toStringAsFixed(0)}% OFF",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "RM $PAPrice",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      "RM $PPrice",
                      style: const TextStyle(
                        color: Color(0xFF464E65),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInstantBookingCard({
    required String IPTitle,
    required String ServiceStates,
    required String ServiceCategory,
    required List<String> imageUrls,
    required int IPPrice,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      (imageUrls.isNotEmpty) ? imageUrls.first : "https://via.placeholder.com/150",
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          IPTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ServiceStates,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.build, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ServiceCategory,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 8,
                right: 10,
                child: Text(
                  "RM $IPPrice",
                  style: const TextStyle(
                    color: Color(0xFFfb9798),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}