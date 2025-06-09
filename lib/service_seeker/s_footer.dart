import 'package:fix_mate/service_seeker/s_BookingModule/s_BookingHistory.dart';
import 'package:fix_mate/service_seeker/s_Dashboard.dart';
import 'package:fix_mate/service_seeker/s_Favourite.dart';
import 'package:fix_mate/service_seeker/s_HomePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class s_footer extends StatelessWidget {
  final int selectedIndex;

  const s_footer({Key? key, required this.selectedIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    String route = '';
    switch (index) {
      case 0:
        route = s_HomePage.routeName;
        break;
      case 1:
        route = s_BookingHistory.routeName;
        break;
      case 2:
        route = s_Favourite.routeName;
        break;
      case 3:
        route = s_Dashboard.routeName;
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _getScreen(index),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return s_HomePage();
      case 1:
        return s_BookingHistory();
      case 2:
        return s_Favourite();
      case 3:
        return s_Dashboard();
      default:
        return s_HomePage();
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return BottomNavigationBar(
  //     type: BottomNavigationBarType.fixed,
  //     showSelectedLabels: true,
  //     showUnselectedLabels: true,
  //     items: const [
  //       BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: 'Home'),
  //       BottomNavigationBarItem(icon: Icon(Icons.history, size: 30), label: 'Booking History'),
  //       BottomNavigationBarItem(icon: Icon(Icons.favorite, size: 30), label: 'Favourite'),
  //       BottomNavigationBarItem(
  //         icon: Icon(Icons.dashboard_rounded, size: 30),
  //         label: 'Dashboard',
  //       )
  //     ],
  //     currentIndex: selectedIndex,
  //     selectedItemColor: Color(0xFFfb9798),
  //     unselectedItemColor: Colors.grey,
  //     backgroundColor: Colors.white,
  //     elevation: 10,
  //     onTap: (index) => _onItemTapped(context, index),
  //   );
  // }


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
        // ✅ Booking History with Red Dot
        BottomNavigationBarItem(
          icon: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('s_notifications')
                .where('seekerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
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
          icon: Icon(Icons.favorite, size: 30),
          label: 'Favourite',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded, size: 30),
          label: 'Dashboard',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: const Color(0xFFfb9798),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 10,
      onTap: (index) => _onItemTapped(context, index),
    );
  }
}