import 'package:flutter/material.dart';

// Import all admin screens
import 'package:fix_mate/admin/contact_developer.dart';
import 'package:fix_mate/admin/U_inquiries.dart';
import 'package:fix_mate/admin/SP_application.dart';
import 'package:fix_mate/admin/admin_layout.dart'; // Import the layout

final Map<String, WidgetBuilder> routes = {
  SP_application.routeName: (context) => AdminLayout(child: SP_application(), selectedIndex: 0),
  U_inquiries.routeName: (context) => AdminLayout(child: U_inquiries(), selectedIndex: 1),
  contact_developer.routeName: (context) => AdminLayout(child: contact_developer(), selectedIndex: 2),
};

