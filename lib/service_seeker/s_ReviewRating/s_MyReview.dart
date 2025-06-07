import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';
import 'package:fix_mate/services/ReviewVideoViewer.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';

class s_MyReview extends StatefulWidget {
  const s_MyReview({Key? key}) : super(key: key);

  @override
  State<s_MyReview> createState() => _s_MyReviewState();
}

class _s_MyReviewState extends State<s_MyReview> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String seekerId = '';
  List<QueryDocumentSnapshot> allReviews = [];
  String selectedFilter = 'All';
  bool showWithMediaOnly = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final user = _auth.currentUser;
    if (user != null) {
      seekerId = user.uid;
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: seekerId)
          .orderBy('updatedAt', descending: true)
          .get();

      setState(() {
        allReviews = snapshot.docs;
      });
    }
  }

  List<QueryDocumentSnapshot> _filteredReviews() {
    return allReviews.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final int rating = data['rating'] ?? 0;
      final hasMedia = (data['reviewPhotoUrls'] != null && data['reviewPhotoUrls'].isNotEmpty) ||
          (data['reviewVideoUrl'] != null && data['reviewVideoUrl'].toString().isNotEmpty);

      final ratingMatches = selectedFilter == 'All' || rating.toString() == selectedFilter;
      final mediaMatches = !showWithMediaOnly || hasMedia;

      return ratingMatches && mediaMatches;
    }).toList();
  }

  Future<List<String>> fetchPostImages(String postId) async {
    final postSnap = await FirebaseFirestore.instance
        .collection('instant_booking')
        .doc(postId)
        .get();

    if (postSnap.exists) {
      final data = postSnap.data();
      if (data != null && data['IPImage'] is List) {
        return List<String>.from(data['IPImage']);
      }
    }
    return [];
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    final dt = timestamp.toDate();
    return DateFormat('dd MMM yyyy, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _filteredReviews();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfb9798),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Reviews",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 5,
      ),
      body: CustomScrollView(
        slivers: [
          // Total Reviews Counter
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        const Color(0xFFfb9798).withOpacity(0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfb9798).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFfb9798).withOpacity(0.2)),
                        ),
                        child: Icon(
                          Icons.rate_review_rounded,
                          color: const Color(0xFFfb9798),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${allReviews.length}",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFfb9798),
                              ),
                            ),
                            const Text(
                              "Total Reviews",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const Text(
                              "submitted",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            color: const Color(0xFFfb9798),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Filter Reviews",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            _buildFilterChip('5'),
                            _buildFilterChip('4'),
                            _buildFilterChip('3'),
                            _buildFilterChip('2'),
                            _buildFilterChip('1'),
                            const SizedBox(width: 10),
                            FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.photo_camera_rounded,
                                    size: 16,
                                    color: showWithMediaOnly ? const Color(0xFFfb9798) : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  const Text("With Media"),
                                ],
                              ),
                              selected: showWithMediaOnly,
                              onSelected: (val) => setState(() => showWithMediaOnly = val),
                              selectedColor: const Color(0xFFfb9798).withOpacity(0.2),
                              checkmarkColor: const Color(0xFFfb9798),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: showWithMediaOnly ? const Color(0xFFfb9798) : Colors.grey[300]!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Results Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt_rounded,
                    color: const Color(0xFFfb9798),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Showing ${reviews.length} review${reviews.length != 1 ? 's' : ''}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reviews List
          reviews.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No reviews found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Try adjusting your filters or submit your first review!",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final review = reviews[index].data() as Map<String, dynamic>;
                final postId = review['postId'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(review['userProfilePic'] ?? ""),
                                backgroundColor: Colors.grey[200],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review['userName'] ?? "Anonymous",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      formatTimestamp(review['updatedAt']),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${review['rating'] ?? 0}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (review['quality'] != null || review['responsiveness'] != null || review['punctuality'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (review['quality'] != null)
                                    _buildCriteriaTag("Service Quality", review['quality']),
                                  if (review['responsiveness'] != null)
                                    _buildCriteriaTag("Responsiveness", review['responsiveness']),
                                  if (review['punctuality'] != null)
                                    _buildCriteriaTag("Punctuality", review['punctuality']),
                                ],
                              ),
                            ),

                          if (review['comment']?.toString().trim().isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                review['comment'],
                                style: const TextStyle(fontSize: 14, height: 1.4),
                                textAlign: TextAlign.justify,
                              ),
                            ),

                          if ((review['reviewVideoUrl'] != null) ||
                              (review['reviewPhotoUrls'] != null && review['reviewPhotoUrls'].isNotEmpty))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (review['reviewVideoUrl'] != null)
                                    SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: ReviewVideoPreview(videoUrl: review['reviewVideoUrl']),
                                    ),
                                  if (review['reviewPhotoUrls'] != null)
                                    ...List.generate(
                                      (review['reviewPhotoUrls'] as List).length,
                                          (i) => SizedBox(
                                        width: 90,
                                        height: 90,
                                        child: GestureDetector(
                                          onTap: () => showDialog(
                                            context: context,
                                            builder: (_) => FullScreenImageViewer(
                                              imageUrls: List<String>.from(review['reviewPhotoUrls']),
                                              initialIndex: i,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              review['reviewPhotoUrls'][i],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: postId)),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFfb9798).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFfb9798).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  FutureBuilder<List<String>>(
                                    future: fetchPostImages(postId),
                                    builder: (context, snapshot) {
                                      final img = snapshot.data?.firstOrNull ?? "";
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: img.isNotEmpty
                                            ? Image.network(
                                          img,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                            : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image_outlined, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review['serviceTitle'] ?? 'Service',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "By: ${review['providerName'] ?? 'Provider'}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: const Color(0xFFfb9798),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: reviews.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'All') ...[
              Icon(
                Icons.star,
                size: 14,
                color: isSelected ? const Color(0xFFfb9798) : Colors.grey[600],
              ),
              const SizedBox(width: 4),
            ],
            Text(label == 'All' ? 'All Ratings' : '$label Star'),
          ],
        ),
        selected: isSelected,
        onSelected: (val) => setState(() => selectedFilter = label),
        selectedColor: const Color(0xFFfb9798).withOpacity(0.2),
        checkmarkColor: const Color(0xFFfb9798),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFFfb9798) : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaTag(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFfb9798).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFfb9798).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            "$title: $value",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}