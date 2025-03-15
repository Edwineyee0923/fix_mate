import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_mate/services/upload_service.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:flutter/services.dart';


class p_EditInstantPost extends StatefulWidget {
  @override
  _p_EditInstantPostState createState() => _p_EditInstantPostState();
}

class TitleWithDescriptions {
  String title;
  List<String> descriptions;

  TitleWithDescriptions({required this.title, required this.descriptions});

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "descriptions": descriptions,
    };
  }
}


class _p_EditInstantPostState extends State<p_EditInstantPost> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  List<String> _imageUrls = [];

  File? _image;
  String? _imageUrl;
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
    _loadSPData();
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
      entries[titleIndex].descriptions.add("");
    });
  }

  void removeDescriptionField(int titleIndex, int descIndex) {
    setState(() {
      entries[titleIndex].descriptions.removeAt(descIndex);
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


  Future<void> addInstantPost() async {
      setState(() {
        selectedStatesError = selectedStates.isEmpty ? "Please select at least one operation state!" : null;
        selectedExpertiseError = selectedExpertiseFields.isEmpty ? "Please select at least one expertise field!" : null;
      });

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not found. Please log in again.")));
      return;
    }

    print("Adding post for userId: $userId"); // ✅ Debugging

    await _firestore.collection('instant_booking').add({
      'userId': userId,
      'SPname': spName,
      'SPimageURL': spImageUrl,
      'IPImage': _imageUrls,
      'IPTitle': titleController.text.trim(),
      'IPPrice': int.tryParse(priceController.text.trim()) ?? 0, // ✅ Convert to int
      'IPDescriptions': entries.map((entry) => entry.toMap()).toList(),
      'ServiceStates': List.from(selectedStates),
      'ServiceCategory': List.from(selectedExpertiseFields),
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Instant Booking Post Added Successfully!")));
    Navigator.pop(context);
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
          "Add Instant Booking Post",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
                        Container(
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
                        Positioned(
                          top: 6,
                          right: 15,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: BoxDecoration(
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
                      IPTitleError = titleController.text.trim().isEmpty ? "Title of the service is required!" : null;
                      print("Current text: $value");
                      print("Current error: $IPTitleError");
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
                  "(May select more than one service category.)",
                  style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                CustomRadioGroup(
                  options: expertiseOptions, // ✅ This ensures options are loaded
                  selectedValues: selectedExpertiseFields, // ✅ Creates a fresh instance
                  isRequired: true,
                  requiredMessage: "Please select at least one service category!",
                  onSelected: (newSelection) {
                    setState(() {
                      selectedExpertiseFields = List.from(newSelection); // ✅ Ensure it's a new instance
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
            SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(entries.length, (titleIndex) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Input
                      TextField(
                        decoration: InputDecoration(
                          labelText: "Title",
                          hintText: "e.g. Clog Removal",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {
                          entries[titleIndex].title = value;
                        }),
                      ),

                      SizedBox(height: 10),

                      // Description Inputs
                      ...List.generate(entries[titleIndex].descriptions.length, (descIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: "Description ${descIndex + 1}",
                                    hintText: "e.g. Quick and thorough clearing of blockages...",
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: null,
                                  onChanged: (value) => setState(() {
                                    entries[titleIndex].descriptions[descIndex] = value;
                                  }),
                                ),
                              ),
                              SizedBox(width: 10),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  removeDescriptionField(titleIndex, descIndex);
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
                          onPressed: () => addDescriptionField(titleIndex),
                          child: Text("+ Add Description"),
                        ),
                      ),

                      // Remove Title Section Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => removeTitleEntry(titleIndex),
                          child: Text("Remove Title", style: TextStyle(color: Colors.red)),
                        ),
                      ),

                      Divider(),
                    ],
                  );
                }),

                SizedBox(height: 20),
              ],
            ),

            ElevatedButton(
                onPressed: addTitleEntry,
                child: Text("+ Add Title")),
            ElevatedButton(
              onPressed: addInstantPost,
              child: Text("Submit Post"),
            ),
          ],
        ),
      ),
    );
  }
}