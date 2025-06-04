import 'package:fix_mate/service_seeker/s_FilterInstantPost.dart';
import 'package:fix_mate/service_seeker/s_HomePage.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class s_InstantPostList extends StatefulWidget {
  final String initialSearchQuery;
  final List<String> initialCategories; // ✅ Ensure it's a List<String>
  final List<String> initialStates; // ✅ Ensure it's a List<String>
  final RangeValues initialPriceRange; // ✅ Add price range parameter
  final String initialSortOrder; // ✅ Sorting order
  final double? initialProviderRating;
  final double? initialServiceRating;

  const s_InstantPostList({
    Key? key,
    this.initialSearchQuery = "",
    this.initialCategories = const [], // ✅ Default to empty list
    this.initialStates = const [], // ✅ Default to empty list
    this.initialPriceRange = const RangeValues(0, 1000), // ✅ Default price range
    this.initialSortOrder = "Random", // ✅ Default sorting order
    this.initialProviderRating,
    this.initialServiceRating,
  }) : super(key: key);

  @override
  _s_InstantPostListState createState() => _s_InstantPostListState();
}

class _s_InstantPostListState extends State<s_InstantPostList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  bool hasFiltered = false; // Track if the user has applied filters
  String? filterMessage;

  List<Widget> allInstantPosts = [];
  String searchQuery = "";
  List<String> selectedCategories = []; // ✅ Declare selectedCategories
  List<String> selectedStates = []; // ✅ Declare selectedStates
  RangeValues selectedPriceRange = RangeValues(0, 1000); // ✅ Store price range
  String? selectedSortOrder; // Can be null when nothing is selected
  double? selectedProviderRating;
  double? selectedServiceRating;


  @override
  void initState() {
    super.initState();
    searchQuery = widget.initialSearchQuery;
    selectedCategories = List<String>.from(widget.initialCategories); // ✅ Ensure list format
    selectedStates = List<String>.from(widget.initialStates); // ✅ Ensure list format
    selectedPriceRange = widget.initialPriceRange; // ✅ Initialize price range
    selectedSortOrder = widget.initialSortOrder; // ✅ Initialize sorting
    selectedProviderRating = widget.initialProviderRating;
    selectedServiceRating = widget.initialServiceRating;

    _searchController.text = searchQuery; // ✅ Set initial text
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
      _loadInstantPosts(); // ✅ Refresh posts on search update
    });

    _loadInstantPosts();
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        controller: _searchController, // ✅ Use controller
        decoration: InputDecoration(
          hintText: "Search your post.......",
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Color(0xFFfb9798)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear(); // ✅ Clear search text
            },
          )
              : null,
        ),
      ),
    );
  }


  Future<void> _loadInstantPosts() async {
    print("🔍 Loading Instant Posts...");
    print("🔄 Reloading posts with filters:");
    print("Search Query: $searchQuery");
    print("Categories: $selectedCategories");
    print("States: $selectedStates");
    print("Price Range: $selectedPriceRange");
    print("Sort Order: $selectedSortOrder");
    print("Selected Provider Rating: $selectedProviderRating");
    print("Selected Post Rating: $selectedServiceRating");

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User not logged in");
        return;
      }

      Query query = _firestore
          .collection('instant_booking')
          .where('isActive', isEqualTo: true);

      if (selectedSortOrder == "Newest") {
        query = query.orderBy('updatedAt', descending: true);
      } else if (selectedSortOrder == "Oldest") {
        query = query.orderBy('updatedAt', descending: false);
      }

      QuerySnapshot snapshot = await query.get();
      List<QueryDocumentSnapshot> docs = snapshot.docs.toList();

      if (selectedSortOrder == "Random") {
        docs.shuffle();
      }

      List<Map<String, dynamic>> scoredPosts = [];

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int matchScore = 0;

        if (selectedCategories.isNotEmpty &&
            (data['ServiceCategory'] as List<dynamic>)
                .any((category) => selectedCategories.contains(category))) {
          matchScore += 1;
        }

        if (selectedStates.isNotEmpty &&
            (data['ServiceStates'] as List<dynamic>)
                .any((state) => selectedStates.contains(state))) {
          matchScore += 1;
        }

        // Fetch provider review summary
        final providerId = data['userId'] ?? "";

        if (providerId.isEmpty) {
          print("⚠️ Skipping post due to missing userId (providerId)");
          continue;
        }

        print("🧪 providerId used for filtering: $providerId");

        final providerReviewSummary = await fetchProviderReviewSummary(providerId); // ✅ Now correct
        final averagePRating = providerReviewSummary['avgRating'] ?? 0.0;
        final providerReviewCount = providerReviewSummary['count'] ?? 0;

        // if (selectedProviderRating != null && averagePRating >= selectedProviderRating!) {
        //   matchScore += 1;
        // }
        if (selectedProviderRating != null && averagePRating >= selectedProviderRating!) {
          print("✅ Matched Provider Rating: $averagePRating");
          matchScore += 1;
        } else {
          print("❌ Skipped due to low provider rating: $averagePRating");
        }


        data['averagePRating'] = averagePRating;
        data['providerReviewCount'] = providerReviewCount;

        // Fetch post review summary
        final postReviewSummary = await fetchPostReviewSummary(doc.id);
        final averageRating = postReviewSummary['avgRating'] ?? 0.0;
        final reviewCount = postReviewSummary['count'] ?? 0;

        if (selectedServiceRating != null && averageRating >= selectedServiceRating!) {
          matchScore += 1;
        }

        data['averageRating'] = averageRating;
        data['reviewCount'] = reviewCount;

        if (searchQuery.isNotEmpty &&
            (data['IPTitle'] as String).toLowerCase().contains(searchQuery.toLowerCase())) {
          matchScore += 1;
        }

        int postPrice = (data['IPPrice'] as num?)?.toInt() ?? 0;
        if (postPrice >= selectedPriceRange.start && postPrice <= selectedPriceRange.end) {
          matchScore += 1;
        }

        if (selectedCategories.isEmpty &&
            selectedStates.isEmpty &&
            searchQuery.isEmpty &&
            selectedPriceRange == RangeValues(0, double.infinity) &&
            selectedProviderRating == null &&
            selectedServiceRating == null) {
          matchScore = 1;
        }

        if (matchScore > 0) {
          data['matchScore'] = matchScore;
          data['docId'] = doc.id;
          scoredPosts.add(data);
        }
      }

      scoredPosts.sort((a, b) {
        int scoreCompare = b['matchScore'].compareTo(a['matchScore']);
        if (scoreCompare != 0) return scoreCompare;

        if (selectedSortOrder == "Newest") {
          return (b['updatedAt'] as Timestamp).compareTo(a['updatedAt'] as Timestamp);
        } else if (selectedSortOrder == "Oldest") {
          return (a['updatedAt'] as Timestamp).compareTo(b['updatedAt'] as Timestamp);
        } else {
          return 0;
        }
      });

      List<Widget> instantPosts = scoredPosts.map((data) {
        int postPrice = (data['IPPrice'] as num?)?.toInt() ?? 0;

        return buildInstantBookingCard(
          docId: data['docId'],
          avgRating: data['averageRating'] ?? 0.0,
          reviewCount: data['reviewCount'] ?? 0,
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
                builder: (context) => s_InstantPostInfo(docId: data['docId']),
              ),
            );
          },
        );
      }).toList();

      setState(() {
        allInstantPosts = instantPosts;
      });
    } catch (e) {
      print("Error loading Instant Booking Posts: $e");
    }
  }




  void _openFilterScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => s_FilterInstantPost(
          initialSearchQuery: searchQuery,
          initialCategories: selectedCategories,
          initialStates: selectedStates,
          initialPriceRange: selectedPriceRange,
          initialSortOrder: selectedSortOrder,
          initialProviderRating: selectedProviderRating,
          initialServiceRating: selectedServiceRating,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        searchQuery = result['searchQuery'] ?? "";
        selectedCategories = List<String>.from(result['selectedCategories'] ?? []);
        selectedStates = List<String>.from(result['selectedStates'] ?? []);
        selectedPriceRange = result["priceRange"];
        selectedSortOrder = result["sortOrder"];
        selectedProviderRating = result["providerRating"];
        selectedServiceRating = result["serviceRating"];

        // ✅ Mark filters as applied
        hasFiltered = true;

        // ✅ Update the filter message
        bool isFiltered = searchQuery.isNotEmpty ||
            selectedCategories.isNotEmpty ||
            selectedStates.isNotEmpty ||
            selectedSortOrder != null ||
            selectedProviderRating != null ||
            selectedServiceRating != null ||
            (selectedPriceRange.start > 0 || selectedPriceRange.end < 1000);

        if (isFiltered) {
          filterMessage = "Showing ${allInstantPosts.length} matching posts";
        } else {
          filterMessage = null; // Hide message if no filters are applied
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInstantPosts();
      });
    }
  }




  Widget _buildInstantBookingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // ✅ Align with title
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Instant Booking",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ✅ Show message if no posts exist
          allInstantPosts.isEmpty
              ? const Text(
            "No instant booking post found.",
            style: TextStyle(color: Colors.black54),
          )
              : GridView.builder(
            shrinkWrap: true, // ✅ Makes GridView fit content
            physics: const NeverScrollableScrollPhysics(), // ✅ Prevents nested scrolling
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // ✅ Ensures exactly 2 columns
              crossAxisSpacing: 0, // ✅ Space between columns
              mainAxisSpacing: 10, // ✅ Space between rows
              childAspectRatio: 0.66, // ✅ Adjust aspect ratio to fit better
            ),
            itemCount: allInstantPosts.length,
            itemBuilder: (context, index) {
              return allInstantPosts[index];
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: Color(0xFFfb9798),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => s_HomePage(),
                ),
              ), // return true = change,
        ),
        title: Text(
          "Instant Booking Post List",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        titleSpacing: 2,
        automaticallyImplyLeading: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),

            // Actions (post count + filter button) below search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // White background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFfb9798), width: 1.5), // Border color
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // Smaller height
              margin: const EdgeInsets.symmetric(vertical: 10), // Adds spacing
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasFiltered
                          ? (allInstantPosts.isEmpty
                          ? "No matching posts found"
                          : "${allInstantPosts.length} matching posts")
                          : "No filter applied", // Default message before filtering
                      style: TextStyle(color: Color(0xFFfb9798), fontSize: 14),
                    ),

                    TextButton.icon(
                      label: Text("Filter", style: TextStyle(color: Color(0xFFfb9798))),
                      onPressed: _openFilterScreen,
                      icon: Icon(Icons.filter_list, color: Color(0xFFfb9798)),
                    ),
                  ]
              ),
            ),
            const SizedBox(height: 2),
            _buildInstantBookingSection(),
          ],
        ),
      ),
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
                    height: 120,
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
                      const SizedBox(height: 24), // Reserve vertical space for rating
                    ],
                  ),
                ),
              ],
            ),

            // ❤️ Favorite Button
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

            // ⭐ Rating Badge (Bottom-left)
            Positioned(
              bottom: 12,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                        fontSize: 11,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 💰 Price (Bottom-right)
            Positioned(
              bottom: 8,
              right: 8,
              child: Text(
                "RM$IPPrice",
                style: const TextStyle(
                  color: Color(0xFFfb9798),
                  fontSize: 22,
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
  if (reviews.isEmpty) return {'avgRating': 0.0, 'count': 0};

  double totalRating = 0.0;
  for (var doc in reviews) {
    final data = doc.data();
    totalRating += (data['rating'] ?? 0).toDouble();
  }

  return {
    'avgRating': totalRating / reviews.length,
    'count': reviews.length,
  };
}
