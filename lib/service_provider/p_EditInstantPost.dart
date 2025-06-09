import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_mate/services/upload_service.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:flutter/services.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';



class p_EditInstantPost extends StatefulWidget {
  final String docId; // Accept document ID for fetching data

  const p_EditInstantPost({Key? key, required this.docId}) : super(key: key);

  @override
  _p_EditInstantPostState createState() => _p_EditInstantPostState();
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

class _p_EditInstantPostState extends State<p_EditInstantPost> {
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

  List<String> stateOptions = [];
  List<String> selectedStates = [];
  List<String> expertiseOptions = [];
  List<String> selectedExpertiseFields = [];
  List<TitleWithDescriptions> entries = [];
  String? IPTitleError;
  String? priceError;
  bool isEditing = true;

  String? selectedStatesError;
  String? selectedExpertiseError;


  @override
  void initState() {
    super.initState();
    _loadSPData().then((_) {
      _fetchIPData();
    });
  }

  Future<void> _fetchIPData() async {
    DocumentSnapshot snapshot =
    await _firestore.collection('instant_booking').doc(widget.docId).get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      setState(() {
        titleController.text = data['IPTitle'] ?? '';
        priceController.text = (data['IPPrice'] ?? '').toString();
        _imageUrls = List<String>.from(data['IPImage'] ?? []);
        selectedStates = List<String>.from(data['ServiceStates'] ?? []);
        selectedExpertiseFields = List<String>.from(data['ServiceCategory'] ?? []);

        // Ensure the fetched values exist in the options lists
        // selectedStates = List<String>.from(data['ServiceStates'] ?? [])
        //     .where((state) => stateOptions.contains(state))
        //     .toList();
        // selectedExpertiseFields = List<String>.from(data['ServiceCategory'] ?? [])
        //     .where((category) => expertiseOptions.contains(category))
        //     .toList();

        entries = (data['IPDescriptions'] as List<dynamic>?)
            ?.map((entry) => TitleWithDescriptions(
          title: entry['title'],
          descriptions: List<String>.from(entry['descriptions']),
        ))
            .toList() ??
            [];
      });

      // 🔥 Force UI rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }



  void validatePrice() {
    setState(() {
      priceError = priceController.text.trim().isEmpty ? "Price is required!" : null;
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
      setState(() => _images.addAll(selectedImages)); // ✅ Temporarily store local images

      UploadService uploadService = UploadService();

      // ✅ Upload images in parallel
      List<Future<String?>> uploadTasks = selectedImages.map((imageFile) {
        return uploadService.uploadImage(imageFile);
      }).toList();

      List<String?> uploadedUrls = await Future.wait(uploadTasks);

      // ✅ Remove null URLs
      uploadedUrls.removeWhere((url) => url == null);

      // ✅ Update state: add URLs & remove local images
      setState(() {
        _imageUrls.addAll(uploadedUrls.cast<String>());
        _images.clear(); // ✅ Clear local images after successful upload
      });
    }
  }


  void _removeImage(int index) {
    setState(() {
      if (index < _imageUrls.length) {
        // ✅ Removing an uploaded image
        _imageUrls.removeAt(index);
      } else {
        // ✅ Removing a newly picked image
        int localIndex = index - _imageUrls.length; // Adjust index for _images
        _images.removeAt(localIndex);
      }
    });
  }



  Future<void> updateInstantPost() async {

    if (widget.docId.isEmpty) return;
    // setState(() {
    //   selectedStatesError = selectedStates.isEmpty ? "Please select at least one operation state!" : null;
    //   selectedExpertiseError = selectedExpertiseFields.isEmpty ? "Please select at least one expertise field!" : null;
    // });


    setState(() {
      selectedStatesError = selectedStates.isEmpty ? "Please select at least one operation state!" : null;
      selectedExpertiseError = selectedExpertiseFields.isEmpty ? "Please select at least one expertise field!" : null;

      print("selectedStatesError: $selectedStatesError");
      print("selectedExpertiseError: $selectedExpertiseError");
    });

    if (selectedStates.isEmpty || selectedExpertiseFields.isEmpty) {
      ReusableSnackBar(
        context,
        selectedStates.isEmpty && selectedExpertiseFields.isEmpty
            ? "Please select at least one operation state and one service category."
            : selectedStates.isEmpty
            ? "Please select at least one operation state."
            : "Please select at least one service category.",
        icon: Icons.warning,
        iconColor: Colors.orange,
      );
      return;
    }


    if (userId == null) {
      ReusableSnackBar(
          context,
          "User not found. Please log in again.",
          icon: Icons.warning,
          iconColor: Colors.orange
      );
      return;
    }

    // ✅ Validate if each title has at least one description
    bool hasValidDescriptions = entries.every((entry) => entry.descriptionControllers.isNotEmpty);

    if (entries.isEmpty || !hasValidDescriptions) {
      ReusableSnackBar(
          context,
          "Each title must have at least one description.",
          icon: Icons.warning,
          iconColor: Colors.orange
      );
      return;
    }

    if (IPTitleError != null ||
        titleController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
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

    // Show loading dialog (blocking UI until post is added)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Add to Firestore
      await _firestore.collection('instant_booking').doc(widget.docId).update({
        // 'userId': userId,
        // 'SPname': spName,
        'SPimageURL': spImageUrl,
        'IPImage': _imageUrls,
        'IPTitle': titleController.text.trim(),
        'IPPrice': int.tryParse(priceController.text.trim()) ?? 0,
        'IPDescriptions': entries.map((entry) => entry.toMap()).toList(),
        'ServiceStates': List.from(selectedStates),
        'ServiceCategory': List.from(selectedExpertiseFields),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.pop(context);

      // Notify user
      ReusableSnackBar(
        context,
        "Instant Booking Post Updated Successfully!",
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
          "Edit Instant Booking Post",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Scrollable uploaded images
            if (_imageUrls.isNotEmpty || _images.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length + _images.length,
                  itemBuilder: (context, index) {
                    final isNetworkImage = index < _imageUrls.length;

                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => FullScreenImageViewer(
                                imageUrls: _imageUrls,
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
                                image: isNetworkImage
                                    ? NetworkImage(_imageUrls[index])
                                    : FileImage(_images[index - _imageUrls.length]) as ImageProvider,
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
              errorMessage: IPTitleError, // ✅ Dynamic error message
              onChanged: (value) {
                setState(() {
                  IPTitleError = value.trim().isEmpty ? "Title of the service is required!" : null;
                });
              },
            ),

            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Price",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                Text(
                  "(Only accept whole number e.g 12)",
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
                      priceError = value.trim().isEmpty ? "Price is required!" : null;
                    });
                  },
                ),
              ],
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
                  key: ValueKey(selectedStates.hashCode), // Force rebuild when selectedStates change
                  options: stateOptions, // ✅ This ensures options are loaded
                  selectedValues: selectedStates, // ✅ Creates a fresh instance
                  isRequired: true,
                  requiredMessage: "Please select at least one operation state!",
                  onSelected: (selectedList) {
                    setState(() {
                      selectedStates = List.from(selectedList); // ✅ Ensure it's a new instance
                    });
                  },
                  onValidation: (error) {
                    setState(() {
                      selectedStatesError = error;
                    });
                  },
                ),
                if (selectedStatesError != null) // 🔥 Ensure this error message is rendered
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      selectedStatesError!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
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
                  key: ValueKey(selectedExpertiseFields.hashCode), // Force rebuild when selectedExpertiseFields change
                  options: expertiseOptions, // This ensures options are loaded
                  selectedValues: selectedExpertiseFields, // Creates a fresh instance
                  isSingleSelect: true,
                  isRequired: true,
                  requiredMessage: "Please select one category",
                  onSelected: (newSelection) {
                    setState(() {
                      selectedExpertiseFields = List.from(newSelection); // ✅ Ensure it's a new instance
                    });
                  },
                  onValidation: (error) {
                    setState(() {
                      selectedExpertiseError = error;
                    });
                  },
                ),
                if (selectedExpertiseError != null) // 🔥 Ensure this error message is rendered
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      selectedExpertiseError!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),

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
                "Update Post",
                    () async {
                  updateInstantPost();
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}