import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
import 'package:fix_mate/service_provider/p_FilterInstantPost.dart';
import 'package:fix_mate/service_seeker/s_FilterInstantPost.dart';
import 'package:fix_mate/service_seeker/s_FilterSPPost.dart';
import 'package:fix_mate/service_seeker/s_HomePage.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:fix_mate/service_seeker/s_SPInfo.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class s_SPList extends StatefulWidget {
  final String initialSearchQuery;
  final List<String> initialCategories; // ✅ Ensure it's a List<String>
  final List<String> initialStates; // ✅ Ensure it's a List<String>
  // final RangeValues initialPriceRange; // ✅ Add price range parameter
  final String initialSortOrder; // ✅ Sorting order
  final double? initialRatingThreshold;

  const s_SPList({
    Key? key,
    this.initialSearchQuery = "",
    this.initialCategories = const [], // ✅ Default to empty list
    this.initialStates = const [], // ✅ Default to empty list
    // this.initialPriceRange = const RangeValues(0, 1000), // ✅ Default price range
    this.initialSortOrder = "Random", // ✅ Default sorting order
    this.initialRatingThreshold,
  }) : super(key: key);

  @override
  _s_SPListState createState() => _s_SPListState();
}

class _s_SPListState extends State<s_SPList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  bool hasFiltered = false; // Track if the user has applied filters
  String? filterMessage;

  List<Widget> allSPPosts = [];
  String searchQuery = "";
  List<String> selectedCategories = []; // ✅ Declare selectedCategories
  List<String> selectedStates = []; // ✅ Declare selectedStates
  // RangeValues selectedPriceRange = RangeValues(0, 1000); // ✅ Store price range
  String? selectedSortOrder; // Can be null when nothing is selected
  double? selectedRatingThreshold;
  double averageRating = 0.0;
  int totalReviews = 0;
  List<Widget> providerFavourites = [];


  @override
  void initState() {
    super.initState();
    searchQuery = widget.initialSearchQuery;
    selectedCategories = List<String>.from(widget.initialCategories); // ✅ Ensure list format
    selectedStates = List<String>.from(widget.initialStates); // ✅ Ensure list format
    // selectedPriceRange = widget.initialPriceRange; // ✅ Initialize price range
    selectedSortOrder = widget.initialSortOrder; // ✅ Initialize sorting
    selectedRatingThreshold = widget.initialRatingThreshold;

    _searchController.text = searchQuery; // ✅ Set initial text
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
      _loadSPPosts(); // ✅ Refresh posts on search update
    });

    _loadSPPosts();
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
          hintText: "Search your service provider.......",
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



  Future<void> _loadSPPosts() async {
    print("🔍 Loading Service Provider(s)...");
    print("🔄 Reloading posts with filters:");
    print("Search Query: $searchQuery");
    print("Categories: $selectedCategories");
    print("States: $selectedStates");
    print("Sort Order: $selectedSortOrder");
    print("🎯 Selected Rating Threshold: $selectedRatingThreshold");

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User not logged in");
        return;
      }

      // Query query = _firestore.collection('service_providers');
      Query query = _firestore
          .collection('service_providers')
          .where('status', isEqualTo: 'Approved');

      // Apply Sorting
      if (selectedSortOrder != null) {
        if (selectedSortOrder == "Newest") {
          query = query.orderBy('createdAt', descending: true);
        } else if (selectedSortOrder == "Oldest") {
          query = query.orderBy('createdAt', descending: false);
        }
      }

      QuerySnapshot snapshot = await query.get();
      List<QueryDocumentSnapshot> docs = snapshot.docs.toList();

      if (selectedSortOrder == "Random") {
        docs.shuffle(); // still apply random
      }

      List<Map<String, dynamic>> scoredPosts = [];

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        int matchScore = 0;

        // Category match scoring
        if (selectedCategories.isNotEmpty) {
          int categoryMatches = (data['selectedExpertiseFields'] as List<dynamic>)
              .where((category) => selectedCategories.contains(category))
              .length;
          matchScore += categoryMatches; // ✅ Adds 1 per matched category
        }



        // State match scoring
        if (selectedStates.isNotEmpty) {
          int stateMatches = (data['selectedStates'] as List<dynamic>)
              .where((state) => selectedStates.contains(state))
              .length;
          matchScore += stateMatches; // ✅ Adds 1 per match
        }

        // 👇 Fetch review summary for this provider
        // Fetch rating summary
        final reviewSummary = await fetchProviderReviewSummary(doc.id);
        final averageRating = reviewSummary['avgRating'];
        final totalReviews = reviewSummary['count'];

        // ✅ Add score if meets or exceeds threshold
        if (selectedRatingThreshold != null && averageRating >= selectedRatingThreshold!) {
          matchScore += 1;
        }

        data['averageRating'] = averageRating;
        data['totalReviews'] = totalReviews;


        // Name match scoring
        if (searchQuery.isNotEmpty &&
            (data['name'] as String).toLowerCase().contains(searchQuery.toLowerCase())) {
          matchScore += 1;
        }

        if (selectedCategories.isEmpty && selectedStates.isEmpty && searchQuery.isEmpty) {
          // ✅ No filters applied → include all posts with matchScore = 1 (default)
          matchScore = 1;
        }

        // ✅ Only skip post if it completely fails to match filters when filters exist
        if (matchScore > 0) {
          data['matchScore'] = matchScore;
          data['docId'] = doc.id;
          scoredPosts.add(data);
        }

      }

      // // Sort based on matchScore if no custom sort is applied
      // if (selectedSortOrder == null || selectedSortOrder == "Random") {
      //   scoredPosts.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));
      // }


      scoredPosts.sort((a, b) {
        int scoreCompare = b['matchScore'].compareTo(a['matchScore']);
        if (scoreCompare != 0) return scoreCompare; // Most relevant first

        // Tie-breaker: sort by createdAt only when matchScore is equal
        if (selectedSortOrder == "Newest") {
          return (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp);
        } else if (selectedSortOrder == "Oldest") {
          return (a['createdAt'] as Timestamp).compareTo(b['createdAt'] as Timestamp);
        } else {
          return 0; // Leave order as-is if Random or null
        }
      });


      // Build widgets
      List<Widget> SPPosts = scoredPosts.map((data) {
        return buildSPCard(
          name: data['name'] ?? "Unknown",
          ServiceStates: (data['selectedStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
          ServiceCategory: (data['selectedExpertiseFields'] as List<dynamic>?)?.join(", ") ?? "No services listed",
          imageUrl: data['profilePic'] ?? "",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceProviderScreen(docId: data['docId']),
              ),
            );
          },
          docId: data['docId'],
          averageRating: data['averageRating'] ?? 0.0,
          totalReviews: data['totalReviews'] ?? 0,
          onUnfavourite: () {
            setState(() {
              providerFavourites.removeWhere((w) => w.key == ValueKey(data['docId']));
            });
          },
        );
      }).toList();

      setState(() {
        allSPPosts = SPPosts;
      });
    } catch (e) {
      print("Error loading service provider(s): $e");
    }
  }



  void _openFilterScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => s_FilterSPPost(
          initialSearchQuery: searchQuery,
          initialCategories: selectedCategories,
          initialStates: selectedStates,
          // initialPriceRange: selectedPriceRange,
          initialSortOrder: selectedSortOrder,
          initialRatingThreshold: selectedRatingThreshold,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        searchQuery = result['searchQuery'] ?? "";
        selectedCategories = List<String>.from(result['selectedCategories'] ?? []);
        selectedStates = List<String>.from(result['selectedStates'] ?? []);
        // selectedPriceRange = result["priceRange"];
        selectedSortOrder = result["sortOrder"];
        selectedRatingThreshold = result['ratingThreshold'];

        // ✅ Mark filters as applied
        hasFiltered = true;

        // ✅ Update the filter message
        bool isFiltered = searchQuery.isNotEmpty ||
            selectedCategories.isNotEmpty ||
            selectedStates.isNotEmpty ||
            selectedSortOrder != null ||
            selectedRatingThreshold != null;
            // (selectedPriceRange.start > 0 || selectedPriceRange.end < 1000);

        if (isFiltered) {
          filterMessage = "Showing ${allSPPosts.length} matching posts";
        } else {
          filterMessage = null; // Hide message if no filters are applied
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSPPosts();
      });
    }
  }





  Widget _buildInstantBookingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Service Provider",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ✅ Show message if no posts exist
          allSPPosts.isEmpty
              ? const Text(
            "No instant booking post found.",
            style: TextStyle(color: Colors.black54),
          )
              : ListView.builder(
            shrinkWrap: true, // ✅ Makes ListView fit content
            physics: const NeverScrollableScrollPhysics(), // ✅ Prevents nested scrolling issues
            itemCount: allSPPosts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2), // ✅ Adds spacing between items
                child: allSPPosts[index], // ✅ Displays the service provider card
              );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () =>
              Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => s_HomePage(),
            ),
          ), // return true = change,
        ),
        title: Text(
          "Service Provider List",
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
                          ? (allSPPosts.isEmpty
                          ? "No matching posts found"
                          : "${allSPPosts.length} matching posts")
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


Widget buildSPCard({
  required String name,
  required String ServiceStates,
  required String ServiceCategory,
  required String imageUrl,
  required VoidCallback onTap,
  required String docId,
  required double averageRating, // ✅ New
  required int totalReviews,
  required VoidCallback onUnfavourite, // ✅ Add this

}) {
  return GestureDetector(
    onTap: onTap,
    child: Center(
      child: Container(
        width: 320,
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
                          const SizedBox(height: 4),
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
                ),
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
            icon: Icons.favorite, iconColor: Color(0xFFF06275));
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