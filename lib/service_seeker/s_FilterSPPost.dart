import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class s_FilterSPPost extends StatefulWidget {
  final String initialSearchQuery;
  final List<String> initialCategories;
  final List<String> initialStates;
  // final RangeValues initialPriceRange;
  final String? initialSortOrder; // ✅ Allow null values

  const s_FilterSPPost({
    Key? key,
    required this.initialSearchQuery,
    required this.initialCategories,
    required this.initialStates,
    // required this.initialPriceRange,
    this.initialSortOrder, // ✅ Now accepts null
  }) : super(key: key);

  @override
  _s_FilterSPPostState createState() => _s_FilterSPPostState();
}

class _s_FilterSPPostState extends State<s_FilterSPPost> {
  late TextEditingController _searchController;
  List<String> selectedCategories = [];
  List<String> selectedStates = [];
  // RangeValues _priceRange = RangeValues(0, 1000);
  String? selectedSortOrder; // Can be null when nothing is selected


  final List<String> categories = [
    "Cleaning", "Electrical", "Plumbing", "Painting",
    "Door Install", "Roofing", "Flooring", "Home Security",
    "Renovation", "Others"
  ];

  final List<String> states = [
    "Perlis", "Kedah", "Penang", "Perak", "Selangor",
    "Negeri Sembilan", "Melaka", "Johor",
    "Terengganu", "Kelantan", "Pahang", "Sabah", "Sarawak"
  ];

  final List<String> sortOptions = [ "Random" ,"Newest", "Oldest"]; // ✅ Sorting options

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    selectedCategories = widget.initialCategories;
    selectedStates = widget.initialStates;
    // _priceRange = widget.initialPriceRange;
    selectedSortOrder = widget.initialSortOrder; // ✅ Initialize sorting order

  }

  void _applyFilters() {
    Navigator.pop(context, {
      "searchQuery": _searchController.text,
      "selectedCategories": selectedCategories,
      "selectedStates": selectedStates,
      // "priceRange": _priceRange,
      "sortOrder": selectedSortOrder, // ✅ Pass sorting order
    });
  }

  // Widget priceBarFilter() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: <Widget>[
  //       Padding(
  //         padding: const EdgeInsets.all(0.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               "Budget",
  //               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
  //             ),
  //             const SizedBox(height: 2),
  //             Text(
  //               "(Adjust the slider to filter posts with your preferred budget.)",
  //               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
  //             ),
  //           ],
  //         ),
  //       ),
  //
  //       const SizedBox(height: 10),
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 20),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text("RM${_priceRange.start.toInt()}",
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //             Text("RM${_priceRange.end.toInt()}",
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //           ],
  //         ),
  //       ),
  //       SliderTheme(
  //         data: SliderTheme.of(context).copyWith(
  //           activeTrackColor: Color(0xFFfb9798),
  //           inactiveTrackColor: Colors.grey.shade300,
  //           thumbColor: Colors.white,
  //           overlayColor: Color(0xFFfb9798).withOpacity(0.2),
  //           valueIndicatorColor: Color(0xFFfb9798),
  //           thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
  //           trackHeight: 5,
  //         ),
  //         child: RangeSlider(
  //           values: _priceRange,
  //           min: 0,
  //           max: 1000,
  //           labels: RangeLabels(
  //             "RM${_priceRange.start.toInt()}",
  //             "RM${_priceRange.end.toInt()}",
  //           ),
  //           onChanged: (RangeValues values) {
  //             setState(() {
  //               _priceRange = values;
  //             });
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: Color(0xFFfb9798),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Filter Service Providers",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 25,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            // priceBarFilter(),

            // /// **Thick Grey Divider**
            // const Divider(
            //   color: Colors.grey, // Grey color
            //   thickness: 1.0, // Make it thicker
            //   height: 10, // Adjust spacing above and below the divider
            // ),
            //
            // const SizedBox(height: 10),
            // // Operation State Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Service Operation State",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  "(Select one or more service operation states to filter and find service providers that match your need.)",
                  style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                CustomRadioGroup(
                  options: states,
                  selectedValues: selectedStates,
                  activeColor: Color(0xFFfb9798), // Optional custom colors
                  inactiveColor: Color(0xFFfb9798),
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
                  "(Choose one or more service categories to filter and discover relevant service providers.)",
                  style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                CustomRadioGroup(
                  options: categories,
                  selectedValues: selectedCategories,
                  activeColor: Color(0xFFfb9798), // Optional custom colors
                  inactiveColor: Color(0xFFfb9798),
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
                  borderSide: BorderSide(color: Color(0xFFfb9798), width: 1.5), // Custom border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFfb9798), width: 1.5), // Normal state border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFfb9798), width: 2), // Highlighted when selected
                ),
              ),
              dropdownColor: Colors.white, // Ensures dropdown matches the field
              icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFFfb9798)), // Custom dropdown icon color
              style: TextStyle(fontSize: 16, color: Colors.black87), // Text styling
              items: sortOptions
                  .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option, style: TextStyle(fontSize: 16)),
              ))
                  .toList(),
              onChanged: (value) => setState(() => selectedSortOrder = value ?? "Random"),
            ),



            SizedBox(height: 20),

            pk_button(
              context, "Apply Filters",
              _applyFilters,
            ),
          ],
        ),
      ),
    );
  }
}


