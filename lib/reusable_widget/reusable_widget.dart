import 'package:fix_mate/home_page/home_page.dart';
import 'package:flutter/material.dart';

// TextField for the login/registration page
Widget reusableTextField(String text, IconData icon, bool isPasswordType,
    TextEditingController controller) {
  FocusNode focusNode = FocusNode();

  return SizedBox(
    width: 340, // Set smaller width
    child: AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              if (focusNode.hasFocus)
                BoxShadow(
                  color: Color(0xFFD19C86).withOpacity(0.5), // Glowing effect when focused
                  blurRadius: 14,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPasswordType,
            enableSuggestions: !isPasswordType,
            autocorrect: !isPasswordType,
            cursorColor: Colors.brown,
            style: TextStyle(
              color: Colors.black.withOpacity(0.9),
              fontSize: 18, // Updated text size
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 15.0), // Adjusted icon padding for spacing
                child: Icon(
                  icon,
                  color: Color(0xFF4C3532), // Updated icon color
                  size: 26, // Updated icon size
                ),
              ),
              labelText: text,
              labelStyle: TextStyle(color: Colors.grey.withOpacity(0.9)),
              filled: true,
              floatingLabelBehavior: FloatingLabelBehavior.never,
              fillColor: Colors.white, // Change background to white
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(60.0),
                borderSide: BorderSide(color: Color(0xFF4C3532)), // Custom border color
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Color(0xFF4C3532)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            keyboardType: isPasswordType
                ? TextInputType.visiblePassword
                : TextInputType.emailAddress,
          ),
        );
      },
    ),
  );
}

// Button for the Service Provider
Container dk_button(BuildContext context, String title, Function onTap) {
  return Container(
    width: 340,
    height: 60,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
      onPressed: () {
        onTap();
      },
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF464E65), // Fixed button color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Rounded corners
        ),
      ),
    ),
  );
}


// Button for Service Provider (change colour)
// Container dk_button(BuildContext context, String title, Function onTap) {
//   return Container(
//     width: 340,
//     height: 60,
//     margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
//     decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
//     child: ElevatedButton(
//       onPressed: () {
//         onTap();
//       },
//       child: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 20,
//         ),
//       ),
//       style: ButtonStyle(
//         // Update the background color more responsively
//         overlayColor: MaterialStateProperty.all(Color(0xFFfb9798)), // Touch, Hover, Focus
//         backgroundColor: MaterialStateProperty.all(Color(0xFF464E65)), // Default color
//         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//         ),
//       ),
//     ),
//   );
// }
// Button for the Service Seeker
Container pk_button(BuildContext context, String title, Function onTap) {
  return Container(
    width: 340,
    height: 60,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
      onPressed: () {
        onTap();
      },
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFfb9798), // Fixed color (no change)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),
  );
}


Container a_button(BuildContext context, String title, Function onTap) {
  return Container(
    width: 340,
    height: 60,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
      onPressed: () {
        onTap();
      },
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4C3532), // Fixed color (no change)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),
  );
}

// // Button for the Service Seeker (change colour)
// Container pk_button(BuildContext context, String title, Function onTap) {
//   return Container(
//     width: 340,
//     height: 60,
//     margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
//     decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
//     child: ElevatedButton(
//       onPressed: () {
//         onTap();
//       },
//       child: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 20,
//         ),
//       ),
//       style: ButtonStyle(
//         // Update the background color more responsively
//         overlayColor: MaterialStateProperty.all(Color(0xFF464E65)), // Touch, Hover, Focus
//         backgroundColor: MaterialStateProperty.all(Color(0xFFfb9798)), // Default color
//         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//         ),
//       ),
//     ),
//   );
// }

// Validation Message UI
void showValidationMessage(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        elevation: 10, // Subtle shadow for depth
        backgroundColor: Colors.white, // Background color
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline, // Error icon
                color: Color(0xFFfb9798), // Icon color
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                'Validation Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 15),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFfb9798), // Custom button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded button
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Button text color
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


// Forget Password Function
Widget forgetPassword(BuildContext context, Color textColor) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 35,
    // alignment: Alignment.bottomRight,
    alignment: Alignment.centerRight, // Changed to centerRight for slight left
    padding: const EdgeInsets.only(right: 20), // Add left padding to shift lef
    child: TextButton(
      child: Text(
        "Forgot Password?",
        style: TextStyle(
          color: textColor, // Accepting color dynamically
          fontWeight: FontWeight.w900, // Increase font weight
          fontSize: 16,
        ),
        textAlign: TextAlign.right,
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => home_page()),
      ),
    ),
  );
}

void showSuccessMessage(BuildContext context, String message, {VoidCallback? onPressed}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        elevation: 10, // Subtle shadow for depth
        backgroundColor: Colors.white, // Background color
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline, // Success icon
                color: Colors.green, // Green color for success
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 15),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    if (onPressed != null) {
                      onPressed(); // Execute the function passed in onPressed
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Green button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded button
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Button text color
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}






