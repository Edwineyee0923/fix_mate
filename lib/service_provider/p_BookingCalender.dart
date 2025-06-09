// import 'package:fix_mate/service_provider/p_BookingModule/p_ABookingDetail.dart';
// import 'package:fix_mate/service_provider/p_BookingModule/p_CCBookingDetail.dart';
// import 'package:fix_mate/service_provider/p_BookingModule/p_CBookingDetail.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
//
// class p_BookingCalender extends StatefulWidget {
//   final String? highlightedBookingId;
//   const p_BookingCalender({Key? key, this.highlightedBookingId}) : super(key: key);
//
//
//   @override
//   State<p_BookingCalender> createState() => _p_BookingCalenderState();
// }
//
// class _p_BookingCalenderState extends State<p_BookingCalender> {
//   late Map<DateTime, List<Map<String, dynamic>>> _events;
//   DateTime _selectedDay = DateTime.now();
//   DateTime _focusedDay = DateTime.now();
//
//   @override
//   void initState() {
//     super.initState();
//     _events = {};
//     _loadEvents();
//   }
//
//   Future<void> _loadEvents() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     final snapshot = await FirebaseFirestore.instance
//         .collection('bookings')
//         .where('serviceProviderId', isEqualTo: uid)
//         .where('status', whereIn: ['Active', 'Completed'])
//         .get();
//
//     Map<DateTime, List<Map<String, dynamic>>> bookingsByDay = {};
//
//     for (var doc in snapshot.docs) {
//       final data = doc.data();
//       final dateStr = data['finalDate'];
//       final timeStr = data['finalTime'];
//
//       if (dateStr == null || timeStr == null) continue;
//
//       final date = DateFormat("d MMM yyyy").parse(dateStr);
//
//       // fetch title from instant_booking
//       String title = 'Service';
//       if (data['postId'] != null) {
//         final postDoc = await FirebaseFirestore.instance
//             .collection('instant_booking')
//             .doc(data['postId'])
//             .get();
//         title = postDoc.data()?['IPTitle'] ?? 'Service';
//       }
//
//       final booking = {
//         'title': title,
//         'time': timeStr,
//         'location': data['location'] ?? '',
//         'bookingId': data['bookingId'],
//         'postId': data['postId'],
//         'seekerId': data['serviceSeekerId'],
//         'status': data['status'],
//       };
//
//       final normalizedDate = DateTime(date.year, date.month, date.day);
//       bookingsByDay.putIfAbsent(normalizedDate, () => []).add(booking);
//     }
//
//     setState(() {
//       _events = bookingsByDay;
//     });
//   }
//
//   List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
//     final normalized = DateTime(day.year, day.month, day.day);
//     return _events[normalized] ?? [];
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFFFFFF2),
//       appBar: AppBar(
//         backgroundColor: Color(0xFF464E65),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           "My Booking Calendar",
//           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         titleSpacing: 2,
//       ),
//
//       body: Column(
//         children: [
//           TableCalendar(
//             focusedDay: _focusedDay,
//             firstDay: DateTime.utc(2020, 1, 1),
//             lastDay: DateTime.utc(2030, 12, 31),
//             selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
//             eventLoader: _getEventsForDay,
//             onDaySelected: (selected, focused) {
//               setState(() {
//                 _selectedDay = selected;
//                 _focusedDay = focused;
//               });
//             },
//             calendarStyle: const CalendarStyle(
//               todayDecoration: BoxDecoration(
//                 color: Color(0xFF6D768F),
//                 shape: BoxShape.circle,
//               ),
//               selectedDecoration: BoxDecoration(
//                 color: Color(0xFF464E65),
//                 shape: BoxShape.circle,
//               ),
//               markerDecoration: BoxDecoration(
//                 color: Color(0xFF464E65),
//                 shape: BoxShape.circle,
//               ),
//             ),
//             headerStyle: const HeaderStyle(
//               formatButtonVisible: false,
//               titleCentered: true,
//               titleTextStyle: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Expanded(
//             child: _getEventsForDay(_selectedDay).isEmpty
//                 ? const Center(
//               child: Text(
//                 "No bookings on this day.",
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//             )
//                 : ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: _getEventsForDay(_selectedDay).length,
//               itemBuilder: (context, index) {
//                 final event = _getEventsForDay(_selectedDay)[index];
//                 return GestureDetector(
//                   onTap: () {
//                     final status = event['status'];
//                     final bookingId = event['bookingId'];
//                     final postId = event['postId'];
//                     final seekerId = event['seekerId'];
//
//                     if (status == 'Completed') {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => p_CBookingDetail(
//                             bookingId: bookingId,
//                             postId: postId,
//                             seekerId: seekerId,
//                           ),
//                         ),
//                       );
//                     } else if (status == 'Active') {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => p_ABookingDetail(
//                             bookingId: bookingId,
//                             postId: postId,
//                             seekerId: seekerId,
//                           ),
//                         ),
//                       );
//                     }
//                   },
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 300),
//                     curve: Curves.easeInOut,
//                     margin: const EdgeInsets.only(bottom: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.04),
//                           blurRadius: 12,
//                           offset: const Offset(0, 6),
//                         ),
//                       ],
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF464E65),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             padding: const EdgeInsets.all(12),
//                             child: const Icon(Icons.event, color: Colors.white, size: 20),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   event['title'],
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Color(0xFF1D1D1D),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 6),
//                                 Row(
//                                   children: [
//                                     const Icon(Icons.access_time, size: 14, color: Colors.grey),
//                                     const SizedBox(width: 4),
//                                     Text(event['time'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Icon(Icons.location_on, size: 14, color: Colors.grey),
//                                     const SizedBox(width: 4),
//                                     Expanded(
//                                       child: Text(
//                                         event['location'],
//                                         style: const TextStyle(fontSize: 13, color: Colors.black87),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Text(
//                                 event['bookingId'],
//                                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
//                               ),
//                               const SizedBox(height: 8),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                                 decoration: BoxDecoration(
//                                   color: event['status'] == 'Completed'
//                                       ? Colors.green.shade50
//                                       : Colors.blue.shade50,
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                                 child: Text(
//                                   event['status'],
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.bold,
//                                     color: event['status'] == 'Completed'
//                                         ? Colors.green.shade800
//                                         : Colors.blue.shade800,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           )
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//
//
//               },
//             ),
//           )
//         ],
//       ),
//       // backgroundColor: const Color(0xFFF5F6FA),
//     );
//   }
//   Color getEventColor(String bookingId) {
//     if (bookingId == widget.highlightedBookingId) {
//       return Colors.orangeAccent; // 🔶 Highlight color
//     }
//     return const Color(0xFF464E65); // Default card icon color
//   }
//
// }




import 'package:fix_mate/service_provider/p_BookingModule/p_ABookingDetail.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_CCBookingDetail.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_CBookingDetail.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class p_BookingCalender extends StatefulWidget {
  final String? highlightedBookingId;
  const p_BookingCalender({Key? key, this.highlightedBookingId}) : super(key: key);

  @override
  State<p_BookingCalender> createState() => _p_BookingCalenderState();
}

class _p_BookingCalenderState extends State<p_BookingCalender>
    with SingleTickerProviderStateMixin {
  late Map<DateTime, List<Map<String, dynamic>>> _events;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Blinking animation for highlighted card
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _events = {};

    // Blinking animation - more obvious than breathing
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800), // Each blink cycle
      vsync: this,
    );

    _blinkAnimation = Tween<double>(
      begin: 0.2, // Very dim
      end: 1.0,   // Full brightness
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));

    _loadEvents();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: uid)
        .where('status', whereIn: ['Active', 'Completed'])
        .get();

    Map<DateTime, List<Map<String, dynamic>>> bookingsByDay = {};
    DateTime? highlightedBookingDate;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateStr = data['finalDate'];
      final timeStr = data['finalTime'];

      if (dateStr == null || timeStr == null) continue;

      final date = DateFormat("d MMM yyyy").parse(dateStr);

      // Check if this is the highlighted booking
      if (data['bookingId'] == widget.highlightedBookingId) {
        highlightedBookingDate = DateTime(date.year, date.month, date.day);
      }

      String title = 'Service';
      if (data['postId'] != null) {
        final postDoc = await FirebaseFirestore.instance
            .collection('instant_booking')
            .doc(data['postId'])
            .get();
        title = postDoc.data()?['IPTitle'] ?? 'Service';
      }

      final booking = {
        'title': title,
        'time': timeStr,
        'location': data['location'] ?? '',
        'bookingId': data['bookingId'],
        'postId': data['postId'],
        'seekerId': data['serviceSeekerId'],
        'status': data['status'],
      };

      final normalizedDate = DateTime(date.year, date.month, date.day);
      bookingsByDay.putIfAbsent(normalizedDate, () => []).add(booking);
    }

    setState(() {
      _events = bookingsByDay;

      // If we have a highlighted booking, select that day and start blinking
      if (highlightedBookingDate != null) {
        _selectedDay = highlightedBookingDate;
        _focusedDay = highlightedBookingDate;

        // Start the blinking animation after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _startBlinkingEffect();
        });
      }
    });
  }

  void _startBlinkingEffect() {
    // Blink 3 times slowly then stop
    int blinkCount = 0;

    void performBlink() {
      if (blinkCount < 3) {
        _blinkController.forward().then((_) {
          _blinkController.reverse().then((_) {
            blinkCount++;
            if (blinkCount < 3) {
              // Small pause between blinks
              Future.delayed(const Duration(milliseconds: 200), performBlink);
            }
          });
        });
      }
    }

    performBlink();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _events[normalized] ?? [];
  }

  Widget _buildHighlightedCard(Map<String, dynamic> event, int index) {
    final isHighlighted = event['bookingId'] == widget.highlightedBookingId;

    if (isHighlighted) {
      return GestureDetector(
        onTap: () {
          final status = event['status'];
          final bookingId = event['bookingId'];
          final postId = event['postId'];
          final seekerId = event['seekerId'];

          if (status == 'Completed') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => p_CBookingDetail(
                  bookingId: bookingId,
                  postId: postId,
                  seekerId: seekerId,
                ),
              ),
            );
          } else if (status == 'Active') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => p_ABookingDetail(
                  bookingId: bookingId,
                  postId: postId,
                  seekerId: seekerId,
                ),
              ),
            );
          }
        },
        child: AnimatedBuilder(
          animation: _blinkAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(0xFF464E65).withOpacity(_blinkAnimation.value),
                  width: 3, // Slightly thicker border for more visibility
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF464E65).withOpacity(_blinkAnimation.value * 0.5), // More intense shadow
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _buildCardContent(event, isClickable: false),
            );
          },
        ),
      );
    } else {
      // Regular card without highlight
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _buildCardContent(event),
      );
    }
  }

  Widget _buildCardContent(Map<String, dynamic> event, {bool isClickable = true}) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: getEventColor(event['bookingId']),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.event, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1D),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(event['time'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event['location'],
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                event['bookingId'],
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: event['status'] == 'Completed'
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event['status'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: event['status'] == 'Completed'
                        ? Colors.green.shade800
                        : Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );

    if (!isClickable) {
      return content;
    }

    return GestureDetector(
      onTap: () {
        final status = event['status'];
        final bookingId = event['bookingId'];
        final postId = event['postId'];
        final seekerId = event['seekerId'];

        if (status == 'Completed') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => p_CBookingDetail(
                bookingId: bookingId,
                postId: postId,
                seekerId: seekerId,
              ),
            ),
          );
        } else if (status == 'Active') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => p_ABookingDetail(
                bookingId: bookingId,
                postId: postId,
                seekerId: seekerId,
              ),
            ),
          );
        }
      },
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: Color(0xFF464E65),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Booking Calendar",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 2,
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: _getEventsForDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFF6D768F),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF464E65),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Color(0xFF464E65),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _getEventsForDay(_selectedDay).isEmpty
                ? const Center(
              child: Text(
                "No bookings on this day.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _getEventsForDay(_selectedDay).length,
              itemBuilder: (context, index) {
                final event = _getEventsForDay(_selectedDay)[index];
                return _buildHighlightedCard(event, index);
              },
            ),
          )
        ],
      ),
    );
  }

  Color getEventColor(String bookingId) {
    if (bookingId == widget.highlightedBookingId) {
      return  Color(0xFF464E65); // Highlighted booking color
    }
    return const Color(0xFF464E65); // Default card icon color
  }
}