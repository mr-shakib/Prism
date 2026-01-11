import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:prism/services/auth/auth_service.dart';
import 'package:prism/services/database/database_provider.dart';
import 'package:prism/services/cloudinary/cloudinary_service.dart';
import 'package:prism/themes/app_colors.dart';
import 'package:prism/pages/home_page.dart';
import 'package:prism/models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  bool _isPosting = false;
  bool _isUploadingMedia = false;
  XFile? _selectedImage;
  XFile? _selectedVideo;
  double _uploadProgress = 0.0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
    
    // Auto-focus on the text field
    Future.delayed(const Duration(milliseconds: 500), () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _postMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImage == null && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add some content to your post'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    
    setState(() {
      _isPosting = true;
      _uploadProgress = 0.0;
    });
    
    try {
      String? imageUrl;
      String? videoUrl;
      
      // Upload image if selected
      if (_selectedImage != null) {
        setState(() => _uploadProgress = 0.3);
        final postId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await _cloudinaryService.uploadPostImage(_selectedImage!, postId);
        
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }
      
      // Upload video if selected
      if (_selectedVideo != null) {
        setState(() => _uploadProgress = 0.6);
        final postId = DateTime.now().millisecondsSinceEpoch.toString();
        videoUrl = await _cloudinaryService.uploadPostVideo(_selectedVideo!, postId);
        
        if (videoUrl == null) {
          throw Exception('Failed to upload video');
        }
      }
      
      setState(() => _uploadProgress = 0.9);
      
      // Post to database
      final databaseProvider = Get.find<DatabaseProvider>();
      await databaseProvider.postMessage(
        _messageController.text.trim(),
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );
      
      setState(() => _uploadProgress = 1.0);
      
      if (mounted) {
        // Show success feedback with shimmer effect
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Post created successfully! 🎉',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        // Clear the text and media
        _messageController.clear();
        _selectedImage = null;
        _selectedVideo = null;
        _focusNode.unfocus();
        
        // Navigate back to home with smooth transition
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Get.find<NavigationController>().selectedIndex.value = 0;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to post: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
  
  Future<void> _pickImage() async {
    setState(() => _isUploadingMedia = true);
    
    try {
      final XFile? image = await _cloudinaryService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _selectedVideo = null; // Clear video if image is selected
        });
      }
    } finally {
      setState(() => _isUploadingMedia = false);
    }
  }
  
  Future<void> _pickVideo() async {
    setState(() => _isUploadingMedia = true);
    
    try {
      final XFile? video = await _cloudinaryService.pickVideoFromGallery();
      if (video != null) {
        setState(() {
          _selectedVideo = video;
          _selectedImage = null; // Clear image if video is selected
        });
      }
    } finally {
      setState(() => _isUploadingMedia = false);
    }
  }
  
  void _removeMedia() {
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = AuthService();
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header
                _buildHeader(isDark),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info
                        _buildUserInfo(isDark),
                        
                        const SizedBox(height: 24),
                        
                        // Text input
                        _buildTextInput(isDark),
                        
                        const SizedBox(height: 20),
                        
                        // Media preview
                        if (_selectedImage != null || _selectedVideo != null)
                          _buildMediaPreview(isDark),
                        
                        if (_selectedImage != null || _selectedVideo != null)
                          const SizedBox(height: 20),
                        
                        // Loading indicator with progress
                        if (_isPosting)
                          _buildUploadProgress(isDark),
                        
                        if (_isPosting)
                          const SizedBox(height: 20),
                        
                        // Media options (placeholder for future)
                        if (!_isPosting)
                          _buildMediaOptions(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              Get.find<NavigationController>().selectedIndex.value = 0;
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          Text(
            'Create Post',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          SizedBox(
            width: 80,
            child: _isPosting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: (_messageController.text.trim().isEmpty && 
                               _selectedImage == null && 
                               _selectedVideo == null) 
                        ? null 
                        : _postMessage,
                    child: Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: (_messageController.text.trim().isEmpty && 
                               _selectedImage == null && 
                               _selectedVideo == null)
                            ? (isDark ? Colors.white : Colors.black).withOpacity(0.3)
                            : Colors.blue,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(bool isDark) {
    final authService = AuthService();
    final currentUid = authService.getCurrentUid();
    
    return FutureBuilder<UserProfile?>(
      future: Get.find<DatabaseProvider>().userProfile(currentUid),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        
        return Row(
          children: [
            Hero(
              tag: 'profile_$currentUid',
              child: CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? AppColors.darkCard : Colors.grey[200],
                backgroundImage: currentUser?.profilePictureUrl != null
                    ? NetworkImage(currentUser!.profilePictureUrl!)
                    : null,
                child: currentUser?.profilePictureUrl == null
                    ? Icon(
                        Icons.person_outline,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                        size: 28,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.name ?? 'User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public,
                        size: 14,
                        color: (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Public',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextInput(bool isDark) {
    return TextField(
      controller: _messageController,
      focusNode: _focusNode,
      maxLines: null,
      minLines: 5,
      style: TextStyle(
        fontSize: 18,
        height: 1.5,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      decoration: InputDecoration(
        hintText: "What's on your mind?",
        hintStyle: TextStyle(
          fontSize: 18,
          color: (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.3),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onChanged: (value) {
        setState(() {}); // Rebuild to update post button state
      },
    );
  }

  Widget _buildMediaOptions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add to your post',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMediaButton(
                Icons.photo_outlined,
                'Photo',
                Colors.green,
                isDark,
                _isUploadingMedia ? null : () => _pickImage(),
              ),
              _buildMediaButton(
                Icons.videocam_outlined,
                'Video',
                Colors.red,
                isDark,
                _isUploadingMedia ? null : () => _pickVideo(),
              ),
              _buildMediaButton(
                Icons.emoji_emotions_outlined,
                'Feeling',
                Colors.orange,
                isDark,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feeling selector coming soon!')),
                  );
                },
              ),
              _buildMediaButton(
                Icons.location_on_outlined,
                'Location',
                Colors.blue,
                isDark,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location picker coming soon!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (value * 0.1),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _selectedImage != null
                  ? Image.file(
                      File(_selectedImage!.path),
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    )
                  : _selectedVideo != null
                      ? Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.black87,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                size: 64,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Video selected',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(),
            ),
            // Remove button
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _removeMedia,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress(bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkCard, AppColors.darkCard.withOpacity(0.8)]
                : [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 6.28 * 2,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploading your post...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_uploadProgress * 100).toInt()}% complete',
                        style: TextStyle(
                          fontSize: 13,
                          color: (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: 0.0, end: _uploadProgress),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.lerp(Colors.blue, Colors.purple, value) ?? Colors.blue,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton(
    IconData icon,
    String label,
    Color color,
    bool isDark,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
