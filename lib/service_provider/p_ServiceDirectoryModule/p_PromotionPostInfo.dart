import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/service_provider/p_ReviewRating/p_ServiceRating.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:fix_mate/services/ReviewVideoViewer.dart';


class PromotionPost {
  final String title;
  final String serviceStates;
  final String serviceCategory;
  final List<String> imageUrls;
  final int price;
  final int Aprice;
  final double discountPercentage;
  final String docId;
  final List<TitleWithDescriptions> descriptions;
  String? spName;
  String? spImageURL;

  PromotionPost({
    required this.title,
    required this.serviceStates,
    required this.serviceCategory,
    required this.imageUrls,
    required this.price,
    required this.Aprice,
    required this.discountPercentage,
    required this.docId,
    required this.descriptions,
    required this.spName,
    required this.spImageURL,
  });

  factory PromotionPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PromotionPost(
      title: data['PTitle'] ?? 'Unknown',
      serviceStates: (data['ServiceStates'] as List<dynamic>?)?.join(", ") ?? 'Unknown',
      serviceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? 'No services listed',
      imageUrls: (data['PImage'] != null && data['PImage'] is List<dynamic>)
          ? List<String>.from(data['PImage'])
          : [],
      price: (data['PPrice'] as num?)?.toInt() ?? 0,
      Aprice: (data['PAPrice'] as num?)?.toInt() ?? 0,
      docId: doc.id,

      /// **🔹 Retrieving SPname and SPimageURL**
      spName: data['SPname'] ?? 'Unknown Service Provider',
      spImageURL: data['SPimageURL'] ?? '',
      discountPercentage: (data['PDiscountPercentage'] as num?)?.toDouble() ?? 0.0,
      descriptions: (data['PDescriptions'] as List<dynamic>?)
          ?.map((entry) => TitleWithDescriptions(
        title: entry['title'] ?? '',
        descriptions: List<String>.from(entry['descriptions'] ?? []),
      ))
          .toList() ??
          [],
    );
  }
}

class TitleWithDescriptions {
  final String title;
  final List<String> descriptions;

  TitleWithDescriptions({required this.title, required this.descriptions});
}

class p_PromotionPostInfo extends StatefulWidget {
  final String docId;
  const p_PromotionPostInfo({Key? key, required this.docId}) : super(key: key);

  @override
  _p_PromotionPostInfoState createState() => _p_PromotionPostInfoState();
}


class _p_PromotionPostInfoState extends State<p_PromotionPostInfo> with TickerProviderStateMixin {
  late AnimationController animationController;
  PromotionPost? post;
  PageController _pageController = PageController();
  int _currentPage = 0;
  List<DocumentSnapshot> reviews = [];
  List<DocumentSnapshot> postReviews = [];
  double avgPostRating = 0.0;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    animationController.forward();
    fetchPost();

  }

  // Future<void> fetchPost() async {
  //   DocumentSnapshot doc = await FirebaseFirestore.instance
  //       .collection('promotion')
  //       .doc(widget.docId)
  //       .get();
  //   setState(() {
  //     post = PromotionPost.fromFirestore(doc);
  //   });
  // }

  Future<void> fetchPost() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('promotion')
          .doc(widget.docId)
          .get();

      PromotionPost fetchedPost = PromotionPost.fromFirestore(doc);

      await fetchPostRatings(fetchedPost.docId);

      if (!mounted) return;
      if (post == null || post!.docId != fetchedPost.docId) {
        setState(() {
          post = fetchedPost;
        });
      }
    } catch (e) {
      print("❌ Error in fetchPost: $e");
    }
  }

  Future<void> fetchPostRatings(String postId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('postId', isEqualTo: postId)
          .orderBy('updatedAt', descending: true)
          .get();

      double total = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['rating'] ?? 0).toDouble();
      }
      if (!mounted) return;
      setState(() {
        postReviews = snapshot.docs;
        avgPostRating = postReviews.isNotEmpty ? total / postReviews.length : 0;
      });
    } catch (e) {
      print("❌ Error in fetchPostRatings: $e");
    }
  }


  // Function to format timestamps
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    // DateTime dateTime = timestamp.toDate().add(const Duration(hours: 8));
    DateTime dateTime = timestamp.toDate();
    List<String> monthNames = ["Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ogo", "Sep", "Okt", "Nov", "Dis"];

    String hour = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12).toString(); // No padLeft here
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return "${dateTime.day.toString().padLeft(2, '0')} ${monthNames[dateTime.month - 1]} ${dateTime.year}, "
        "$hour:$minute $period";
  }


  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: post == null
  //         ? const Center(child: CircularProgressIndicator())
  //         : Stack(
  //       children: <Widget>[
  //         /// **Image Carousel with Page Indicator**
  //         Column(
  //           children: <Widget>[
  //             AspectRatio(
  //               aspectRatio: 1.2,
  //               child: Stack(
  //                 children: [
  //                   /// **Scrollable Image List**
  //                   PageView.builder(
  //                     controller: _pageController,
  //                     itemCount: post!.imageUrls.isNotEmpty ? post!.imageUrls.length : 1,
  //                     onPageChanged: (index) {
  //                       setState(() {
  //                         _currentPage = index;
  //                       });
  //                     },
  //                     itemBuilder: (context, index) {
  //                       return GestureDetector(
  //                         onTap: () {
  //                           showDialog(
  //                             context: context,
  //                             builder: (_) => FullScreenImageViewer(
  //                               imageUrls: post!.imageUrls,
  //                               initialIndex: index,
  //                             ),
  //                           );
  //                         },
  //                         child: Image.network(
  //                           post!.imageUrls[index],
  //                           fit: BoxFit.cover,
  //                         ),
  //                       );
  //                     },
  //                   ),
  //
  //                   /// **Page Indicator (e.g., 1/3)**
  //                   Positioned(
  //                     bottom: 60,
  //                     left: 16,
  //                     child: Container(
  //                       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
  //                       decoration: BoxDecoration(
  //                         color: Colors.white,
  //                         borderRadius: BorderRadius.circular(20),
  //                       ),
  //                       child: Text(
  //                         "${_currentPage + 1}/${post!.imageUrls.isNotEmpty ? post!.imageUrls.length : 1}",
  //                         style: const TextStyle(color: Colors.black, fontSize: 14),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //
  //         /// **Main Content Container**
  //         Positioned(
  //           top: MediaQuery.of(context).size.width / 1.3 - 24.0,
  //           bottom: 0,
  //           left: 0,
  //           right: 0,
  //           child: Container(
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: const BorderRadius.only(
  //                 topLeft: Radius.circular(32.0),
  //                 topRight: Radius.circular(32.0),
  //               ),
  //               boxShadow: <BoxShadow>[
  //                 BoxShadow(
  //                   color: Colors.grey.withOpacity(0.2),
  //                   offset: const Offset(1.1, 1.1),
  //                   blurRadius: 10.0,
  //                 ),
  //               ],
  //             ),
  //
  //             child: Column(
  //               children: [
  //                 /// **Scrollable Description Section**
  //                 Expanded(
  //                   child: SingleChildScrollView(
  //                     padding: const EdgeInsets.all(16.0),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: <Widget>[
  //                         Padding(
  //                           padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
  //                           child: Row(
  //                             children: [
  //                               /// **Circular Profile Image**
  //                               CircleAvatar(
  //                                 radius: 28,
  //                                 backgroundImage: (post!.spImageURL != null && post!.spImageURL!.isNotEmpty)
  //                                     ? NetworkImage(post!.spImageURL!)
  //                                     : const AssetImage('assets/default_profile.png') as ImageProvider,
  //                               ),
  //                               const SizedBox(width: 12),
  //
  //                               /// **SP Name & Rating**
  //                               Expanded(
  //                                 child: Column(
  //                                   crossAxisAlignment: CrossAxisAlignment.start,
  //                                   children: [
  //                                     /// **SP Name**
  //                                     Text(
  //                                       post!.spName ?? 'Unknown Service Provider',
  //                                       style: const TextStyle(
  //                                         fontSize: 18,
  //                                         fontWeight: FontWeight.w600,
  //                                       ),
  //                                     ),
  //
  //                                     // /// **Rating in 5 stars**
  //                                     // Row(
  //                                     //   children: List.generate(5, (index) {
  //                                     //     double rating = post!.rating ?? 0; // Ensure rating is not null
  //                                     //     return Icon(
  //                                     //       index < rating ? Icons.star : Icons.star_border,
  //                                     //       color: Colors.orange,
  //                                     //       size: 18,
  //                                     //     );
  //                                     //   }),
  //                                     // ),
  //
  //                                     /// **Static Rating UI (Placeholder)**
  //                                     Row(
  //                                       children: [
  //                                         /// **Placeholder Rating Text**
  //                                         const Text(
  //                                           "0.0",
  //                                           style: TextStyle(
  //                                             fontSize: 16,
  //                                             fontWeight: FontWeight.bold,
  //                                             color: Colors.black,
  //                                           ),
  //                                         ),
  //                                         const SizedBox(width: 6), // Add spacing between rating text and stars
  //                                         /// **Stars**
  //                                         Row(
  //                                           children: List.generate(5, (index) {
  //                                             return const Icon(
  //                                               Icons.star_border, // Empty stars for now
  //                                               color: Colors.orange,
  //                                               size: 18,
  //                                             );
  //                                           }),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //
  //                         /// **Thick Grey Divider**
  //                         const Divider(
  //                           color: Colors.grey, // Grey color
  //                           thickness: 1.5, // Make it thicker
  //                           height: 10, // Adjust spacing above and below the divider
  //                         ),
  //                         const SizedBox(height: 5),
  //                         Text(
  //                           post!.title,
  //                           style: const TextStyle(
  //                             fontWeight: FontWeight.w600,
  //                             fontSize: 20,
  //                             letterSpacing: 0.27,
  //                           ),
  //                         ),
  //
  //                         const SizedBox(height: 5),
  //                         // 📌 Location with Icon
  //                         Row(
  //                           children: [
  //                             const Icon(Icons.location_on, size: 16, color: Colors.black45),
  //                             const SizedBox(width: 4), // Spacing
  //                             Expanded( // ✅ Ensures text truncates within available space
  //                               child: Text(
  //                                 post!.serviceStates,
  //                                 style: const TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w500),
  //                                 overflow: TextOverflow.ellipsis,
  //                                 maxLines: 1,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                         const SizedBox(height: 5),
  //                         // 📌 Service Category with Icon
  //                         Row(
  //                           children: [
  //                             const Icon(Icons.build, size: 16, color: Colors.black45),
  //                             const SizedBox(width: 4), // Spacing
  //                             Expanded( // ✅ Ensures text truncates properly
  //                               child: Text(
  //                                 post!.serviceCategory,
  //                                 style: const TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w500),
  //                                 overflow: TextOverflow.ellipsis,
  //                                 maxLines: 1,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                         const SizedBox(height: 5),
  //                         Row(
  //                           mainAxisAlignment: MainAxisAlignment.start,
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           children: <Widget>[
  //
  //                             // ✅ Discounted Price
  //                             Text(
  //                               "RM ${post!.price}",
  //                               style: const TextStyle(
  //                                 fontSize: 22,
  //                                 fontWeight: FontWeight.w600,
  //                                 color: Color(0xFF464E65),
  //                               ),
  //                             ),
  //
  //                             const SizedBox(width: 8), // Add spacing
  //
  //                             // ✅ Original Price with Strikethrough (Aprice)
  //                             Text(
  //                               "RM ${post!.Aprice}",
  //                               style: const TextStyle(
  //                                 fontSize: 14,
  //                                 fontWeight: FontWeight.w500,
  //                                 color: Colors.grey, // Greyed out color
  //                                 decoration: TextDecoration.lineThrough, // Strikethrough effect
  //                               ),
  //                             ),
  //                             const SizedBox(width: 8), // Add spacing
  //
  //
  //                             Container(
  //                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                               decoration: BoxDecoration(
  //                                 color: Colors.red, // Red background for discount
  //                                 borderRadius: BorderRadius.circular(6),
  //                               ),
  //                               child: Text(
  //                                 "${post!.discountPercentage.toStringAsFixed(0)}% OFF",
  //                                 style: const TextStyle(
  //                                   fontSize: 14,
  //                                   fontWeight: FontWeight.bold,
  //                                   color: Colors.white, // White text for contrast
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //
  //                         const SizedBox(height: 5),
  //
  //                         /// **Thick Grey Divider**
  //                         const Divider(
  //                           color: Colors.grey, // Grey color
  //                           thickness: 1.5, // Make it thicker
  //                           height: 10, // Adjust spacing above and below the divider
  //                         ),
  //
  //                         const SizedBox(height: 5),
  //                         /// **Bullet Point Descriptions**
  //                         if (post!.descriptions.isNotEmpty)
  //                           Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: post!.descriptions.map((desc) {
  //                               return Column(
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: [
  //                                   Text(
  //                                     desc.title,
  //                                     style: const TextStyle(
  //                                       fontWeight: FontWeight.bold,
  //                                       color: Colors.black54,
  //                                       fontSize: 20,
  //                                     ),
  //                                   ),
  //                                   const SizedBox(height: 4),
  //                                   Column(
  //                                     crossAxisAlignment: CrossAxisAlignment.start,
  //                                     children: desc.descriptions.map((point) {
  //                                       return Padding(
  //                                         padding: const EdgeInsets.only(left: 8.0, bottom: 4),
  //                                         child: Row(
  //                                           crossAxisAlignment: CrossAxisAlignment.start,
  //                                           children: [
  //                                             const Text(
  //                                               "• ",
  //                                               style: TextStyle(
  //                                                   fontSize: 16
  //                                               ),
  //                                             ),
  //                                             Expanded(
  //                                               child: Text(
  //                                                 point,
  //                                                 style: const TextStyle(
  //                                                   fontSize: 14,
  //                                                   color: Colors.black54,
  //                                                 ),
  //                                               ),
  //                                             ),
  //                                           ],
  //                                         ),
  //                                       );
  //                                     }).toList(),
  //                                   ),
  //                                   const SizedBox(height: 12),
  //                                 ],
  //                               );
  //                             }).toList(),
  //                           ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //
  //         /// **🔹 Styled Back Button**
  //         Padding(
  //           padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 10), // Move button slightly right
  //           child: Material(
  //             color: Colors.transparent,
  //             child: InkWell(
  //               borderRadius: BorderRadius.circular(20), // Ensure smooth tap effect
  //               onTap: () {
  //                 Navigator.pop(context);
  //               },
  //               child: Container(
  //                 width: 34, // Small circular background
  //                 height: 34,
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFF464E65), // Background color
  //                   shape: BoxShape.circle, // Makes it circular
  //                 ),
  //                 child: Align( // Adjust the icon position inside the circle
  //                   alignment: Alignment.centerRight, // Move the icon slightly to the right
  //                   child: const Padding(
  //                     padding: EdgeInsets.only(right: 5), // Fine-tune position
  //                     child: Icon(
  //                       Icons.arrow_back_ios,
  //                       color: Colors.white, // Contrast against background
  //                       size: 18, // Smaller size
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: post == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          CustomScrollView(
            slivers: [
              /// 🔳 Image Carousel
              SliverAppBar(
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                expandedHeight: MediaQuery.of(context).size.width * 0.70,
                pinned: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: post!.imageUrls.isNotEmpty ? post!.imageUrls.length : 1,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => FullScreenImageViewer(
                                imageUrls: post!.imageUrls,
                                initialIndex: index,
                              ),
                            ),
                            child: Image.network(
                              post!.imageUrls[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 9,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Text(
                            "${_currentPage + 1}/${post!.imageUrls.isNotEmpty ? post!.imageUrls.length : 1}",
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// 📦 Detail Section
              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        /// 🔖 Title
                        Text(post!.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
                        const SizedBox(height: 5),

                        /// 🌍 Location
                        Row(children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.black45),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              post!.serviceStates,
                              style: const TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 5),

                        /// 🛠️ Category
                        Row(children: [
                          const Icon(Icons.build, size: 16, color: Colors.black45),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              post!.serviceCategory,
                              style: const TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),

                        /// 💵 Price Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "RM ${post!.price}",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF464E65),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "RM ${post!.Aprice}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${post!.discountPercentage.toStringAsFixed(0)}% OFF",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),
                        const Divider(thickness: 1.5),
                        const SizedBox(height: 5),

                        /// 📌 Descriptions
                        ...post!.descriptions.map((desc) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(desc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            ...desc.descriptions.map((point) => Padding(
                              padding: const EdgeInsets.only(left: 8.0, bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("• ", style: TextStyle(fontSize: 16)),
                                  Expanded(child: Text(point, style: const TextStyle(fontSize: 14, color: Colors.black54))),
                                ],
                              ),
                            )),
                            const SizedBox(height: 12),
                          ],
                        )),

                        /// 🌟 Post Rating Summary
                        _buildPostRatingSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// 🔙 Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF464E65),
                    shape: BoxShape.circle,
                  ),
                  child: Align( // Adjust the icon position inside the circle
                    alignment: Alignment.centerRight, // Move the icon slightly to the right
                    child: const Padding(
                      padding: EdgeInsets.only(right: 5), // Fine-tune position
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white, // Contrast against background
                        size: 18, // Smaller size
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostRatingSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => p_ServiceRating(postId: widget.docId)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(avgPostRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    const Icon(Icons.star, color: Colors.amber, size: 22),
                    const SizedBox(width: 6),
                    const Text("Service Ratings", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text("(${postReviews.length} Ratings)", style: const TextStyle(color: Colors.black54, fontSize: 14)),
                  ],
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: Colors.grey.shade400, thickness: 1.2),
          const SizedBox(height: 6),

          ...postReviews.take(2).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final images = (data['reviewPhotoUrls'] ?? []) as List;
            final video = data['reviewVideoUrl'] as String?;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundImage: NetworkImage(data['userProfilePic'] ?? '')),
                    const SizedBox(width: 10),
                    Text(data['userName'] ?? "Anonymous", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(formatTimestamp(data['updatedAt']), style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 3),
                Row(
                  children: List.generate((data['rating'] ?? 0),
                          (index) => const Icon(Icons.star_rounded, size: 18, color: Colors.amber)),
                ),
                if ((data['comment'] ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(data['comment'], style: const TextStyle(fontSize: 14)),
                ],
                if (data['quality'] != null || data['responsiveness'] != null || data['punctuality'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (data['quality'] != null) _buildCriteriaTag("Service Quality", data['quality']),
                        if (data['responsiveness'] != null) _buildCriteriaTag("Responsiveness", data['responsiveness']),
                        if (data['punctuality'] != null) _buildCriteriaTag("Punctuality", data['punctuality']),
                      ],
                    ),
                  ),
                if ((video != null && video.isNotEmpty) || (images.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (video != null && video.isNotEmpty)
                        SizedBox(width: 90, height: 90, child: ReviewVideoPreview(videoUrl: video)),
                      ...images.map((url) => SizedBox(
                        width: 90,
                        height: 90,
                        child: GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => FullScreenImageViewer(
                              imageUrls: List<String>.from(images),
                              initialIndex: images.indexOf(url),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                if (postReviews.indexOf(doc) < postReviews.take(2).length - 1)
                  Divider(color: Colors.grey.shade400, thickness: 1.2),
                const SizedBox(height: 6),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }




  Widget _buildCriteriaTag(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1Aff6f61), // light tinted background
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            "$title: $value",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}





