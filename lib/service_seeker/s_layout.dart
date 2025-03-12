import 'package:flutter/material.dart';
import 'package:fix_mate/service_seeker/s_footer.dart';

class SeekerLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex; // Add selectedIndex parameter

  const SeekerLayout({Key? key, required this.child, required this.selectedIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          s_footer(selectedIndex: selectedIndex),
        ],
      ),
    );
  }
}
