import 'package:fix_mate/service_seeker/s_BookingModule/s_AInstantBookingDetail.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_CCInstantBookingDetail.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_CInstantBookingDetail.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_Notification.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_PInstantBookingDetail.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/service_seeker/s_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';


class s_BookingHistory extends StatefulWidget {
  static String routeName = "/service_seeker/s_BookingHistory";

  final int initialTabIndex;

  const s_BookingHistory({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  _s_BookingHistoryState createState() => _s_BookingHistoryState();
}

class _s_BookingHistoryState extends State<s_BookingHistory> {
  String? seekerId;
  int _selectedIndex = 0;
  final List<String> statuses = ["Pending Confirmation", "Active", "Completed", "Cancelled", "Review"];
  final ScrollController _tabScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchMatches = [];
  int _matchIndex = 0;
  List<Map<String, dynamic>> _allBookings = [];


  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    seekerId = user?.uid;

    if (seekerId != null) {
      _fetchAllBookings();
    }

    _selectedIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Estimate the width of each button + padding (adjust if needed)
      final buttonWidth = 120.0;
      _tabScrollController.animateTo(
        _selectedIndex * buttonWidth,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
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

  Future<void> _fetchAllBookings() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceSeekerId', isEqualTo: seekerId)
        .get();

    setState(() {
      _allBookings = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            final query = value.trim().toLowerCase();

            setState(() {
              _searchQuery = query;

              _searchMatches = _allBookings.where((b) {
                final title = (b['IPTitle'] ?? '').toString().toLowerCase();
                final id = (b['bookingId'] ?? '').toString().toLowerCase();
                return title.contains(query) || id.contains(query);
              }).toList();

              _matchIndex = 0;

              if (_searchMatches.isNotEmpty) {
                final tabIndex = statuses.indexOf(_searchMatches[_matchIndex]['status']);
                if (tabIndex != _selectedIndex && tabIndex != -1) {
                  _selectedIndex = tabIndex;
                  final buttonWidth = 120.0;
                  _tabScrollController.animateTo(
                    tabIndex * buttonWidth,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                }
              }
            });
          },
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search post title or booking ID...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF464E65)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchMatches.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${_matchIndex + 1} of ${_searchMatches.length}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                if (_searchMatches.length > 1)
                  Tooltip(
                    message: 'Previous match',
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_drop_up,
                        color: _matchIndex > 0 ? Color(0xFFfb9798) : Colors.grey,
                      ),
                      onPressed: _matchIndex > 0
                          ? () {
                        setState(() {
                          _matchIndex--;
                          final tabIndex = statuses.indexOf(
                              _searchMatches[_matchIndex]['status']);
                          if (tabIndex != _selectedIndex && tabIndex != -1) {
                            _selectedIndex = tabIndex;
                            _tabScrollController.animateTo(
                              tabIndex * 120.0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      }
                          : null,
                    ),
                  ),
                if (_searchMatches.length > 1)
                  Tooltip(
                    message: 'Next match',
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: _matchIndex < _searchMatches.length - 1
                            ? Color(0xFFfb9798)
                            : Colors.grey,
                      ),
                      onPressed: _matchIndex < _searchMatches.length - 1
                          ? () {
                        setState(() {
                          _matchIndex++;
                          final tabIndex = statuses.indexOf(
                              _searchMatches[_matchIndex]['status']);
                          if (tabIndex != _selectedIndex && tabIndex != -1) {
                            _selectedIndex = tabIndex;
                            _tabScrollController.animateTo(
                              tabIndex * 120.0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      }
                          : null,
                    ),
                  ),
                if (_searchController.text.isNotEmpty)
                  Tooltip(
                    message: 'Clear search',
                    child: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _searchMatches.clear();
                          _matchIndex = 0;
                        });
                        FocusScope.of(context).unfocus(); // dismiss keyboard
                      },
                    ),
                  ),
              ],
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }


  // Widget _buildSearchBar() {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(30),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black12,
  //             blurRadius: 6,
  //             offset: Offset(0, 3),
  //           ),
  //         ],
  //       ),
  //       child: TextField(
  //         controller: _searchController,
  //         onChanged: (value) {
  //           final query = value.trim().toLowerCase();
  //
  //           setState(() {
  //             _searchQuery = query;
  //
  //             _searchMatches = _allBookings.where((b) {
  //               final title = (b['IPTitle'] ?? '').toString().toLowerCase();
  //               final id = (b['bookingId'] ?? '').toString().toLowerCase();
  //               return title.contains(query) || id.contains(query);
  //             }).toList();
  //
  //             _matchIndex = 0;
  //
  //             if (_searchMatches.isNotEmpty) {
  //               final tabIndex = statuses.indexOf(_searchMatches[_matchIndex]['status']);
  //               if (tabIndex != _selectedIndex && tabIndex != -1) {
  //                 _selectedIndex = tabIndex;
  //                 final buttonWidth = 120.0;
  //                 _tabScrollController.animateTo(
  //                   tabIndex * buttonWidth,
  //                   duration: const Duration(milliseconds: 400),
  //                   curve: Curves.easeOut,
  //                 );
  //               }
  //             }
  //           });
  //         },
  //         style: const TextStyle(fontSize: 15),
  //         decoration: InputDecoration(
  //           hintText: 'Search post title or booking ID...',
  //           hintStyle: TextStyle(color: Colors.grey.shade500),
  //           prefixIcon: const Icon(Icons.search, color: Color(0xFF464E65)),
  //           suffixIcon: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               if (_searchMatches.length > 1)
  //                 IconButton(
  //                   icon: const Icon(Icons.arrow_drop_up, color: Colors.grey),
  //                   onPressed: () {
  //                     if (_matchIndex > 0) {
  //                       setState(() {
  //                         _matchIndex--;
  //                         final tabIndex = statuses.indexOf(_searchMatches[_matchIndex]['status']);
  //                         if (tabIndex != _selectedIndex && tabIndex != -1) {
  //                           _selectedIndex = tabIndex;
  //                           _tabScrollController.animateTo(
  //                             tabIndex * 120.0,
  //                             duration: const Duration(milliseconds: 400),
  //                             curve: Curves.easeOut,
  //                           );
  //                         }
  //                       });
  //                     }
  //                   },
  //                 ),
  //               if (_searchMatches.length > 1)
  //                 IconButton(
  //                   icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
  //                   onPressed: () {
  //                     if (_matchIndex < _searchMatches.length - 1) {
  //                       setState(() {
  //                         _matchIndex++;
  //                         final tabIndex = statuses.indexOf(_searchMatches[_matchIndex]['status']);
  //                         if (tabIndex != _selectedIndex && tabIndex != -1) {
  //                           _selectedIndex = tabIndex;
  //                           _tabScrollController.animateTo(
  //                             tabIndex * 120.0,
  //                             duration: const Duration(milliseconds: 400),
  //                             curve: Curves.easeOut,
  //                           );
  //                         }
  //                       });
  //                     }
  //                   },
  //                 ),
  //               if (_searchController.text.isNotEmpty)
  //                 IconButton(
  //                   icon: const Icon(Icons.clear, color: Colors.grey),
  //                   onPressed: () {
  //                     _searchController.clear();
  //                     setState(() {
  //                       _searchQuery = '';
  //                       _searchMatches.clear();
  //                       _matchIndex = 0;
  //                     });
  //                     FocusScope.of(context).unfocus(); // dismiss keyboard
  //                   },
  //                 ),
  //             ],
  //           ),
  //           contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  //           border: InputBorder.none,
  //         ),
  //       ),
  //     ),
  //   );
  // }



  Color getStatusColor(Map<String, dynamic> data) {
    if (data['status'] == 'Completed') return Colors.green;

    if (data['status'] == 'Cancelled') {
      return Colors.redAccent;
    }

    if (data['status'] == 'Pending Confirmation' &&
        (data['sCancelled'] ?? false) == true &&
        (data['isRescheduling'] ?? false) == false) {
      return Colors.redAccent;
    }

    if (data['isRescheduling'] == true) return Colors.amber;

    if (data['status'] == 'Active' && (data['pCompleted'] ?? false) == true) {
      return Colors.orange;
    }

    if (data['status'] == 'Active') return Colors.green;

    return const Color(0xFFfb9798); // Fallback
  }

  String getStatusLabel(Map<String, dynamic> data) {
    if (data['status'] == 'Completed') return "Service Completed";

    if (data['status'] == 'Cancelled') {
      return (data['refundIssued'] ?? false)
          ? "Cancelled - Refunded"
          : "Cancelled - Refund Rejected";
    }

    if (data['status'] == 'Pending Confirmation' &&
        (data['sCancelled'] ?? false) == true &&
        (data['isRescheduling'] ?? false) == false) {
      return "Cancellation Requested";
    }

    if (data['isRescheduling'] == true) return "Booking Rescheduled";

    if (data['status'] == 'Active' && (data['pCompleted'] ?? false) == true) {
      return "Service Delivered";
    }

    if (data['status'] == 'Active') return "Service in Progress";

    return "New Order Assigned";
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

  @override
  Widget build(BuildContext context) {
    return SeekerLayout(
      selectedIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFfb9798),
          title: const Text(
            "Booking History",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          titleSpacing: 25,
          automaticallyImplyLeading: false,
          actions: [
            if (seekerId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('s_notifications')
                    .where('seekerId', isEqualTo: seekerId)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = snapshot.data?.docs.length ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10), // 👈 Shift icon slightly left
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => s_Notification()),
                        );
                      },
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none_rounded, size: 28, color: Colors.white),
                          if (unreadCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            SingleChildScrollView(
              controller: _tabScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12, right: 12, top: 1, bottom: 0), // 👈 Less space below buttons
              child: Row(
                children: List.generate(statuses.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _selectedIndex = index);

                        // 👇 Auto-scroll to bring selected tab into view
                        final buttonWidth = 120.0; // Approximate width of each button
                        _tabScrollController.animateTo(
                          index * buttonWidth,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Color(0xFFfb9798) : Colors.grey[300],
                        foregroundColor: isSelected ? Colors.white : Colors.black45,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold, // 👈 Make text bold
                        ),
                      ),
                      child: Text(statuses[index].split(" ")[0]),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: seekerId == null
                  // ? const Center(child: Text("You must be logged in."))
                  ? const Center(child: Text("You must be logged in."))
                  : statuses[_selectedIndex] == "Review"
                  ? const Center(
                child: Text(
                  "Coming Soon",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              )
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings')
                    .where('serviceSeekerId', isEqualTo: seekerId)
                    .where('status', isEqualTo: statuses[_selectedIndex])
                    .orderBy('updatedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No bookings found."));
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    // children: snapshot.data!.docs.map((doc) {
                    children: snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final postTitle = (data['IPTitle'] ?? '').toString().toLowerCase();
                    final bookingId = (data['bookingId'] ?? '').toString().toLowerCase();

                    return postTitle.contains(_searchQuery) || bookingId.contains(_searchQuery);
                    }).map((doc) {
                      {
                        final data = doc.data() as Map<String, dynamic>;
                        final isActive = data['status'] == 'Active';
                        final isCompleted = data['status'] == 'Completed';
                        final isCancelled = data['status'] == 'Cancelled';
                        final isInstantBooking = data['bookingId']
                            .toString()
                            .startsWith('BKIB');
                        final bookingId = data['bookingId'];
                        final seekerId = FirebaseAuth.instance.currentUser
                            ?.uid ?? '';

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('s_notifications')
                              .where('seekerId', isEqualTo: seekerId)
                              .where('bookingId', isEqualTo: bookingId)
                              .where('isRead', isEqualTo: false)
                              .snapshots(),
                          builder: (context, notiSnapshot) {
                            final hasUnread = notiSnapshot.hasData &&
                                notiSnapshot.data!.docs.isNotEmpty;

                            return InkWell(
                                onTap: () async {
                                  if (hasUnread) {
                                    for (var notiDoc in notiSnapshot.data!
                                        .docs) {
                                      await notiDoc.reference.update(
                                          {'isRead': true});
                                    }
                                  }

                                  if (isInstantBooking) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        isCompleted
                                            ? s_CInstantBookingDetail(
                                          bookingId: bookingId,
                                          postId: data['postId'],
                                          providerId: data['serviceProviderId'],
                                        )
                                            : isActive
                                            ? s_AInstantBookingDetail(
                                          bookingId: bookingId,
                                          postId: data['postId'],
                                          providerId: data['serviceProviderId'],
                                        ) : isCancelled
                                            ? s_CCInstantBookingDetail(
                                          bookingId: data['bookingId'],
                                          postId: data['postId'],
                                          providerId: data['serviceProviderId'],
                                        )
                                            : s_PInstantBookingDetail(
                                          bookingId: bookingId,
                                          postId: data['postId'],
                                          providerId: data['serviceProviderId'],
                                        ),
                                      ),
                                    );
                                  }
                                  else {
                                    // TODO: Navigate to promotion booking detail
                                  }
                                },
                                // child: Card(
                                //   margin: const EdgeInsets.symmetric(vertical: 10),
                                //   elevation: 3,
                                //   child: Stack(
                                //     children: [
                                //       Padding(
                                //         padding: const EdgeInsets.all(16),
                                //         child: Column(
                                //           crossAxisAlignment: CrossAxisAlignment.start,
                                //           children: [
                                //
                                //             Container(
                                //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                //               decoration: BoxDecoration(
                                //                 color: getStatusColor(data),
                                //                 borderRadius: BorderRadius.circular(8),
                                //               ),
                                //               child: Text(
                                //                 getStatusLabel(data),
                                //                 style: const TextStyle(
                                //                   color: Colors.white,
                                //                   fontWeight: FontWeight.w500,
                                //                   fontSize: 14,
                                //                 ),
                                //               ),
                                //             ),
                                //
                                //             const SizedBox(height: 5),
                                //             Text("Service Title: ${doc['IPTitle']}", style: TextStyle(fontSize: 12)),
                                //             Text("Booking ID: $bookingId", style: TextStyle(fontSize: 12)),
                                //             Text("Status: ${data['status']}", style: TextStyle(color: Colors.red, fontSize: 12)),
                                //             Text("Service Category: ${data['serviceCategory']}", style: TextStyle(fontSize: 12)),
                                //             Text("Price: RM ${data['price']}", style: TextStyle(fontSize: 12)),
                                //             Text("Location: ${data['location']}", style: TextStyle(fontSize: 12)),
                                //
                                //             if (data['isRescheduling'] == true && data['rescheduleSent'] == false) ...[
                                //               Text("Final Schedule (Rescheduled): ${data['finalDate']}, ${data['finalTime']}",
                                //                   style: TextStyle(fontSize: 12)),
                                //               Text(
                                //                 "❌ Previous schedule rejected. Please contact the provider via WhatsApp to reschedule or wait for a new suggestion.",
                                //                 style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500, fontSize: 12),
                                //               ),
                                //             ] else if (data['isRescheduling'] == true && data['rescheduleSent'] == true) ...[
                                //               Text("Final Schedule (Rescheduled): ${data['finalDate']}, ${data['finalTime']}",
                                //                   style: TextStyle(fontSize: 12)),
                                //               Text(
                                //                 "⚠ The provider has suggested a new schedule. Please review it and confirm or reject accordingly.",
                                //                 style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 12),
                                //               ),
                                //             ] else if (isActive || data['status'] == "Completed") ...[
                                //               Text("Final Schedule: ${data['finalDate']}, ${data['finalTime']}", style: TextStyle(fontSize: 12)),
                                //             ] else if (data['status'] == 'Cancelled') ...[
                                //               Text("Cancelled At: ${formatTimestamp(data['cancelledAt'])}", style: TextStyle(fontSize: 12)),
                                //             ] else ...[
                                //               Text("Preferred Schedule: ${data['preferredDate']}, ${data['preferredTime']}", style: TextStyle(fontSize: 12)),
                                //               if (data["alternativeDate"] != null && data["alternativeTime"] != null) ...[
                                //                 Text("Alternative Schedule: ${data['alternativeDate']}, ${data['alternativeTime']}", style: TextStyle(fontSize: 12)),
                                //               ],
                                //             ],
                                //
                                //             if (data['status'] == 'Completed' && data['completedAt'] != null)
                                //               Text("Completed At: ${formatTimestamp(data['completedAt'])}", style: TextStyle(fontSize: 12)),
                                //
                                //             const SizedBox(width: 10),
                                //             Text(
                                //               "Type: ${isInstantBooking ? "Instant Booking" : "Promotion"}",
                                //               style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                //             ),
                                //
                                //
                                //             if (data['pCompleted'] == true && data['status'] == "Active") ...[
                                //               Row(
                                //                 crossAxisAlignment: CrossAxisAlignment.center,
                                //                 children: [
                                //                   Icon(Icons.sticky_note_2_outlined, color: Colors.green, size: 18),
                                //                   const SizedBox(width: 6),
                                //                   Expanded(
                                //                     child: Text(
                                //                       "You may tap on the card to view the service evidence photos before click on “Service Received”.",
                                //                       style: TextStyle(
                                //                         color: Colors.green,
                                //                         fontSize: 12,
                                //                         fontWeight: FontWeight.w500,
                                //                       ),
                                //                     ),
                                //                   ),
                                //                 ],
                                //               ),
                                //               Row(
                                //                 mainAxisAlignment: MainAxisAlignment.end,
                                //                 children: [
                                //                   // ElevatedButton(
                                //                   //   onPressed: () async {
                                //                   //     final email = "fixmate1168@gmail.com";
                                //                   //     final subject = Uri.encodeComponent("Issue with Service: $bookingId");
                                //                   //     final body = Uri.encodeComponent("Hello FixMate,\n\nI have an issue regarding my booking (ID: $bookingId). Please assist.");
                                //                   //     final emailUrl = "mailto:$email?subject=$subject&body=$body";
                                //                   //
                                //                   //     if (await canLaunch(emailUrl)) {
                                //                   //       await launch(emailUrl);
                                //                   //     } else {
                                //                   //       ScaffoldMessenger.of(context).showSnackBar(
                                //                   //         SnackBar(content: Text("Could not open the email client.")),
                                //                   //       );
                                //                   //     }
                                //                   //   },
                                //                   //   child: Text("Report Issue"),
                                //                   //   style: ElevatedButton.styleFrom(
                                //                   //     backgroundColor: Colors.redAccent,
                                //                   //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                //                   //   ),
                                //                   // ),
                                //
                                //                   ElevatedButton(
                                //                     onPressed: () async {
                                //                       final docRef = FirebaseFirestore.instance.collection('bookings').doc(doc.id);
                                //
                                //                       // Mark seeker complete
                                //                       await docRef.update({'sCompleted': true});
                                //
                                //                       // 🔁 Re-fetch latest data from Firestore
                                //                       final updatedDoc = await docRef.get();
                                //                       final updatedData = updatedDoc.data();
                                //
                                //                       if (updatedData?['pCompleted'] == true) {
                                //                         await docRef.update({
                                //                           'status': 'Completed',
                                //                           'completedAt': FieldValue.serverTimestamp(),
                                //                         });
                                //
                                //                         ReusableSnackBar(
                                //                           context,
                                //                           "Booking marked as completed!",
                                //                           icon: Icons.check_circle,
                                //                           iconColor: Colors.green,
                                //                         );
                                //
                                //                         // ✅ Delay before navigating
                                //                         await Future.delayed(const Duration(milliseconds: 400));
                                //
                                //                         // ✅ Switch tab without pushing a new screen
                                //                         // ✅ FULL redirect that resets state properly
                                //                         Navigator.push(
                                //                           context,
                                //                           MaterialPageRoute(
                                //                             builder: (_) => s_BookingHistory(initialTabIndex: 2),
                                //                           ),
                                //                         );
                                //                       }
                                //                     },
                                //
                                //                     child: Text("Service Received"),
                                //                     style: ElevatedButton.styleFrom(
                                //                       backgroundColor: Colors.green,
                                //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                //                     ),
                                //                   ),
                                //                 ],
                                //               ),
                                //             ],
                                //
                                //             if (data['status'] == 'Completed') ...[
                                //               const SizedBox(height: 12),
                                //               Row(
                                //                 mainAxisAlignment: MainAxisAlignment.end,
                                //                 children: [
                                //                   ElevatedButton(
                                //                     onPressed: () {
                                //                       // TODO: Navigate to rating screen
                                //                     },
                                //                     style: ElevatedButton.styleFrom(
                                //                       backgroundColor: const Color(0xFFfb9798),
                                //                       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                                //                       shape: RoundedRectangleBorder(
                                //                         borderRadius: BorderRadius.circular(30),
                                //                       ),
                                //                       elevation: 4,
                                //                     ),
                                //                     child: const Text(
                                //                       "Rate",
                                //                       style: TextStyle(
                                //                         fontSize: 14, // 👈 made slightly larger
                                //                         fontWeight: FontWeight.w700,
                                //                         color: Colors.white,
                                //                       ),
                                //                     ),
                                //                   ),
                                //                 ],
                                //               ),
                                //             ],
                                //
                                //
                                //           ],
                                //         ),
                                //       ),
                                //       if (hasUnread)
                                //         Positioned(
                                //           top: 8,
                                //           right: 8,
                                //           child: Container(
                                //             width: 10,
                                //             height: 10,
                                //             decoration: const BoxDecoration(
                                //               color: Colors.red,
                                //               shape: BoxShape.circle,
                                //             ),
                                //           ),
                                //         ),
                                //     ],
                                //   ),
                                // ),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  elevation: 3,
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          FutureBuilder<List<String>>(
                                            future: fetchPostImages(
                                                data['postId']),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const SizedBox(
                                                  height: 160,
                                                  child: Center(
                                                      child: CircularProgressIndicator()),
                                                );
                                              }

                                              final imageUrls = snapshot.data ??
                                                  [];

                                              if (imageUrls.isEmpty) {
                                                return const SizedBox(); // No image
                                              }

                                              return ClipRRect(
                                                borderRadius: const BorderRadius
                                                    .vertical(
                                                    top: Radius.circular(15)),
                                                child: Image.network(
                                                  imageUrls.first,
                                                  height: 160,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return const Center(
                                                        child: CircularProgressIndicator());
                                                  },
                                                  errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Center(child: Icon(
                                                      Icons.broken_image)),
                                                ),
                                              );
                                            },
                                          ),


                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize
                                                      .min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: getStatusColor(
                                                            data),
                                                        borderRadius: BorderRadius
                                                            .circular(8),
                                                      ),
                                                      child: Text(
                                                        getStatusLabel(data),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight
                                                              .w500,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    if (hasUnread) ...[
                                                      const SizedBox(width: 6),
                                                      const CircleAvatar(
                                                        radius: 5,
                                                        backgroundColor: Colors
                                                            .red,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                    "Service Title: ${doc['IPTitle']}",
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                                Text("Booking ID: $bookingId",
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                                // Text("Status: ${data['status']}", style: const TextStyle(color: Colors.red, fontSize: 14)),
                                                Text(
                                                    "Service Category: ${data['serviceCategory']}",
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                                Text(
                                                    "Price: RM ${data['price']}",
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                                // Text("Location: ${data['location']}", style: const TextStyle(fontSize: 14)),

                                                if (data['isRescheduling'] ==
                                                    true &&
                                                    data['rescheduleSent'] ==
                                                        false) ...[
                                                  Text(
                                                      "Final Schedule (Rescheduled): ${data['finalDate']}, ${data['finalTime']}",
                                                      style: const TextStyle(
                                                          fontSize: 14)),
                                                  Text(
                                                    "❌ Previous schedule rejected. Please contact the provider via WhatsApp to reschedule or wait for a new suggestion.",
                                                    style: const TextStyle(
                                                        color: Colors.redAccent,
                                                        fontWeight: FontWeight
                                                            .w500,
                                                        fontSize: 14),
                                                  ),
                                                ] else
                                                  if (data['isRescheduling'] ==
                                                      true &&
                                                      data['rescheduleSent'] ==
                                                          true) ...[
                                                    Text(
                                                        "Final Schedule (Rescheduled): ${data['finalDate']}, ${data['finalTime']}",
                                                        style: const TextStyle(
                                                            fontSize: 14)),
                                                    Text(
                                                      "⚠ The provider has suggested a new schedule. Please review it and confirm or reject accordingly.",
                                                      style: const TextStyle(
                                                          color: Colors.orange,
                                                          fontWeight: FontWeight
                                                              .w500,
                                                          fontSize: 14),
                                                    ),
                                                  ] else
                                                    if (isActive ||
                                                        data['status'] ==
                                                            "Completed") ...[
                                                      Text(
                                                          "Final Schedule: ${data['finalDate']}, ${data['finalTime']}",
                                                          style: const TextStyle(
                                                              fontSize: 14)),
                                                    ] else
                                                      if (data['status'] ==
                                                          'Cancelled') ...[
                                                        Text(
                                                            "Cancelled At: ${formatTimestamp(
                                                                data['cancelledAt'])}",
                                                            style: const TextStyle(
                                                                fontSize: 14)),
                                                      ] else
                                                        ...[
                                                          Text(
                                                              "Preferred Schedule: ${data['preferredDate']}, ${data['preferredTime']}",
                                                              style: const TextStyle(
                                                                  fontSize: 14)),
                                                          if (data["alternativeDate"] !=
                                                              null &&
                                                              data["alternativeTime"] !=
                                                                  null) ...[
                                                            Text(
                                                                "Alternative Schedule: ${data['alternativeDate']}, ${data['alternativeTime']}",
                                                                style: const TextStyle(
                                                                    fontSize: 14)),
                                                          ],
                                                        ],


                                                if (data['status'] ==
                                                    'Completed' &&
                                                    data['completedAt'] != null)
                                                  Text(
                                                      "Completed At: ${formatTimestamp(
                                                          data['completedAt'])}",
                                                      style: const TextStyle(
                                                          fontSize: 14)),

                                                if (data['autoCompletedBySystem'] ==
                                                    true)
                                                  Text(
                                                    "✅ This service was auto-completed by the system after 7 days.",
                                                    style: TextStyle(
                                                        color: Colors.orange,
                                                        fontStyle: FontStyle
                                                            .italic),
                                                  ),


                                                const SizedBox(width: 10),
                                                Text(
                                                  "Type: ${isInstantBooking
                                                      ? "Instant Booking"
                                                      : "Promotion"}",
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight
                                                          .bold),
                                                ),

                                                if (data['pCompleted'] ==
                                                    true && data['status'] ==
                                                    "Active") ...[
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment
                                                        .center,
                                                    children: [
                                                      const Icon(Icons
                                                          .sticky_note_2_outlined,
                                                          color: Colors.green,
                                                          size: 18),
                                                      const SizedBox(width: 6),
                                                      const Expanded(
                                                        child: Text(
                                                          "Tap to view service evidences and confirm, or wait for system auto-completion.",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .green,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight
                                                                  .w500),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Align(
                                                    alignment: Alignment
                                                        .centerRight,
                                                    child: ElevatedButton(
                                                      // onPressed: () async {
                                                      //   final docRef = FirebaseFirestore.instance.collection('bookings').doc(doc.id);
                                                      //
                                                      //   await docRef.update({'sCompleted': true});
                                                      //
                                                      //   final updatedDoc = await docRef.get();
                                                      //   final updatedData = updatedDoc.data();
                                                      //
                                                      //   if (updatedData?['pCompleted'] == true) {
                                                      //     await docRef.update({
                                                      //       'status': 'Completed',
                                                      //       'completedAt': FieldValue.serverTimestamp(),
                                                      //     });
                                                      //
                                                      //     ReusableSnackBar(
                                                      //       context,
                                                      //       "Booking marked as completed!",
                                                      //       icon: Icons.check_circle,
                                                      //       iconColor: Colors.green,
                                                      //     );
                                                      //
                                                      //     await Future.delayed(const Duration(milliseconds: 400));
                                                      //     Navigator.push(
                                                      //       context,
                                                      //       MaterialPageRoute(
                                                      //         builder: (_) => s_BookingHistory(initialTabIndex: 2),
                                                      //       ),
                                                      //     );
                                                      //   }
                                                      // },
                                                      onPressed: () async {
                                                        final docRef = FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                            'bookings').doc(
                                                            doc.id);

                                                        await docRef.update({''
                                                            'sCompleted': true,
                                                          'updatedAt': FieldValue
                                                              .serverTimestamp(),
                                                        });

                                                        final updatedDoc = await docRef
                                                            .get();
                                                        final updatedData = updatedDoc
                                                            .data();

                                                        if (updatedData?['pCompleted'] ==
                                                            true) {
                                                          await docRef.update({
                                                            'status': 'Completed',
                                                            'completedAt': FieldValue
                                                                .serverTimestamp(),
                                                            'updatedAt': FieldValue
                                                                .serverTimestamp(),
                                                          });

                                                          // ✅ Update the tab and scroll
                                                          setState(() {
                                                            _selectedIndex = 2;
                                                          });

                                                          final buttonWidth = 120.0;
                                                          _tabScrollController
                                                              .animateTo(
                                                            2 * buttonWidth,
                                                            duration: const Duration(
                                                                milliseconds: 400),
                                                            curve: Curves
                                                                .easeOut,
                                                          );

                                                          // ✅ Show snackbar
                                                          WidgetsBinding
                                                              .instance
                                                              .addPostFrameCallback((
                                                              _) {
                                                            ReusableSnackBar(
                                                              context,
                                                              "Booking marked as completed!",
                                                              icon: Icons
                                                                  .check_circle,
                                                              iconColor: Colors
                                                                  .green,
                                                            );
                                                          });
                                                        }
                                                      },


                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor: const Color(
                                                            0xFFfb9798),
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 30,
                                                            vertical: 11),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius
                                                              .circular(30),
                                                        ),
                                                        elevation: 4,
                                                      ),
                                                      child: const Text(
                                                        "Service Received",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight
                                                              .w700,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],


                                                if (data['status'] ==
                                                    'Completed') ...[
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .end,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          // TODO: Navigate to rating screen
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor: const Color(
                                                              0xFFfb9798),
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 30,
                                                              vertical: 11),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius
                                                                .circular(30),
                                                          ),
                                                          elevation: 4,
                                                        ),
                                                        child: const Text(
                                                          "Rate",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight
                                                                .w700,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],


                                                if (data['status'] ==
                                                    'Cancelled') ...[
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .end,
                                                    children: [
                                                      ElevatedButton(
                                                        // onPressed: () {
                                                        //   Navigator.push(
                                                        //     context,
                                                        //     MaterialPageRoute(
                                                        //       builder: (context) => s_InstantPostInfo(
                                                        //         docId: data['postId'], // 🔁 Get postId directly from the booking data
                                                        //       ),
                                                        //     ),
                                                        //   );
                                                        // },
                                                        onPressed: () async {
                                                          final postDoc = await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                              'instant_booking')
                                                              .doc(
                                                              data['postId'])
                                                              .get();

                                                          if (!postDoc.exists ||
                                                              postDoc
                                                                  .data()?['isActive'] !=
                                                                  true) {
                                                            showFloatingMessage(
                                                              context,
                                                              "This item is not available for now.",
                                                              icon: Icons
                                                                  .warning_amber_rounded,
                                                            );
                                                            return;
                                                          }

                                                          // ✅ Post is active → Navigate
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (
                                                                  context) =>
                                                                  s_InstantPostInfo(
                                                                    docId: data['postId'],
                                                                  ),
                                                            ),
                                                          );
                                                        },

                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor: const Color(
                                                              0xFFfb9798),
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 30,
                                                              vertical: 11),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius
                                                                .circular(30),
                                                          ),
                                                          elevation: 4,
                                                        ),
                                                        child: const Text(
                                                          "Bug Again",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight
                                                                .w700,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                            );
                          },
                        );
                      }
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

