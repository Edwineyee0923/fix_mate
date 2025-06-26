import 'package:fix_mate/home_page/HomePage.dart';
import 'package:fix_mate/service_provider/p_BookingCalender.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_ABookingDetail.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
import 'package:fix_mate/service_provider/p_HomePage.dart';
import 'package:fix_mate/service_provider/p_Revenue.dart';
import 'package:fix_mate/service_provider/p_SchedulePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/service_provider/p_profile.dart';
import 'package:fix_mate/service_provider/p_ReviewRating/p_Rating.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/service_provider/p_layout.dart';


class p_Dashboard extends StatefulWidget {
  static String routeName = "/service_provider/p_Dashboard";

  const p_Dashboard({Key? key}) : super(key: key);

  @override
  _p_DashboardState createState() => _p_DashboardState();
}

class _p_DashboardState extends State<p_Dashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String providerName = "Loading...";
  String profilePicUrl = "";
  double averageRating = 0.0;
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


  String? providerEmail;
  String? providerRole;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
    _fetchUnseenCounts();
    _fetchUpcomingBookings();
    _loadCurrentUserInfo();
  }

  Future<void> _loadProviderData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Load provider profile data
        DocumentSnapshot providerDoc = await _firestore
            .collection('service_providers')
            .doc(user.uid)
            .get();

        if (providerDoc.exists) {
          Map<String, dynamic> providerData = providerDoc.data() as Map<String, dynamic>;

          // Load reviews data
          QuerySnapshot reviewsSnapshot = await _firestore
              .collection('reviews')
              .where('providerId', isEqualTo: user.uid)
              .get();

          double totalRating = 0;
          int reviewCount = reviewsSnapshot.docs.length;

          for (var doc in reviewsSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalRating += (data['rating'] ?? 0).toDouble();
          }

          setState(() {
            providerName = providerData['name'] ?? 'Service Provider';
            profilePicUrl = providerData['profilePic'] ?? '';
            totalReviews = reviewCount;
            averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
            operationHours = Map<String, dynamic>.from(providerData['availability'] ?? {});
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


  Future<void> _fetchUnseenCounts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: currentUser.uid)
        .where('providerHasSeen', isEqualTo: false)
        .get();

    final Map<String, int> tempCounts = {
      'pending confirmation': 0,
      'active': 0,
      'completed': 0,
      'cancelled': 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final statusRaw = data['status'];
      if (statusRaw is String) {
        final status = statusRaw.toLowerCase();
        if (tempCounts.containsKey(status)) {
          tempCounts[status] = tempCounts[status]! + 1;
        }
      }
    }


    setState(() {
      unseenCounts = tempCounts;
    });
  }

  Future<void> _fetchUpcomingBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: user.uid)
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
        'serviceSeekerId': data['serviceSeekerId'] ?? '',
        'IPTitle': data['IPTitle'] ?? '',
        'finalDate': dateStr,
        'finalTime': timeStr,
        'location': data['location'] ?? '',
        'timestamp': combined,
      };
    }).where((b) => b['timestamp'] != null && b['timestamp'].isAfter(now)).toList();

    bookings.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    setState(() {
      _upcomingBookings = bookings.take(3).toList();
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
    final doc = await FirebaseFirestore.instance.collection('service_providers').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      setState(() {
        providerEmail = data['email'] ?? user.email;
        providerName = data['name'] ?? 'Unknown';
        providerRole = data['role'] ?? 'Service Provider';
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
        backgroundColor: const Color(0xFF464E65),
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
                _buildCompactProviderInfoSection(),
                _buildCompactOperationScheduleSection(),
                _buildBookingOverviewSection(),
                _buildUpcomingBookingsSection(),
                _buildRevenueSection(),
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

// Alternative Option 2: Using fixed height (1/3 of screen height)
// Replace the body with this if you prefer fixed height:
/*
body: Column(
  children: [
    // Dashboard content - fixed to 1/3 of screen height
    SizedBox(
      height: MediaQuery.of(context).size.height * 0.33, // 1/3 of screen height
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          _buildCompactProviderInfoSection(),
          _buildCompactOperationScheduleSection(),
        ],
      ),
    ),
    // Remaining space
    Expanded(
      child: Container(
        color: const Color(0xFFFFF8F2),
        child: Center(
          child: Text(
            "Additional content can go here",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    ),
  ],
),
*/

Widget _buildCompactProviderInfoSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const p_profile()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Profile picture
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF464E65).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: profilePicUrl.isNotEmpty
                      ? NetworkImage(profilePicUrl)
                      : null,
                  child: profilePicUrl.isEmpty
                      ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Name + rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? "Loading..." : providerName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF464E65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Rating button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const p_Rating()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF7EC), Color(0xFFFEE9D7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.15),
                              blurRadius: 6,
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
                              averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "| $totalReviews ${totalReviews == 1 ? 'Review' : 'Reviews'}",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow to profile
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF6C7CE7),
              ),
            ],
          ),
        ),
      ),
    );
  }


// Compact version of operation schedule section
  Widget _buildCompactOperationScheduleSection() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final fullDays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // reduced top padding
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
          // Compact header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C7CE7).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled,
                      color: Color(0xFF464E65),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Operation Hour",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF464E65),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const p_SchedulePage()),
                  ).then((_) {
                    _loadProviderData(); // 🔁 Refresh the schedule section after returning
                  });
                },

                child: Row(
                  children: const [
                    const Text(
                      "Edit",
                      style: TextStyle(
                        color: Color(0xFF6C7CE7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6C7CE7)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Horizontal scrollable schedule
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final dayKey = fullDays[index];
                final raw = operationHours[dayKey];

                // Check if availability is not set at all (i.e., no 'availability' field in Firebase)
                final availabilitySet = operationHours.isNotEmpty;

                Map<String, dynamic> schedule = {};
                if (raw != null && raw is Map<String, dynamic>) {
                  schedule = Map<String, dynamic>.from(raw);
                }

                final start = schedule['start'];
                final end = schedule['end'];
                final isOpen = start != null && end != null;

                String statusText;
                if (!availabilitySet) {
                  statusText = "Available"; // default fallback if field doesn't exist
                } else if (isOpen) {
                  try {
                    final startTime = DateFormat.jm().format(DateFormat("h:mm a").parse(start));
                    final endTime = DateFormat.jm().format(DateFormat("h:mm a").parse(end));
                    statusText = "$startTime -\n$endTime";
                  } catch (_) {
                    statusText = "Invalid";
                  }

                } else {
                  statusText = "Closed";
                }

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusText == "Closed"
                        ? Colors.grey.withOpacity(0.1)
                        : const Color(0xFF6C7CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusText == "Closed"
                          ? Colors.grey.withOpacity(0.3)
                          : const Color(0xFF6C7CE7).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusText == "Closed" ? Colors.grey[600] : const Color(0xFF6C7CE7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: statusText == "Closed" ? Colors.grey[600] : const Color(0xFF6C7CE7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )

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
                      color: const Color(0xFF6C7CE7).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF464E65),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "My Bookings",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF464E65),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const p_BookingHistory()),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      "View History",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C7CE7),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6C7CE7)),
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
            builder: (_) => p_BookingHistory(initialTabIndex: index),
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
                  color: const Color(0xFF6C7CE7).withOpacity(0.08),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: const Color(0xFF464E65),
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
              color: Color(0xFF464E65),
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
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
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
                      color: const Color(0xFF6C7CE7).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF464E65),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Next Service",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF464E65),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const p_BookingCalender()),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      "View Calendar",
                      style: TextStyle(
                        color: Color(0xFF6C7CE7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6C7CE7)),
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
          final seekerId = booking['serviceSeekerId'];
          final bookingId = booking['bookingId'];

          if (postId == null || seekerId == null || bookingId == null) {
            print("❌ Missing booking data:");
            print("postId: $postId");
            print("providerId: $seekerId");
            print("bookingId: $bookingId");

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Booking info is incomplete.")),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => p_ABookingDetail(
                bookingId: bookingId,
                postId: postId,
                seekerId: booking['serviceSeekerId'],
              ),
            ),
          );
        },
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6C7CE7).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C7CE7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking['IPTitle'] ?? '',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF464E65)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 16, color: Color(0xFF6C7CE7)),
              const SizedBox(width: 6),
              Text("ID: ${booking['bookingId']}", style: const TextStyle(fontSize: 13, color: Color(0xFF6C7CE7))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text("${booking['finalDate']} at ${booking['finalTime']}", style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(booking['location'], style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildRevenueSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
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
                      color: const Color(0xFF6C7CE7).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Color(0xFF464E65),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "June Revenue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF464E65),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to detailed analytics page
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => p_Revenue()), // Replace with your actual class name
                    );
                  },
                  child: const Row(
                    children: [
                      Text(
                        "View Details",
                        style: TextStyle(
                          color: Color(0xFF6C7CE7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6C7CE7)),
                    ],
                  ),
                )
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie Chart Section
              Container(
                width: 130,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 20,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        ),
                        // Promotion jobs (1/3 = 0.333)
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: 0.333,
                            strokeWidth: 20,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C7CE7)), // Purple
                          ),
                        ),
                        // Instant booking (2/3 = 0.667) - rotated to start after promotion
                        Transform.rotate(
                          angle: 0.333 * 2 * 3.14159,
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: 0.667,
                              strokeWidth: 20,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8A65)), // Orange
                            ),
                          ),
                        ),
                        // Center Text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              "Total Jobs",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF464E65),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "3",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF464E65),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),


              const SizedBox(width: 20),

              // Summary Card Section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Revenue Summary",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF464E65),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Total Revenue
                      _buildSummaryItem(
                        "Total Revenue",
                        "RM 440",
                        const Color(0xFF22C55E),
                      ),
                      const SizedBox(height: 6),

                      // FiMate Commission
                      _buildSummaryItem(
                        "Commission Due",
                        "RM 22",
                        const Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 6),

                      // Net Earnings
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C7CE7).withOpacity(0.2), // slightly more visible
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Net Earnings",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF464E65),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "RM 418",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C7CE7),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Instant Booking", const Color(0xFFFF8A65), "2"),
              const SizedBox(width: 24),
              _buildLegendItem("Promotion Jobs", const Color(0xFF6C7CE7), "1"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "$label ($count)",
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }





  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      padding: const EdgeInsets.all(16),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C7CE7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent, color: Color(0xFF464E65), size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                "Support",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF464E65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Help Center Button (Outlined)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text("Help Center"),
              onPressed: () async {
                final Uri emailUri = Uri.parse(
                    "mailto:fixmate1168@gmail.com"
                        "?subject=FixMate%20Support%20Request%20from%20${Uri.encodeComponent(providerName ?? 'User')}"
                        "&body=${Uri.encodeComponent('Dear FixMate Team,\n\n'
                        'I am experiencing an issue and would like assistance. Please find my details below:\n\n'
                        '- Name: ${providerName ?? 'N/A'}\n'
                        '- Email: ${providerEmail ?? 'N/A'}\n'
                        '- Role: ${providerRole ?? 'N/A'}\n\n'
                        'Describe your issue here...\n\n'
                        'Thank you,\n'
                        '${providerName ?? 'User'}')}"
                );

                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF464E65),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Log Out Button (Elevated)
          // Log Out Button (Secondary)
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
                foregroundColor: const Color(0xFF464E65),
                side: const BorderSide(color: Color(0xFF464E65), width: 1.5),
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