import 'package:fix_mate/home_page/home_page.dart';
import 'package:fix_mate/home_page/reset_password.dart';
import 'package:flutter/material.dart';

// TextField for the login page
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
        MaterialPageRoute(builder: (context) => reset_password()),
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

// Reusable Big Button with Icons on Both Sides
Widget big_button({
  required BuildContext context,
  required String title,
  required VoidCallback onTap,
  IconData? leftIcon,  // ✅ Optional left icon
  IconData? rightIcon, // ✅ Optional right icon
  Color color = const Color(0xFFfb9798), // Default color (Pink)
}) {
  return Container(
    width: 300, // Increased width
    height: 100, // Slightly increased height for better UI
    margin: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // Customizable button color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leftIcon != null) ...[ // ✅ Show left icon only if it's provided
          Icon(leftIcon, size: 40, color: Colors.white), // Left-side icon
          SizedBox(width: 10),
    ],// Space between icon & text
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
          if (rightIcon != null) ...[ // ✅ Show right icon only if it's provided
          SizedBox(width: 10), // Space between text & icon
          Icon(rightIcon, size: 35, color: Colors.white), // Right-side icon
  ],
        ],
      ),
    ),
  );
}


class InternalTextField extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final IconData? icon;
  final TextEditingController controller;
  final bool isPassword;
  final String? validationMessage; // Optional validation message
  final Function(String)? onChanged;
  final bool isValid; // Parent-controlled validation state

  const InternalTextField({
    Key? key,
    required this.labelText,
    this.hintText,
    this.icon,
    required this.controller,
    this.isPassword = false,
    this.validationMessage,
    this.onChanged,
    this.isValid = true, // Defaults to true (no validation error)
  }) : super(key: key);

  @override
  _InternalTextFieldState createState() => _InternalTextFieldState();
}

class _InternalTextFieldState extends State<InternalTextField> {
  bool isPasswordVisible = false; // Password visibility toggle
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 340,
          height: 50,
          child: AnimatedBuilder(
            animation: focusNode,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    if (focusNode.hasFocus)
                      BoxShadow(
                        color: const Color(0xFFD19C86).withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: focusNode,
                  obscureText: widget.isPassword ? !isPasswordVisible : false,
                  cursorColor: Colors.brown,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    prefixIcon: widget.icon != null
                        ? Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 5.0),
                      child: Icon(widget.icon, color: Colors.brown.withOpacity(0.8), size: 22),
                    )
                        : null,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: Colors.brown.withOpacity(0.6), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: const BorderSide(color: Color(0xFF4C3532)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: const BorderSide(color: Color(0xFF4C3532), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    suffixIcon: widget.isPassword
                        ? IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.brown.withOpacity(0.8),
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    )
                        : null,
                  ),
                  onChanged: (text) {
                    if (widget.onChanged != null) {
                      widget.onChanged!(text);
                    }
                  },
                ),
              );
            },
          ),
        ),
        if (!widget.isValid && widget.validationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10),
            child: Text(
              widget.validationMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}


class LongInputContainer extends StatefulWidget {
  final String labelText;
  final TextEditingController controller;
  final int? maxWords;
  final double width;
  final double height;
  final String placeholder;
  final bool isRequired;
  final String? requiredMessage;

  const LongInputContainer({
    Key? key,
    required this.labelText,
    required this.controller,
    this.maxWords,
    this.width = 340,
    this.height = 100,
    this.placeholder = "Enter here...",
    this.isRequired = false,
    this.requiredMessage = "This field is required.",
  }) : super(key: key);

  @override
  _LongInputContainerState createState() => _LongInputContainerState();
}

class _LongInputContainerState extends State<LongInputContainer> {
  FocusNode focusNode = FocusNode();
  String errorMessage = "";

  void validateInput(String text) {
    setState(() {
      // Required field validation
      if (widget.isRequired && text.trim().isEmpty) {
        errorMessage = widget.requiredMessage!;
        return;
      }

      // Word limit validation
      if (widget.maxWords != null) {
        int wordCount = text.trim().split(RegExp(r"\s+")).length;
        if (wordCount > widget.maxWords!) {
          errorMessage = "Maximum ${widget.maxWords} words allowed!";
          return;
        }
      }

      // No errors
      errorMessage = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedBuilder(
          animation: focusNode,
          builder: (context, child) {
            return Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.black),
                boxShadow: [
                  if (focusNode.hasFocus)
                    BoxShadow(
                      color: const Color(0xFFD19C86).withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                cursorColor: Colors.brown,
                focusNode: focusNode,
                maxLines: null, // Allows multiline input
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.placeholder, // Custom placeholder
                  hintStyle: TextStyle(color: Colors.brown.withOpacity(0.6), fontSize: 14),
                ),
                onChanged: validateInput,
                onEditingComplete: () => validateInput(widget.controller.text),
              ),
            );
          },
        ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}







