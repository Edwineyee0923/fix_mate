import 'package:fix_mate/service_provider/p_AddInstantPost.dart';
import 'package:fix_mate/service_provider/p_InstantPostsList.dart';
import 'package:fix_mate/service_provider/p_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';


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


  @override
  void initState() {
    super.initState();
    _loadInstantPosts(); // Load posts when the page initializes
  }



  Future<void> _loadInstantPosts() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User not logged in");
        return;
      }

      print("Fetching posts for userId: ${user.uid}");

      QuerySnapshot snapshot = await _firestore
          .collection('instant_booking')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        print("No instant booking posts found for user: ${user.uid}");
      } else {
        print("Fetched ${snapshot.docs.length} posts");
      }

      List<Widget> instantPosts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return buildInstantBookingCard(
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
          onEdit: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => p_AddInstantPost(),
              ),
            );
            if (result == true) {
              _loadInstantPosts(); // Refresh after editing
            }
          },
          onDelete: () {
            _confirmDelete(doc.id); // ✅ Call delete confirmation
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


  // void _confirmDelete(String docId) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("Delete Post"),
  //       content: const Text("Are you sure you want to delete this post?"),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context), // Cancel
  //           child: const Text("Cancel"),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             Navigator.pop(context); // Close dialog
  //             await _deletePost(docId); // ✅ Call delete function
  //           },
  //           child: const Text("Delete", style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Delete Post",
        message: "Are you sure you want to delete this post?",
        confirmText: "Delete",
        cancelText: "Cancel",
        onConfirm: () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => p_HomePage()),
          ); // Close dialog
          await _deletePost(docId); // ✅ Call delete function
        },
        icon: Icons.delete,
        iconColor: Colors.red,
        confirmButtonColor: Colors.red,
        cancelButtonColor: Colors.grey.shade300,
      ),
    );
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
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => p_InstantPostList(),
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
          allInstantPosts.isEmpty
              ? const Text(
            "No instant booking post found.\nPlease click on the + button to add an instant booking post.",
            style: TextStyle(color: Colors.black54),
          )
              : SizedBox(
            height: 280,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: allInstantPosts),
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
                _buildPromotionSection(context),
                const SizedBox(height: 20),
                _buildInstantBookingSection(),
              ],
            ),
          ),
        )
    );
  }
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
      decoration: InputDecoration(
        hintText: "Search your post.......",
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search, color: Color(0xFF464E65)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}


Widget _buildPromotionSection(BuildContext context) {
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
            GestureDetector(
              onTap: () {}, // Implement navigation to 'See More'
              child: Row(
                children: const [
                  Text("See more", style: TextStyle(color: Colors.blue, fontSize: 14)),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "No promotion post found.\nPlease click on the + button to add a promotion post.",
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Center(
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditPromotionPostPage()),
              );
            },
            backgroundColor: const Color(0xFF464E65),
            child: const Icon(Icons.add, size: 28, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}





Widget buildInstantBookingCard({
  required String IPTitle,
  required String ServiceStates,
  required String ServiceCategory,
  required List<String> imageUrls,
  required int IPPrice,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Container(
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
                      onPressed: () {
                        final RenderBox button = context.findRenderObject() as RenderBox;
                        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                        final RelativeRect position = RelativeRect.fromRect(
                          Rect.fromPoints(
                            button.localToGlobal(Offset.zero, ancestor: overlay),
                            button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                          ),
                          Offset.zero & overlay.size,
                        );

                        showMenu(
                          context: context,
                          position: position,
                          color: Colors.white, // ✅ White background for dropdown
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // ✅ More rounded edges
                          ),
                          elevation: 8, // ✅ Adds depth with a shadow
                          items: [
                            PopupMenuItem(
                              value: 'edit',
                              onTap: () {
                                onEdit(); // ✅ Now the Edit button works
                              },
                              child: Row(
                                children: const [
                                  Icon(Icons.edit, color: Color(0xFF464E65), size: 18), // ✅ Custom color & size
                                  SizedBox(width: 14),
                                  Text('Edit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              onTap: () {
                                onDelete(); // ✅ Now the Delete button works
                              },
                              child: Row(
                                children: const [
                                  Icon(Icons.delete, color: Colors.red, size: 18),
                                  SizedBox(width: 14),
                                  Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),






          // 📌 Price (Bottom-right of the card)
          Positioned(
            bottom: 15,
            right: 20,
            child: Text(
              "RM $IPPrice", // Directly use the stored integer
              style: const TextStyle(
                color: Color(0xFF464E65),
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),





        ],
      ),
    ),
  );
}





class EditPromotionPostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Promotion Post")),
      body: Center(child: Text("Edit Promotion Post Page")),
    );
  }
}



