/*

CLOUDINARY SERVICE

This handles image uploads to Cloudinary

---------------------------------------------------------------------

- Upload profile pictures
- Upload cover photos
- Upload post images
- Delete images

*/

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Cloudinary configuration from environment or defaults
  static String get cloudName => 
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'prism_profile';
  static String get uploadPreset => 
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'prism_preset';
  static String get apiKey => 
      dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  
  final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Upload profile picture to Cloudinary
  Future<String?> uploadProfilePicture(XFile imageFile, String userId) async {
    try {
      print('Cloudinary Config: cloudName=$cloudName, uploadPreset=$uploadPreset');
      print('Uploading profile picture for user: $userId');
      
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'prism/profile_pictures',
          publicId: 'profile_$userId',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      print('Upload successful: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      print('Make sure your upload preset "$uploadPreset" exists and is set to Unsigned mode in Cloudinary dashboard');
      return null;
    }
  }

  /// Upload cover photo to Cloudinary
  Future<String?> uploadCoverPhoto(XFile imageFile, String userId) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'prism/cover_photos',
          publicId: 'cover_$userId',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('Error uploading cover photo: $e');
      return null;
    }
  }

  /// Upload post image to Cloudinary
  Future<String?> uploadPostImage(XFile imageFile, String postId) async {
    try {
      print('Uploading post image to prism_posts preset');
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'prism_posts',
          publicId: 'post_${postId}_${DateTime.now().millisecondsSinceEpoch}',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      print('Post image uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('Error uploading post image: $e');
      return null;
    }
  }

  /// Upload post video to Cloudinary
  Future<String?> uploadPostVideo(XFile videoFile, String postId) async {
    try {
      print('Uploading post video to prism_posts preset');
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          videoFile.path,
          folder: 'prism_posts',
          publicId: 'video_${postId}_${DateTime.now().millisecondsSinceEpoch}',
          resourceType: CloudinaryResourceType.Video,
        ),
      );
      
      print('Post video uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('Error uploading post video: $e');
      return null;
    }
  }

  /// Pick video from gallery
  Future<XFile?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      return video;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  /// Pick video from camera
  Future<XFile?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      return video;
    } catch (e) {
      print('Error recording video: $e');
      return null;
    }
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      // Note: Deleting requires authenticated requests
      // You might need to implement a backend API for secure deletion
      // For now, this is a placeholder
      print('Delete image with publicId: $publicId');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(
    String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!imageUrl.contains('cloudinary')) return imageUrl;
    
    // Insert transformations into the URL
    final transformations = <String>[];
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    
    final transformation = transformations.join(',');
    return imageUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }
}
