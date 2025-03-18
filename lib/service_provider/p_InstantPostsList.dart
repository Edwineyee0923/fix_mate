import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class p_InstantPostList extends StatefulWidget {
  @override
  _p_InstantPostListState createState() => _p_InstantPostListState();
}

class _p_InstantPostListState extends State<p_InstantPostList> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // ✅ Initialize FirebaseAuth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ✅ Initialize Firestore
  List<Map<String, dynamic>> allInstantPosts = [];
  List<Map<String, dynamic>> filteredPosts = [];
  String searchQuery = "";
  String sortOrder = "Newest First"; // Default sorting

  @override
  void initState() {
    super.initState();
    _loadInstantPosts();
  }

  // Future<void> _loadInstantPosts() async {
  //   try {
  //     QuerySnapshot snapshot = await _firestore
  //         .collection('instant_booking')
  //         .where('userId', isEqualTo: user.uid) // ✅ Corrected
  //         .get();
  //
  //     List<Map<String, dynamic>> posts = snapshot.docs.map((doc) {
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //       data['id'] = doc.id; // Store doc ID for deletion/edit
  //       return data;
  //     }).toList();
  //
  //     setState(() {
  //       allInstantPosts = posts;
  //       _applyFilters(); // Apply search & sorting
  //     });
  //   } catch (e) {
  //     print("Error fetching instant booking posts: $e");
  //   }
  // }
  Future<void> _loadInstantPosts() async {
    try {
      User? user = _auth.currentUser; // ✅ Get the logged-in user
      if (user == null) {
        print("User not logged in");
        return;
      }

      print("Fetching posts for userId: ${user.uid}");

      QuerySnapshot snapshot = await _firestore
          .collection('instant_booking')
          .where('userId', isEqualTo: user.uid) // ✅ Correct usage
          .get();

      List<Map<String, dynamic>> posts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Store doc ID for deletion/edit
        return data;
      }).toList();

      setState(() {
        allInstantPosts = posts;
        _applyFilters(); // Apply search & sorting
      });
    } catch (e) {
      print("Error fetching instant booking posts: $e");
    }
  }



  void _applyFilters() {
    List<Map<String, dynamic>> tempPosts = allInstantPosts
        .where((post) => post['IPTitle']
        .toString()
        .toLowerCase()
        .contains(searchQuery.toLowerCase()))
        .toList();

    if (sortOrder == "Newest First") {
      tempPosts.sort((a, b) => (b['createdAt'] as Timestamp)
          .compareTo(a['createdAt'] as Timestamp));
    } else {
      tempPosts.sort((a, b) => (a['createdAt'] as Timestamp)
          .compareTo(b['createdAt'] as Timestamp));
    }

    setState(() {
      filteredPosts = tempPosts;
    });
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(docId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String docId) async {
    try {
      await _firestore.collection('instant_booking').doc(docId).delete();
      _loadInstantPosts();
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Instant Bookings"),
      ),
      body: Column(
        children: [
          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                labelText: "Search by Service Provider",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // 🔹 Sorting Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: sortOrder,
              onChanged: (newValue) {
                setState(() {
                  sortOrder = newValue!;
                  _applyFilters();
                });
              },
              items: ["Newest First", "Oldest First"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              isExpanded: true,
            ),
          ),

          Expanded(
            child: filteredPosts.isEmpty
                ? const Center(child: Text("No posts found."))
                : ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Image.network(
                      (post['IPImage'] != null && post['IPImage'] is List<dynamic> && post['IPImage'].isNotEmpty)
                          ? post['IPImage'][0] // ✅ Get the first image URL from the list
                          : 'https://via.placeholder.com/50', // ✅ Fallback placeholder image
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(post['IPTitle'] ?? "Unknown"),
                    subtitle: Text(post['ServiceCategory']?.join(", ") ?? "No services listed"),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(post['id']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
