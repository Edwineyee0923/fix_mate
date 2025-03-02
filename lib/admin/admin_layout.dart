import 'package:flutter/material.dart';
import 'package:fix_mate/admin/admin_footer.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex; // Add selectedIndex parameter

  const AdminLayout({Key? key, required this.child, required this.selectedIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          admin_footer(selectedIndex: selectedIndex),
        ],
      ),
    );
  }
}
