import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
import 'package:fix_mate/service_provider/p_FilterInstantPost.dart';
import 'package:fix_mate/service_seeker/s_FilterInstantPost.dart';
import 'package:fix_mate/service_seeker/s_FilterSPPost.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
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

  const s_SPList({
    Key? key,
    this.initialSearchQuery = "",
    this.initialCategories = const [], // ✅ Default to empty list
    this.initialStates = const [], // ✅ Default to empty list
    // this.initialPriceRange = const RangeValues(0, 1000), // ✅ Default price range
    this.initialSortOrder = "Random", // ✅ Default sorting order
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

  @override
  void initState() {
    super.initState();
    searchQuery = widget.initialSearchQuery;
    selectedCategories = List<String>.from(widget.initialCategories); // ✅ Ensure list format
    selectedStates = List<String>.from(widget.initialStates); // ✅ Ensure list format
    // selectedPriceRange = widget.initialPriceRange; // ✅ Initialize price range
    selectedSortOrder = widget.initialSortOrder; // ✅ Initialize sorting

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
    // print("Price Range: $selectedPriceRange");
    print("Sort Order: $selectedSortOrder");


    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User not logged in");
        return;
      }

      print("Fetching posts for userId: ${user.uid}");

      // ✅ Start with a Query, NOT QuerySnapshot
      Query query = _firestore
          .collection('service_providers');

      // ✅ Apply Sorting Based on updatedAt Timestamp
      if (selectedSortOrder != null) {
        if (selectedSortOrder == "Newest") {
          query = query.orderBy('createdAt', descending: true);
        } else if (selectedSortOrder == "Oldest") {
          query = query.orderBy('createdAt', descending: false);
        }
      }


      // ✅ Execute the query only once
      QuerySnapshot snapshot = await query.get();

// ✅ Shuffle documents for random order if needed
      List<QueryDocumentSnapshot> docs = snapshot.docs.toList();
      if (selectedSortOrder == "Random") {
        docs.shuffle();
      }

      if (docs.isEmpty) {
        print("No service provider(s) found for user: ${user.uid}");
      } else {
        print("Fetched ${docs.length} service provider(s)");
      }

      List<Widget> SPPosts = [];

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        bool matchesCategory = selectedCategories.isEmpty ||
            (data['selectedExpertiseFields'] as List<dynamic>)
                .any((category) => selectedCategories.contains(category));

        bool matchesState = selectedStates.isEmpty ||
            (data['selectedStates'] as List<dynamic>)
                .any((state) => selectedStates.contains(state));

        bool matchesSearch = searchQuery.isEmpty ||
            (data['name'] as String).toLowerCase().contains(searchQuery.toLowerCase());

        // int postPrice = (data['IPPrice'] as num?)?.toInt() ?? 0;
        // bool matchesPrice = postPrice >= selectedPriceRange.start && postPrice <= selectedPriceRange.end;

        // ✅ Exclude posts that do NOT match the filters // No !matchesPrice
        if (!matchesCategory || !matchesState || !matchesSearch ) {
          continue;
        }

        SPPosts.add(
          buildSPCard(
            name: data['name'] ?? "Unknown",
            ServiceStates: (data['selectedStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
            ServiceCategory: (data['selectedExpertiseFields'] as List<dynamic>?)?.join(", ") ?? "No services listed",
            imageUrl: data['profilePic'] ?? "", // Default image if null
            // IPPrice: (data['IPPrice'] as num?)?.toInt() ?? 0,
            // IPPrice: postPrice,
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => s_InstantPostInfo(docId: doc.id),
              //   ),
              // );
            },
          ),
        );
      }

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

        // ✅ Mark filters as applied
        hasFiltered = true;

        // ✅ Update the filter message
        bool isFiltered = searchQuery.isNotEmpty ||
            selectedCategories.isNotEmpty ||
            selectedStates.isNotEmpty ||
            selectedSortOrder != null;
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
        title: Text(
          "Service Provider List",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
                          Row(
                            children: [
                              const Text(
                                "0.0",
                                style: TextStyle(fontSize: 18, color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Row(
                                children: List.generate(5, (index) {
                                  return const Icon(Icons.star_border, color: Colors.orange, size: 18);
                                }),
                              ),
                            ],
                          ),
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
                child: FavoriteButton2(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}




class FavoriteButton2 extends StatefulWidget {
  const FavoriteButton2({Key? key}) : super(key: key);

  @override
  _FavoriteButton2State createState() => _FavoriteButton2State();
}

class _FavoriteButton2State extends State<FavoriteButton2> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // Smooth transition effect
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isFavorite ? Color(0xFFF06275).withOpacity(0.5) : Colors.grey.withOpacity(0.0), // Change shadow color
            spreadRadius: 2,
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center, // Ensures the icon is perfectly centered
        children: [
          Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 22, // ✅ Ensures the icon is 25 in size
            color: isFavorite ? Color(0xFFF06275) : Colors.black,
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  setState(() {
                    isFavorite = !isFavorite;
                  });
                },
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}