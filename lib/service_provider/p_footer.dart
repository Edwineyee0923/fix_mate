import 'package:fix_mate/service_provider/p_Account.dart';
import 'package:fix_mate/service_provider/p_BookingHistory.dart';
import 'package:fix_mate/service_provider/p_HomePage.dart';
import 'package:flutter/material.dart';

class p_footer extends StatelessWidget {
  final int selectedIndex;

  const p_footer({Key? key, required this.selectedIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    String route = '';
    switch (index) {
      case 0:
        route = p_HomePage.routeName;
        break;
      case 1:
        route = p_BookingHistory.routeName;
        break;
      case 2:
        route = p_Account.routeName;
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
        return p_HomePage();
      case 1:
        return p_BookingHistory();
      case 2:
        return p_Account();
      default:
        return p_HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history, size: 30), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person, size: 30), label: 'Account'),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Color(0xFF464E65),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 10,
      onTap: (index) => _onItemTapped(context, index),
    );
  }
}