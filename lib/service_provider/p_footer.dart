// import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
// import 'package:fix_mate/service_provider/p_HomePage.dart';
// import 'package:fix_mate/service_provider/p_Rating.dart';
// import 'package:fix_mate/service_provider/p_profile.dart';
// import 'package:flutter/material.dart';
//
//
//
//
// class p_footer extends StatelessWidget {
//   final int selectedIndex;
//
//   const p_footer({Key? key, required this.selectedIndex}) : super(key: key);
//
//   void _onItemTapped(BuildContext context, int index) {
//     if (index == selectedIndex) return;
//
//     String route = '';
//     switch (index) {
//       case 0:
//         route = p_HomePage.routeName;
//         break;
//       case 1:
//         route = p_BookingHistory.routeName;
//         break;
//       case 2:
//         route = p_Rating.routeName;
//         break;
//       case 3:
//         route = p_profile.routeName;
//         break;
//     }
//
//     Navigator.pushReplacement(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) =>
//             _getScreen(index),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           return FadeTransition(opacity: animation, child: child);
//         },
//       ),
//     );
//   }
//
//   Widget _getScreen(int index) {
//     switch (index) {
//       case 0:
//         return p_HomePage();
//       case 1:
//         return p_BookingHistory();
//       case 2:
//         return p_Rating();
//       case 3:
//         return p_profile();
//       default:
//         return p_HomePage();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       type: BottomNavigationBarType.fixed,
//       showSelectedLabels: true,
//       showUnselectedLabels: true,
//       items: const [
//         BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: 'Home'),
//         BottomNavigationBarItem(icon: Icon(Icons.history, size: 30), label: 'Booking History'),
//         BottomNavigationBarItem(icon: Icon(Icons.stars, size: 30), label: 'My Reviews'),
//         BottomNavigationBarItem(icon: Icon(Icons.person, size: 30), label: 'Profile'),
//       ],
//       currentIndex: selectedIndex,
//       selectedItemColor: Color(0xFF464E65),
//       unselectedItemColor: Colors.grey,
//       backgroundColor: Colors.white,
//       elevation: 10,
//       onTap: (index) => _onItemTapped(context, index),
//     );
//   }
// }


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
// import 'package:fix_mate/service_provider/p_HomePage.dart';
// import 'package:fix_mate/service_provider/p_Rating.dart';
// import 'package:fix_mate/service_provider/p_profile.dart';
// import 'package:flutter/material.dart';
//
// class p_footer extends StatefulWidget {
//   final int selectedIndex;
//
//   const p_footer({Key? key, required this.selectedIndex}) : super(key: key);
//
//   @override
//   _p_footerState createState() => _p_footerState();
// }
//
// class _p_footerState extends State<p_footer> {
//   bool showNotificationDot = false;
//
//   @override
//   void initState() {
//     super.initState();
//     checkUnreadNotifications();
//   }
//
//   void checkUnreadNotifications() async {
//     final providerId = FirebaseAuth.instance.currentUser?.uid;
//     if (providerId == null) return;
//
//     final snapshot = await FirebaseFirestore.instance
//         .collection('p_notifications')
//         .where('providerId', isEqualTo: providerId)
//         .where('isRead', isEqualTo: false)
//         .get();
//
//     if (mounted) {
//       setState(() {
//         showNotificationDot = snapshot.docs.isNotEmpty;
//       });
//     }
//   }
//
//   Future<bool> hasUnreadBookingNotifications(String providerId) async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('p_notifications')
//         .where('providerId', isEqualTo: providerId)
//         .where('isRead', isEqualTo: false)
//         .limit(1)
//         .get();
//
//     return snapshot.docs.isNotEmpty;
//   }
//
//   void _onItemTapped(BuildContext context, int index) {
//     if (index == widget.selectedIndex) return;
//
//     Widget screen;
//     switch (index) {
//       case 0:
//         screen = p_HomePage();
//         break;
//       case 1:
//         screen = p_BookingHistory();
//         break;
//       case 2:
//         screen = p_Rating();
//         break;
//       case 3:
//         screen = p_profile();
//         break;
//       default:
//         screen = p_HomePage();
//     }
//
//     Navigator.pushReplacement(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => screen,
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           return FadeTransition(opacity: animation, child: child);
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       type: BottomNavigationBarType.fixed,
//       showSelectedLabels: true,
//       showUnselectedLabels: true,
//       items: [
//         const BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: 'Home'),
//         BottomNavigationBarItem(
//           icon: Stack(
//             children: [
//               const Icon(Icons.history, size: 30),
//               if (showNotificationDot)
//                 Positioned(
//                   right: 0,
//                   top: 0,
//                   child: Container(
//                     width: 10,
//                     height: 10,
//                     decoration: const BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           label: 'Booking History',
//         ),
//         const BottomNavigationBarItem(icon: Icon(Icons.stars, size: 30), label: 'My Reviews'),
//         const BottomNavigationBarItem(icon: Icon(Icons.person, size: 30), label: 'Profile'),
//       ],
//       currentIndex: widget.selectedIndex,
//       selectedItemColor: const Color(0xFF464E65),
//       unselectedItemColor: Colors.grey,
//       backgroundColor: Colors.white,
//       elevation: 10,
//       onTap: (index) => _onItemTapped(context, index),
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
import 'package:fix_mate/service_provider/p_HomePage.dart';
import 'package:fix_mate/service_provider/p_Rating.dart';
import 'package:fix_mate/service_provider/p_profile.dart';
import 'package:flutter/material.dart';

class p_footer extends StatefulWidget {
  final int selectedIndex;

  const p_footer({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  _p_footerState createState() => _p_footerState();
}

class _p_footerState extends State<p_footer> {
  void _onItemTapped(BuildContext context, int index) {
    if (index == widget.selectedIndex) return;

    Widget screen;
    switch (index) {
      case 0:
        screen = p_HomePage();
        break;
      case 1:
        screen = p_BookingHistory();
        break;
      case 2:
        screen = p_Rating();
        break;
      case 3:
        screen = p_profile();
        break;
      default:
        screen = p_HomePage();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 30),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('p_notifications')
                .where('providerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return Stack(
                children: [
                  const Icon(Icons.history, size: 30),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: 'Booking History',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.stars, size: 30),
          label: 'My Reviews',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person, size: 30),
          label: 'Profile',
        ),
      ],
      currentIndex: widget.selectedIndex,
      selectedItemColor: const Color(0xFF464E65),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 10,
      onTap: (index) => _onItemTapped(context, index),
    );
  }
}
