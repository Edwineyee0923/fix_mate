import 'package:fix_mate/service_seeker/s_SPDetail.dart';
import 'package:fix_mate/service_seeker/s_SPRating.dart';
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
  double averageRating = 0.0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _fetchSPDetails();
    loadRatingSummary();
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

  Future<void> loadRatingSummary() async {
    final result = await fetchProviderReviewSummary(widget.docId);
    setState(() {
      averageRating = result['avgRating'];
      totalReviews = result['count'];
    });
  }


  Future<Map<String, dynamic>> fetchProviderReviewSummary(String providerId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('providerId', isEqualTo: providerId)
        .get();

    final reviews = querySnapshot.docs;

    if (reviews.isEmpty) {
      return {
        'avgRating': 0.0,
        'count': 0,
      };
    }

    double totalRating = 0.0;

    for (var doc in reviews) {
      final data = doc.data() as Map<String, dynamic>;
      totalRating += (data['rating'] ?? 0).toDouble();
    }

    final double avgRating = totalRating / reviews.length;

    return {
      'avgRating': avgRating,
      'count': reviews.length,
    };
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
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => s_SPRating(providerId: widget.docId)),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFFFF7EC), Color(0xFFFEE9D7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(color: Colors.orange.shade100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${averageRating.toStringAsFixed(1)}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.grey[800],                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          "| $totalReviews Reviews",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
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
                        ],
                        labelColor: Color(0xFFfb9798),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFFfb9798),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          child: TabBarView(
                            children: [
                              _buildInstantBookingsList(),
                              _buildPromotionsList(),
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
          padding: const EdgeInsets.all(0),
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
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          crossAxisCount: 2,
          crossAxisSpacing: 1,
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
        margin: const EdgeInsets.symmetric(horizontal: 10),
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