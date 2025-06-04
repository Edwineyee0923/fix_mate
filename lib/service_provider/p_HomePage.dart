import 'package:fix_mate/service_provider/p_AddInstantPost.dart';
import 'package:fix_mate/service_provider/p_AddPromotionPost.dart';
import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
import 'package:fix_mate/service_provider/p_EditPromotionPost.dart';
import 'package:fix_mate/service_provider/p_InstantPostsList.dart';
import 'package:fix_mate/service_provider/p_PromotionPostList.dart';
import 'package:fix_mate/service_provider/p_ServiceDirectoryModule/p_InstantPostInfo.dart';
import 'package:fix_mate/service_provider/p_ServiceDirectoryModule/p_PromotionPostInfo.dart';
import 'package:fix_mate/service_provider/p_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:fix_mate/services/showBookingNotification.dart';
import 'package:fix_mate/services/booking_reminder.dart';


class p_HomePage extends StatefulWidget {
  static String routeName = "/service_provider/p_HomePage";

  const p_HomePage({Key? key}) : super(key: key);

  @override
  _p_HomePageState createState() => _p_HomePageState();
}

class _p_HomePageState extends State<p_HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Widget> allInstantPosts = [];
  List<Widget> filteredInstantPosts = []; // Stores filtered instant booking posts
  List<Widget> displayedInstantPosts = []; // ✅ Stores 4 newest posts or filtered results

  List<Widget> allPromotionPosts = [];
  List<Widget> filteredPromotionPosts = []; // Stores filtered promotion posts
  List<Widget> displayedPromotionPosts = []; // ✅ Stores 4 newest posts or filtered results
  TextEditingController _searchController = TextEditingController();

  @override
  // void initState() {
  //   super.initState();
  //   _loadInstantPosts(); // Load posts when the page initializes
  //   _loadPromotionPosts(); // Load posts when the page initializes
  // }

  @override
  void initState() {
    super.initState();

    // 📦 Load content posts
    _loadInstantPosts();
    _loadPromotionPosts();

    // 🔔 Schedule booking reminders if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      scheduleReminders(currentUser.uid);
    }

    // Optional: listenToProviderNotifications(); // if you want to re-enable this later
  }


  // Future<void> listenToProviderNotifications() async {
  //   final currentUser = FirebaseAuth.instance.currentUser;
  //   if (currentUser == null) return;
  //
  //   // 👇 Confirm the user is a service provider
  //   final spDoc = await FirebaseFirestore.instance
  //       .collection('service_providers')
  //       .doc(currentUser.uid)
  //       .get();
  //
  //   if (!spDoc.exists) return; // ❌ Not a provider
  //
  //   // ✅ Listen to real-time booking notifications
  //   FirebaseFirestore.instance
  //       .collection('p_notifications')
  //       .where('providerId', isEqualTo: currentUser.uid)
  //       .where('isRead', isEqualTo: false)
  //       .snapshots()
  //       .listen((snapshot) {
  //     for (var docChange in snapshot.docChanges) {
  //       if (docChange.type == DocumentChangeType.added) {
  //         final data = docChange.doc.data();
  //         if (data != null) {
  //           showBookingNotification(
  //             title: data['title'],
  //             message: data['message'],
  //             bookingId: data['bookingId'],
  //             postId: data['postId'],
  //             seekerId: data['seekerId'],
  //           );
  //         }
  //       }
  //     }
  //   });
  // }

  void _filterInstantPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedInstantPosts = allInstantPosts.take(4).toList(); // ✅ Reset to newest 4 posts
      } else {
        displayedInstantPosts = allInstantPosts.where((post) {
          String title = (post.key as ValueKey<String>?)?.value ?? "";
          return title.toLowerCase().contains(query.toLowerCase());
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
          _filterInstantPosts(query);
          _filterPromotionPosts(query);
        },
        decoration: InputDecoration(
          hintText: "Search your post.......",
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF464E65)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              _filterInstantPosts("");
              _filterPromotionPosts("");
              FocusScope.of(context).unfocus(); // Optional: close keyboard
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
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User not logged in");
        return;
      }

      print("Fetching posts for userId: ${user.uid}");

      // Start with a Query
      Query query = _firestore.collection('instant_booking').where('userId', isEqualTo: user.uid);

      // Apply Sorting Based on `updatedAt`
      query = query.orderBy('updatedAt', descending: true); // ✅ Always get the latest posts first

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("No instant booking posts found for user: ${user.uid}");
      } else {
        print("Fetched ${snapshot.docs.length} posts");
      }

      List<Widget> instantPosts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return KeyedSubtree(
            key: ValueKey<String>(data['IPTitle'] ?? "Unknown"),
        child: buildInstantBookingCard(
          context: context,
          IPTitle: data['IPTitle'] ?? "Unknown",
          ServiceStates: (data['ServiceStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
          ServiceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? "No services listed",
          // imageUrls: (data['IPImage'] as List<dynamic>?)?.cast<String>() ?? [], // ✅ Convert to List<String>
          // imageUrls: (data['IPImage'] is List<dynamic>)
          //     ? (data['IPImage'] as List<dynamic>).cast<String>()  // ✅ If it's a list, cast it
          //     : (data['IPImage'] is String)
          //     ? [data['IPImage'] as String]  // ✅ If it's a string, wrap it in a list
          //     : [], // ✅ Default to empty list if null
          imageUrls: (data['IPImage'] != null && data['IPImage'] is List<dynamic>)
              ? List<String>.from(data['IPImage'])  // ✅ Convert Firestore List<dynamic> to List<String>
              : [],
          IPPrice: (data['IPPrice'] as num?)?.toInt() ?? 0,

          // ✅ New required fields
          isActive: data['isActive'] ?? true,         // defaults to true if missing
          postId: doc.id,                             // Firestore doc ID of the post

          onEdit: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => p_EditInstantPost(docId: doc.id), // Pass docId
              ),
            );

            if (result == true) {
              _loadInstantPosts(); // Refresh after editing
            }
          },

          onDelete: () {
            _confirmDelete(doc.id); // ✅ Call delete confirmation
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
      }).toList();

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

      print("Fetching posts for userId: ${user.uid}");

      // Start with a Query
      Query query = _firestore.collection('promotion').where('userId', isEqualTo: user.uid);

      // Apply Sorting Based on `updatedAt`
      query = query.orderBy('updatedAt', descending: true); // ✅ Always get the latest posts first

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("No promotion posts found.");
      } else {
        print("Fetched ${snapshot.docs.length} promotion posts");
      }

      List<Widget> promotionPosts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return KeyedSubtree(
            key: ValueKey<String>(data['PTitle'] ?? "Unknown"),
        child: buildPromotionCard(
          PTitle: data['PTitle'] ?? "Unknown",
          ServiceStates: (data['ServiceStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
          ServiceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? "No services listed",
          // imageUrls: (data['IPImage'] as List<dynamic>?)?.cast<String>() ?? [], // ✅ Convert to List<String>
          // imageUrls: (data['IPImage'] is List<dynamic>)
          //     ? (data['IPImage'] as List<dynamic>).cast<String>()  // ✅ If it's a list, cast it
          //     : (data['IPImage'] is String)
          //     ? [data['IPImage'] as String]  // ✅ If it's a string, wrap it in a list
          //     : [], // ✅ Default to empty list if null
          imageUrls: (data['PImage'] != null && data['PImage'] is List<dynamic>)
              ? List<String>.from(data['PImage'])  // ✅ Convert Firestore List<dynamic> to List<String>
              : [],


          PPrice: (data['PPrice'] as num?)?.toInt() ?? 0,
          PAPrice: (data['PAPrice'] as num?)?.toInt() ?? 0,

          // ✅ Extract and convert PDiscountPercentage safely
          PDiscountPercentage: (data['PDiscountPercentage'] as num?)?.toDouble() ?? 0.0,

          // ✅ New required fields
          isActive: data['isActive'] ?? true,         // defaults to true if missing
          postId: doc.id,                             // Firestore doc ID of the post

          onEdit: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => p_EditPromotionPost(docId: doc.id), // Pass docId
              ),
            );

            if (result == true) {
              _loadPromotionPosts(); // Refresh after editing
            }
          },

          onDelete: () {
            _confirmP_Delete(doc.id); // ✅ Call delete confirmation
          },

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => p_PromotionPostInfo(docId: doc.id),
              ),
            );
          },

          onToggleComplete: _loadPromotionPosts,
        ),
        );
      }).toList();

      setState(() {
        allPromotionPosts = promotionPosts;
        displayedPromotionPosts = allPromotionPosts.take(4).toList(); // ✅ Show only 4 newest posts
      });
    } catch (e) {
      print("Error loading Promotion Posts: $e");
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
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => p_HomePage()),
  //         ); // Close dialog
  //         await _deletePost(docId); // ✅ Call delete function
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
        builder: (context) => ConfirmationDialog(
          title: "Delete Post",
          message: "Are you sure you want to delete this instant booking post?",
          confirmText: "Delete",
          cancelText: "Cancel",
          onConfirm: () async {
            await _deletePost(docId);

            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => p_HomePage()),
            // );

            // ✅ Show success message using ReusableSnackBar
            ReusableSnackBar(
              context,
              "Instant booking post successfully deleted!",
              icon: Icons.check_circle,
              iconColor: Colors.green,
            );

            Navigator.of(context).maybePop();
            // Close dialog
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

  // void _confirmP_Delete(String docId) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => ConfirmationDialog(
  //       title: "Delete Post",
  //       message: "Are you sure you want to delete this post?",
  //       confirmText: "Delete",
  //       cancelText: "Cancel",
  //       onConfirm: () async {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => p_HomePage()),
  //         ); // Close dialog
  //         await _deleteP_Post(docId); // ✅ Call delete function
  //       },
  //       icon: Icons.delete,
  //       iconColor: Colors.red,
  //       confirmButtonColor: Colors.red,
  //       cancelButtonColor: Colors.grey.shade300,
  //     ),
  //   );
  // }

  void _confirmP_Delete(String docId) async {
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
        builder: (context) => ConfirmationDialog(
          title: "Delete Post",
          message: "Are you sure you want to delete this promotion post?",
          confirmText: "Delete",
          cancelText: "Cancel",
          onConfirm: () async {
              await _deleteP_Post(docId);

              // ✅ Show success message using ReusableSnackBar
              ReusableSnackBar(
                context,
                "Promotion post successfully deleted!",
                icon: Icons.check_circle,
                iconColor: Colors.green,
              );

              Navigator.of(context).maybePop();
              // Close dialog
            },
          icon: Icons.delete,
          iconColor: Colors.red,
          confirmButtonColor: Colors.red,
          cancelButtonColor: Colors.grey.shade300,
        ),
      );
    }
  }

  Future<void> _deleteP_Post(String docId) async {
    try {
      await _firestore.collection('promotion').doc(docId).delete();
      print("Post deleted successfully: $docId");

      _loadPromotionPosts(); // ✅ Refresh list after deletion
    } catch (e) {
      print("Error deleting post: $e");
    }
  }


  Widget _buildInstantBookingSection() {
    // ✅ Take only the first 4 newest posts (no need for `.reversed`)
    List<Widget> latestInstantPosts = allInstantPosts.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    ? () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => p_InstantPostList(),
                    ),
                  );

                  if (result == true) {
                    _loadInstantPosts(); // 🔄 Refresh home page on return
                  }
                }
                    : null,
                child: Opacity(
                  opacity: allInstantPosts.isNotEmpty ? 1.0 : 0.5, // Faded if no posts
                  child: Row(
                    children: const [
                      Text(
                        "See more",
                        style: TextStyle(color: Color(0xFF464E65), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 4), // ✅ Adds spacing between text and icon
                      Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF464E65)),
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
            height: 280,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: displayedInstantPosts), // ✅ Updates dynamically
            ),
          ),

          const SizedBox(height: 16),

          // ✅ Floating Action Button to add a new post
          Center(
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => p_AddInstantPost()),
                ).then((value) {
                  if (value == true) {
                    setState(() {
                      _loadInstantPosts(); // 🔄 Reload posts after adding
                    });
                  }
                });
              },
              backgroundColor: const Color(0xFF464E65),
              child: const Icon(Icons.add, size: 28, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPromotionSection() {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    ? () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => p_PromotionPostList(),
                    ),
                  );

                  if (result == true) {
                    _loadPromotionPosts(); // 🔄 Refresh home page on return
                  }
                }
                    : null,

                child: Opacity(
                  opacity: allPromotionPosts.isNotEmpty ? 1.0 : 0.5, // Faded if no posts
                  child: Row(
                    children: const [
                      Text(
                        "See more",
                        style: TextStyle(color: Color(0xFF464E65), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 4), // ✅ Adds spacing between text and icon
                      Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF464E65)),
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
            height: 280,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: displayedPromotionPosts), // ✅ Updated dynamically
            ),
          ),

          const SizedBox(height: 16),

          // ✅ Floating Action Button to add a new post
          Center(
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => p_AddPromotionPost()),
                ).then((value) {
                  if (value == true) {
                    setState(() {
                      _loadPromotionPosts(); // 🔄 Reload posts after adding
                    });
                  }
                });
              },
              backgroundColor: const Color(0xFF464E65),
              child: const Icon(Icons.add, size: 28, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return ProviderLayout(
        selectedIndex: 0,
        child: Scaffold(
          backgroundColor: Color(0xFFFFF8F2),
          appBar: AppBar(
            backgroundColor: Color(0xFF464E65),
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
                const SizedBox(height: 16),
                _buildPromotionSection(),
                const SizedBox(height: 20),
                _buildInstantBookingSection(),
              ],
            ),
          ),
        )
    );
  }
}


Widget buildInstantBookingCard({
  required BuildContext context,
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
            bottom: 10,
            right: 12,
            child: Text(
              "RM $IPPrice", // Directly use the stored integer
              style: const TextStyle(
                color: Color(0xFF464E65),
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 👇 Status label at bottom-right of the card (beside price)
          Positioned(
            bottom: 15,
            left: 15,
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
                  fontSize: 12,
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


Widget buildPromotionCard({
  required String PTitle,
  required String ServiceStates,
  required String ServiceCategory,
  required List<String> imageUrls,
  required int PPrice,
  required int PAPrice,
  required bool isActive,
  required String postId,
  required double PDiscountPercentage,
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
                      PTitle,
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
                                .collection('promotion')
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

          // 📌 Discount Badge (Top-left of the image)
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

          // 📌 Price Display (Bottom-right)
          Positioned(
            bottom: 10,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Original Price (Strikethrough)
                Text(
                  "RM $PAPrice",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough, // Strikethrough effect
                  ),
                ),
                const SizedBox(height: 2), // Spacing

                // Discounted Price (Larger & Bold)
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

          // 👇 Status label at bottom-right of the card (beside price)
          Positioned(
            bottom: 15,
            left: 15,
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
                  fontSize: 12,
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
