import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class p_FilterPromotionPost extends StatefulWidget {
  final String initialSearchQuery;
  final List<String> initialCategories;
  final List<String> initialStates;
  final RangeValues initialPriceRange;
  final String? initialSortOrder; // ✅ Allow null values
  final RangeValues initialDiscountRange;
  final String? initialPostType;


  const p_FilterPromotionPost({
    Key? key,
    required this.initialSearchQuery,
    required this.initialCategories,
    required this.initialStates,
    required this.initialPriceRange,
    this.initialSortOrder, // ✅ Now accepts null
    this.initialDiscountRange = const RangeValues(0, 100), // ✅ Default price range
    this.initialPostType,
  }) : super(key: key);

  @override
  _p_FilterPromotionPostState createState() => _p_FilterPromotionPostState();
}

class _p_FilterPromotionPostState extends State<p_FilterPromotionPost> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId;

  late TextEditingController _searchController;
  List<String> categories = [];
  List<String> selectedCategories = [];
  List<String> states = [];
  List<String> selectedStates = [];
  RangeValues _priceRange = RangeValues(0, 1000);
  RangeValues _discountRange = RangeValues(0, 100);
  String? selectedSortOrder; // Can be null when nothing is selected
  RangeValues selectedDiscountRange = RangeValues(0, 100); // ✅ Store price range
  String? selectedPostType = "No selected"; // ✅ Neutral starting state

  // final List<String> categories = [
  //   "Cleaning", "Electrical", "Plumbing", "Painting",
  //   "Door Install", "Roofing", "Flooring", "Home Security",
  //   "Renovation", "Others"
  // ];
  //
  // final List<String> states = [
  //   "Perlis", "Kedah", "Penang", "Perak", "Selangor",
  //   "Negeri Sembilan", "Melaka", "Johor",
  //   "Terengganu", "Kelantan", "Pahang", "Sabah", "Sarawak"
  // ];

  Future<void> _loadSPData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
      DocumentSnapshot snapshot =
      await _firestore
          .collection('service_providers')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          // states = (data['selectedStates'] as List<dynamic>?)?.cast<String>() ?? [];
          states =  List<String>.from(data['selectedStates'] ?? []);  // ✅ Only pre-selected states
          selectedStates = List.from(states);
          // categories = (data['selectedExpertiseFields'] as List<dynamic>?)?.cast<String>() ?? [];
          categories = List<String>.from(data['selectedExpertiseFields'] ?? []); // ✅ Only pre-selected categories
          selectedCategories = List.from(categories);
        });
      }
    }
  }


  final List<String> postType = ["No selected", "Active", "Inactive"];
  final List<String> sortOptions = [ "Random" ,"Newest", "Oldest"]; // ✅ Sorting options

  @override
  void initState() {
    super.initState();
    _loadSPData(); // ✅ Load service provider data on screen startup
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    selectedCategories = widget.initialCategories;
    selectedStates = widget.initialStates;
    _priceRange = widget.initialPriceRange;
    _discountRange = widget.initialDiscountRange;
    selectedSortOrder = widget.initialSortOrder; // ✅ Initialize sorting order
    selectedPostType = widget.initialPostType ?? "No selected"; // ✅ Fixed line
  }

  void _applyFilters() {
    Navigator.pop(context, {
      "searchQuery": _searchController.text,
      "selectedCategories": selectedCategories,
      "selectedStates": selectedStates,
      "priceRange": _priceRange,
      "discountRange": _discountRange,
      "sortOrder": selectedSortOrder, // ✅ Pass sorting order
      "postType": selectedPostType,
    });
  }

  Widget priceBarFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Service Price",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(height: 2),
              Text(
                "( Adjust the slider to filter posts by service price range. )",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("RM${_priceRange.start.toInt()}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("RM${_priceRange.end.toInt()}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Color(0xFF464E65),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Colors.white,
            overlayColor: Color(0xFF464E65).withOpacity(0.2),
            valueIndicatorColor: Color(0xFF464E65),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
            trackHeight: 5,
          ),
          child: RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000,
            labels: RangeLabels(
              "RM${_priceRange.start.toInt()}",
              "RM${_priceRange.end.toInt()}",
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget discountBarFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Discount Percentage",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(height: 2),
              Text(
                "( Adjust the slider to filter posts by discount percentage. )",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${_discountRange.start.toInt()}%",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("${_discountRange.end.toInt()}%",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Color(0xFF464E65),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Colors.white,
            overlayColor: Color(0xFF464E65).withOpacity(0.2),
            valueIndicatorColor: Color(0xFF464E65),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
            trackHeight: 5,
          ),
          child: RangeSlider(
            values: _discountRange,
            min: 0,
            max: 100,
            labels: RangeLabels(
              "${_discountRange.start.toInt()}%",
              "${_discountRange.end.toInt()}%",
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _discountRange = values;
              });
            },
          ),
        ),
      ],
    );
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
          "Filter Post",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            priceBarFilter(),

            /// **Thick Grey Divider**
            const Divider(
              color: Colors.grey, // Grey color
              thickness: 1.0, // Make it thicker
              height: 10, // Adjust spacing above and below the divider
            ),

            const SizedBox(height: 10),


            discountBarFilter(), // ✅ Show Discount Filter


            /// **Thick Grey Divider**
            const Divider(
              color: Colors.grey, // Grey color
              thickness: 1.0, // Make it thicker
              height: 10, // Adjust spacing above and below the divider
            ),

            const SizedBox(height: 10),
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
                  "(Multiple service operation states can be selected for filtering.)",
                  style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                CustomRadioGroup(
                  options: states,
                  selectedValues: selectedStates,
                  isRequired: false, // ✅ Not required
                  requiredMessage: "",
                  onSelected: (selectedList) {
                    setState(() {
                      selectedStates = selectedList;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),
            /// **Thick Grey Divider**
            const Divider(
              color: Colors.grey, // Grey color
              thickness: 1.0, // Make it thicker
              height: 10, // Adjust spacing above and below the divider
            ),

            const SizedBox(height: 10),

            // Operation State Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Service Category",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  "(Multiple types of service category can be selected for filtering.)",
                  style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                CustomRadioGroup(
                  options: categories,
                  selectedValues: selectedCategories,
                  isRequired: false, // ✅ Not required
                  requiredMessage: "",
                  onSelected: (selectedList) {
                    setState(() {
                      selectedCategories = selectedList;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),
            /// **Thick Grey Divider**
            const Divider(
              color: Colors.grey, // Grey color
              thickness: 1.0, // Make it thicker
              height: 10, // Adjust spacing above and below the divider
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedSortOrder,
              decoration: InputDecoration(
                labelText: "Post Order (Random/Newest/Oldest)",
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                filled: true,
                fillColor: Colors.white, // White background
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Better spacing
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded border
                  borderSide: BorderSide(color: Color(0xFF464E65), width: 1.5), // Custom border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF464E65), width: 1.5), // Normal state border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF464E65), width: 2), // Highlighted when selected
                ),
              ),
              dropdownColor: Colors.white, // Ensures dropdown matches the field
              icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF464E65)), // Custom dropdown icon color
              style: TextStyle(fontSize: 16, color: Colors.black87), // Text styling
              items: sortOptions
                  .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option, style: TextStyle(fontSize: 16)),
              ))
                  .toList(),
              onChanged: (value) => setState(() => selectedSortOrder = value ?? "Newest"),
            ),

            const SizedBox(height: 10),
            /// **Thick Grey Divider**
            const Divider(
              color: Colors.grey, // Grey color
              thickness: 1.0, // Make it thicker
              height: 10, // Adjust spacing above and below the divider
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedPostType,
              decoration: InputDecoration(
                labelText: "Post Type (Active/Inactive)",
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF464E65), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF464E65), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF464E65), width: 2),
                ),
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF464E65)),
              style: TextStyle(fontSize: 16, color: Colors.black87),
              items: postType.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type, style: TextStyle(fontSize: 16)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPostType = value ?? "No selected";
                });
              },
            ),
            SizedBox(height: 20),

            dk_button(
              context, "Apply Filters",
              _applyFilters,
            ),
          ],
        ),
      ),
    );
  }
}


