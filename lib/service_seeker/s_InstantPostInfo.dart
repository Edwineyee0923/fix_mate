import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_SetBookingDetails.dart';
import 'package:fix_mate/service_seeker/s_SPInfo.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';


class InstantPost {
  final String title;
  final String serviceStates;
  final String serviceCategory;
  final List<String> imageUrls;
  final int price;
  final String docId;
  final List<TitleWithDescriptions> descriptions;
  final String spId; // Service Provider ID
  String? spName;
  String? spImageURL;

  InstantPost({
    required this.title,
    required this.serviceStates,
    required this.serviceCategory,
    required this.imageUrls,
    required this.price,
    required this.docId,
    required this.descriptions,
    required this.spId,
    required this.spName,
    required this.spImageURL,
  });

  factory InstantPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return InstantPost(
      title: data['IPTitle'] ?? 'Unknown',
      serviceStates: (data['ServiceStates'] as List<dynamic>?)?.join(", ") ?? 'Unknown',
      serviceCategory: (data['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? 'No services listed',
      imageUrls: (data['IPImage'] != null && data['IPImage'] is List<dynamic>)
          ? List<String>.from(data['IPImage'])
          : [],
      price: (data['IPPrice'] as num?)?.toInt() ?? 0,
      docId: doc.id,

      /// 🔹 Extracting Service Provider ID
      spId: data['userId'] ?? 'Unknown',

      /// **🔹 Retrieving SPname and SPimageURL**
      spName: data['SPname'] ?? 'Unknown Service Provider',
      spImageURL: data['SPimageURL'] ?? '',

      descriptions: (data['IPDescriptions'] as List<dynamic>?)
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

class s_InstantPostInfo extends StatefulWidget {
  final String docId;
  const s_InstantPostInfo({Key? key, required this.docId}) : super(key: key);

  @override
  _s_InstantPostInfoState createState() => _s_InstantPostInfoState();
}


class _s_InstantPostInfoState extends State<s_InstantPostInfo> with TickerProviderStateMixin {
  late AnimationController animationController;
  InstantPost? post;
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFavorite = false; // Track favorite state
  List<DocumentSnapshot> reviews = [];
  double avgRating = 0.0;
  double avgQuality = 0.0;
  double avgResponsiveness = 0.0;
  double avgPunctuality = 0.0;
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


  Future<void> fetchPost() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('instant_booking')
        .doc(widget.docId)
        .get();

    InstantPost fetchedPost = InstantPost.fromFirestore(doc);
    await fetchSPRatings(fetchedPost.spId); // ✅ fetch ratings after post loaded
    await fetchPostRatings(fetchedPost.docId);

    setState(() {
      post = fetchedPost;
    });
  }


  Future<void> fetchSPRatings(String providerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('providerId', isEqualTo: providerId)
        .orderBy('updatedAt', descending: true)
        .get();

    double totalRating = 0;
    double totalQuality = 0;
    double totalResponsiveness = 0;
    double totalPunctuality = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRating += (data['rating'] ?? 0).toDouble();
      totalQuality += (data['quality'] ?? 0).toDouble();
      totalResponsiveness += (data['responsiveness'] ?? 0).toDouble();
      totalPunctuality += (data['punctuality'] ?? 0).toDouble();
    }

    if (!mounted) return; // 🔒 ADD THIS

    setState(() {
      reviews = snapshot.docs;
      avgRating = reviews.isNotEmpty ? totalRating / reviews.length : 0;
      avgQuality = reviews.isNotEmpty ? totalQuality / reviews.length : 0;
      avgResponsiveness = reviews.isNotEmpty ? totalResponsiveness / reviews.length : 0;
      avgPunctuality = reviews.isNotEmpty ? totalPunctuality / reviews.length : 0;
    });
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: post == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          /// Scrollable Content
          CustomScrollView(
            slivers: [
              /// 📸 Image Carousel
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
                        bottom: 20,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Text(
                            "${_currentPage + 1}/${post!.imageUrls.length}",
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// 📄 Description Container with Rounded Transition
              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: Padding(
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
                          Text(
                            post!.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 20),
                          ),
                          const SizedBox(height: 5),
                          Row(children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.black45),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post!.serviceStates,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 5),
                          Row(children: [
                            const Icon(Icons.build, size: 16, color: Colors.black45),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post!.serviceCategory,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            "RM ${post!.price}",
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFfb9798)),
                          ),
                          const Divider(thickness: 1.5, height: 30),
                          ...post!.descriptions.map((desc) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(desc.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87)),
                              const SizedBox(height: 4),
                              ...desc.descriptions.map((point) => Padding(
                                padding: const EdgeInsets.only(left: 8.0, bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("• ", style: TextStyle(fontSize: 16)),
                                    Expanded(
                                      child: Text(point,
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.black54)),
                                    ),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 12),
                            ],
                          )),
                          Text("Product Ratings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              SizedBox(width: 4),
                              Text(avgPostRating.toStringAsFixed(1), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              SizedBox(width: 6),
                              Text("(${postReviews.length} Reviews)", style: TextStyle(color: Colors.black54, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Column(
                            children: [
                              ...postReviews.take(2).map((doc) {
                                final data = doc.data() as Map<String, dynamic>;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      /// Reviewer info
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundImage: NetworkImage(data['userProfilePic'] ?? ''),
                                          ),
                                          SizedBox(width: 8),
                                          Text(data['userName'] ?? "Anonymous", style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      SizedBox(height: 6),

                                      /// Rating stars
                                      Row(
                                        children: List.generate((data['rating'] ?? 0), (index) =>
                                            Icon(Icons.star, size: 16, color: Colors.amber)),
                                      ),
                                      SizedBox(height: 6),

                                      /// Comment
                                      if ((data['comment'] ?? '').toString().trim().isNotEmpty)
                                        Text(data['comment'], style: TextStyle(fontSize: 14, color: Colors.black87)),

                                      /// Images
                                      if ((data['reviewPhotoUrls'] ?? []).isNotEmpty)
                                        SizedBox(
                                          height: 90,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: (data['reviewPhotoUrls'] as List).length,
                                            itemBuilder: (_, i) {
                                              final img = data['reviewPhotoUrls'][i];
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(img, width: 90, height: 90, fit: BoxFit.cover),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              if (postReviews.length > 2)
                                TextButton(
                                  onPressed: () {
                                    // Navigate to full screen review
                                  },
                                  child: Text("View All Reviews"),
                                ),
                            ],
                          ),





                          // Service Provider's Rating
                          _buildProviderRatingCard(),

                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// 🧭 Back Button
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
                    color: Color(0xFFfb9798),
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

          /// ❤️ + 🧭 Bottom Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isFavorite ? Colors.white : Colors.grey,
                        border: _isFavorite
                            ? Border.all(color: const Color(0xFFF06275), width: 2)
                            : null,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.favorite,
                          color: _isFavorite ? const Color(0xFFF06275) : Colors.white,
                          size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: pk_button(
                      context,
                      "Next",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => s_SetBookingDetails(
                              spId: post!.spId,
                              spName: post!.spName ?? 'Unknown Service Provider',
                              spImageURL: post!.spImageURL ?? '',
                              IBpostId: post!.docId,
                              IBPrice: post!.price,
                              IPTitle: post!.title,
                              serviceCategory: post!.serviceCategory,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  }
  /// 🔶 Combined Service Provider Rating Card
  Widget _buildProviderRatingCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProviderScreen(docId: post!.spId), // Use `spId` as docId
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Row for Image + Name/Rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Profile Image
                CircleAvatar(
                  radius: 32,
                  backgroundImage: (post!.spImageURL != null && post!.spImageURL!.isNotEmpty)
                      ? NetworkImage(post!.spImageURL!)
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                ),
                const SizedBox(width: 16),

                /// Name + Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post!.spName ?? 'Unknown Service Provider',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(${reviews.length} Reviews)",
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔸 Second Row for Criteria Ratings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildAspectRating("Service Quality", avgQuality)),
                _verticalDivider(),
                Expanded(child: _buildAspectRating("Responsiveness", avgResponsiveness)),
                _verticalDivider(),
                Expanded(child: _buildAspectRating("Punctuality", avgPunctuality)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  /// 🔸 Vertical divider between criteria
  Widget _verticalDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.grey[600],
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  /// 🔹 Reusable criteria rating block
  Widget _buildAspectRating(String title, double value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

}
