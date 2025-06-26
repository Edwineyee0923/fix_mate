import 'dart:io';
import 'package:fix_mate/home_page/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_mate/services/upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:intl/intl.dart'; // For formatting date
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/services/send_email.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';


class p_register extends StatefulWidget {
  final bool isEditing;

  p_register({this.isEditing = false}); // Default to false (registration mode)

  @override
  _p_registerState createState() => _p_registerState();
}

class _p_registerState extends State<p_register> {
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
      return HomePage();
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
  TextEditingController spUSecretController = TextEditingController();   // Toyyibpay User Secret
  TextEditingController spCCodeController = TextEditingController(); // Toyyibpay User Secret
  TextEditingController certificateController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  // Form Validation
  bool isNameValid = true;
  bool isDobValid = true;
  bool isPhoneValid = true;
  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;
  bool isspUSecretValid = true;
  bool isspCCodeValid = true;
  bool isEditing = true;
  String? selectedGender; // Holds selected gender value
  final List<String> genderOptions = ["Male", "Female", "Prefer not to say"]; // Dropdown options
  List<String> selectedStates = []; // Store the selected states
  List<String> selectedExpertiseFields = []; // Store the selected expertise fields
  String? selectedStatesError;
  String? selectedGenderError;
  String? selectedExpertiseFieldsError;
  String? bioError;
  String? certificateError;

  void _validateCertificate() {
    setState(() {
      String text = certificateController.text.trim();
      certificateError = text.isEmpty
          ? "A Google Drive link to supporting documents is required for service provider verification! (e.g., certificate, business card, proposal, IC/passport, or service evidence)."
          : null;
    });
  }


  // 🔹 Register User & Save Data
  Future<bool> registerUser() async {

    // Trigger validation manually
    setState(() {
      selectedGenderError = selectedGender == null ? "Please select a gender!" : null;
      // Validate Bio & Certificate
      bioError = bioController.text.trim().isEmpty ? "Bio is required!" : null;
      certificateError = certificateController.text.trim().isEmpty ? "A Google Drive link to supporting documents is required for service provider verification! (e.g., certificate, business card, proposal, IC/passport, or service evidence)." : null;
      // Validate certificate again before saving
      _validateCertificate();
    });



    if (!isNameValid || !isEmailValid || !isPhoneValid || !isDobValid || !isPasswordValid || !isConfirmPasswordValid || selectedGender == null || selectedStates.isEmpty  || selectedExpertiseFields.isEmpty || bioError != null
        || certificateError != null || !isspUSecretValid || !isspCCodeValid ) {
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

      await _firestore.collection('service_providers').doc(userId).set({
        'id': userId,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'dob': dobController.text.trim(),
        'gender': selectedGender,
        'bio': bioController.text.trim(),
        'spUSecret': spUSecretController.text.trim(),
        'spCCode': spCCodeController.text.trim(),
        'certificateLink': certificateController.text.trim(),
        'profilePic': _imageUrl ?? '',
        'role': "Service Provider",
        'createdAt': Timestamp.now(),
        'selectedStates': selectedStates,
        'address': addressController.text.trim(),
        'selectedExpertiseFields': selectedExpertiseFields,
        'status': "Pending", // Set status as pending
        'resubmissionCount': 0, // Initialize resubmission count
      });

      // ✅ Send Email Notification
      await EmailService.sendEmail(
          emailController.text.trim(),
          "Your Service Provider Application is Pending",
          "Hello ${nameController.text.trim()},\n\nYour application has been submitted for verification. You will receive another email once your registration is approved.\n\nThank you!"
      );


      Navigator.pop(context);
      // ReusableSnackBar(
      //     context,
      //     "Application submitted! Your registration is pending verification. Please check your email.",
      //     icon: Icons.check_circle,
      //     iconColor: Colors.green // Green icon for success
      // );
      Future.delayed(Duration.zero, () {
        showSuccessMessage(
          context,
          "Application submitted! Your registration is pending verification. Please check your email.",
        );
      });



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
        backgroundColor: Color(0xFF464E65),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            navigateNextPage(context); // Navigates back when pressed
          },
        ),
        title: Text(
          "Service Provider Application",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        titleSpacing: 5, // Aligns title closer to the leading icon (left-aligned)
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
                    ? GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => FullScreenImageViewer(
                        imageUrls: [_imageUrl!],
                        images: const [],
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(_imageUrl!),
                  ),
                )
                    : Icon(Icons.person, size: 100, color: Colors.grey),
                TextButton(
                  onPressed: _pickAndUploadImage,
                  child: Text(
                    "Upload Profile Picture",
                    style: TextStyle(
                      color: Color(0xFF464E65).withOpacity(0.8),
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
                        labelText: "Company Name (or User Name)",
                        hintText: "Enter your company name or username",
                        icon: Icons.domain,
                        controller: nameController,
                        validationMessage: "Please enter your company name or user name",
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
                        labelText: "Bio (Description of your services)",
                        controller: bioController,
                        enabled: isEditing,
                        isRequired: true, // ✅ Required field
                        maxWords: 500,
                        width: 340,
                        placeholder: "Please describe your services in detail...",
                        height: 150,
                        errorMessage: bioError, // ✅ Pass validation error
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
                              border: Border.all(color: selectedGenderError != null ? Colors.red : Colors.black), // Show red border if error
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
                                      style: TextStyle(
                                        color: Colors.brown.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedGender = newValue;
                                    selectedGenderError = null; // Clear error when user selects gender
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

                          // 🔹 Show validation message below dropdown
                          if (selectedGenderError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                selectedGenderError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
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
                        validationMessage: "Enter a valid email! (e.g abc123@gmail.com)",
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
                      const SizedBox(height: 15),

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
                      const SizedBox(height: 15),

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

                      const SizedBox(height: 15),

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Expertise Field",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "(Select multiple fields if applicable. Specify details in the description.)",
                            style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                          ),
                          CustomRadioGroup(
                            options: ['Cleaning', 'Electrical', 'Plumbing','Painting', 'Door Install', 'Roofing', 'Flooring', 'Home Security', 'Renovation', 'Others'],
                            selectedValues: selectedExpertiseFields,
                            isRequired: true,
                            requiredMessage: "Please select at least one expertise field!",
                            onSelected: (selectedList) {
                              setState(() {
                                selectedExpertiseFields = selectedList;
                              });
                            },
                            onValidation: (error) {
                              setState(() {
                                selectedExpertiseFieldsError = error;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Operation State",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "(May select more than one operation state.)",
                            style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                          ),
                          const SizedBox(height: 5),

                          CustomRadioGroup(
                            options: ['Perlis', 'Kedah', 'Penang','Perak', 'Selangor', 'Negeri Sembilan', 'Melaka', 'Johor',
                              'Terengganu', 'Kelantan', 'Pahang', 'Sabah', 'Sarawak'],
                            selectedValues: selectedStates,
                            isRequired: true,
                            requiredMessage: "Please select at least one operation state!",
                            onSelected: (selectedList) {
                              setState(() {
                                selectedStates = selectedList;
                              });
                            },
                            onValidation: (error) {
                              setState(() {
                                selectedStatesError = error;
                              });
                            },
                          ),

                        ],
                      ),
                      SizedBox(height: 15),
                      // InternalTextField(
                      //   labelText: "ToyyibPay User Secret Key",
                      //   hintText: "Enter your registered ToyyibPay User Secret Key",
                      //   icon: Icons.key_sharp,
                      //   controller: spUSecretController,
                      //   validationMessage: "Please enter your registered ToyyibPay user secret key",
                      //   isValid: isspUSecretValid,
                      //   enabled: isEditing,
                      //   onChanged: (value) {
                      //     setState(() {
                      //       isspUSecretValid = value.trim().isNotEmpty; // Check if input is not empty
                      //     });
                      //   },// Pass validation status
                      // ),
                      // SizedBox(height: 15),
                      // InternalTextField(
                      //   labelText: "ToyyibPay Category Code",
                      //   hintText: "Enter your registered ToyyibPay category code",
                      //   icon: Icons.category_outlined,
                      //   controller: spCCodeController,
                      //   validationMessage: "Please enter your registered ToyyibPay category code",
                      //   isValid: isspCCodeValid,
                      //   enabled: isEditing,
                      //   onChanged: (value) {
                      //     setState(() {
                      //       isspCCodeValid = value.trim().isNotEmpty; // Check if input is not empty
                      //     });
                      //   },// Pass validation status
                      // ),
                      SizedBox(height: 15),
                      InternalTextField(
                        labelText: "Transfer Bank Name",
                        hintText: "Enter your preferred bank for revenue transfer",
                        icon: Icons.key_sharp,
                        controller: spUSecretController,
                        validationMessage: "Please enter your preferred bank for revenue transfer",
                        isValid: isspUSecretValid,
                        enabled: isEditing,
                        onChanged: (value) {
                          setState(() {
                            isspUSecretValid = value.trim().isNotEmpty; // Check if input is not empty
                          });
                        },// Pass validation status
                      ),
                      SizedBox(height: 15),
                      InternalTextField(
                        labelText: "Bank Account Number",
                        hintText: "Bank account number without dash (-) ",
                        icon: Icons.category_outlined,
                        controller: spCCodeController,
                        validationMessage: "Please enter your bank account number without dash (-)",
                        isValid: isspCCodeValid,
                        enabled: isEditing,
                        onChanged: (value) {
                          setState(() {
                            isspCCodeValid = value.trim().isNotEmpty; // Check if input is not empty
                          });
                        },// Pass validation status
                      ),
                      SizedBox(height: 15),
                      // InternalTextField(
                      //   labelText: "Bank Account Holder Name",
                      //   hintText: "Enter the bank account holder name",
                      //   icon: Icons.category_outlined,
                      //   controller: spCCodeController,
                      //   validationMessage: "Please enter your bank account holder name",
                      //   isValid: isspCCodeValid,
                      //   enabled: isEditing,
                      //   onChanged: (value) {
                      //     setState(() {
                      //       isspCCodeValid = value.trim().isNotEmpty; // Check if input is not empty
                      //     });
                      //   },// Pass validation status
                      // ),
                      // SizedBox(height: 15),
                      LongInputContainer(
                        labelText: "Google Drive Link (Supporting Document Upload)",
                        controller: certificateController,
                        placeholder: "Enter a Google Drive link for supporting documents as a valid service providers.",
                        isRequired: true, // ✅ Required field
                        isUrl: true, // ✅ Ensures valid URL
                        errorMessage: certificateError, // ✅ Pass validation error
                        onChanged: (text) => _validateCertificate(),
                      ),
                      SizedBox(height: 15),
                      LongInputContainer(
                        labelText: "Business Address (Optional)",
                        controller: addressController,
                        placeholder: "Enter Your Business Address here...",
                        isRequired: false,
                      ),
                      SizedBox(height: 15),
                      dk_button(
                        context,
                        "Register",
                            () async {
                          bool isRegistered = await registerUser(); // ✅ Call function and wait for result
                          if (isRegistered) {
                            navigateNextPage(context); // ✅ Navigate only if registration is successful
                          }
                        },
                      ),
                      SizedBox(height: 15),
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
