import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';


// Uploads an image file to Cloudinary and returns the secure image URL.
//
// This function:
// - Sends the image to Cloudinary using an HTTP multipart request.
// - Uses a predefined `upload_preset` to simplify the upload process.
// - Returns the URL of the uploaded image if successful.
// - Prints an error message and returns `null` if the upload fails.
class UploadService {
  final String cloudName = "dj7uux8yz";
  final String uploadPreset = "profile_upload_preset"; // Create in Cloudinary settings

  Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = json.decode(await response.stream.bytesToString());
      return responseData["secure_url"]; // Returns the uploaded image URL.
    } else {
      print("Failed to upload image");
      return null;
    }
  }
}


