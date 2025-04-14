import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
import 'package:fix_mate/service_provider/p_FilterInstantPost.dart';
import 'package:fix_mate/service_provider/p_ServiceDirectoryModule/p_InstantPostInfo.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class p_InstantPostList extends StatefulWidget {
  final String initialSearchQuery;
  final List<String> initialCategories; // ✅ Ensure it's a List<String>
  final List<String> initialStates; // ✅ Ensure it's a List<String>
  final RangeValues initialPriceRange; // ✅ Add price range parameter
  final String initialSortOrder; // ✅ Sorting order
  final String? initialPostType;

  const p_InstantPostList({
    Key? key,
    this.initialSearchQuery = "",
    this.initialCategories = const [], // ✅ Default to empty list
    this.initialStates = const [], // ✅ Default to empty list
    this.initialPriceRange = const RangeValues(0, 1000), // ✅ Default price range
    this.initialSortOrder = "Newest", // ✅ Default sorting order
    this.initialPostType = "No selected",
  }) : super(key: key);

  @override
  _p_InstantPostListState createState() => _p_InstantPostListState();
}

class _p_InstantPostListState extends State<p_InstantPostList> {
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
  String? selectedPostType;

  @override
  void initState() {
    super.initState();
    searchQuery = widget.initialSearchQuery;
    selectedCategories =
    List<String>.from(widget.initialCategories); // ✅ Ensure list format
    selectedStates =
    List<String>.from(widget.initialStates); // ✅ Ensure list format
    selectedPriceRange = widget.initialPriceRange; // ✅ Initialize price range
    selectedSortOrder = widget.initialSortOrder; // ✅ Initialize sorting
    selectedPostType = widget.initialPostType;

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
          prefixIcon: const Icon(Icons.search, color: Color(0xFF464E65)),
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

  Future<bool> _hasBookingReference(String postId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('postId', isEqualTo: postId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking booking reference: $e");
      return false;
    }
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
          .collection('instant_booking')
          .where('userId', isEqualTo: user.uid);

      // ✅ Apply post type filter if selected
      if (selectedPostType == "Active") {
        query = query.where('isActive', isEqualTo: true);
      } else if (selectedPostType == "Inactive") {
        query = query.where('isActive', isEqualTo: false);
      }

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
            (data['IPTitle'] as String).toLowerCase().contains(
                searchQuery.toLowerCase());

        int postPrice = (data['IPPrice'] as num?)?.toInt() ?? 0;
        bool matchesPrice = postPrice >= selectedPriceRange.start &&
            postPrice <= selectedPriceRange.end;

        // ✅ Exclude posts that do NOT match the filters
        if (!matchesCategory || !matchesState || !matchesSearch ||
            !matchesPrice) {
          continue;
        }

        instantPosts.add(
          buildInstantBookingCard(
            IPTitle: data['IPTitle'] ?? "Unknown",
            ServiceStates: (data['ServiceStates'] as List<dynamic>?)?.join(
                ", ") ?? "Unknown",
            ServiceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(
                ", ") ?? "No services listed",
            imageUrls: (data['IPImage'] != null &&
                data['IPImage'] is List<dynamic>)
                ? List<String>.from(data['IPImage'])
                : [],
            // IPPrice: (data['IPPrice'] as num?)?.toInt() ?? 0,
            IPPrice: postPrice,

            isActive: data['isActive'] ?? true,
            postId: doc.id,

            onEdit: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => p_EditInstantPost(docId: doc.id),
                ),
              );

              if (result == true) {
                _loadInstantPosts();
              }
            },
            onDelete: () {
              _confirmDelete(doc.id);
            },

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => p_InstantPostInfo(docId: doc.id),
                ),
              );
            },

            onToggleComplete: _loadInstantPosts,
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
        builder: (context) =>
            p_FilterInstantPost(
              initialSearchQuery: searchQuery,
              initialCategories: selectedCategories,
              initialStates: selectedStates,
              initialPriceRange: selectedPriceRange,
              initialSortOrder: selectedSortOrder,
              initialPostType: selectedPostType,
            ),
      ),
    );

    if (result != null) {
      setState(() {
        searchQuery = result['searchQuery'] ?? "";
        selectedCategories =
        List<String>.from(result['selectedCategories'] ?? []);
        selectedStates = List<String>.from(result['selectedStates'] ?? []);
        selectedPriceRange = result["priceRange"];
        selectedSortOrder = result["sortOrder"];
        selectedPostType = result["postType"];

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

  // void _confirmDelete(String docId) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => ConfirmationDialog(
  //       title: "Delete Post",
  //       message: "Are you sure you want to delete this post?",
  //       confirmText: "Delete",
  //       cancelText: "Cancel",
  //       onConfirm: () async {
  //         await _deletePost(docId); // ✅ Call delete function first
  //
  //         // ✅ Show success message using ReusableSnackBar
  //         ReusableSnackBar(
  //           context,
  //           "Instant Booking post successfully deleted!",
  //           icon: Icons.check_circle,
  //           iconColor: Colors.green,
  //         );
  //
  //         // ✅ Navigate back to the original screen after deleting
  //         Navigator.popUntil(context, (route) => route.isFirst);
  //       },
  //       icon: Icons.delete,
  //       iconColor: Colors.red,
  //       confirmButtonColor: Colors.red,
  //       cancelButtonColor: Colors.grey.shade300,
  //     ),
  //   );
  // }

  void _confirmDelete(String docId) async {
    final hasBooking = await _hasBookingReference(docId);


    if (hasBooking) {
      showFloatingMessage(
        context,
        "Deletion blocked!\n This post has a booking record.",
        icon: Icons.warning_amber_rounded,
      );
    } else {
      showDialog(
        context: context,
        builder: (context) =>
            ConfirmationDialog(
              title: "Delete Post",
              message: "Are you sure you want to delete this post?",
              confirmText: "Delete",
              cancelText: "Cancel",
              onConfirm: () async {
                await _deletePost(docId); // ✅ Call delete function first

                // ✅ Show success message using ReusableSnackBar
                ReusableSnackBar(
                  context,
                  "Instant Booking post successfully deleted!",
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                );

                // ✅ Navigate back to the original screen after deleting
                Navigator.pop(context, true);
              },
              icon: Icons.delete,
              iconColor: Colors.red,
              confirmButtonColor: Colors.red,
              cancelButtonColor: Colors.grey.shade300,
            ),
      );
    }
  }


  Future<void> _deletePost(String docId) async {
    try {
      await _firestore.collection('instant_booking').doc(docId).delete();
      print("Post deleted successfully: $docId");

      _loadInstantPosts(); // ✅ Refresh list after deletion
    } catch (e) {
      print("Error deleting post: $e");
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
            "No instant booking post found.\nPlease click on the + button at the homepage under the instant booking section to add an instant booking post.",
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
        backgroundColor: Color(0xFF464E65),
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
                border: Border.all(color: Color(0xFF464E65), width: 1.5), // Border color
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
                      style: TextStyle(color: Color(0xFF464E65), fontSize: 14),
                    ),

                    TextButton.icon(
                      label: Text("Filter", style: TextStyle(color: Color(0xFF464E65))),
                      onPressed: _openFilterScreen,
                      icon: Icon(Icons.filter_list, color: Color(0xFF464E65)),
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
  required bool isActive,
  required String postId,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onToggleComplete,
  required VoidCallback onTap,

}) {
  return GestureDetector(
    onTap: onTap,
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
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz, size: 18, color: Colors.black), // ✅ Smaller icon
                      padding: EdgeInsets.zero, // ✅ No extra padding
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 20), // ✅ Forces a smaller button
                      onPressed: () async {
                        final RenderBox button = context.findRenderObject() as RenderBox;
                        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                        final RelativeRect position = RelativeRect.fromRect(
                          Rect.fromPoints(
                            button.localToGlobal(Offset.zero, ancestor: overlay),
                            button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                          ),
                          Offset.zero & overlay.size,
                        );

                        final result = await showMenu<String>(
                          context: context,
                          position: position,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          items: [
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Color(0xFF464E65), size: 18),
                                  SizedBox(width: 14),
                                  Text('Edit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 18),
                                  SizedBox(width: 14),
                                  Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.visibility_off : Icons.visibility,
                                    color: isActive ? Colors.red : Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    isActive ? 'Set Inactive' : 'Set Active',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );

                        if (result == 'edit') {
                          onEdit();
                        } else if (result == 'delete') {
                          onDelete();
                        } else if (result == 'toggle') {
                          try {
                            final newStatus = !isActive;

                            await FirebaseFirestore.instance
                                .collection('instant_booking')
                                .doc(postId)
                                .update({'isActive': newStatus});

                            ReusableSnackBar(
                              context,
                              "Post is now ${newStatus ? 'Active' : 'Inactive'}",
                              icon: Icons.check_circle,
                              iconColor: Colors.green,
                            );

                            onToggleComplete(); // ✅ Refresh from parent!
                          } catch (e) {
                            print("Toggle failed: \$e");
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),


          // 📌 Price (Bottom-right of the card)
          Positioned(
            bottom: 7,
            right: 10,
            child: Text(
              "RM $IPPrice", // Directly use the stored integer
              style: const TextStyle(
                color: Color(0xFF464E65),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),


          // 👇 Status label at bottom-right of the card (beside price)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade100 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? "Active" : "Inactive",
                style: TextStyle(
                  color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  );
}
