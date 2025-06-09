import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:fix_mate/service_seeker/s_InstantPostList.dart';
import 'package:fix_mate/service_seeker/s_PromotionPostInfo.dart';
import 'package:fix_mate/service_seeker/s_PromotionPostList.dart';
import 'package:fix_mate/service_seeker/s_SPInfo.dart';
import 'package:fix_mate/service_seeker/s_SPList.dart';
import 'package:fix_mate/service_seeker/s_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'dart:io'; // For exit()
import 'package:flutter/services.dart';
import 'package:fix_mate/services/showBookingNotification.dart';
import 'package:intl/intl.dart';



class s_HomePage extends StatefulWidget {
  static String routeName = "/service_seeker/s_HomePage";

  const s_HomePage({Key? key}) : super(key: key);

  @override
  _s_HomePageState createState() => _s_HomePageState();
}

class _s_HomePageState extends State<s_HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Widget> allInstantPosts = [];
  List<Widget> filteredInstantPosts = []; // Stores filtered instant booking posts
  List<Widget> displayedInstantPosts = []; // ✅ Stores 4 newest posts or filtered results


  List<Widget> allPromotionPosts = [];
  List<Widget> filteredPromotionPosts = []; // Stores filtered promotion posts
  List<Widget> displayedPromotionPosts = []; // ✅ Stores 4 newest posts or filtered results
  TextEditingController _searchController = TextEditingController();

  List<Widget> allSPPosts = [];
  List<Widget> filteredSPPosts = []; // Stores filtered promotion posts
  List<Widget> displayedSPPosts = []; // ✅ Stores 4 newest posts or filtered results
  List<Widget> providerFavourites = [];

  @override
  void initState() {
    super.initState();
    _loadInstantPosts(); // Load posts when the page initializes
    _loadPromotionPosts(); // Load posts when the page initializes
    print("Initializing service provider fetch...");
    _loadSPPosts(); // Load posts when the page initializes
    _checkAndScheduleUpcomingBookings();
  }

  Future<void> _checkAndScheduleUpcomingBookings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('seekerId', isEqualTo: currentUser.uid) // or 'providerId'
        .where('status', isEqualTo: 'Active')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final bookingId = doc.id;
      final postId = data['postId'];
      final seekerId = data['seekerId'];
      final providerId = data['providerId'];
      final dateStr = data['finalDate'];
      final timeStr = data['finalTime'];

      if (dateStr == null || timeStr == null) continue;

      final finalDateTime = DateFormat("d MMM yyyy h:mm a").parse("$dateStr $timeStr");

      // 🟡 Your scheduleBookingReminders() method goes here
      await scheduleBookingReminders(
        bookingId: bookingId,
        postId: postId,
        seekerId: seekerId,
        providerId: providerId,
        finalDateTime: finalDateTime,
      );
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Exit Application",
        message: "Are you sure you want to leave this application?",
        confirmText: "Yes",
        cancelText: "No",
        icon: Icons.exit_to_app,
        iconColor: const Color(0xFFfb9798),
        confirmButtonColor: const Color(0xFFfb9798),
        cancelButtonColor: Colors.white,
        onConfirm: () {
          if (Platform.isAndroid) {
            SystemNavigator.pop(); // Smooth close on Android
          } else if (Platform.isIOS) {
            // iOS doesn't support closing programmatically — suggest user to swipe up
            Navigator.of(context).pop(); // Just close dialog
          }
        },
      ),
    ) ??
        false;
  }

  void _filterInstantPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedInstantPosts = allInstantPosts.take(4).toList(); // ✅ Reset to newest 4 posts
      } else {
        displayedInstantPosts = allInstantPosts.where((post) {
          String title = (post.key as ValueKey<String>?)?.value ?? "";
          return title.toLowerCase().contains(query.toLowerCase());
        }).toList(); // ✅ Show filtered results
      }
    });
  }

  void _filterPromotionPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedPromotionPosts = allPromotionPosts.take(4).toList(); // ✅ Reset to latest 4 posts
      } else {
        displayedPromotionPosts = allPromotionPosts.where((post) {
          String title = (post.key as ValueKey<String>?)?.value ?? "";
          return title.toLowerCase().contains(query.toLowerCase());
        }).toList(); // ✅ Show filtered results
      }
    });
  }

  void _filterSPPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedSPPosts = allSPPosts.take(4).toList(); // ✅ Reset to latest 4 posts
      } else {
        displayedSPPosts = allSPPosts.where((post) {
          String name = (post.key as ValueKey<String>?)?.value ?? "";
          return name.toLowerCase().contains(query.toLowerCase());
        }).toList(); // ✅ Show filtered results
      }
    });
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          _filterInstantPosts(query);  // ✅ Updates Instant Booking Section
          _filterPromotionPosts(query);
          _filterSPPosts(query); // ✅ Updates Promotion Section
        },
        decoration: InputDecoration(
          hintText: "Search your SP name or post title...",
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Color(0xFFfb9798)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              _filterInstantPosts("");
              _filterPromotionPosts("");
              _filterSPPosts("");
              FocusScope.of(context).unfocus(); // Optional: close keyboard
            },
          )
              : null,
        ),
      ),
    );
  }



  Future<void> _loadInstantPosts() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User not logged in");
        return;
      }

      // Query query = _firestore.collection('instant_booking').orderBy('updatedAt', descending: true);
      Query query = _firestore
          .collection('instant_booking')
          .where('isActive', isEqualTo: true) // ✅ Filter active posts only
          .orderBy('updatedAt', descending: true);

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("No instant booking posts found.");
      } else {
        print("Fetched ${snapshot.docs.length} instant booking posts");
      }


      // List<Widget> instantPosts = snapshot.docs.map((doc) {
      //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // 👇 Use Future.wait to handle async inside the loop
      List<Widget> instantPosts = await Future.wait(snapshot.docs.map((doc) async {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 👇 Fetch review summary
        final reviewSummary = await fetchPostReviewSummary(doc.id);
        final double avgRating = reviewSummary['avgRating'] ?? 0.0;
        final int reviewCount = reviewSummary['count'] ?? 0;

        return KeyedSubtree(
          key: ValueKey<String>(data['IPTitle'] ?? "Unknown"),
          child: buildInstantBookingCard(
            docId: doc.id,
            avgRating: avgRating,
            reviewCount: reviewCount,
            IPTitle: data['IPTitle'] ?? "Unknown",
            ServiceStates: (data['ServiceStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
            ServiceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? "No services listed",
            imageUrls: (data['IPImage'] != null && data['IPImage'] is List<dynamic>)
                ? List<String>.from(data['IPImage'])
                : [],
            IPPrice: (data['IPPrice'] as num?)?.toInt() ?? 0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => s_InstantPostInfo(docId: doc.id),
                ),
              );
            },
          ),
        );
      }).toList());

      setState(() {
        allInstantPosts = instantPosts;
        displayedInstantPosts = allInstantPosts.take(4).toList(); // ✅ Show only 4 newest posts
      });
    } catch (e) {
      print("Error loading Instant Booking Posts: $e");
    }
  }



  Future<void> _loadPromotionPosts() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User not logged in");
        return;
      }

      // print("Fetching posts for userId: ${user.uid}");

      Query query = _firestore
          .collection('promotion')
          .where('isActive', isEqualTo: true) // ✅ Only active posts
          .orderBy('updatedAt', descending: true);

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("No promotion posts found.");
      } else {
        print("Fetched ${snapshot.docs.length} promotion posts");
      }

      // List<Widget> promotionPosts = snapshot.docs.map((doc) {
      //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // 👇 Use Future.wait to handle async inside the loop
      List<Widget> promotionPosts = await Future.wait(snapshot.docs.map((doc) async {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 👇 Fetch review summary
        final reviewSummary = await fetchPostReviewSummary(doc.id);
        final double avgRating = reviewSummary['avgRating'] ?? 0.0;
        final int reviewCount = reviewSummary['count'] ?? 0;

        return KeyedSubtree(
          key: ValueKey<String>(data['PTitle'] ?? "Unknown"),
          child: buildPromotionCard(
            docId: doc.id,
            avgRating: avgRating,
            reviewCount: reviewCount,
            PTitle: data['PTitle'] ?? "Unknown",
            ServiceStates: (data['ServiceStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
            ServiceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? "No services listed",
            imageUrls: (data['PImage'] != null && data['PImage'] is List<dynamic>)
                ? List<String>.from(data['PImage'])
                : [],
            PPrice: (data['PPrice'] as num?)?.toInt() ?? 0,
            PAPrice: (data['PAPrice'] as num?)?.toInt() ?? 0,
            PDiscountPercentage: (data['PDiscountPercentage'] as num?)?.toDouble() ?? 0.0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => s_PromotionPostInfo(docId: doc.id),
                ),
              );
            },
          ),
        );
      }).toList());


      setState(() {
        allPromotionPosts = promotionPosts;
        displayedPromotionPosts = allPromotionPosts.take(4).toList(); // ✅ Show only 4 newest posts
      });
    } catch (e) {
      print("Error loading Promotion Posts: $e");
    }
  }

  Future<void> _loadSPPosts() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User not logged in");
        return;
      }

      Query query = _firestore
                    .collection('service_providers')
                    .where('status', isEqualTo: 'Approved')
                    .orderBy('createdAt', descending: true);
      QuerySnapshot snapshot = await query.get();

      print("Fetched ${snapshot.docs.length} service providers"); // ✅ Check how many docs are retrieved

      if (snapshot.docs.isEmpty) {
        print("No service provider found.");
      } else {
        print("Fetched ${snapshot.docs.length} service providers");
      }

      // 👇 Use Future.wait to handle async inside the loop
      List<Widget> SPPosts = await Future.wait(snapshot.docs.map((doc) async {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 👇 Fetch review summary
        final reviewSummary = await fetchProviderReviewSummary(doc.id);
        data['averageRating'] = reviewSummary['avgRating'];
        data['totalReviews'] = reviewSummary['count'];

        return KeyedSubtree(
          key: ValueKey<String>(data['name'] ?? "Unknown"),
          child: buildSPCard(
            docId: doc.id,
            name: data['name'] ?? "Unknown",
            location: (data['selectedStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
            services: (data['selectedExpertiseFields'] as List<dynamic>?)?.join(", ") ?? "No services listed",
            imageUrl: data['profilePic'] ?? "", // Default image if null
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceProviderScreen(docId: doc.id),
                ),
              );
            },
            onUnfavourite: () {
              setState(() {
                providerFavourites.removeWhere((w) => w.key == ValueKey(doc.id));
              });
            },

          ),
        );
      }).toList());
      print("Total SPPosts created: ${SPPosts.length}"); // ✅ Check if the list is populated


      setState(() {
        allSPPosts = SPPosts;
        displayedSPPosts = allSPPosts.take(4).toList(); // ✅ Show only 4 newest posts
      });

      print("Displayed SP Posts: ${displayedSPPosts.length}"); // ✅ Check if displayed list is updated
    } catch (e) {
      print("Error loading service providers posts details: $e");
    }
  }


  Widget _buildInstantBookingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Instant Booking",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              // ✅ "See More" button with dynamic opacity & interactivity
              GestureDetector(
                onTap: allInstantPosts.isNotEmpty
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => s_InstantPostList(),
                    ),
                  );
                }
                    : null, // Disabled if no posts
                child: Opacity(
                  opacity: allInstantPosts.isNotEmpty ? 1.0 : 0.5, // Faded if no posts
                  child: Row(
                    children: const [
                      Text(
                        "See more",
                        style: TextStyle(color: Color(0xFFfb9798), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 4), // ✅ Adds spacing between text and icon
                      Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFfb9798)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ✅ Display message if no posts exist
          displayedInstantPosts.isEmpty
              ? const Text(
            "No instant booking post found.",
            style: TextStyle(color: Colors.black54),
          )
              : SizedBox(
            height: 290,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: displayedInstantPosts), // ✅ Updates dynamically
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildPromotionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Promotion",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              // ✅ "See More" button with dynamic opacity & interactivity
              GestureDetector(
                onTap: allPromotionPosts.isNotEmpty
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => s_PromotionPostList(),
                    ),
                  );
                }
                    : null, // Disabled if no posts
                child: Opacity(
                  opacity: allPromotionPosts.isNotEmpty ? 1.0 : 0.5, // Faded if no posts
                  child: Row(
                    children: const [
                      Text(
                        "See more",
                        style: TextStyle(color: Color(0xFFfb9798), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 4), // ✅ Adds spacing between text and icon
                      Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFfb9798)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ✅ Show "No Posts" message if no promotions exist
          displayedPromotionPosts.isEmpty
              ? const Text(
            "No promotion post found.",
            style: TextStyle(color: Colors.black54),
          )
              : SizedBox(
            height: 290,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: displayedPromotionPosts), // ✅ Updated dynamically
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSPSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4), // Matches the promotion section padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Service Providers",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Matches the title style
              ),
              if (displayedSPPosts.isNotEmpty)
                GestureDetector(
                  onTap: allSPPosts.isNotEmpty
                      ? () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) => s_SPList(),
                    ),
                    );
                  }
                      : null, // Disables the button if there are no more service providers
                  child: Opacity(
                    opacity: allSPPosts.isNotEmpty ? 1.0 : 0.5, // Matches the "See More" styling
                    child: Row(
                      children: const [
                        Text(
                          "See more",
                          style: TextStyle(color: Color(0xFFfb9798), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFfb9798)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8), // Ensures consistent spacing

          // Displays a message if there are no service providers, aligned with the title
          displayedSPPosts.isEmpty
              ? const Align(
            alignment: Alignment.centerLeft, // Aligns text to the left
            child: Padding(
              padding: EdgeInsets.only(left:0), // Adjusts spacing to match the title
              child: Text(
                "No service providers available.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          )
              : SizedBox(
            height: 160, // Keeps the height consistent
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10), // Prevents content from touching the edges
              scrollDirection: Axis.horizontal, // Enables horizontal scrolling
              itemCount: displayedSPPosts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12), // Keeps spacing between cards
                  child: SizedBox(
                    width: 360, // Keeps the card width consistent
                    child: displayedSPPosts[index], // Displays the service provider card
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () => _onWillPop(context),
    child:SeekerLayout(
        selectedIndex: 0,
        child: Scaffold(
          backgroundColor: Color(0xFFFFF8F2),
          appBar: AppBar(
            backgroundColor: Color(0xFFfb9798),
            title: Text(
              "Home Page",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,),
            ),
            titleSpacing: 25,
            automaticallyImplyLeading: false,
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 4),
                _buildSPSection(),
                _buildPromotionSection(),
                const SizedBox(height: 2),
                _buildInstantBookingSection(),
              ],
            ),
          ),
        )
    )
    );
  }
}

Widget buildInstantBookingCard({
  required String IPTitle,
  required String ServiceStates,
  required String ServiceCategory,
  required List<String> imageUrls,
  required int IPPrice,
  required String docId,
  required double avgRating,
  required int reviewCount,
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
                              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w400),
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
                              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w400),
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

            // ⭐ Favorite Button
            Positioned(
              top: 6,
              right: 6,
              child: Builder(
                builder: (BuildContext context) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Material(
                      color: Colors.white,
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return FavoriteButton(instantBookingId: docId);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // ⭐ Rating (Bottom-left)
            Positioned(
              bottom: 12,
              left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7EC), Color(0xFFFEE9D7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.orange.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 💸 Price (Bottom-right)
            Positioned(
              bottom: 6,
              right: 12,
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



Widget buildPromotionCard({
  required String PTitle,
  required String ServiceStates,
  required String ServiceCategory,
  required List<String> imageUrls,
  required int PPrice,
  required int PAPrice,
  required double PDiscountPercentage,
  required String docId,
  required double avgRating, // ⭐️ New
  required int reviewCount,  // ⭐️ New
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
                              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w400),
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
                              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w400),
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

            // Favorite button
            Positioned(
              top: 6,
              right: 6,
              child: Builder(
                builder: (BuildContext context) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Material(
                      color: Colors.white,
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return FavoriteButton3(promotionId: docId);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Discount Badge
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

            // ⭐️ Rating badge (bottom-left)
            Positioned(
              bottom: 12,
              left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7EC), Color(0xFFFEE9D7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.orange.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Price
            Positioned(
              bottom: 6,
              right: 12,
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
                      color: Color(0xFFfb9798),
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


Widget buildSPCard({
  required String docId,
  required String name,
  required String location,
  required String services,
  required String imageUrl,
  required VoidCallback onTap,
  required VoidCallback onUnfavourite, // ✅ Add this

}) {
  return GestureDetector(
    onTap: onTap,
    child: Center(
      child: Container(
        width: 360,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none, // ✅ Allows elements to overflow outside the container
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "assets/default_profile.png",
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.build, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  services,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Star Rating
                          Container(
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
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: fetchProviderReviewSummary(docId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Text("Loading...", style: TextStyle(fontSize: 12));
                                }

                                final data = snapshot.data!;
                                final avgRating = data['avgRating'] as double;
                                final count = data['count'] as int;

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 3),
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "| $count Reviews",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Favorite Button - Half inside the container, half outside
            Positioned(
              top: -3,
              left: -10,// ✅ Moves half of the icon outside
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // ✅ Background to make it visible
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: FavoriteButton2(
                  providerId: docId,
                  onUnfavourite: onUnfavourite, // ✅ Pass callback to button
                  ), // or data['providerId'],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



// Service Provider Favourite
class FavoriteButton2 extends StatefulWidget {
  final String providerId;
  final VoidCallback? onUnfavourite; // ✅ Add this

  const FavoriteButton2({
    Key? key,
    required this.providerId,
    this.onUnfavourite, // ✅ Add this
  }) : super(key: key);

  @override
  _FavoriteButton2State createState() => _FavoriteButton2State();
}

class _FavoriteButton2State extends State<FavoriteButton2> {
  bool isFavorite = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('service_seekers')
        .doc(user!.uid)
        .collection('favourites_provider')
        .doc(widget.providerId)
        .get();

    setState(() {
      isFavorite = doc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('service_seekers')
        .doc(user!.uid)
        .collection('favourites_provider')
        .doc(widget.providerId);

    try {
      if (isFavorite) {
        await favRef.delete();
        widget.onUnfavourite?.call(); // ✅ Trigger removal callback
        ReusableSnackBar(context, "Removed provider from favourites",
            icon: Icons.favorite_border, iconColor: Colors.grey);
      } else {
        await favRef.set({
          'providerId': widget.providerId,
          'favoritedAt': FieldValue.serverTimestamp(),
        });
        ReusableSnackBar(context, "Added provider to favourites",
            icon: Icons.favorite, iconColor: Color(0xFFF06275), );
      }

      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      ReusableSnackBar(context, "Failed to update provider favourite",
          icon: Icons.error, iconColor: Colors.red);
      print("❌ Error toggling provider favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isFavorite
                ? const Color(0xFFF06275).withOpacity(0.5)
                : Colors.grey.withOpacity(0.0),
            spreadRadius: 2,
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 22,
            color: isFavorite ? const Color(0xFFF06275) : Colors.black,
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _toggleFavorite,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// Instant Booking Favourite
class FavoriteButton extends StatefulWidget {
  final String instantBookingId;
  final VoidCallback? onUnfavourite;

  const FavoriteButton({
    Key? key,
    required this.instantBookingId,
    this.onUnfavourite,
  }) : super(key: key);

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool isFavorite = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('service_seekers')
        .doc(user!.uid)
        .collection('favourites_instant')
        .doc(widget.instantBookingId)
        .get();

    setState(() {
      isFavorite = doc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('service_seekers')
        .doc(user!.uid)
        .collection('favourites_instant')
        .doc(widget.instantBookingId);

    try {
      if (isFavorite) {
        await favRef.delete();
        widget.onUnfavourite?.call(); // ✅ Call the callback
        ReusableSnackBar(context, "Removed from favourites", icon: Icons.favorite_border, iconColor: Colors.grey);
      } else {
        await favRef.set({
          'instantBookingId': widget.instantBookingId,
          'favoritedAt': FieldValue.serverTimestamp(),
        });
        ReusableSnackBar(context, "Added to favourites", icon: Icons.favorite, iconColor: Color(0xFFF06275));
      }

      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      ReusableSnackBar(context, "Failed to update favourite", icon: Icons.error, iconColor: Colors.red);
      print("❌ Error toggling favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 25,
          color: isFavorite ? const Color(0xFFF06275) : Colors.black,
        ),
        onPressed: _toggleFavorite,
      ),
    );
  }
}




// Promotion Favourite
class FavoriteButton3 extends StatefulWidget {
  final String promotionId;
  final VoidCallback? onUnfavourite; // ✅ Add optional callback

  const FavoriteButton3({
    Key? key,
    required this.promotionId,
    this.onUnfavourite,
  }) : super(key: key);

  @override
  _FavoriteButton3State createState() => _FavoriteButton3State();
}

class _FavoriteButton3State extends State<FavoriteButton3> {
  bool isFavorite = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('service_seekers')
        .doc(user!.uid)
        .collection('favourites_promotion')
        .doc(widget.promotionId)
        .get();

    setState(() {
      isFavorite = doc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('service_seekers')
        .doc(user!.uid)
        .collection('favourites_promotion')
        .doc(widget.promotionId);

    try {
      if (isFavorite) {
        await favRef.delete();
        widget.onUnfavourite?.call(); // ✅ Call the callback if exists
        ReusableSnackBar(context, "Removed from favourites", icon: Icons.favorite_border, iconColor: Colors.grey);
      } else {
        await favRef.set({
          'promotionId': widget.promotionId,
          'favoritedAt': FieldValue.serverTimestamp(),
        });
        ReusableSnackBar(context, "Added to favourites", icon: Icons.favorite, iconColor: Color(0xFFF06275));
      }

      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      ReusableSnackBar(context, "Failed to update favourite", icon: Icons.error, iconColor: Colors.red);
      print("❌ Error toggling favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 25,
          color: isFavorite ? const Color(0xFFF06275) : Colors.black,
        ),
        onPressed: _toggleFavorite,
      ),
    );
  }
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


Future<Map<String, dynamic>> fetchPostReviewSummary(String postId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('reviews')
      .where('postId', isEqualTo: postId)
      .get();

  final reviews = snapshot.docs;

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
