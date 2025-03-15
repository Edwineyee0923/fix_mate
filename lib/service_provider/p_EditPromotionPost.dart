import 'package:flutter/material.dart';

class p_EditPromotionPost extends StatefulWidget {
  @override
  _p_EditPromotionPostState createState() => _p_EditPromotionPostState();
}

class _p_EditPromotionPostState extends State<p_EditPromotionPost> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: Color(0xFF464E65),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Corrected navigation
          }
        ),
        title: Text(
          "My Profile",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 2,
      ),
      body: SingleChildScrollView(

      ),
    );
  }
}