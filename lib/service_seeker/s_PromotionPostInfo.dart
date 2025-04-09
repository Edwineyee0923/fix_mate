import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

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
        .collection('promotion')
        .doc(widget.docId)
        .get();
    setState(() {
      post = PromotionPost.fromFirestore(doc);
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
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => FullScreenImageViewer(
                                imageUrls: post!.imageUrls,
                                initialIndex: index,
                              ),
                            );
                          },
                          child: Image.network(
                            post!.imageUrls[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),

                    /// **Page Indicator (e.g., 1/3)**
                    Positioned(
                      bottom: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${_currentPage + 1}/${post!.imageUrls.isNotEmpty ? post!.imageUrls.length : 1}",
                          style: const TextStyle(color: Colors.black, fontSize: 14),
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
            top: MediaQuery.of(context).size.width / 1.3 - 24.0,
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
                  /// **Scrollable Description Section**
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                            child: Row(
                              children: [
                                /// **Circular Profile Image**
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: (post!.spImageURL != null && post!.spImageURL!.isNotEmpty)
                                      ? NetworkImage(post!.spImageURL!)
                                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                                ),
                                const SizedBox(width: 12),

                                /// **SP Name & Rating**
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      /// **SP Name**
                                      Text(
                                        post!.spName ?? 'Unknown Service Provider',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      // /// **Rating in 5 stars**
                                      // Row(
                                      //   children: List.generate(5, (index) {
                                      //     double rating = post!.rating ?? 0; // Ensure rating is not null
                                      //     return Icon(
                                      //       index < rating ? Icons.star : Icons.star_border,
                                      //       color: Colors.orange,
                                      //       size: 18,
                                      //     );
                                      //   }),
                                      // ),

                                      /// **Static Rating UI (Placeholder)**
                                      Row(
                                        children: [
                                          /// **Placeholder Rating Text**
                                          const Text(
                                            "0.0",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 6), // Add spacing between rating text and stars
                                          /// **Stars**
                                          Row(
                                            children: List.generate(5, (index) {
                                              return const Icon(
                                                Icons.star_border, // Empty stars for now
                                                color: Colors.orange,
                                                size: 18,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// **Thick Grey Divider**
                          const Divider(
                            color: Colors.grey, // Grey color
                            thickness: 1.5, // Make it thicker
                            height: 10, // Adjust spacing above and below the divider
                          ),
                          const SizedBox(height: 5),
                          Text(
                            post!.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              letterSpacing: 0.27,
                            ),
                          ),

                          const SizedBox(height: 5),
                          // 📌 Location with Icon
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.black45),
                              const SizedBox(width: 4), // Spacing
                              Expanded( // ✅ Ensures text truncates within available space
                                child: Text(
                                  post!.serviceStates,
                                  style: const TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // 📌 Service Category with Icon
                          Row(
                            children: [
                              const Icon(Icons.build, size: 16, color: Colors.black45),
                              const SizedBox(width: 4), // Spacing
                              Expanded( // ✅ Ensures text truncates properly
                                child: Text(
                                  post!.serviceCategory,
                                  style: const TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[

                              // ✅ Discounted Price
                              Text(
                                "RM ${post!.price}",
                                style: const TextStyle(
                                  fontSize: 22,
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
                            color: Colors.grey, // Grey color
                            thickness: 1.5, // Make it thicker
                            height: 10, // Adjust spacing above and below the divider
                          ),

                          const SizedBox(height: 5),
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
                                        color: Colors.black54,
                                        fontSize: 20,
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
                                                style: TextStyle(
                                                    fontSize: 16
                                                ),
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

                  pk_button(
                    context,
                    "Next",
                        () {
                      print("Joined ${post!.title}");
                    },
                  ),
                ],
              ),
            ),
          ),
          // /// **🔹 Animated Floating Favorite Button**
          // Positioned(
          //   top: MediaQuery.of(context).size.width / 1.3 - 24.0 - 35,
          //   right: 35,
          //   child: GestureDetector(
          //     onTap: () {
          //       setState(() {
          //         _isFavorite = !_isFavorite; // Toggle favorite state
          //       });
          //     },
          //     child: ScaleTransition(
          //       alignment: Alignment.center,
          //       scale: CurvedAnimation(
          //         parent: animationController!,
          //         curve: Curves.fastOutSlowIn,
          //       ),
          //       child: Card(
          //         color: _isFavorite ? Colors.white : Color(0xFFF06275), // Change background color
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(50.0),
          //           side: _isFavorite ? const BorderSide(color: Color(0xFFF06275), width: 2) : BorderSide.none, // Add border when favorited
          //         ),
          //         elevation: 10.0,
          //         child: Container(
          //           width: 60,
          //           height: 60,
          //           child: Center(
          //             child: Icon(
          //               _isFavorite ? Icons.favorite : Icons.favorite_border, // Change icon
          //               color: _isFavorite ? const Color(0xFFF06275) : Colors.white, // Change icon color
          //               size: 30,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),


          /// **🔹 Animated Floating Favorite Button**
          Positioned(
            top: MediaQuery.of(context).size.width / 1.3 - 24.0 - 45,
            right: 35,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isFavorite = !_isFavorite; // Toggle favorite state
                });
              },
              child: ScaleTransition(
                alignment: Alignment.center,
                scale: CurvedAnimation(
                  parent: animationController!,
                  curve: Curves.fastOutSlowIn,
                ),
                child: Card(
                  color: _isFavorite ? Colors.white : Colors.grey, // Background changes
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0),
                    side: _isFavorite ? const BorderSide(color: Color(0xFFF06275), width: 2) : BorderSide.none, // Border when favorited
                  ),
                  elevation: 10.0,
                  child: Container(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite, // Always filled heart
                        color: _isFavorite ? const Color(0xFFF06275) : Colors.white, // White heart before click, red after
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// **🔹 Styled Back Button**
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 10), // Move button slightly right
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20), // Ensure smooth tap effect
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 34, // Small circular background
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFfb9798), // Background color
                    shape: BoxShape.circle, // Makes it circular
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
}





