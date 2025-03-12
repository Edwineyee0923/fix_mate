import 'package:flutter/material.dart';
import 'package:fix_mate/service_provider/p_footer.dart';

class ProviderLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex; // Add selectedIndex parameter

  const ProviderLayout({Key? key, required this.child, required this.selectedIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          p_footer(selectedIndex: selectedIndex),
        ],
      ),
    );
  }
}
