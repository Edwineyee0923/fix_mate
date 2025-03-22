import 'package:fix_mate/service_provider/p_InstantPostsList.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo2.dart';
import 'package:fix_mate/service_seeker/s_InstantPostList.dart';
import 'package:fix_mate/service_seeker/s_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';


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
  List<Widget> latestInstantPosts = [];

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

      // print("Fetching posts for userId: ${user.uid}");

      // QuerySnapshot snapshot = await _firestore
      //     .collection('instant_booking')
      //     .get();

      // Start with a Query (Fetching all instant booking posts)
      Query query = _firestore.collection('instant_booking');

      // Apply Sorting Based on `updatedAt`
      query = query.orderBy('updatedAt', descending: true); // ✅ Always get the latest posts first

      // Execute Query
      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("No instant booking posts found.");
      } else {
        print("Fetched ${snapshot.docs.length} instant booking posts");
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => s_InstantPostInfo2(docId: doc.id),
              ),
            );
          },

        );
      }).toList();

      setState(() {
        allInstantPosts = instantPosts;
        latestInstantPosts = allInstantPosts.take(4).toList(); // ✅ Only take the latest 4
      });
    } catch (e) {
      print("Error loading Instant Booking Posts: $e");
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
          latestInstantPosts.isEmpty
              ? const Text(
            "No instant booking post found.",
            style: TextStyle(color: Colors.black54),
          )
              : SizedBox(
            height: 280,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: latestInstantPosts),
            ),
          ),

          const SizedBox(height: 16),

        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return SeekerLayout(
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
                // _buildSearchBar(),
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


// Widget _buildSearchBar() {
//   return Container(
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(25),
//       boxShadow: [
//         BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
//       ],
//     ),
//     child: TextField(
//       decoration: InputDecoration(
//         hintText: "Search your post.......",
//         border: InputBorder.none,
//         prefixIcon: const Icon(Icons.search, color: Color(0xFF464E65)),
//         contentPadding: const EdgeInsets.symmetric(vertical: 14),
//       ),
//     ),
//   );
// }


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
            backgroundColor: const Color(0xFFfb9798),
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
            bottom: 15,
            right: 20,
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


// Widget buildInstantBookingCard({
//   String? IPTitle,  // Nullable
//   String? ServiceStates,  // Nullable
//   String? ServiceCategory,  // Nullable
//   List<String>? imageUrls,  // Nullable
//   int? IPPrice,  // Nullable
//   required VoidCallback onTap,
// }) {
//   return GestureDetector(
//     onTap: onTap,
//     child: Container(
//       width: 220,
//       margin: const EdgeInsets.symmetric(horizontal: 8),
//       child: Card(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 3,
//         child: Stack(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                   child: Image.network(
//                     (imageUrls != null && imageUrls.isNotEmpty)
//                         ? imageUrls.first
//                         : "https://via.placeholder.com/150",
//                     width: double.infinity,
//                     height: 130,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         IPTitle ?? "Unknown Title",
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                         overflow: TextOverflow.ellipsis,
//                         maxLines: 2,
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           const Icon(Icons.location_on, size: 14, color: Colors.grey),
//                           const SizedBox(width: 4),
//                           Expanded(
//                             child: Text(
//                               ServiceStates ?? "Unknown Location",
//                               style: const TextStyle(fontSize: 14, color: Colors.grey),
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 1,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 2),
//                       Row(
//                         children: [
//                           const Icon(Icons.build, size: 14, color: Colors.grey),
//                           const SizedBox(width: 4),
//                           Expanded(
//                             child: Text(
//                               ServiceCategory ?? "No Category",
//                               style: const TextStyle(fontSize: 14, color: Colors.grey),
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 1,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             Positioned(
//               bottom: 15,
//               right: 20,
//               child: Text(
//                 "RM ${IPPrice ?? 0}",
//                 style: const TextStyle(
//                   color: Color(0xFF464E65),
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }


class EditPromotionPostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Promotion Post")),
      body: Center(child: Text("Edit Promotion Post Page")),
    );
  }
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
