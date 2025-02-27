import 'dart:io';
import 'package:fix_mate/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_mate/services/upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:intl/intl.dart'; // For formatting date
import 'package:firebase_auth/firebase_auth.dart';

class s_register extends StatefulWidget {
  final bool isEditing;

  s_register({this.isEditing = false}); // Default to false (registration mode)

  @override
  _s_registerState createState() => _s_registerState();
}

class _s_registerState extends State<s_register> {
  File? _image;
  String? _imageUrl;
  final UploadService _uploadService = UploadService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // Opens the gallery, allows the user to select an image, and uploads it to Cloudinary.
  //
  // This function:
  // - Uses `ImagePicker` to let the user choose an image.
  // - If an image is selected, it updates the UI and calls `uploadImage()` to upload it.
  // - After a successful upload, it stores the image URL in `_imageUrl`.
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() => _image = imageFile); // Update UI with the selected image.

      String? imageUrl = await _uploadService.uploadImage(imageFile);

      if (imageUrl != null) {
        setState(() => _imageUrl = imageUrl); // Update UI with uploaded image URL.

        // // Save image URL to Firestore under 'users' collection
        // _firestore.collection('users').doc("user_id").set({
        //   'profileImage': imageUrl,
        // });
      }
    }
  }

  // Fetches and displays the user's profile picture from Firestore.
  //
  // This function:
  // - Gets the current authenticated user's ID.
  // - Fetches their profile image URL from Firestore (`service_seekers` collection).
  // - Updates `_imageUrl` if the image exists.
  // - Prints an error message if fetching fails.
  Future<void> _loadProfileImage() async {
    if (!widget.isEditing) return; // Skip if in registration mode
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await _firestore.collection('service_seekers').doc(user.uid).get();
        if (snapshot.exists && snapshot.data() != null) {
          setState(() {
            _imageUrl = (snapshot.data() as Map<String, dynamic>)['profilePic'];
          });
        }
      }
    } catch (e) {
      print("Error loading profile image: $e");
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

  // Form Controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  // Form Validation
  bool isNameValid = true;
  bool isDobValid = true;
  bool isPhoneValid = true;
  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;
  bool isEditing = true;
  String? selectedGender; // Holds selected gender value
  final List<String> genderOptions = ["Male", "Female", "Prefer not to say"]; // Dropdown options


  // 🔹 Register User & Save Data
  Future<bool> registerUser() async {
    if (!isNameValid || !isEmailValid || !isPhoneValid || !isDobValid || !isPasswordValid || !isConfirmPasswordValid || selectedGender == null) {
      ReusableSnackBar(context, "Please fill all fields correctly!", icon: Icons.warning, iconColor: Colors.orange);
      return false; // Registration failed
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String userId = userCredential.user!.uid;

      if (_image != null) {
        String? uploadedImageUrl = await _uploadService.uploadImage(_image!);
        if (uploadedImageUrl != null) {
          _imageUrl = uploadedImageUrl;
        }
      }

      await _firestore.collection('service_seekers').doc(userId).set({
        'id': userId,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'dob': dobController.text.trim(),
        'gender': selectedGender,
        'bio': bioController.text.trim(),
        'profilePic': _imageUrl ?? '',
        'role': "Service Seeker",
        'createdAt': Timestamp.now(),
      });

      Navigator.pop(context);
      ReusableSnackBar(
          context,
          "Registration Successful!",
          icon: Icons.check_circle,
          iconColor: Colors.green // Green icon for success
      );
      return true; // Registration successful
    } catch (e) {
      Navigator.pop(context);
      ReusableSnackBar(
          context,
          "Registration failed! Please fill in all the required field! ",
          icon: Icons.error,
          iconColor: Colors.red // Red icon for error
      );
      return false; // Registration failed
    }
  }



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
          "Service Seeker Registration",
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
                        enabled: isEditing,
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
                    enabled: isEditing,
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
                        enabled: isEditing,
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
                        enabled: isEditing,
                        validationMessage: "Enter a valid phone number! (e.g Malaysia: 60123456789, Indonesia: 628123456789))",
                        isValid: isPhoneValid,
                        onChanged: (value) {
                          setState(() {
                            isPhoneValid = RegExp(r'^[1-9]\d{9,11}$').hasMatch(value);
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
                            enabled: isEditing,
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
                        enabled: isEditing,
                        validationMessage: "Password must be at least 6 characters!",
                        isValid: isPasswordValid,
                        onChanged: (value) {
                          setState(() {
                            isPasswordValid = value.length >= 6;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // Confirm Password Field
                      InternalTextField(
                        labelText: "Confirm Password",
                        icon: Icons.lock,
                        controller: confirmPasswordController,
                        hintText: "Confirm your password",
                        isPassword: true,
                        enabled: isEditing,
                        validationMessage: "Passwords do not match!",
                        isValid: isConfirmPasswordValid,
                        onChanged: (value) {
                          setState(() {
                            isConfirmPasswordValid = value == passwordController.text;
                          });
                        },
                      ),
                      SizedBox(height: 15),
                      pk_button(
                        context,
                        "Register",
                            () async {
                          bool isRegistered = await registerUser(); // ✅ Call function and wait for result
                          if (isRegistered) {
                            navigateNextPage(context); // ✅ Navigate only if registration is successful
                          }
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
