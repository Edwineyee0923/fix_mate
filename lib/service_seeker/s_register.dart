import 'dart:io';
import 'package:fix_mate/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_mate/reusable_widget/upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:intl/intl.dart'; // For formatting date


class s_register extends StatefulWidget {
  @override
  _s_registerState createState() => _s_registerState();
}

class _s_registerState extends State<s_register> {
  File? _image;
  String? _imageUrl;
  final UploadService _uploadService = UploadService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() => _image = imageFile);

      String? imageUrl = await _uploadService.uploadImage(imageFile);

      if (imageUrl != null) {
        setState(() => _imageUrl = imageUrl);

        // Save image URL to Firestore under 'users' collection
        _firestore.collection('users').doc("user_id").set({
          'profileImage': imageUrl,
        });
      }
    }
  }

  Future<void> _loadProfileImage() async {
    DocumentSnapshot snapshot = await _firestore.collection('users').doc("user_id").get();

    if (snapshot.exists && snapshot.data() != null) {
      setState(() {
        _imageUrl = (snapshot.data() as Map<String, dynamic>)['profileImage'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Function to select date of birth
  Future<void> _selectDateOfBirth() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text = DateFormat("yyyy-MM-dd").format(pickedDate);
        isDobValid = true;
      });
    }
  }

  void navigateNextPage(BuildContext ctx) {
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) {
      return home_page();
    }));
  }

  TextEditingController nameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool isNameValid = false;
  bool isDobValid = true;
  bool isPhoneValid = true;
  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;


  String? selectedGender; // Holds selected gender value
  final List<String> genderOptions = ["Male", "Female", "Prefer not to say"]; // Dropdown options

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFF2), // Set background color here
      appBar: AppBar(
        backgroundColor: Color(0xFFfb9798),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            navigateNextPage(context); // Navigates back when pressed
          },
        ),
        title: Text(
          "Service Provider Registration",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 0, // Aligns title closer to the leading icon (left-aligned)
      ),
      body: SingleChildScrollView(
        child: Center( // Centers everything
          child: Padding(
            padding: EdgeInsets.only(top: 30), // Adjust the spacing from the top
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevents unnecessary stretching
              crossAxisAlignment: CrossAxisAlignment.center, // Ensures center alignment
              children: [
                Text(
                  'Welcome to FixMate Application,',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    height: 1.0,
                  ),
                ),
                Text(
                  'Create An Account ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.50,
                  ),
                ),
                SizedBox(height: 15),
                _imageUrl != null
                    ? CircleAvatar(radius: 50, backgroundImage: NetworkImage(_imageUrl!))
                    : Icon(Icons.person, size: 100, color: Colors.grey),
                TextButton(
                  onPressed: _pickAndUploadImage,
                  child: Text(
                    "Upload Profile Picture",
                    style: TextStyle(
                      color: Color(0xFFfb9798),
                      decoration: TextDecoration.underline,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      decorationThickness: 3,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Form Fields (Wrapped inside a SizedBox)
                SizedBox(
                  width: 340, // Keeps the form fields centered and at a proper width
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Labels are aligned left
                    children: [
                      InternalTextField(
                        labelText: "User Name",
                        hintText: "Enter your name",
                        icon: Icons.person,
                        controller: nameController,
                        validationMessage: "Please enter your user name",
                        isValid: isNameValid,
                        onChanged: (value) {
                          setState(() {
                            isNameValid = value.trim().isNotEmpty; // Check if input is not empty
                          });
                        },// Pass validation status
                      ),
                      SizedBox(height: 15),
                  LongInputContainer(
                    labelText: "Bio (Optional)",
                    controller: bioController,
                    maxWords: 50,
                    width: 340,
                    placeholder: "Type your description here...",
                    height: 150,
                  ),

                      SizedBox(height: 15),
                      // Gender Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Gender",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: double.infinity, // Expands within SizedBox
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25.0),
                              border: Border.all(color: Colors.black),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedGender,
                                hint: Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.brown.withOpacity(0.8)), // Gender icon
                                    SizedBox(width: 8), // Spacing between icon and text
                                    Text(
                                      "Select Gender",
                                      style: TextStyle(color: Colors.brown.withOpacity(0.6), fontSize: 14),
                                    ),
                                  ],
                                ),
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedGender = newValue;
                                  });
                                },
                                items: genderOptions.map((String gender) {
                                  return DropdownMenuItem<String>(
                                    value: gender,
                                    child: Text(gender),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),

                      InternalTextField(
                        labelText: "Email",
                        controller: emailController,
                        icon: Icons.email,
                        hintText: "Enter your email",
                        validationMessage: "Enter a valid email!",
                        isValid: isEmailValid,
                        onChanged: (value) {
                          setState(() {
                            isEmailValid = value.contains("@");
                          });
                        },
                      ),
                      SizedBox(height: 15),

                      // Contact Number Field
                      InternalTextField(
                        labelText: "Contact Number",
                        icon: Icons.phone,
                        controller: phoneController,
                        hintText: "Enter your phone number",
                        validationMessage: "Enter a valid phone number!",
                        isValid: isPhoneValid,
                        onChanged: (value) {
                          setState(() {
                            isPhoneValid = RegExp(r'^\d{10,12}$').hasMatch(value);
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      // Date of Birth Picker
                      GestureDetector(
                        onTap: _selectDateOfBirth,
                        child: AbsorbPointer(
                          child: InternalTextField(
                            labelText: "Date of Birth",
                            icon: Icons.cake,
                            controller: dobController,
                            hintText: "Select your birthdate",
                            validationMessage: "Please select a valid date",
                            isValid: isDobValid,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Password Field
                      InternalTextField(
                        labelText: "Password",
                        icon: Icons.lock_outline,
                        controller: passwordController,
                        hintText: "Enter your password",
                        isPassword: true,
                        validationMessage: "Password must be at least 6 characters!",
                        isValid: isPasswordValid,
                        onChanged: (value) {
                          setState(() {
                            isPasswordValid = value.length >= 6;
                          });
                        },
                      ),

                      // Confirm Password Field
                      InternalTextField(
                        labelText: "Confirm Password",
                        icon: Icons.lock,
                        controller: confirmPasswordController,
                        hintText: "Confirm your password",
                        isPassword: true,
                        validationMessage: "Passwords do not match!",
                        isValid: isConfirmPasswordValid,
                        onChanged: (value) {
                          setState(() {
                            isConfirmPasswordValid = value == passwordController.text;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
