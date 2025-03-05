import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:fix_mate/services/upload_service.dart';
import 'package:fix_mate/home_page/home_page.dart';
import 'package:intl/intl.dart';

class s_profile extends StatefulWidget {
  @override
  _s_profileState createState() => _s_profileState();
}

class _s_profileState extends State<s_profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UploadService _uploadService = UploadService();

  File? _image;
  String? _imageUrl;
  bool isNameValid = true;
  bool isDobValid = true;
  bool isEditing = false; // 🔹 Initially in read-only mode
  bool showDisabledMessage = false; // Initially false
  bool isPhoneValid = true;
  String? selectedGender;
  String? selectedGenderError;
  final List<String> genderOptions = ["Male", "Female", "Prefer not to say"];

  TextEditingController nameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();


  void onEditPressed() {
    setState(() {
      showDisabledMessage = true; // Show message when Edit is clicked
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await _firestore.collection('service_seekers').doc(user.uid).get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            nameController.text = data['name'] ?? '';
            bioController.text = data['bio'] ?? '';
            phoneController.text = data['phone'] ?? '';
            emailController.text = data['email'] ?? '';
            dobController.text = data['dob'] ?? '';
            selectedGender = data['gender'];
            _imageUrl = data['profilePic'];
          });
        }
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() => _image = imageFile);

      String? uploadedImageUrl = await _uploadService.uploadImage(imageFile);
      if (uploadedImageUrl != null) {
        setState(() => _imageUrl = uploadedImageUrl);
      }
    }
  }

  Future<void> _saveProfileChanges() async {
    setState(() {
      isNameValid = nameController.text.trim().isNotEmpty;
      isDobValid = dobController.text.trim().isNotEmpty;
      isPhoneValid = phoneController.text.trim().isNotEmpty && isValidPhoneNumber(phoneController.text);
      selectedGenderError = selectedGender == null ? "Please select a gender!" : null;
    });

    // Check for any validation errors
    if (!isNameValid || !isPhoneValid || !isDobValid || selectedGender == null) {
      ReusableSnackBar(
        context,
        "Please fill in all required fields correctly!",
        icon: Icons.warning,
        iconColor: Colors.orange,
      );
      return;
    }

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('service_seekers').doc(user.uid).update({
          'name': nameController.text.trim(),
          'bio': bioController.text.trim(),
          'phone': phoneController.text.trim(),
          'dob': dobController.text.trim(),
          'gender': selectedGender,
          'profilePic': _imageUrl ?? '',
        });

        setState(() => isEditing = false);
        ReusableSnackBar(
          context,
          "Profile Updated Successfully!",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  bool isValidPhoneNumber(String number) {
    final regex = RegExp(r'^[1-9]\d{9,11}$'); // Supports Malaysia (60) & Indonesia (62)
    return regex.hasMatch(number);
  }


  // Function to select date of birth
  Future<void> _selectDateOfBirth() async {
    if (!isEditing) return; // 🔹 Prevent opening date picker in read-only mode

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text = DateFormat("yyyy-MM-dd").format(pickedDate);
      });
    }
  }

  void _showDiscardChangesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: "Discard Changes?",
          message: "You have unsaved changes. Are you sure you want to discard them?",
          confirmText: "Discard",
          cancelText: "Cancel",
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orangeAccent,
          confirmButtonColor: Colors.red,
          cancelButtonColor: Colors.grey.shade300,
          onConfirm: () {
            setState(() {
              isEditing = false;
            });
            _loadProfileData(); // Reload original values
          },
        );
      },
    );
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void navigateNextPage(BuildContext ctx) {
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) {
      return home_page();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: Color(0xFFfb9798),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white, // Makes the icon white
          ),
          onPressed: () {
            if (isEditing) {
              _showDiscardChangesDialog(); // Ask user before discarding changes
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => home_page()),
              );
            }
          },
        ),
        title: Text("My Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,)),
        titleSpacing: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10), // Moves left by reducing right padding
            child: IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.white),
              onPressed: () {
                if (isEditing) {
                  _saveProfileChanges(); // ✅ Save when clicking check icon
                } else {
                  onEditPressed(); // ✅ Show disabled message when switching to edit mode
                  _toggleEditMode(); // ✅ Enable edit mode
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _imageUrl != null
                    ? CircleAvatar(radius: 50, backgroundImage: NetworkImage(_imageUrl!))
                    : Icon(Icons.person, size: 100, color: Colors.grey),
                if (isEditing)
                  TextButton(
                    onPressed: _pickAndUploadImage,
                    child: Text(
                      "Change Profile Picture",
                      style: TextStyle(color: Color(0xFFfb9798), fontSize: 18, fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                    ),
                  ),
                SizedBox(height: 15),
                _buildProfileFields(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileFields() {
    return SizedBox(
      width: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InternalTextField
            (
            labelText: "User Name",
            icon: Icons.person,
            controller: nameController,
            enabled: isEditing,
            isValid: isNameValid,
            validationMessage: "Please enter your user name",
            onChanged: (value) {
              setState(() {
                isNameValid = value.trim().isNotEmpty; // Check if input is not empty
              });
            },
          ),
          SizedBox(height: 15),
          LongInputContainer
            (
              labelText: "Bio (Optional)",
              controller: bioController,
              maxWords: 50, width: 340,
              height: 150,
              enabled: isEditing,
              placeholder: "Type your description here..."
          ),
          SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Gender",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              SizedBox(height: 5),
              if (isEditing)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white, // White background
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(25),
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
                )
              else
                Text(
                  selectedGender ?? "Not Specified",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          SizedBox(height: 15),
          InternalTextField
            (
              labelText: "Email",
              controller: emailController,
              icon: Icons.email,
              enabled: false,
              disabledMessage: showDisabledMessage ? "Email cannot be changed as it is a unique identifier." : null,
          ),
          SizedBox(height: 15),
          InternalTextField(
            labelText: "Contact Number",
            icon: Icons.phone,
            controller: phoneController,
            hintText: "Enter your phone number",
            enabled: isEditing,
            validationMessage: isPhoneValid
                ? null
                : "Enter a valid phone number! (e.g Malaysia: 60123456789, Indonesia: 628123456789)",
            isValid: isPhoneValid,
            onChanged: (value) {
              setState(() {
                isPhoneValid = value.trim().isNotEmpty && isValidPhoneNumber(value);
              });
            },
          ),

          SizedBox(height: 15),
          GestureDetector(
            onTap: _selectDateOfBirth,
            child: AbsorbPointer(
              child: InternalTextField(labelText: "Date of Birth", icon: Icons.cake, controller: dobController, enabled: isEditing),
            ),
          ),
          SizedBox(height: 25),
        ],
      ),
    );
  }
}
