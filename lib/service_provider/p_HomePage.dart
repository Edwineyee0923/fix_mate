import 'package:fix_mate/service_provider/p_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class p_HomePage extends StatefulWidget {
  static String routeName = "/service_provider/p_HomePage";

  const p_HomePage({Key? key}) : super(key: key);

  @override
  _p_HomePageState createState() => _p_HomePageState();
}

class _p_HomePageState extends State<p_HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return ProviderLayout(
        selectedIndex: 0,
        child: Scaffold(
          backgroundColor: Color(0xFFFFF8F2),
          appBar: AppBar(
            backgroundColor: Color(0xFF464E65),
            // leading: IconButton(
            //   icon: Icon(Icons.arrow_back_ios_new_rounded),
            //   onPressed: () {
            //     Navigator.pop(context);
            //   },
            // ),
            // centerTitle: true,
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
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildPromotionSection(context),
                const SizedBox(height: 20),
                _buildInstantBookingSection(context),
              ],
            ),
          ),
        )
    );
  }
}


Widget _buildSearchBar() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: TextField(
      decoration: InputDecoration(
        hintText: "Search your post.......",
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search, color: Color(0xFF464E65)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}


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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            backgroundColor: const Color(0xFF464E65),
            child: const Icon(Icons.add, size: 28, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInstantBookingSection(BuildContext context) {
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          "No instant booking post found.\nPlease click on the + button to add an instant booking post.",
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Center(
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditInstantPostPage()),
              );
            },
            backgroundColor: const Color(0xFF464E65),
            child: const Icon(Icons.add, size: 28, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}



class EditPromotionPostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Promotion Post")),
      body: Center(child: Text("Edit Promotion Post Page")),
    );
  }
}

class EditInstantPostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Instant Booking Post")),
      body: Center(child: Text("Edit Instant Booking Post Page")),
    );
  }
}


