import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/service_seeker/s_SPInfo.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:fix_mate/service_seeker/s_PromotionPostInfo.dart';
import 'package:fix_mate/service_seeker/s_layout.dart';
import 's_HomePage.dart';

class s_Favourite extends StatefulWidget {
  static String routeName = "/service_seeker/s_Favourite";

  const s_Favourite({Key? key}) : super(key: key);

  @override
  _s_FavouriteState createState() => _s_FavouriteState();
}

class _s_FavouriteState extends State<s_Favourite> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Widget> instantFavourites = [];
  List<Widget> promotionFavourites = [];
  List<Widget> providerFavourites = [];

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final instantSnap = await _firestore
        .collection('service_seekers')
        .doc(uid)
        .collection('favourites_instant')
        .get();

    // instantFavourites = await Future.wait(instantSnap.docs.map((doc) async {
    List<Widget> tempList = await Future.wait(instantSnap.docs.map((doc) async {
      final postId = doc.id;
      final post = await _firestore.collection('instant_booking').doc(postId).get();
      final data = post.data();
      if (data == null) return const SizedBox();

      final review = await fetchPostReviewSummary(postId);
      return GestureDetector(
        key: ValueKey(postId),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: postId)),
        ),
        child: SizedBox(
          height: 290,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        (data['IPImage'] as List).isNotEmpty ? data['IPImage'][0] : 'https://via.placeholder.com/150',
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['IPTitle'] ?? "Untitled",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (data['ServiceStates'] as List).join(", "),
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.build, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (data['ServiceCategory'] as List).join(", "),
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Material(
                      color: Colors.white,
                      child: FavoriteButton(
                        instantBookingId: postId,
                        onUnfavourite: () {
                          setState(() {
                            instantFavourites.removeWhere((w) => w.key == ValueKey(postId));
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 15,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF7EC), Color(0xFFFEE9D7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.orange.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          review['avgRating'].toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 14,
                  child: Text(
                    "RM ${data['IPPrice']}",
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
    }));

    final promoSnap = await _firestore
        .collection('service_seekers')
        .doc(uid)
        .collection('favourites_promotion')
        .get();

    // promotionFavourites = await Future.wait(promoSnap.docs.map((doc) async {
      List<Widget> tempList1 = await Future.wait(promoSnap.docs.map((doc) async {
      final postId = doc.id;
      final post = await _firestore.collection('promotion').doc(postId).get();
      final data = post.data();
      if (data == null) return const SizedBox();

      final review = await fetchPostReviewSummary(postId);
      return GestureDetector(
        key: ValueKey(postId),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => s_PromotionPostInfo(docId: postId)),
        ),
        child: SizedBox(
          height: 290,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        (data['PImage'] as List).isNotEmpty
                            ? data['PImage'][0]
                            : 'https://via.placeholder.com/150',
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['PTitle'] ?? "Untitled",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (data['ServiceStates'] as List).join(", "),
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.build, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (data['ServiceCategory'] as List).join(", "),
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ❤️ Favorite Button
                Positioned(
                  top: 6,
                  right: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Material(
                      color: Colors.white,
                      child: FavoriteButton3(
                        promotionId: postId,
                        onUnfavourite: () {
                          setState(() {
                            promotionFavourites.removeWhere((w) => w.key == ValueKey(postId));
                          });
                        },
                      ),
                      // child: StatefulBuilder(
                      //   builder: (context, setState) {
                      //     return FavoriteButton3(promotionId: postId);
                      //   },
                      // ),
                    ),
                  ),
                ),

                // 🔖 Discount badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${(data['PDiscountPercentage'] as num).toDouble().toStringAsFixed(0)}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // ⭐ Rating
                Positioned(
                  bottom: 15,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF7EC), Color(0xFFFEE9D7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.orange.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          review['avgRating'].toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 💰 Price with discount
                Positioned(
                  bottom: 12,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "RM ${data['PAPrice']}",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "RM ${data['PPrice']}",
                        style: const TextStyle(
                          color: Color(0xFFfb9798),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

    }));

    final spSnap = await _firestore
        .collection('service_seekers')
        .doc(uid)
        .collection('favourites_provider')
        .get();
    providerFavourites = await Future.wait(spSnap.docs.map((doc) async {
      final spId = doc.id;
      final sp = await _firestore.collection('service_providers').doc(spId).get();
      final data = sp.data();
      if (data == null) return const SizedBox();

      final review = await fetchProviderReviewSummary(spId);

      // ✅ Wrap with ValueKey for easy removal
      return Container(
        key: ValueKey(spId),
        child: buildSPCard(
          docId: spId,
          name: data['name'],
          location: (data['selectedStates'] as List).join(", "),
          services: (data['selectedExpertiseFields'] as List).join(", "),
          imageUrl: data['profilePic'] ?? '',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ServiceProviderScreen(docId: spId)),
          ),
          // ✅ Pass the callback to remove the card
          onUnfavourite: () {
            setState(() {
              providerFavourites.removeWhere((w) => w.key == ValueKey(spId));
            });
          },
        ),
      );
    }));


    setState(() {
      instantFavourites = tempList;
      promotionFavourites = tempList1;
    });
  }

  Widget _buildTabList(List<Widget> cards, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: _loadFavourites,
      child: cards.isEmpty
          ? ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(emptyMessage, style: TextStyle(color: Colors.grey, fontSize: 16))),
        ],
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        itemBuilder: (context, index) => cards[index],
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // go back to previous screen
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const s_HomePage()),
          );
        }
        return false; // block default pop
      },
    child: SeekerLayout(
      selectedIndex: 2,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFF8F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFFfb9798),
            title: const Text("Favourite", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false,

            // bottom: const TabBar(
            //   // isScrollable: true,
            //   indicatorColor: Colors.white,
            //   labelColor: Colors.white,
            //   unselectedLabelColor: Colors.white70,
            //   tabs: [
            //     Tab(text: "Instant Book"),
            //     Tab(text: "Promotions"),
            //     Tab(text: "Providers"),
            //   ],
            // ),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(child: Text("Inst Book", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                Tab(child: Text("Promotion", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                Tab(child: Text("Provider", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              ],
            ),

          ),
          body: TabBarView(
            children: [
              _buildTabList(instantFavourites, "No instant bookings added."),
              _buildTabList(promotionFavourites, "No promotions saved."),
              _buildTabList(providerFavourites, "No providers favorited."),
            ],
          ),
        ),
      ),
    )
    );
  }
}
