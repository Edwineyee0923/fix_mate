import 'package:fix_mate/home_page/HomePage.dart';
import 'package:fix_mate/home_page/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        backgroundColor: const Color(0xFFFF9342), // Fixed color (no change)
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
          fontSize: 17,
          decoration: TextDecoration.underline,
          decorationThickness: 1.5,
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
  final String? validationMessage; // For password mismatch or custom validation errors
  final String? errorMessage; // For required field errors
  final String? disabledMessage; // ✅ New: Message for disabled field
  final Function(String)? onChanged;
  final bool isValid; // Parent-controlled validation state
  final bool enabled;

  const InternalTextField({
    Key? key,
    required this.labelText,
    this.hintText,
    this.icon,
    required this.controller,
    this.isPassword = false,
    this.validationMessage,
    this.errorMessage,
    this.disabledMessage, // ✅ Added new parameter
    this.onChanged,
    this.isValid = true, // Defaults to true (no validation error)
    this.enabled = false,
  }) : super(key: key);

  @override
  _InternalTextFieldState createState() => _InternalTextFieldState();
}

class _InternalTextFieldState extends State<InternalTextField> {
  bool isPasswordVisible = false;
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    // Determine which error to show: `errorMessage` takes priority over `validationMessage`
    String? displayError = widget.errorMessage ?? widget.validationMessage;

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
                    color: widget.enabled ? Colors.black.withOpacity(0.9) : Colors.brown.withOpacity(0.6),
                    fontSize: 16,
                  ),
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    prefixIcon: widget.icon != null
                        ? Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 5.0),
                      child: Icon(widget.icon, color: Colors.brown.withOpacity(0.8), size: 22),
                    )
                        : null,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.9), fontSize: 14),
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
                    disabledBorder: OutlineInputBorder(
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
        if (!widget.enabled && widget.disabledMessage != null) // ✅ Show disabled message
          Padding(
            padding: const EdgeInsets.only(left:10),
            child: Text(
              widget.disabledMessage!,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class LongInputContainer extends StatefulWidget {
  final String? labelText; // ✅ Made optional
  final TextEditingController controller;
  final int? maxWords;
  final double width;
  final double height;
  final String placeholder;
  final bool isRequired;
  final String? requiredMessage;
  final bool enabled;
  final bool isUrl;
  final String? errorMessage;
  final ValueChanged<String>? onChanged;

  const LongInputContainer({
    Key? key,
    this.labelText, // ✅ No longer required
    required this.controller,
    this.maxWords,
    this.width = 340,
    this.height = 100,
    this.placeholder = "Enter here...",
    this.isRequired = false,
    this.requiredMessage = "This field is required.",
    this.enabled = true,
    this.isUrl = false,
    this.errorMessage,
    this.onChanged,
  }) : super(key: key);

  @override
  _LongInputContainerState createState() => _LongInputContainerState();
}

class _LongInputContainerState extends State<LongInputContainer> {
  FocusNode focusNode = FocusNode();
  String? internalErrorMessage;

  bool validate() {
    String text = widget.controller.text.trim();
    setState(() {
      if (widget.isRequired && text.isEmpty) {
        internalErrorMessage = widget.requiredMessage!;
        return;
      }

      if (widget.isUrl) {
        final urlRegex = RegExp(r"^(https?:\/\/)?([\w\-]+\.)+[\w-]+(\/[\w\- ./?%&=]*)?$");
        if (!urlRegex.hasMatch(text)) {
          internalErrorMessage = "Enter a valid URL!";
          return;
        }
      }

      if (widget.maxWords != null) {
        int wordCount = text.split(RegExp(r"\s+")).length;
        if (wordCount > widget.maxWords!) {
          internalErrorMessage = "Maximum ${widget.maxWords} words allowed!";
          return;
        }
      }

      internalErrorMessage = widget.errorMessage;
    });

    return internalErrorMessage == null;
  }

  @override
  Widget build(BuildContext context) {
    String? displayError = widget.errorMessage ?? internalErrorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) // ✅ Only show if labelText is provided
          Text(
            widget.labelText!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        if (widget.labelText != null) const SizedBox(height: 5), // ✅ Space only if label exists
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
                      color: const Color(0xFFD19C86).withOpacity(1),
                      blurRadius: 15,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                cursorColor: Colors.brown,
                focusNode: focusNode,
                maxLines: null,
                keyboardType: widget.isUrl ? TextInputType.url : TextInputType.multiline,
                enabled: widget.enabled,
                style: TextStyle(
                  color: widget.enabled ? Colors.black.withOpacity(0.9) : Colors.brown.withOpacity(0.6),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.9), fontSize: 14),
                ),
                onChanged: (text) {
                  validate(); // ✅ Validate input
                  if (widget.onChanged != null) {
                    widget.onChanged!(text); // ✅ Call the `onChanged` callback
                  // widget.onChanged?.call(text);
                  }
                },
              ),
            );
          },
        ),
        if (displayError != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10),
            child: Text(
              displayError,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}







void ReusableSnackBar(BuildContext context, String message, {
  IconData? icon,
  Color iconColor = Colors.black,
  Color backgroundColor = Colors.white
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor), // Apply custom icon color
            SizedBox(width: 10), // Spacing between icon and text
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor, // Custom background color
      behavior: SnackBarBehavior.floating, // Floating effect
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      elevation: 8, // Shadow effect
    ),
  );
}


class CustomRadioGroup extends StatefulWidget {
  // final String labelText;
  final List<String> options;
  final Function(List<String>) onSelected;
  final List<String>? selectedValues;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool isRequired;
  final String requiredMessage;
  final Function(String?)? onValidation;

  const CustomRadioGroup({
    Key? key,
    // required this.labelText,
    required this.options,
    required this.onSelected,
    this.selectedValues,
    // this.activeColor = const Color(0xFF464E65),
    // this.inactiveColor = const Color(0xFF464E65),
    this.activeColor,
    this.inactiveColor,
    this.isRequired = false,
    this.requiredMessage = "This field is required",
    this.onValidation,
  }) : super(key: key);

  @override
  _CustomRadioGroupState createState() => _CustomRadioGroupState();
}

class _CustomRadioGroupState extends State<CustomRadioGroup> {
  late List<String> _selected;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedValues ?? [];
  }

  void _validateSelection() {
    setState(() {
      if (widget.isRequired && _selected.isEmpty) {
        _errorMessage = widget.requiredMessage;
      } else {
        _errorMessage = null;
      }
    });

    if (widget.onValidation != null) {
      widget.onValidation!(_errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = widget.activeColor ?? const Color(0xFF464E65);
    Color inactiveColor = widget.inactiveColor ?? const Color(0xFF464E65);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Text
        // Text(
        //   widget.labelText,
        //   style: const TextStyle(
        //     fontSize: 16,
        //     fontWeight: FontWeight.w600,
        //     color: Colors.black,
        //   ),
        // ),
        const SizedBox(height: 5),

        // Options with Wrapping Layout
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.options.map((option) {
            bool isSelected = _selected.contains(option);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selected.remove(option);
                  } else {
                    _selected.add(option);
                  }
                });
                widget.onSelected(_selected);
                _validateSelection();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  // color: isSelected ? widget.activeColor : Colors.white,
                  color: isSelected ? (widget.activeColor ?? const Color(0xFFfb9798)) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    // color: isSelected ? widget.activeColor : widget.inactiveColor,
                    color: isSelected ? (widget.activeColor ?? const Color(0xFFfb9798)) : (widget.inactiveColor ?? const Color(0xFF464E65)),
                    width: 2,
                  ),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // color: isSelected ? Colors.white : widget.inactiveColor,
                    color: isSelected ? Colors.white : (widget.inactiveColor ?? const Color(0xFF464E65)),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.30,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              _errorMessage!,
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

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final IconData icon;
  final Color iconColor;
  final Color confirmButtonColor;
  final Color cancelButtonColor;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    required this.icon,
    required this.iconColor,
    required this.confirmButtonColor,
    required this.cancelButtonColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              icon, // Dynamic icon
              color: iconColor, // Dynamic icon color
              size: 60,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: cancelButtonColor, // Dynamic cancel button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Rounded button
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey), // Outlined border
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog first
                      onConfirm(); // Execute confirm action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmButtonColor, // Dynamic confirm button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Rounded button
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PriceInputContainer extends StatefulWidget {
  final String? labelText;
  final TextEditingController controller;
  final double width;
  final double height;
  final bool isRequired;
  final String? errorMessage;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const PriceInputContainer({
    Key? key,
    this.labelText,
    required this.controller,
    this.width = 380,
    this.height = 50,
    this.isRequired = false,
    this.errorMessage,
    this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  _PriceInputContainerState createState() => _PriceInputContainerState();
}

class _PriceInputContainerState extends State<PriceInputContainer> {
  FocusNode focusNode = FocusNode();
  String? internalErrorMessage;

  bool validate() {
    String text = widget.controller.text.trim();
    setState(() {
      if (widget.isRequired && text.isEmpty) {
        internalErrorMessage = widget.errorMessage ?? "Price is required!";
        return;
      }
      internalErrorMessage = null;
    });
    return internalErrorMessage == null;
  }

  @override
  Widget build(BuildContext context) {
    String? displayError = widget.errorMessage ?? internalErrorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Text(
            widget.labelText!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        if (widget.labelText != null) const SizedBox(height: 5),
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
                      color: const Color(0xFFD19C86).withOpacity(1),
                      blurRadius: 15,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    "RM",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(width: 10), // Space between "RM" and input
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: widget.enabled,
                      cursorColor: Colors.brown,
                      style: TextStyle(
                        color: widget.enabled ? Colors.black.withOpacity(0.9) : Colors.brown.withOpacity(0.6),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter price",
                        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.9), fontSize: 14),
                      ),
                      onChanged: (text) {
                        validate();
                        if (widget.onChanged != null) {
                          widget.onChanged!(text);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (displayError != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10),
            child: Text(
              displayError,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}


class ResponsiveTextArea extends StatefulWidget {
  final String labelText;
  final TextEditingController controller;
  final String placeholder;
  final bool isRequired;
  final String? requiredMessage;
  final ValueChanged<String>? onChanged;

  const ResponsiveTextArea({
    Key? key,
    required this.labelText,
    required this.controller,
    this.placeholder = "Enter here...",
    this.isRequired = false,
    this.requiredMessage = "This field is required.",
    this.onChanged,
  }) : super(key: key);

  @override
  _ResponsiveTextAreaState createState() => _ResponsiveTextAreaState();
}

class _ResponsiveTextAreaState extends State<ResponsiveTextArea> {
  FocusNode focusNode = FocusNode();
  String? internalErrorMessage;

  bool validate() {
    String text = widget.controller.text.trim();
    setState(() {
      if (widget.isRequired && text.isEmpty) {
        internalErrorMessage = widget.requiredMessage;
        return;
      }
      internalErrorMessage = null;
    });

    return internalErrorMessage == null;
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.black),
                boxShadow: [
                  if (focusNode.hasFocus)
                    BoxShadow(
                      color: const Color(0xFFD19C86).withOpacity(1),
                      blurRadius: 15,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 20, // ✅ Starts with a small height
                ),
                child: Scrollbar(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: focusNode,
                    cursorColor: Colors.brown,
                    maxLines: null, // ✅ Expands automatically
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.9), fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (text) {
                      validate();
                      setState(() {}); // ✅ Ensures real-time height adjustment
                      if (widget.onChanged != null) {
                        widget.onChanged!(text);
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),

        if (internalErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10),
            child: Text(
              internalErrorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}







