// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// class s_InstantPostInfo2 extends StatefulWidget {
//   final String docId;
//
//   const s_InstantPostInfo2({Key? key, required this.docId}) : super(key: key);
//
//   @override
//   _s_InstantPostInfo2State createState() => _s_InstantPostInfo2State();
// }
//
// class _s_InstantPostInfo2State extends State<s_InstantPostInfo2> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   Map<String, dynamic>? postData;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchPostData();
//   }
//
//   Future<void> fetchPostData() async {
//     try {
//       DocumentSnapshot docSnapshot =
//       await _firestore.collection('instant_booking').doc(widget.docId).get();
//
//       if (docSnapshot.exists) {
//         setState(() {
//           postData = docSnapshot.data() as Map<String, dynamic>;
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error fetching data: $e");
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Instant Booking Details")),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : postData == null
//           ? const Center(child: Text("No data available"))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             // 📌 Safe Image Handling
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.network(
//                 (postData!['IPImage'] is List<dynamic> &&
//                     (postData!['IPImage'] as List<dynamic>).isNotEmpty)
//                     ? (postData!['IPImage'] as List<dynamic>).first.toString()
//                     : "https://via.placeholder.com/150",
//                 width: double.infinity,
//                 height: 200,
//                 fit: BoxFit.cover,
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // 📌 Title
//             Text(
//               postData!['IPTitle']?.toString() ?? "Unknown",
//               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//
//             const SizedBox(height: 8),
//
//             // 📌 Price
//             Text(
//               "Price: RM ${postData!['IPPrice']?.toString() ?? '0'}",
//               style: const TextStyle(fontSize: 18, color: Colors.blue),
//             ),
//
//             const SizedBox(height: 8),
//
//             // 📌 Location
//             Text(
//               "Location: ${(postData!['ServiceStates'] as List<dynamic>?)?.join(", ") ?? "Unknown"}",
//               style: const TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//
//             const SizedBox(height: 8),
//
//             // 📌 Category
//             Text(
//               "Category: ${(postData!['ServiceCategory'] as List<dynamic>?)?.join(", ") ?? "No category"}",
//               style: const TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//
//             const SizedBox(height: 16),
//
//             // 📌 Description
//             Text(
//               "Description:",
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//
//             const SizedBox(height: 8),
//
//             // 📌 Description Entries
//             ...(postData!['IPDescriptions'] as List<dynamic>? ?? []).map((entry) {
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Entry Title
//                   Text(
//                     entry['title']?.toString() ?? "No Title",
//                     style: const TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
//                   ),
//
//                   const SizedBox(height: 4),
//
//                   // Entry Description Bullet Points
//                   ...(entry['descriptions'] as List<dynamic>? ?? []).map((desc) {
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 4),
//                       child: Text("• ${desc.toString()}",
//                           style: const TextStyle(fontSize: 16, color: Colors.black54)),
//                     );
//                   }).toList(),
//
//                   const SizedBox(height: 8),
//                 ],
//               );
//             }).toList(),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InstantPost {
  final String title;
  final String serviceStates;
  final String serviceCategory;
  final List<String> imageUrls;
  final int price;
  final String docId;
  final List<TitleWithDescriptions> descriptions;

  InstantPost({
    required this.title,
    required this.serviceStates,
    required this.serviceCategory,
    required this.imageUrls,
    required this.price,
    required this.docId,
    required this.descriptions,
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

class s_InstantPostInfo2 extends StatefulWidget {
  final String docId;
  const s_InstantPostInfo2({Key? key, required this.docId}) : super(key: key);

  @override
  _s_InstantPostInfo2State createState() => _s_InstantPostInfo2State();
}


class _s_InstantPostInfo2State extends State<s_InstantPostInfo2> with TickerProviderStateMixin {
  late AnimationController animationController;
  InstantPost? post;
  PageController _pageController = PageController();
  int _currentPage = 0;

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
    setState(() {
      post = InstantPost.fromFirestore(doc);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: post == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: <Widget>[
          /// **Image Carousel with Page Indicator**
          Column(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1.2,
                child: Stack(
                  children: [
                    /// **Scrollable Image List**
                    PageView.builder(
                      controller: _pageController,
                      itemCount: post!.imageUrls.isNotEmpty ? post!.imageUrls.length : 1,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return post!.imageUrls.isNotEmpty
                            ? Image.network(post!.imageUrls[index], fit: BoxFit.cover)
                            : Image.asset('assets/design_course/webInterFace.png', fit: BoxFit.cover);
                      },
                    ),

                    /// **Page Indicator (e.g., 1/3)**
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_currentPage + 1}/${post!.imageUrls.isNotEmpty ? post!.imageUrls.length : 1}",
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// **Main Content Container**
          Positioned(
            top: MediaQuery.of(context).size.width / 1.2 - 24.0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32.0),
                  topRight: Radius.circular(32.0),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    offset: const Offset(1.1, 1.1),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// **SP Info Section (Profile Image + Name)**
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        /// **Circular Profile Image**
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: post!.SPimageURL.isNotEmpty
                              ? NetworkImage(post!.SPimageURL)
                              : const AssetImage('assets/default_profile.png') as ImageProvider,
                        ),
                        const SizedBox(width: 12),

                        /// **SP Name**
                        Expanded(
                          child: Text(
                            post!.SPname,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// **Scrollable Description Section**
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            post!.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              letterSpacing: 0.27,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post!.serviceCategory,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                "\$${post!.price}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            post!.serviceStates,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),

                          /// **Bullet Point Descriptions**
                          if (post!.descriptions.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: post!.descriptions.map((desc) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      desc.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: desc.descriptions.map((point) {
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "• ",
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  point,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  /// **Fixed "Join Cart" Section**
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32.0),
                        bottomRight: Radius.circular(32.0),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          offset: const Offset(0, -1),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\$${post!.price}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            print("Joined ${post!.title}");
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text("Join Cart", style: TextStyle(fontSize: 16)),
                        ),
                      ],
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
}



