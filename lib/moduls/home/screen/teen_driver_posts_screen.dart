import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../controller/teen_driver_posts_controller.dart';
import '../implement/teen_driver_experience_interface_impl.dart';
import '../interface/teen_driver_experience_interface.dart';
import '../model/teen_driver_experience_response_model.dart';
import 'community_screen.dart';

class TeenDriverPostsScreen extends StatefulWidget {
  const TeenDriverPostsScreen({super.key});

  @override
  State<TeenDriverPostsScreen> createState() => _TeenDriverPostsScreenState();
}

class _TeenDriverPostsScreenState extends State<TeenDriverPostsScreen> {
  late final TeenDriverPostsController _controller;
  late final SnackbarNotifier _snackbarNotifier;
  bool _initialized = false;

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmedUrl = url.trim();
    return trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (!Get.isRegistered<TeenDriverExperienceInterface>()) {
        Get.put<TeenDriverExperienceInterface>(
          TeenDriverExperienceInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
        );
      }
      _snackbarNotifier = SnackbarNotifier(context: context);
      _controller = TeenDriverPostsController(
        snackbarNotifier: _snackbarNotifier,
      );
      _controller.addListener(_onControllerUpdate);
      _controller.loadPosts();
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.removeListener(_onControllerUpdate);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xFF3F76F6);
    final posts = _controller.posts;
    final isLoading = _controller.isLoading;
    final hasLoaded = _controller.hasLoaded;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Driver posts',
          style: TextStyle(
            fontSize: (size.width * 0.055).clamp(18.0, 24.0),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
          ),
        ),
        leading: BackButton(color: const Color(0xFF222222)),
        
        // IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
                child: isLoading && !hasLoaded && posts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _controller.loadPosts,
                      child: posts.isEmpty
                          ? ListView(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.06,
                                vertical: size.height * 0.02,
                              ),
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'No teen posts yet.',
                                    style: TextStyle(color: Color(0xFF666666)),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.06,
                                vertical: size.height * 0.02,
                              ),
                              itemBuilder: (context, index) {
                                final post = posts[index];
                                return _PostCard(
                                  post: post,
                                  size: size,
                                  isValidImageUrl: _isValidImageUrl,
                                  onTap: () {
                                    debugPrint('Teen post id: ${post.id}');
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CommunityScreen(postId: post.id),
                                      ),
                                    );
                                  },
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: size.height * 0.018),
                              itemCount: posts.length,
                            ),
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: size.height * 0.02,
              ),
              child: SizedBox(
                width: double.infinity,
                height: (size.height * 0.07).clamp(48.0, 58.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Return to Home',
                    style: TextStyle(
                      fontSize: (size.width * 0.05).clamp(16.0, 20.0),
                      fontWeight: FontWeight.w600,
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
}

class _PostCard extends StatelessWidget {
  final TeenDriverExperienceResponseModel post;
  final Size size;
  final VoidCallback onTap;
  final bool Function(String? url) isValidImageUrl;

  const _PostCard({
    required this.post,
    required this.size,
    required this.onTap,
    required this.isValidImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final author = post.authorName.isNotEmpty ? post.authorName : 'Unknown';
    final mediaUrl = post.mediaUrl;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: TextStyle(
                        fontSize: (size.width * 0.048).clamp(16.0, 20.0),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${post.commentsCount} comments',
                      style: TextStyle(
                        fontSize: (size.width * 0.035).clamp(11.0, 13.0),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3F76F6),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.008),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: (size.width * 0.04).clamp(14.0, 18.0),
                    color: const Color(0xFFE53935),
                  ),
                  SizedBox(width: size.width * 0.015),
                  Text(
                    '${post.likesCount} likes',
                    style: TextStyle(
                      fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.012),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: isValidImageUrl(mediaUrl)
                    ? Image.network(
                        mediaUrl!,
                        width: double.infinity,
                        height: size.height * 0.2,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFEDEDED),
                            width: double.infinity,
                            height: size.height * 0.2,
                            child: const Center(
                              child: Icon(
                                Icons.photo,
                                color: Color(0xFF9A9A9A),
                                size: 40,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFFEDEDED),
                        width: double.infinity,
                        height: size.height * 0.2,
                        child: const Center(
                          child: Icon(
                            Icons.photo,
                            color: Color(0xFF9A9A9A),
                            size: 40,
                          ),
                        ),
                      ),
              ),
              SizedBox(height: size.height * 0.012),
              Text(
                author,
                style: TextStyle(
                  fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111111),
                ),
              ),
              SizedBox(height: size.height * 0.006),
              Text(
                post.description,
                style: TextStyle(
                  fontSize: (size.width * 0.042).clamp(13.0, 17.0),
                  color: const Color(0xFF555555),
                ),
              ),
              SizedBox(height: size.height * 0.01),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
            ],
          ),
        ),
      ),
    );
  }
}
