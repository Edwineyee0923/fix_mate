import 'package:flutter/material.dart';
import 'package:fix_mate/admin/SP_application.dart';
import 'package:fix_mate/admin/U_inquiries.dart';
import 'package:fix_mate/admin/contact_developer.dart';

class admin_footer extends StatelessWidget {
  final int selectedIndex;

  const admin_footer({Key? key, required this.selectedIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    String route = '';
    switch (index) {
      case 0:
        route = SP_application.routeName;
        break;
      case 1:
        route = U_inquiries.routeName;
        break;
      case 2:
        route = contact_developer.routeName;
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
        return SP_application();
      case 1:
        return U_inquiries();
      case 2:
        return contact_developer();
      default:
        return SP_application();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard, size: 30), label: 'Application'),
        BottomNavigationBarItem(icon: Icon(Icons.mail, size: 30), label: 'Inquiries'),
        BottomNavigationBarItem(icon: Icon(Icons.phone, size: 30), label: 'Dev Contact'),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Color(0xFFFF9342),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 10,
      onTap: (index) => _onItemTapped(context, index),
    );
  }
}