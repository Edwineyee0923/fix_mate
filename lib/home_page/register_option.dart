import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class register_option extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E8), // Background color
      body: Align(
        alignment: Alignment.topCenter, // Align content to the top
        child: FractionallySizedBox(
          heightFactor: 0.8, // Adjust this value to move it up/down
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You want to ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'REGISTER ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'as...',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40), // Adjust for spacing

              // Service Seeker Button
              big_button(
                context: context,
                title: "Service Seeker",
                onTap: () {
                  print("Service Seeker Clicked!");
                },
                leftIcon: Icons.person_outline, // User icon (Left)
                color: Color(0xFFfb9798), // Pink color
              ),

              SizedBox(height: 10), // Space between buttons
              // Service Provider Button
              big_button(
                context: context,
                title: "Service Provider",
                onTap: () {
                  print("Service Provider Clicked!");
                },
                rightIcon: Icons.handyman, // Handyman icon (Right)
                color: Color(0xFF464E65), // Dark navy color
              ),
            ],
          ),
        ),
      ),
    );
  }
}
