import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/services/ReviewVideoViewer.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';

class p_ServiceRating extends StatefulWidget {
  final String postId;

  const p_ServiceRating({Key? key, required this.postId}) : super(key: key);

  @override
  _p_ServiceRatingState createState() => _p_ServiceRatingState();
}

class _p_ServiceRatingState extends State<p_ServiceRating> {
  String selectedRating = "All Ratings";

  Map<int, int> _calculateStarCounts(List<QueryDocumentSnapshot> reviews) {
    final Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var doc in reviews) {
      final data = doc.data() as Map<String, dynamic>;
      final rating = data['rating'] ?? 0;
      if (rating >= 1 && rating <= 5) {
        starCounts[rating] = (starCounts[rating] ?? 0) + 1;
      }
    }

    return starCounts;
  }

  double _calculateAverageRating(List<QueryDocumentSnapshot> reviews) {
    if (reviews.isEmpty) return 0.0;
    double total = 0;
    for (var doc in reviews) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['rating'] ?? 0).toDouble();
    }
    return total / reviews.length;
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
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF464E65),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Service Ratings",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 2,
        automaticallyImplyLeading: false,
      ),
      body: _buildRatingBody(),
    );
  }

  Widget _buildAspectRating(String title, double value) {
    return Column(
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCriteriaAverages({
    required double quality,
    required double responsiveness,
    required double punctuality,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x2661A9FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAspectRating("Service Quality", quality),
              _buildAspectRating("Responsiveness", responsiveness),
              _buildAspectRating("Punctuality", punctuality),
            ],
          ),
        ],
      ),
    );
  }




  Widget _buildRatingBody() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in"));
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('reviews')
          .where('postId', isEqualTo: widget.postId)
          .orderBy('updatedAt', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No reviews received yet."));
        }

        final reviews = snapshot.data!.docs;
        // Calculate star counts and average
        final starCounts = _calculateStarCounts(reviews);


        // ✅ Assign locally to be used in dropdown
        final ratingCounts = {
          "5 stars": starCounts[5] ?? 0,
          "4 stars": starCounts[4] ?? 0,
          "3 stars": starCounts[3] ?? 0,
          "2 stars": starCounts[2] ?? 0,
          "1 star":  starCounts[1] ?? 0,
        };

        final avgRating = _calculateAverageRating(reviews);

        // Calculate average of each aspect
        double totalQuality = 0;
        double totalResponsiveness = 0;
        double totalPunctuality = 0;

        for (var doc in reviews) {
          final data = doc.data() as Map<String, dynamic>;
          totalQuality += (data['quality'] ?? 0).toDouble();
          totalResponsiveness += (data['responsiveness'] ?? 0).toDouble();
          totalPunctuality += (data['punctuality'] ?? 0).toDouble();
        }

        double avgQuality = reviews.isNotEmpty ? totalQuality / reviews.length : 0;
        double avgResponsiveness = reviews.isNotEmpty ? totalResponsiveness / reviews.length : 0;
        double avgPunctuality = reviews.isNotEmpty ? totalPunctuality / reviews.length : 0;

        // ✅ Filtering based on selectedRating
        final filteredReviews = selectedRating == "All Ratings"
            ? reviews
            : reviews.where((doc) =>
        (doc.data() as Map<String, dynamic>)['rating'].toString() ==
            selectedRating[0]).toList();

        Widget _buildRatingSummary() {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Average rating section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // color: const Color(0xFF464E65).withOpacity(0.05),
                        color: const Color(0x2661A9FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              // color: Color(0xFF464E65),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${reviews.length} Ratings",
                            style: TextStyle(color: Colors.grey[800], fontSize: 15, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Star bar breakdown
                    Expanded(
                      child: Column(
                        children: List.generate(5, (index) {
                          int star = 5 - index;
                          int count = starCounts[star] ?? 0;
                          double ratio = reviews.isNotEmpty ? count / reviews.length : 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Row(
                                    children: [
                                      Text(
                                        "$star",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 10,
                                      backgroundColor: Color(0x3361A9FF),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF464E65)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "(${count.toString()})",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),

                _buildCriteriaAverages(
                  quality: avgQuality,
                  responsiveness: avgResponsiveness,
                  punctuality: avgPunctuality,
                ),
              ],
            ),
          );
        }




        return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildRatingSummary(),
                        Row(
                          children: [
                            // Line from left to middle
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Rating Dropdown aligned right
                            RatingDropdown(
                              selectedRating: selectedRating,
                              ratingCounts: ratingCounts, // 👈 Pass the map here
                              onChanged: (String rating) {
                                setState(() {
                                  selectedRating = rating;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true, // ✅ Important: allow ListView to shrink inside Column
                    physics: const NeverScrollableScrollPhysics(), // ✅ Prevent internal scrolling
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    // itemCount: reviews.length,
                    // itemBuilder: (context, index) {
                    //   final review = reviews[index].data() as Map<String, dynamic>;
                    itemCount: filteredReviews.length,
                    itemBuilder: (context, index) {
                      final review = filteredReviews[index].data() as Map<String, dynamic>;

                      // Review section appear at here
                      final postId = review['postId'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: NetworkImage(
                                          review['userProfilePic'] ?? ""),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      review['userName'] ?? "Anonymous",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                    "${formatTimestamp(
                                        review['updatedAt'])}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,)),
                                const SizedBox(height: 5),
                                Row(
                                  children: List.generate(
                                    review['rating'] ?? 0,
                                        (i) =>
                                    const Icon(
                                        Icons.star, size: 18, color: Colors.amber),
                                  ),
                                ),
                                if (review['quality'] != null ||
                                    review['responsiveness'] != null ||
                                    review['punctuality'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (review['quality'] != null)
                                          _buildCriteriaTag(
                                              "Service Quality", review['quality']),
                                        if (review['responsiveness'] != null)
                                          _buildCriteriaTag("Responsiveness",
                                              review['responsiveness']),
                                        if (review['punctuality'] != null)
                                          _buildCriteriaTag(
                                              "Punctuality", review['punctuality']),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                if (review['comment'] != null && review['comment']
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                                  Text(
                                    review['comment'],
                                    style: const TextStyle(fontSize: 14),
                                    textAlign: TextAlign.justify,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if ((review['reviewVideoUrl'] != null) ||
                                    (review['reviewPhotoUrls'] != null &&
                                        review['reviewPhotoUrls'] is List &&
                                        review['reviewPhotoUrls'].isNotEmpty))
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (review['reviewVideoUrl'] != null)
                                        SizedBox(
                                          width: 90,
                                          height: 90,
                                          child: ReviewVideoPreview(
                                              videoUrl: review['reviewVideoUrl']),
                                        ),
                                      if (review['reviewPhotoUrls'] != null &&
                                          review['reviewPhotoUrls'] is List)
                                        ...List.generate(
                                          (review['reviewPhotoUrls'] as List).length,
                                              (i) {
                                            final url = review['reviewPhotoUrls'][i];
                                            return SizedBox(
                                              width: 90,
                                              height: 90,
                                              child: GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        FullScreenImageViewer(
                                                          imageUrls: List<String>.from(
                                                              review['reviewPhotoUrls']),
                                                          initialIndex: i,
                                                        ),
                                                  );
                                                },
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(
                                                      10),
                                                  child: Image.network(
                                                    url,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child,
                                                        loadingProgress) {
                                                      if (loadingProgress == null)
                                                        return child;
                                                      return Container(
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[300],
                                                          borderRadius: BorderRadius
                                                              .circular(10),
                                                        ),
                                                        child: const Center(
                                                          child: SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child: CircularProgressIndicator(
                                                                strokeWidth: 2),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error,
                                                        stackTrace) {
                                                      return Container(
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[300],
                                                          borderRadius: BorderRadius
                                                              .circular(10),
                                                        ),
                                                        child: const Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ]
            )
        );
      },
    );
  }

  Widget _buildCriteriaTag(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x2661A9FF), // light tinted background
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


class RatingDropdown extends StatelessWidget {
  final String selectedRating;
  final Function(String) onChanged;
  final Map<String, int> ratingCounts;

  const RatingDropdown({
    Key? key,
    required this.selectedRating,
    required this.onChanged,
    required this.ratingCounts,
  }) : super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    final ratings = [
      "All Ratings",
      "5 stars",
      "4 stars",
      "3 stars",
      "2 stars",
      "1 star",
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRating,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: ratings.map((String rating) {
            final countText = rating == "All Ratings"
                ? " (${ratingCounts.values.fold(0, (sum, val) => sum + val)})"
                : " (${ratingCounts[rating] ?? 0})";

            return DropdownMenuItem<String>(
              value: rating,
              child: Text(
                "$rating$countText",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

