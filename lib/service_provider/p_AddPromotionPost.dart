import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_mate/services/upload_service.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:flutter/services.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';


class p_AddPromotionPost extends StatefulWidget {
  @override
  _p_AddPromotionPostState createState() => _p_AddPromotionPostState();
}

class TitleWithDescriptions {
  TextEditingController titleController;
  List<TextEditingController> descriptionControllers;

  TitleWithDescriptions({String title = "", List<String> descriptions = const []})
      : titleController = TextEditingController(text: title),
        descriptionControllers = descriptions.map((desc) => TextEditingController(text: desc)).toList();

  Map<String, dynamic> toMap() {
    return {
      "title": titleController.text,
      "descriptions": descriptionControllers.map((controller) => controller.text).toList(),
    };
  }
}

class _p_AddPromotionPostState extends State<p_AddPromotionPost> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  List<String> _imageUrls = [];


  String? userId;
  String? spName;
  String? spImageUrl;

  TextEditingController titleController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController APriceController = TextEditingController();

  List<String> stateOptions = [];
  List<String> selectedStates = [];
  List<String> expertiseOptions = [];
  List<String> selectedExpertiseFields = [];
  List<TitleWithDescriptions> entries = [];
  String? PTitleError;
  String? priceError;
  String? APriceError;
  double? discountPercentage;
  bool isEditing = true;


  String? selectedStatesError;
  String? selectedExpertiseError;

  @override
  void initState() {
    super.initState();
    _loadSPData();
    APriceController.addListener(calculateDiscountPercentage);
    priceController.addListener(calculateDiscountPercentage);
  }

  @override
  void dispose() {
    APriceController.removeListener(calculateDiscountPercentage);
    priceController.removeListener(calculateDiscountPercentage);
    APriceController.dispose();
    priceController.dispose();
    super.dispose();
  }


  void validatePrice() {
    setState(() {
      priceError = priceController.text.trim().isEmpty ? "  Discount Price is required!" : null;
      APriceError = APriceController.text.trim().isEmpty ? "Actual Price is required!" : null;
    });
  }

  Future<void> _loadSPData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
      DocumentSnapshot snapshot = await _firestore.collection('service_providers').doc(user.uid).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          spName = data['name'];
          spImageUrl = data['profilePic'];
          stateOptions = (data['selectedStates'] as List<dynamic>?)?.cast<String>() ?? [];
          selectedStates = List.from(stateOptions);
          expertiseOptions = (data['selectedExpertiseFields'] as List<dynamic>?)?.cast<String>() ?? [];
          selectedExpertiseFields = List.from(expertiseOptions);
        });
      }
    }
  }


  void addTitleEntry() {
    setState(() {
      entries.add(TitleWithDescriptions(title: "", descriptions: [""]));
    });
  }


  void addDescriptionField(int titleIndex) {
    setState(() {
      entries[titleIndex].descriptionControllers.add(TextEditingController()); // ✅ Corrected
    });
  }

  void removeDescriptionField(int titleIndex, int descIndex) {
    setState(() {
      entries[titleIndex].descriptionControllers[descIndex].dispose(); // ✅ Dispose controller before removing
      entries[titleIndex].descriptionControllers.removeAt(descIndex); // ✅ Corrected
    });
  }


  void removeTitleEntry(int index) {
    setState(() {
      entries.removeAt(index);
    });
  }

  Future<void> _pickAndUploadImage() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(); // ✅ Allows multiple selection

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      List<File> selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      setState(() => _images.addAll(selectedImages)); // ✅ Stores images

      UploadService uploadService = UploadService();
      for (var imageFile in selectedImages) {
        String? uploadedImageUrl = await uploadService.uploadImage(imageFile);
        if (uploadedImageUrl != null) {
          setState(() => _imageUrls.add(uploadedImageUrl)); // ✅ Stores uploaded URLs
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageUrls.removeAt(index); // ✅ Removes from the uploaded list
    });
  }

  void calculateDiscountPercentage() {
    double? actualPrice = double.tryParse(APriceController.text);
    double? discountedPrice = double.tryParse(priceController.text);

    if (actualPrice != null && discountedPrice != null && actualPrice > 0) {
      double discount = ((actualPrice - discountedPrice) / actualPrice) * 100;
      setState(() {
        discountPercentage = discount;
      });
    } else {
      setState(() {
        discountPercentage = null;
      });
    }
  }

  Future<void> addPromotionPost() async {

    if (userId == null) {
      ReusableSnackBar(
          context,
          "User not found. Please log in again.",
          icon: Icons.warning,
          iconColor: Colors.orange
      );
      return;
    }

    setState(() {
      selectedStatesError = selectedStates.isEmpty ? "Please select at least one operation state!" : null;
       if (selectedExpertiseFields.length > 1) {
        selectedExpertiseError = "Please select only one service category that best matches your service.";
      } else {
        selectedExpertiseError = null;
      }
    });

    if (PTitleError != null ||
        titleController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        APriceController.text.trim().isEmpty ||
        selectedStates.isEmpty || selectedExpertiseFields.isEmpty ||
        selectedStatesError != null || selectedExpertiseError != null ||
        _imageUrls == null || _imageUrls!.isEmpty) {  // ✅ Check for empty image list
      ReusableSnackBar(
          context,
          "Please fill in all fields and upload an image.",
          icon: Icons.warning,
          iconColor: Colors.orange
      );
      return;
    }

    // ✅ Validate if each title has content and at least one description
    bool hasValidEntries = entries.every((entry) =>
    entry.titleController.text.trim().isNotEmpty && // ✅ Ensure title is not empty
        entry.descriptionControllers.isNotEmpty && // ✅ Ensure at least one description
        entry.descriptionControllers.any((desc) => desc.text.trim().isNotEmpty) // ✅ Ensure at least one non-empty description
    );

    if (entries.isEmpty || !hasValidEntries) {
      ReusableSnackBar(
        context,
        "Each section must have a title and at least one description.",
        icon: Icons.warning,
        iconColor: Colors.orange,
      );
      return;
    }



    // Show loading dialog (blocking UI until post is added)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // ✅ Calculate discount before adding to Firestore
    calculateDiscountPercentage();

    try {
      // Add to Firestore
      await _firestore.collection('promotion').add({
        'userId': userId,
        'SPname': spName,
        'SPimageURL': spImageUrl,
        'PImage': _imageUrls,
        'PTitle': titleController.text.trim(),
        'PPrice': int.tryParse(priceController.text.trim()) ?? 0,
        'PAPrice': int.tryParse(APriceController.text.trim()) ?? 0,
        'PDiscountPercentage': discountPercentage != null
            ? double.parse(discountPercentage!.toStringAsFixed(1))  // Convert back to double
            : null,
        'PDescriptions': entries.map((entry) => entry.toMap()).toList(),
        'ServiceStates': List.from(selectedStates),
        'ServiceCategory': List.from(selectedExpertiseFields),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Close loading dialog
      Navigator.pop(context);

      // Notify user
      ReusableSnackBar(
        context,
        "Promotion Post Added Successfully!",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );

      // Delay a bit to ensure smooth UI transition
      await Future.delayed(Duration(milliseconds: 100));

      // Pop the current screen and pass `true` to indicate successful addition
      Navigator.pop(context, true);
    } catch (error) {
      Navigator.pop(context); // Close loading dialog on error
      print("Error adding post: $error");
      ReusableSnackBar(
          context,
          "Failed to add post. Please try again. ",
          icon: Icons.error,
          iconColor: Colors.red // Red icon for error
      );
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: Color(0xFF464E65),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Promotion Post",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Scrollable uploaded images
            if (_images.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => FullScreenImageViewer(
                                images: _images,
                                initialIndex: index,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 120,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(_images[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 15,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            Center(
              child: TextButton(
                onPressed: _pickAndUploadImage,
                child: const Text(
                  "Upload Service Picture",
                  style: TextStyle(
                    color: Color(0xFF464E65),
                    decoration: TextDecoration.underline,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            LongInputContainer(
              labelText: "Title of the Service",
              controller: titleController,
              enabled:  isEditing, // Or use isEditing
              isRequired: true, // ✅ Required field
              placeholder: "Enter the title of the service",
              height: 50,
              width: 380,
              errorMessage: PTitleError, // ✅ Dynamic error message
              onChanged: (value) {
                setState(() {
                  PTitleError = value.trim().isEmpty ? "Title of the service is required!" : null;
                });
              },
            ),

            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Actual Price",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                Text(
                  "(Please provide the actual price of the service in whole number (e.g. 50))",
                  style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                PriceInputContainer(
                  // labelText: "Price (Only accept whole number e.g 12)",
                  controller: APriceController,
                  enabled: isEditing, // Enable/Disable input
                  isRequired: true, // Make it required
                  errorMessage: APriceError,
                  onChanged: (value) {
                    setState(() {
                      APriceError = value.trim().isEmpty ? "Actual Price is required!" : null;
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
                  "Discounted Price",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                Text(
                  "(Please provide the discounted price of the service in whole number (e.g. 40))",
                  style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                PriceInputContainer(
                  // labelText: "Price (Only accept whole number e.g 12)",
                  controller: priceController,
                  enabled: isEditing, // Enable/Disable input
                  isRequired: true, // Make it required
                  errorMessage: priceError,
                  onChanged: (value) {
                    setState(() {
                      priceError = value.trim().isEmpty ? "Discounted Price is required!" : null;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 15),

            // Discount Percentage Display
            DiscountDisplayContainer(
              discountPercentage: discountPercentage,
            ),

            SizedBox(height: 15),
            // Operation State Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Service Operation State",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  "(May select more than one service operation state.)",
                  style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                CustomRadioGroup(
                  options: stateOptions, // ✅ This ensures options are loaded
                  selectedValues: selectedStates, // ✅ Creates a fresh instance
                  isRequired: true,
                  requiredMessage: "Please select at least one operation state!",
                  onSelected: (selectedList) {
                    setState(() {
                      selectedStates = List.from(selectedList); // ✅ Ensure it's a new instance
                    });
                  },
                  onValidation: (value) {
                    setState(() {
                      PTitleError = titleController.text.trim().isEmpty ? "Title of the service is required!" : null;
                      print("Current text: $value");
                      print("Current error: $PTitleError");
                    });
                  },
                ),

              ],
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Service Category",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  "(Please select the most suitable service category.)",
                  style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                CustomRadioGroup(
                  options: expertiseOptions,
                  selectedValues: selectedExpertiseFields,
                  isSingleSelect: true, // ✅ Force only 1 selection
                  isRequired: true,
                  requiredMessage: "Please select one category",
                  onSelected: (selection) {
                    setState(() => selectedExpertiseFields = List.from(selection));
                  },
                  onValidation: (error) {
                    setState(() => selectedExpertiseError = error);
                  },
                ),
                if (selectedExpertiseError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      selectedExpertiseError!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 15),

            Text(
              "Service Description",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
            ),
            const SizedBox(height: 2),
            Text(
              "(Add a title and supporting descriptions for clarity. Use '+ Add Description' to include more details and '- Remove Section' to delete this section.)",
              style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
            ),
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(entries.length, (titleIndex) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Input (✅ Uses Persistent Controller)
                      LongInputContainer(
                        labelText: "Title",
                        controller: entries[titleIndex].titleController, // ✅ Uses existing controller
                        placeholder: "e.g. Clog Removal",
                        width: double.infinity,
                        height: 50,
                        isRequired: true,
                        requiredMessage: "Title is required.",
                      ),

                      SizedBox(height: 10),

                      // Description Inputs (✅ Uses Persistent Controllers)
                      ...List.generate(entries[titleIndex].descriptionControllers.length, (descIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: ResponsiveTextArea(
                                  labelText: "Description ${descIndex + 1}",
                                  controller: entries[titleIndex].descriptionControllers[descIndex],
                                  placeholder: "e.g. Quick and thorough clearing of blockages...",
                                  isRequired: true,
                                  requiredMessage: "Description ${descIndex + 1} is required.",
                                  onChanged: (value) {
                                    setState(() {}); // ✅ Triggers rebuild for dynamic height
                                  },
                                ),
                              ),

                              SizedBox(width: 10),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    entries[titleIndex].descriptionControllers.removeAt(descIndex);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),

                      // Add Description Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              entries[titleIndex].descriptionControllers.add(TextEditingController());
                            });
                          },
                          child: Text(
                            "+ Add Description",
                            style: TextStyle(
                              fontSize: 15,
                              color: const Color(0xFF464E65).withOpacity(0.8), // ✅ Fixed: Removed `const`
                              fontWeight: FontWeight.w600, // Medium bold

                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 150, // Adjust width as needed
                          height: 45, // Set fixed height
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                entries.removeAt(titleIndex);
                              });
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF464E65), width: 2.0), // Thin border
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // Smooth rounded corners
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8), // Compact padding
                            ),
                            child: const Text(
                              "- Remove Section",
                              style: TextStyle(
                                fontSize: 16, // Set to 16
                                color: Color(0xFF464E65), // Keep red color for remove action
                                fontWeight: FontWeight.w600, // Medium bold
                              ),
                            ),
                          ),
                        ),
                      ),

                      Divider(
                        color: Color(0xFF464E65), // ✅ Makes it grey
                        thickness: 2,       // ✅ Makes it thicker
                        height: 20,         // ✅ Adjusts spacing
                      ),

                    ],
                  );
                }),

                SizedBox(height: 10),
              ],
            ),

            SizedBox(
              width: 130, // Slightly wider for better aesthetics
              height: 45, // Balanced height
              child: Material(
                elevation: 5, // Shadow for depth
                borderRadius: BorderRadius.circular(30), // Smooth rounded corners
                shadowColor: Colors.black38, // Soft shadow effect
                child: TextButton(
                  onPressed: addTitleEntry,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF464E65), // Dark bluish-gray background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Smooth rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10), // Compact padding
                  ),
                  child: const Text(
                    "+ Add Section",
                    style: TextStyle(
                      fontSize: 16, // Readable size
                      color: Colors.white, // White text for contrast
                      fontWeight: FontWeight.w600, // Slightly bolder for emphasis
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: dk_button(
                context,
                "Submit Post",
                    () async {
                  addPromotionPost();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}