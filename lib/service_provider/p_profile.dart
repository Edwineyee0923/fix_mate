import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:fix_mate/services/upload_service.dart';
import 'package:fix_mate/home_page/HomePage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:fix_mate/service_provider/p_layout.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';


class p_profile extends StatefulWidget {
  static String routeName = "/service_provider/p_profile";

  const p_profile({Key? key}) : super(key: key);

  @override
  _p_profileState createState() => _p_profileState();
}

class _p_profileState extends State<p_profile> {
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
  List<String> selectedStates = []; // Store the selected states
  List<String> selectedExpertiseFields = []; // Store the selected expertise fields
  String? bioError;
  String? certificateError;

  TextEditingController nameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController certificateController = TextEditingController();
  TextEditingController addressController = TextEditingController();

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
        DocumentSnapshot snapshot = await _firestore.collection('service_providers').doc(user.uid).get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            nameController.text = data['name'] ?? '';
            bioController.text = data['bio'] ?? '';
            phoneController.text = data['phone'] ?? '';
            emailController.text = data['email'] ?? '';
            dobController.text = data['dob'] ?? '';
            selectedGender = data['gender'] ?? "";
            _imageUrl = data['profilePic'];
            selectedStates = (data['selectedStates'] as List<dynamic>?)?.cast<String>() ?? [];
            selectedExpertiseFields = (data['selectedExpertiseFields'] as List<dynamic>?)?.cast<String>() ?? [];
            certificateController.text = data['certificateLink'] ?? "";
            addressController.text = data['address'] ?? "";
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
      bioError = bioController.text.trim().isEmpty ? "Bio is required!" : null;
      // certificateError = certificateController.text.trim().isEmpty ? "A Google Drive link to supporting documents is required for service provider verification! (e.g., certificate, business card, proposal, IC/passport, or service evidence)." : null;
      // Validate certificate again before saving
      _validateCertificate();
    });

    // Check for any validation errors
    if (!isNameValid || !isPhoneValid || !isDobValid || selectedGender == null || selectedStates.isEmpty || selectedExpertiseFields.isEmpty || bioError != null || certificateError != null) {
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
        await _firestore.collection('service_providers').doc(user.uid).update({
          'name': nameController.text.trim(),
          'bio': bioController.text.trim(),
          'phone': phoneController.text.trim(),
          'dob': dobController.text.trim(),
          'gender': selectedGender,
          'profilePic': _imageUrl ?? '',
          'certificateLink': certificateController.text.trim(),
          'selectedStates': selectedStates,
          'selectedExpertiseFields' : selectedExpertiseFields,
          'address' : addressController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(), // Store update timestamp
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

  void _validateCertificate() {
    setState(() {
      String text = certificateController.text.trim();
      certificateError = text.isEmpty
          ? "A Google Drive link to supporting documents is required for service provider verification! (e.g., certificate, business card, proposal, IC/passport, or service evidence)."
          : null;
    });
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

  void _logoutUser() async {
    try {
      await _auth.signOut(); // ✅ Firebase sign-out
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // ✅ Redirect to login
      );
    } catch (e) {
      print("Logout failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderLayout(
      selectedIndex: 2,
      child: Scaffold(
      backgroundColor: Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: Color(0xFF464E65),
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        //   onPressed: () {
        //     if (isEditing) {
        //       _showDiscardChangesDialog(); // Ask user before discarding changes
        //     } else {
        //       Navigator.pushReplacement(
        //         context,
        //         MaterialPageRoute(builder: (context) => HomePage()),
        //       );
        //     }
        //   },
        // ),
        leading: isEditing
            ? IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white, // Makes the icon white
          ),
          onPressed: () {
            _showDiscardChangesDialog(); // ✅ Ask user before discarding changes
          },
        )
            : null, // ✅ Hides the back button when `isEditing` is false

        title: Text("My Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,)),
        titleSpacing: isEditing ? 5 : 25, // ✅ Adjust title spacing dynamically
        automaticallyImplyLeading: false,
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

                if (isEditing)
                  TextButton(
                    onPressed: _pickAndUploadImage,
                    child: Text(
                      "Change Profile Picture",
                      style: TextStyle(color: Color(0xFF464E65).withOpacity(0.8), fontSize: 18, fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                    ),
                  ),
                SizedBox(height: 15),
                _buildProfileFields(),
              ],
            ),
          ),
        ),
      ),
      )
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
              labelText: "Bio (Description of your services)",
              controller: bioController,
              maxWords: 300,
              width: 340,
              height: 150,
              enabled: isEditing,
              isRequired: true,
              placeholder: "Please describe your services in detail...",
              errorMessage: bioError,
          ),
          SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Gender",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              SizedBox(height: 3),
              if (isEditing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                )
              else
                Text(
                  selectedGender ?? "Not Specified",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500, // ✅ Semi-bold
                    fontStyle: FontStyle.italic, // ✅ Italic
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
          SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Operation State",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              if (isEditing) ...[ // ✅ Show this only in edit mode
                const SizedBox(height: 2),
                Text(
                  "(May select more than one operation state.)",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                const SizedBox(height: 5),
              ],
              SizedBox(height: 3),
              // If Editing Mode is Enabled, Show CustomRadioGroup
              if (isEditing)
                CustomRadioGroup(
                  options: ['Perlis', 'Kedah', 'Penang', 'Perak', 'Selangor', 'Negeri Sembilan', 'Melaka', 'Johor',
                    'Terengganu', 'Kelantan', 'Pahang', 'Sabah', 'Sarawak'],
                  selectedValues: selectedStates,
                  isRequired: true,
                  requiredMessage: "Please select at least one state!",
                  onSelected: (selectedList) {
                    setState(() {
                      selectedStates = selectedList;
                    });
                  },
                )
              else
                Text(
                  selectedStates.isNotEmpty ? selectedStates.join(", ") : "No states selected",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500, // ✅ Semi-bold
                    fontStyle: FontStyle.italic, // ✅ Italic
                  ),
                ),
            ],
          ),
          SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Expertise Field",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              if (isEditing) ...[ // ✅ Show this only in edit mode
                const SizedBox(height: 2),
                Text(
                  "(Select multiple fields if applicable. Specify details in the description.)",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                const SizedBox(height: 5),
              ],
              SizedBox(height: 3),
              if (isEditing)
                CustomRadioGroup(
                  options: ['Cleaning', 'Electrical', 'Plumbing','Painting', 'Door Install', 'Roofing', 'Flooring', 'Home Security', 'Others'],
                  selectedValues: selectedExpertiseFields,
                  isRequired: true,
                  requiredMessage: "Please select at least one expertise field!",
                  onSelected: (selectedList) {
                    setState(() {
                      selectedExpertiseFields = selectedList;
                    });
                  },
                )
              else
                Text(
                  selectedExpertiseFields.isNotEmpty ? selectedExpertiseFields.join(", ") : "No expertise fields selected",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500, // ✅ Semi-bold
                    fontStyle: FontStyle.italic, // ✅ Italic
                  ),
                ),
            ],
          ),
          SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Certificate Link (Google Drive)",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(height: 3),

              if (isEditing)
                LongInputContainer(
                  controller: certificateController,
                  placeholder: "Enter a Google Drive link for supporting documents as a valid service provider.",
                  isRequired: true, // ✅ Required field
                  isUrl: true, // ✅ Ensures valid URL
                  errorMessage: certificateError,
                  onChanged: (text) => _validateCertificate(),
                )
              else
                GestureDetector(
                  onTap: () {
                    if (certificateController.text.isNotEmpty) {
                      launchUrl(Uri.parse(certificateController.text));
                    }
                  },
                  child: Text(
                    certificateController.text.isNotEmpty
                        ? certificateController.text
                        : "No certificate link provided",
                    style: TextStyle(
                      fontSize: 15,
                      color: certificateController.text.isNotEmpty ? Colors.blue : Colors.black54,
                      decoration: certificateController.text.isNotEmpty ? TextDecoration.underline : TextDecoration.none,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Business Address (Optional)",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(height: 5),

              if (isEditing)
                LongInputContainer(
                  controller: addressController,
                  placeholder: "Enter Your Business Address here...",
                  isRequired: false,
                )
              else
                GestureDetector(
                  onTap: () {
                    if (addressController.text.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: addressController.text));
                      ReusableSnackBar(
                          context,
                          "Address copied to clipboard!",
                          icon: Icons.check_circle,
                          iconColor: Colors.green,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black45, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            addressController.text.isNotEmpty ? addressController.text : "No address provided.",
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                            overflow: TextOverflow.ellipsis, // Prevents overflow issues
                            maxLines: 2, // Limits text to 2 lines
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.copy, size: 20, color: Colors.black54), // Copy icon
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 25),

          // ✅ Show Log Out button only when isEditing is true
          if (!isEditing)
          dk_button(
            context,
            "Log Out",
            _logoutUser, // Calls the logout function
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }
}
