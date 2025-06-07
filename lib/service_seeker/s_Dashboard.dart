import 'package:fix_mate/home_page/HomePage.dart';
import 'package:fix_mate/service_provider/p_HomePage.dart';
import 'package:fix_mate/service_seeker/s_BookingCalender.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_AInstantBookingDetail.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_BookingHistory.dart';
import 'package:fix_mate/service_seeker/s_Favourite.dart';
import 'package:fix_mate/service_seeker/s_ReviewRating/s_MyReview.dart';
import 'package:fix_mate/service_seeker/s_profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/service_provider/p_layout.dart';


class s_Dashboard extends StatefulWidget {
  static String routeName = "/service_provider/p_Dashboard";

  const s_Dashboard({Key? key}) : super(key: key);

  @override
  _s_DashboardState createState() => _s_DashboardState();
}

class _s_DashboardState extends State<s_Dashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String seekerName = "Loading...";
  String profilePicUrl = "";
  int totalReviews = 0;
  bool isLoading = true;
  Map<String, dynamic> operationHours = {};
  Map<String, int> unseenCounts = {
    'pending confirmation': 0,
    'active': 0,
    'completed': 0,
    'cancelled': 0,
  };
  List<Map<String, dynamic>> _upcomingBookings = [];


  String? seekerEmail;
  String? seekerRole;

  // Add these variables in your state class
  int instantFavCount = 0;
  int promoFavCount = 0;
  int providerFavCount = 0;
  int totalReviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSeekerData();
    _loadFavouritesAndReviews();
    _fetchUnseenCounts();
    _fetchUpcomingBookings();
    _loadCurrentUserInfo();
  }

  Future<void> _loadSeekerData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Load provider profile data
        DocumentSnapshot seekerDoc = await _firestore
            .collection('service_seekers')
            .doc(user.uid)
            .get();

        if (seekerDoc.exists) {
          Map<String, dynamic> seekerData = seekerDoc.data() as Map<String, dynamic>;

          // Load reviews data
          QuerySnapshot reviewsSnapshot = await _firestore
              .collection('reviews')
              .where('userId', isEqualTo: user.uid)
              .get();

          int reviewCount = reviewsSnapshot.docs.length;


          setState(() {
            seekerName = seekerData['name'] ?? 'Service Seeker';
            profilePicUrl = seekerData['profilePic'] ?? '';
            totalReviews = reviewCount;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading provider data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFavouritesAndReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final instantSnap = await FirebaseFirestore.instance
        .collection('service_seekers')
        .doc(uid)
        .collection('favourites_instant')
        .get();

    final promoSnap = await FirebaseFirestore.instance
        .collection('service_seekers')
        .doc(uid)
        .collection('favourites_promotion')
        .get();

    final providerSnap = await FirebaseFirestore.instance
        .collection('service_seekers')
        .doc(uid)
        .collection('favourites_provider')
        .get();

    final reviewSnap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: uid)
        .get();

    setState(() {
      instantFavCount = instantSnap.size;
      promoFavCount = promoSnap.size;
      providerFavCount = providerSnap.size;
      totalReviewCount = reviewSnap.size;
    });
  }


  Future<void> _fetchUnseenCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('s_notifications')
        .where('seekerId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final Map<String, int> tempCounts = {
      'pending confirmation': 0,
      'active': 0,
      'completed': 0,
      'cancelled': 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final bookingId = data['bookingId'];

      if (bookingId != null) {
        // 🔍 Correct way: match the field, not document ID
        final querySnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('bookingId', isEqualTo: bookingId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final bookingData = querySnapshot.docs.first.data();
          final statusRaw = bookingData['status'];

          if (statusRaw is String) {
            final status = statusRaw.toLowerCase();
            if (tempCounts.containsKey(status)) {
              tempCounts[status] = tempCounts[status]! + 1;
            }
          }
        }
      }
    }


    setState(() {
      unseenCounts = tempCounts; // 🔁 Used by your dashboard UI
    });
  }

  Future<void> _fetchUpcomingBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceSeekerId', isEqualTo: user.uid) // for seeker side
        .where('status', isEqualTo: "Active")
        .get();

    final bookings = snapshot.docs.map((doc) {
      final data = doc.data();
      final dateStr = data['finalDate'] ?? '';
      final timeStr = data['finalTime'] ?? '';

      DateTime? combined;
      try {
        final cleanDateStr = dateStr.replaceAll(RegExp(r'\s+'), ' ').trim();
        final cleanTimeStr = timeStr.replaceAll(RegExp(r'\s+'), ' ').trim();

        final parsedDate = DateFormat('d MMM yyyy').parseLoose(cleanDateStr);
        final parsedTime = DateFormat.jm().parseLoose(cleanTimeStr);

        combined = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          parsedTime.hour,
          parsedTime.minute,
        );
      } catch (e) {
        print('❌ Failed to parse: "$dateStr $timeStr" → $e');
      }

      return {
        'docId': doc.id,
        'bookingId': data['bookingId'] ?? '',
        'postId': data['postId'] ?? '',
        'serviceProviderId': data['serviceProviderId'] ?? '',
        'IPTitle': data['IPTitle'] ?? '',
        'finalDate': dateStr,
        'finalTime': timeStr,
        'location': data['location'] ?? '',
        'timestamp': combined,
      };

    }).where((b) => b['timestamp'] != null && b['timestamp'].isAfter(now)).toList();

    bookings.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    setState(() {
      _upcomingBookings = bookings.take(3).toList(); // top 3 nearest future
    });

    // ✅ Log after setState to confirm
    print("✅ Found ${_upcomingBookings.length} upcoming bookings");
  }



  void _logoutUser() async {
    try {
      await _auth.signOut(); // ✅ Firebase sign-out
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // ✅ Redirect to login
      );
    } catch (e) {
      print("Logout failed: $e");
    }
  }


  Future<void> _loadCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final doc = await FirebaseFirestore.instance.collection('service_seekers').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      setState(() {
        seekerEmail = data['email'] ?? user.email;
        seekerName = data['name'] ?? 'Unknown';
        seekerRole = data['role'] ?? 'Service Seeker';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // go back to previous screen
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const p_HomePage()),
            );
          }
          return false; // block default pop
        },
        child: ProviderLayout(
            selectedIndex: 3,
            child:Scaffold(
              backgroundColor: const Color(0xFFFFF8F2),
              appBar: AppBar(
                backgroundColor: const Color(0xFFfb9798),
                // leading: IconButton(
                //   icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                //   onPressed: () {
                //     Navigator.pop(context);
                //   },
                // ),
                title: const Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                ),
                titleSpacing: 25,
                automaticallyImplyLeading: false,
              ),
              body: Column(
                children: [
                  // Dashboard content - takes 1/3 of available space
                  Expanded(
                    flex: 1, // This takes 1/3 of the screen
                    child: ListView(
                      padding: const EdgeInsets.all(0),
                      children: [
                        _buildCompactSeekerInfoSection(),
                        _buildFavouriteReviewSection(),
                        _buildBookingOverviewSection(),
                        _buildUpcomingBookingsSection(),
                        _buildSupportSection()
                      ],
                    ),
                  ),
                ],
              ),
            )
        )
    );
  }


  Widget _buildCompactSeekerInfoSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const s_profile()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFFfb9798).withOpacity(0.15),
          highlightColor: const Color(0xFFfb9798).withOpacity(0.08),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFfb9798).withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFfb9798).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                // Compact Profile picture
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFfb9798),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFfb9798).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFF5F5F5),
                        backgroundImage: profilePicUrl.isNotEmpty
                            ? NetworkImage(profilePicUrl)
                            : null,
                        child: profilePicUrl.isEmpty
                            ? Icon(
                          Icons.person,
                          size: 30,
                          color: const Color(0xFFfb9798),
                        )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Compact text section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smaller welcome badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfb9798).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFfb9798).withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.waving_hand,
                              size: 13,
                              color: const Color(0xFFfb9798),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              "Welcome Back!",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFfb9798),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      // Compact name
                      Text(
                        isLoading ? "Loading..." : seekerName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Compact subtitle
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 12,
                            color: const Color(0xFF888888),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Tap to view profile",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF888888),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Compact arrow
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFfb9798).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFfb9798).withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: Color(0xFFfb9798),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


// Favourite and My Review Button
// Update the FavouriteReviewSection UI
  Widget _buildFavouriteReviewSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF8F8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFfb9798).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.dashboard_rounded, color: Color(0xFFfb9798), size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Quick Access", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const s_Favourite())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [const Color(0xFFfb9798), const Color(0xFFfb9798).withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFfb9798).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text("My Favourite", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(
                          "${instantFavCount + promoFavCount + providerFavCount} items",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const s_MyReview())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFfb9798), width: 2),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFfb9798).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFfb9798).withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.rate_review_rounded, color: Color(0xFFfb9798), size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text("My Review", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFfb9798)), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(
                          "$totalReviewCount reviews",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFfb9798)
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingOverviewSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with icon + title + "View History"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfb9798).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFFfb9798),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "My Bookings",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const s_BookingHistory()),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      "View History",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFfb9798),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFfb9798)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Booking status buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBookingShortcut(icon: Icons.pending_actions, label: "Pending", index: 0),
              _buildBookingShortcut(icon: Icons.play_circle_fill_outlined, label: "Active", index: 1),
              _buildBookingShortcut(icon: Icons.check_circle_outline, label: "Completed", index: 2),
              _buildBookingShortcut(icon: Icons.cancel_outlined, label: "Cancelled", index: 3),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildBookingShortcut({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final statusKeys = ['pending confirmation', 'active', 'completed', 'cancelled'];
    final badgeCount = unseenCounts[statusKeys[index]] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => s_BookingHistory(initialTabIndex: index),
          ),
        ).then((_) {
          _fetchUnseenCounts(); // 🔁 Refresh badge after returning
        });
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFfb9798).withOpacity(0.1),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: const Color(0xFFfb9798),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUpcomingBookingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFfb9798).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfb9798).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFFfb9798),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Upcoming Services",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const s_BookingCalender()),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      "View Calendar",
                      style: TextStyle(
                        color: Color(0xFFfb9798),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFfb9798)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Cards
          if (_upcomingBookings.isEmpty)
            Center(
              child: Text("No upcoming bookings", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            )
          else
            SingleChildScrollView(
              child: Column(
                children: _upcomingBookings.map((b) => _buildBookingCard(b)).toList(),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return InkWell(
      onTap: () {
        final postId = booking['postId'];
        final providerId = booking['serviceProviderId'];
        final bookingId = booking['bookingId'];

        if (postId == null || providerId == null || bookingId == null) {
          print("❌ Missing booking data:");
          print("postId: $postId");
          print("providerId: $providerId");
          print("bookingId: $bookingId");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Booking info is incomplete.")),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => s_AInstantBookingDetail(
              bookingId: bookingId,
              postId: postId,
              providerId: providerId,
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFfb9798).withOpacity(0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFfb9798).withOpacity(0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking['IPTitle'] ?? '',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 16, color: Color(0xFFfb9798)),
                const SizedBox(width: 6),
                Text("ID: ${booking['bookingId']}", style: const TextStyle(fontSize: 13, color: Color(0xFFfb9798), fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text("${booking['finalDate']} at ${booking['finalTime']}", style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Expanded(child: Text(booking['location'], style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFfb9798).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFfb9798).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent, color: Color(0xFFfb9798), size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                "Support",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Help Center Button (Elevated)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text("Help Center"),
              onPressed: () async {
                final Uri emailUri = Uri.parse(
                    "mailto:fixmate1168@gmail.com"
                        "?subject=FixMate%20Support%20Request%20from%20${Uri.encodeComponent(seekerName ?? 'User')}"
                        "&body=${Uri.encodeComponent('Dear FixMate Team,\n\n'
                        'I am experiencing an issue and would like assistance. Please find my details below:\n\n'
                        '- Name: ${seekerName ?? 'N/A'}\n'
                        '- Email: ${seekerEmail ?? 'N/A'}\n'
                        '- Role: ${seekerRole ?? 'N/A'}\n\n'
                        'Describe your issue here...\n\n'
                        'Thank you,\n'
                        '${seekerName ?? 'User'}')}"
                );

                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFfb9798),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Log Out Button (Outlined)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                "Log Out",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed: _logoutUser,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFfb9798),
                side: const BorderSide(color: Color(0xFFfb9798), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

}