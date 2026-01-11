import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prism/helper/naviagte_pages.dart';
import 'package:prism/models/user.dart';
import 'package:prism/services/auth/auth_service.dart';
import 'package:prism/services/cloudinary/cloudinary_service.dart';
import 'package:prism/services/database/database_provider.dart';
import 'package:prism/services/chat/chat_service.dart';
import 'package:prism/screens/settings_screen.dart';
import 'package:prism/screens/chat_conversation_screen.dart';
import 'package:prism/themes/app_colors.dart';
import 'package:prism/themes/app_styles.dart';

/// Ultra-Modern Minimalist Profile Page
/// Design Philosophy: Clean, Spatial, Floating Elements, Micro-interactions
class ModernProfilePage extends StatefulWidget {
  final String uid;
  
  const ModernProfilePage({
    super.key,
    required this.uid,
  });

  @override
  State<ModernProfilePage> createState() => _ModernProfilePageState();
}

class _ModernProfilePageState extends State<ModernProfilePage> {
  late final databaseProvider = Get.find<DatabaseProvider>();
  final cloudinaryService = CloudinaryService();
  
  UserProfile? user;
  String currentUserId = AuthService().getCurrentUid();
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isUploadingImage = false;
  int _selectedTabIndex = 0;
  
  final bioTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadUser();
    checkIfFollowing();
  }

  @override
  void dispose() {
    bioTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadUser() async {
    try {
      user = await databaseProvider.userProfile(widget.uid);
    } catch (e) {
      print('Error loading user: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> createUserProfile() async {
    if (widget.uid != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot create profile for other users')),
      );
      return;
    }

    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your profile is missing. Let\'s create it!'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final auth = AuthService();
        final email = auth.getCurrentUserEmail() ?? 'user@example.com';
        
        await databaseProvider.saveUserInfoInFirebase(
          name: nameController.text,
          email: email,
        );
        
        await loadUser();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> checkIfFollowing() async {
    _isFollowing = databaseProvider.isFollowing(widget.uid);
    setState(() {});
  }

  Future<void> toggleFollow() async {
    if (_isFollowing) {
      await databaseProvider.unfollowUser(widget.uid);
    } else {
      await databaseProvider.followUser(widget.uid);
    }
    await checkIfFollowing();
  }

  void _showEditBioSheet() {
    bioTextController.text = user?.bio ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditBioSheet(),
    );
  }

  Future<void> saveBio() async {
    setState(() => _isLoading = true);
    await databaseProvider.updateBio(bioTextController.text);
    await loadUser();
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  Future<void> uploadProfilePicture() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageSourceSheet(),
    );

    if (source == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final XFile? imageFile = source == ImageSource.camera
          ? await cloudinaryService.pickImageFromCamera()
          : await cloudinaryService.pickImageFromGallery();

      if (imageFile == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final String? imageUrl = await cloudinaryService.uploadProfilePicture(
        imageFile,
        widget.uid,
      );

      if (imageUrl != null) {
        await databaseProvider.updateProfilePicture(imageUrl);
        await loadUser();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: _buildLoadingState(),
      );
    }
    
    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(title: const Text('Profile')),
        body: _buildErrorState(isDark),
      );
    }
    
    final allUserPost = databaseProvider.filterUserPosts(widget.uid);
    final isOwnProfile = widget.uid == currentUserId;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
              // Back button for other users' profiles
              if (!isOwnProfile)
                SliverToBoxAdapter(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              
              // Floating Profile Card
              SliverToBoxAdapter(
                child: _buildFloatingProfileCard(isDark, isOwnProfile),
              ),
              
              // Stats Section
              SliverToBoxAdapter(
                child: _buildMinimalStats(isDark),
              ),
              
              // Action Buttons
              SliverToBoxAdapter(
                child: _buildFloatingActions(isDark, isOwnProfile),
              ),
              
              // Bio Section
              if (user?.bio?.isNotEmpty == true)
                SliverToBoxAdapter(
                  child: _buildMinimalBio(isDark),
                ),
              
              // Minimal Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  child: _buildMinimalTabBar(isDark),
                  isDark: isDark,
                ),
              ),
              
              // Content
              SliverToBoxAdapter(
                child: _buildTabContent(allUserPost, isDark),
              ),
              
              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
      ),
    );
  }

  Widget _buildMinimalIconButton(IconData icon, VoidCallback onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingProfileCard(bool isDark, bool isOwnProfile) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
            // Profile Picture with minimal design
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[100],
                      backgroundImage: user?.profilePictureUrl != null
                          ? NetworkImage(
                              cloudinaryService.getOptimizedImageUrl(
                                user!.profilePictureUrl!,
                                width: 200,
                                height: 200,
                              ),
                            )
                          : null,
                      child: user?.profilePictureUrl == null
                          ? Icon(
                              Icons.person_outline,
                              size: 40,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                            )
                          : null,
                    ),
                  ),
                ),
                
                if (isOwnProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isUploadingImage ? null : uploadProfilePicture,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: _isUploadingImage
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? AppColors.darkCard : Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16,
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Name with minimal verified badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    user?.name ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Text(
              '@${user?.username ?? ''}',
              style: TextStyle(
                fontSize: 15,
                color: (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildMinimalStats(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            '${databaseProvider.filterUserPosts(widget.uid).length}',
            'Posts',
            isDark,
          ),
          Container(
            width: 1,
            height: 30,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          ),
          _buildStatItem(
            '${user?.followers.length ?? 0}',
            'Followers',
            isDark,
          ),
          Container(
            width: 1,
            height: 30,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          ),
          _buildStatItem(
            '${user?.following.length ?? 0}',
            'Following',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActions(bool isDark, bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(
            flex: isOwnProfile ? 1 : 3,
            child: _buildMinimalButton(
              label: isOwnProfile ? 'Edit' : (_isFollowing ? 'Following' : 'Follow'),
              onTap: isOwnProfile ? _showEditBioSheet : toggleFollow,
              isPrimary: !isOwnProfile && !_isFollowing,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          if (isOwnProfile)
            Expanded(
              flex: 1,
              child: _buildMinimalButton(
                label: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(),
                    ),
                  );
                },
                isPrimary: false,
                isDark: isDark,
              ),
            )
          else
            Expanded(
              flex: 2,
              child: _buildMinimalButton(
                label: 'Message',
                onTap: () async {
                  try {
                    final chatService = ChatService();
                    final chatId = await chatService.getOrCreateChat(widget.uid);
                    if (context.mounted && user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatConversationScreen(
                            otherUser: user!,
                            chatId: chatId,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to start chat: $e')),
                      );
                    }
                  }
                },
                isPrimary: false,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimalButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isPrimary 
                ? (isDark ? AppColors.darkText : AppColors.lightText)
                : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isPrimary 
                    ? (isDark ? AppColors.darkCard : Colors.white)
                    : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBio(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Text(
        user?.bio ?? '',
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: isDark ? AppColors.darkText : AppColors.lightText,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMinimalTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildMinimalTab(Icons.grid_on_outlined, 0, isDark),
          _buildMinimalTab(Icons.video_library_outlined, 1, isDark),
          _buildMinimalTab(Icons.bookmark_border, 2, isDark),
        ],
      ),
    );
  }

  Widget _buildMinimalTab(IconData icon, int index, bool isDark) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTabIndex = index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isSelected
                  ? (isDark ? AppColors.darkText : AppColors.lightText)
                  : (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List allUserPost, bool isDark) {
    if (_selectedTabIndex == 0) {
      return _buildPostsGrid(allUserPost, isDark);
    } else if (_selectedTabIndex == 1) {
      return _buildEmptyState(Icons.video_library_outlined, 'No Videos', isDark);
    } else {
      return _buildEmptyState(Icons.bookmark_border, 'No Saved Posts', isDark);
    }
  }

  Widget _buildPostsGrid(List allUserPost, bool isDark) {
    if (allUserPost.isEmpty) {
      return _buildEmptyState(Icons.photo_camera_outlined, 'No Posts Yet', isDark);
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: allUserPost.length,
        itemBuilder: (context, index) {
          final post = allUserPost[index];
          final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
          final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => goPostPage(context, post),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Show post image if available
                    if (hasImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          post.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                                size: 32,
                              ),
                            );
                          },
                        ),
                      )
                    // Show video icon if video
                    else if (hasVideo)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: isDark ? Colors.black : Colors.white,
                            size: 32,
                          ),
                        ),
                      )
                    // Show text icon for text-only posts
                    else
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            post.message,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    
                    // Likes overlay
                    if (post.likedBy.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 12,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likedBy.length}',
                                style: TextStyle(
                                  color: isDark ? Colors.black : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message, bool isDark) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'User profile not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This user profile doesn\'t exist in the database.',
              style: TextStyle(
                fontSize: 14,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isLoading = true);
                  loadUser();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              if (widget.uid == currentUserId) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: createUserProfile,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditBioSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Edit Bio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                TextButton(
                  onPressed: saveBio,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: bioTextController,
              maxLines: 4,
              maxLength: 150,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              decoration: InputDecoration(
                hintText: 'Tell us about yourself...',
                hintStyle: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              _buildOptionItem(
                Icons.share_outlined,
                'Share Profile',
                () {},
                isDark,
              ),
              _buildOptionItem(
                Icons.link,
                'Copy Profile Link',
                () {},
                isDark,
              ),
              _buildOptionItem(
                Icons.qr_code_outlined,
                'QR Code',
                () {},
                isDark,
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title, VoidCallback onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Choose Photo Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildImageSourceOption(
              Icons.camera_alt_outlined,
              'Camera',
              'Take a new photo',
              () => Navigator.pop(context, ImageSource.camera),
              isDark,
            ),
            
            _buildImageSourceOption(
              Icons.photo_library_outlined,
              'Gallery',
              'Choose from your photos',
              () => Navigator.pop(context, ImageSource.gallery),
              isDark,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isDark ? AppColors.darkCard : Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom delegate for sticky tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isDark;

  _SliverTabBarDelegate({required this.child, required this.isDark});

  @override
  double get minExtent => 70;

  @override
  double get maxExtent => 70;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return child != oldDelegate.child || isDark != oldDelegate.isDark;
  }

}