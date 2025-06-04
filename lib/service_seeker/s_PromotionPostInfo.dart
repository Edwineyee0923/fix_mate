import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_SetBookingDetails.dart';
import 'package:fix_mate/service_seeker/s_ReviewRating/s_ServiceRating.dart';
import 'package:fix_mate/service_seeker/s_SPInfo.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String spId; // Service Provider ID
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
    required this.spId,
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

      /// 🔹 Extracting Service Provider ID
      spId: data['userId'] ?? 'Unknown',

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

class s_PromotionPostInfo extends StatefulWidget {
  final String docId;
  const s_PromotionPostInfo({Key? key, required this.docId}) : super(key: key);

  @override
  _s_PromotionPostInfoState createState() => _s_PromotionPostInfoState();
}


class _s_PromotionPostInfoState extends State<s_PromotionPostInfo> with TickerProviderStateMixin {
  late AnimationController animationController;
  PromotionPost? post;
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

      await fetchSPRatings(fetchedPost.spId);
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

  @override
  void dispose() {
    _pageController.dispose(); // ✅ Avoid memory leak
    animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: post == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
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
                            "${_currentPage + 1}/${post!.imageUrls.isNotEmpty ? post!.imageUrls.length : 1}",
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// 📄 Description & Details
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
                        // Title
                        Text(post!.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
                        const SizedBox(height: 5),

                        // Location
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
                        // Category
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[

                            // ✅ Discounted Price
                            Text(
                              "RM ${post!.price}",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFfb9798),
                              ),
                            ),

                            const SizedBox(width: 8), // Add spacing

                            // ✅ Original Price with Strikethrough (Aprice)
                            Text(
                              "RM ${post!.Aprice}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey, // Greyed out color
                                decoration: TextDecoration.lineThrough, // Strikethrough effect
                              ),
                            ),
                            const SizedBox(width: 8), // Add spacing


                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red, // Red background for discount
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${post!.discountPercentage.toStringAsFixed(0)}% OFF",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // White text for contrast
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        /// **Thick Grey Divider**
                        const Divider(
                          thickness: 1.5, // Make it thicker
                          height: 10, // Adjust spacing above and below the divider
                        ),
                        const SizedBox(height: 5),

                        // Bullet Descriptions
                        ...post!.descriptions.map((desc) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(desc.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
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

                        // Service Post Ratings
                        Container(
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
                              /// --- Ratings Summary with Arrow ---
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => s_ServiceRating(postId: widget.docId),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(avgPostRating.toStringAsFixed(1),
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                        SizedBox(width: 6),
                                        Icon(Icons.star, color: Colors.amber, size: 22),
                                        SizedBox(width: 6),
                                        Text("Service Ratings", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        SizedBox(width: 6),
                                        Text("(${postReviews.length} Ratings)",
                                            style: TextStyle(color: Colors.black54, fontSize: 14)),
                                      ],
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.black54),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 6),
                              Divider(color: Colors.grey.shade400, thickness: 1.2),
                              const SizedBox(height: 6),

                              /// --- Review List ---
                              ...postReviews.take(2).map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final images = (data['reviewPhotoUrls'] ?? []) as List;
                                final video = data['reviewVideoUrl'] as String?;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// Reviewer Info
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: NetworkImage(data['userProfilePic'] ?? ''),
                                        ),
                                        SizedBox(width: 10),
                                        Text(data['userName'] ?? "Anonymous",
                                            style: TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                        "${formatTimestamp(
                                            data['updatedAt'])}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,)),
                                    const SizedBox(height: 3),

                                    /// Rating Stars
                                    Row(
                                      children: List.generate(
                                        (data['rating'] ?? 0),
                                            (index) => Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                      ),
                                    ),

                                    /// Comment
                                    if ((data['comment'] ?? '').toString().trim().isNotEmpty) ...[
                                      SizedBox(height: 6),
                                      Text(data['comment'], style: TextStyle(fontSize: 14)),
                                    ],

                                    // Optional Criteria Tags (modern pill-style boxes)
                                    if (data['quality'] != null || data['responsiveness'] != null || data['punctuality'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            if (data['quality'] != null)
                                              _buildCriteriaTag("Service Quality", data['quality']),
                                            if (data['responsiveness'] != null)
                                              _buildCriteriaTag("Responsiveness", data['responsiveness']),
                                            if (data['punctuality'] != null)
                                              _buildCriteriaTag("Punctuality", data['punctuality']),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 10),

                                    /// Media (Photo & Video)
                                    if ((video != null && video.isNotEmpty) || (images.isNotEmpty)) ...[
                                      SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (video != null && video.isNotEmpty)
                                            SizedBox(
                                              width: 90,
                                              height: 90,
                                              child: ReviewVideoPreview(videoUrl: video),
                                            ),
                                          ...List.generate(images.length, (index) {
                                            final url = images[index];
                                            return SizedBox(
                                              width: 90,
                                              height: 90,
                                              child: GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) => FullScreenImageViewer(
                                                      imageUrls: List<String>.from(images),
                                                      initialIndex: index,
                                                    ),
                                                  );
                                                },
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Image.network(
                                                    url,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[300],
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: const Center(
                                                          child: SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child: CircularProgressIndicator(strokeWidth: 2),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[300],
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],

                                    /// Divider between reviews (only if not last)
                                    if (postReviews.indexOf(doc) < postReviews.take(2).length - 1)
                                      Divider(color: Colors.grey.shade400, thickness: 1.2),
                                    const SizedBox(height: 6),
                                  ],
                                );
                              }).toList(),

                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ✅ Provider Rating Card
                        _buildProviderRatingCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Back Button
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

          // Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Row(
                  children: [
                    // Favourite button
                    FavoriteCircleButton(
                      promotionId: post!.docId,
                      onUnfavourite: () {
                        // Optional: refresh UI or update list
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: pk_button(
                        context,
                        "Next",
                            () => Navigator.push(
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
                        ),
                      ),
                    ),
                  ],
                ),
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
                            "(${reviews.length} Ratings)",
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

  Widget _buildAspectRating(String title, double value) {
    return Column(
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


class FavoriteCircleButton extends StatefulWidget {
  final String promotionId;
  final VoidCallback? onUnfavourite;

  const FavoriteCircleButton({
    Key? key,
    required this.promotionId,
    this.onUnfavourite,
  }) : super(key: key);

  @override
  _FavoriteCircleButtonState createState() => _FavoriteCircleButtonState();
}

class _FavoriteCircleButtonState extends State<FavoriteCircleButton> {
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
        .collection('favourites_promotion')
        .doc(widget.promotionId)
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
        .collection('favourites_promotion')
        .doc(widget.promotionId);

    try {
      if (isFavorite) {
        await favRef.delete();
        widget.onUnfavourite?.call();
        ReusableSnackBar(context, "Removed from favourites",
            icon: Icons.favorite_border, iconColor: Colors.grey);
      } else {
        await favRef.set({
          'promotionId': widget.promotionId,
          'favoritedAt': FieldValue.serverTimestamp(),
        });
        ReusableSnackBar(context, "Added to favourites",
            icon: Icons.favorite, iconColor: Color(0xFFF06275));
      }

      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      print("❌ Error toggling favorite: $e");
      ReusableSnackBar(context, "Failed to update favourite",
          icon: Icons.error, iconColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(27.5),
        onTap: _toggleFavorite,
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFavorite ? Colors.white : Colors.grey,
            border: isFavorite
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
          child: Icon(
            Icons.favorite,
            color: isFavorite ? const Color(0xFFF06275) : Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}



