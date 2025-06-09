import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/service_provider/p_ReviewRating/p_ServiceRating.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_SetBookingDetails.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';
import 'package:fix_mate/services/ReviewVideoViewer.dart';


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

class p_InstantPostInfo extends StatefulWidget {
  final String docId;
  const p_InstantPostInfo({Key? key, required this.docId}) : super(key: key);

  @override
  _p_InstantPostInfoState createState() => _p_InstantPostInfoState();
}


class _p_InstantPostInfoState extends State<p_InstantPostInfo> with TickerProviderStateMixin {
  late AnimationController animationController;
  InstantPost? post;
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFavorite = false; // Track favorite state
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

  Future<void> fetchPost() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('instant_booking')
          .doc(widget.docId)
          .get();

      InstantPost fetchedPost = InstantPost.fromFirestore(doc);
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

  @override
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
              /// Image Carousel
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
                            "${_currentPage + 1}/${post!.imageUrls.length}",
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Description + Rating
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
                        Text(post!.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
                        const SizedBox(height: 5),
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
                        Text("RM ${post!.price}",
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Color(0xFF464E65))),
                        const Divider(thickness: 1.5, height: 30),

                        /// Descriptions
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
                                  Expanded(
                                    child: Text(point,
                                        style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                  ),
                                ],
                              ),
                            )),
                            const SizedBox(height: 12),
                          ],
                        )),

                        /// Post Rating Section
                        _buildPostRatingSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// Back Button
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
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
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
            offset: const Offset(0, 4),
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
                    Text("(${postReviews.length} Ratings)",
                        style: const TextStyle(color: Colors.black54, fontSize: 14)),
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
                    Text(data['userName'] ?? "Anonymous",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(formatTimestamp(data['updatedAt']),
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
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
                        if (data['quality'] != null)
                          _buildCriteriaTag("Service Quality", data['quality']),
                        if (data['responsiveness'] != null)
                          _buildCriteriaTag("Responsiveness", data['responsiveness']),
                        if (data['punctuality'] != null)
                          _buildCriteriaTag("Punctuality", data['punctuality']),
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
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: ReviewVideoPreview(videoUrl: video),
                        ),
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





