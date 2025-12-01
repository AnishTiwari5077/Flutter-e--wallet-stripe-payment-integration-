import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  // Capture image from camera
  static Future<File?> captureImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Error capturing image from camera: $e');
      return null;
    }
  }

  // Show image source dialog
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Choose Image Source',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Colors.purpleAccent,
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final image = await pickImageFromGallery();
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Colors.purpleAccent,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final image = await captureImageFromCamera();
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Convert image to Base64
  static Future<String?> convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Error converting image to base64: $e');
      return null;
    }
  }

  // ============ PERSISTENCE METHODS ============

  // Save image as Base64 to SharedPreferences
  static Future<bool> saveImageToPreferences(
    String key,
    String base64Image,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, base64Image);
    } catch (e) {
      debugPrint('Error saving image to preferences: $e');
      return false;
    }
  }

  // Get saved Base64 image from SharedPreferences
  static Future<String?> getImageFromPreferences(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('Error getting image from preferences: $e');
      return null;
    }
  }

  // Delete image from SharedPreferences
  static Future<bool> deleteImageFromPreferences(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      debugPrint('Error deleting image from preferences: $e');
      return false;
    }
  }

  // Complete flow: Pick, Convert, and Save image
  static Future<String?> pickAndSaveImage(
    BuildContext context,
    String storageKey,
  ) async {
    final imageFile = await showImageSourceDialog(context);
    if (imageFile == null) return null;

    final base64Image = await convertImageToBase64(imageFile);
    if (base64Image == null) return null;

    final saved = await saveImageToPreferences(storageKey, base64Image);
    if (!saved) {
      debugPrint('Failed to save image');
      return null;
    }

    return base64Image;
  }

  // Display Base64 image widget
  static Widget displayBase64Image(
    String? base64String, {
    double width = 100,
    double height = 100,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    if (base64String == null || base64String.isEmpty) {
      return placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Icon(Icons.person, color: Colors.grey, size: 40),
          );
    }

    try {
      return Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[800],
                child: const Icon(Icons.error, color: Colors.red),
              );
        },
      );
    } catch (e) {
      debugPrint('Error displaying base64 image: $e');
      return placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Icon(Icons.error, color: Colors.red),
          );
    }
  }
}
