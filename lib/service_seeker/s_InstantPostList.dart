import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
import 'package:fix_mate/service_provider/p_FilterInstantPost.dart';
import 'package:fix_mate/service_seeker/s_FilterInstantPost.dart';
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

  const s_InstantPostList({
    Key? key,
    this.initialSearchQuery = "",
    this.initialCategories = const [], // ✅ Default to empty list
    this.initialStates = const [], // ✅ Default to empty list
    this.initialPriceRange = const RangeValues(0, 1000), // ✅ Default price range
    this.initialSortOrder = "Random", // ✅ Default sorting order
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

  @override
  void initState() {
    super.initState();
    searchQuery = widget.initialSearchQuery;
    selectedCategories = List<String>.from(widget.initialCategories); // ✅ Ensure list format
    selectedStates = List<String>.from(widget.initialStates); // ✅ Ensure list format
    selectedPriceRange = widget.initialPriceRange; // ✅ Initialize price range
    selectedSortOrder = widget.initialSortOrder; // ✅ Initialize sorting

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


    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User not logged in");
        return;
      }

      print("Fetching posts for userId: ${user.uid}");

      // ✅ Start with a Query, NOT QuerySnapshot
      Query query = _firestore
          .collection('instant_booking');

      // ✅ Apply Sorting Based on updatedAt Timestamp
      if (selectedSortOrder != null) {
        if (selectedSortOrder == "Newest") {
          query = query.orderBy('updatedAt', descending: true);
        } else if (selectedSortOrder == "Oldest") {
          query = query.orderBy('updatedAt', descending: false);
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
        print("No instant booking posts found for user: ${user.uid}");
      } else {
        print("Fetched ${docs.length} posts");
      }

      List<Widget> instantPosts = [];

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        bool matchesCategory = selectedCategories.isEmpty ||
            (data['ServiceCategory'] as List<dynamic>)
                .any((category) => selectedCategories.contains(category));

        bool matchesState = selectedStates.isEmpty ||
            (data['ServiceStates'] as List<dynamic>)
                .any((state) => selectedStates.contains(state));

        bool matchesSearch = searchQuery.isEmpty ||
            (data['IPTitle'] as String).toLowerCase().contains(searchQuery.toLowerCase());

        int postPrice = (data['IPPrice'] as num?)?.toInt() ?? 0;
        bool matchesPrice = postPrice >= selectedPriceRange.start && postPrice <= selectedPriceRange.end;

        // ✅ Exclude posts that do NOT match the filters
        if (!matchesCategory || !matchesState || !matchesSearch || !matchesPrice) {
          continue;
        }

        instantPosts.add(
          buildInstantBookingCard(
            IPTitle: data['IPTitle'] ?? "Unknown",
            ServiceStates: (data['ServiceStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
            ServiceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? "No services listed",
            imageUrls: (data['IPImage'] != null && data['IPImage'] is List<dynamic>)
                ? List<String>.from(data['IPImage'])
                : [],
            // IPPrice: (data['IPPrice'] as num?)?.toInt() ?? 0,
            IPPrice: postPrice,
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
      }

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

        // ✅ Mark filters as applied
        hasFiltered = true;

        // ✅ Update the filter message
        bool isFiltered = searchQuery.isNotEmpty ||
            selectedCategories.isNotEmpty ||
            selectedStates.isNotEmpty ||
            selectedSortOrder != null ||
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
              childAspectRatio: 0.72, // ✅ Adjust aspect ratio to fit better
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
        title: Text(
          "Instant Booking Post List",
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
  required VoidCallback onTap, // ✅ Added onTap
}) {
  return GestureDetector(
    onTap: onTap, // ✅ Calls the navigation function
    child: Container(
      width: 220, // Adjust width for better spacing in horizontal scroll
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📌 Image with rounded corners
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    (imageUrls.isNotEmpty) ? imageUrls.first : "https://via.placeholder.com/150",
                    width: double.infinity,
                    height: 130, // Adjust height for better fit
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

                      // 📌 Location with Icon
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4), // Spacing
                          Expanded( // ✅ Ensures text truncates within available space
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

                      // 📌 Service Category with Icon
                      Row(
                        children: [
                          const Icon(Icons.build, size: 14, color: Colors.grey),
                          const SizedBox(width: 4), // Spacing
                          Expanded( // ✅ Ensures text truncates properly
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
            Positioned(
              top: 6,
              right: 6,
              child: Builder(
                builder: (BuildContext context) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6), // ✅ Smaller rounding
                    child: Material(
                      color: Colors.white, // ✅ Button background
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return FavoriteButton(setState: setState);
                        },
                      ),
                    ),

                  );
                },
              ),
            ),

            // 📌 Price (Bottom-right of the card)
            Positioned(
              bottom: 8,
              right: 10,
              child: Text(
                "RM $IPPrice", // Directly use the stored integer
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
class FavoriteButton extends StatefulWidget {
  final void Function(void Function()) setState;
  const FavoriteButton({Key? key, required this.setState}) : super(key: key);

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool isFavorite = false; // ✅ Persistent state for toggle effect

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, // ✅ Bigger container
      height: 40, // ✅ Bigger container
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2), // ✅ Soft shadow
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border, // ✅ Toggle between filled & outlined heart
          size: 25, // ✅ Bigger icon
          color: isFavorite ? const Color(0xFFF06275) : Colors.black, // ✅ Toggle color
        ),
        onPressed: () {
          setState(() {
            isFavorite = !isFavorite; // 🔄 Toggle favorite state
          });
        },
      ),
    );
  }
}