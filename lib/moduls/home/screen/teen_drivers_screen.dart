import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../controller/teen_driver_posts_controller.dart';
import '../implement/teen_driver_experience_interface_impl.dart';
import '../interface/teen_driver_experience_interface.dart';
import '../model/teen_driver_experience_response_model.dart';

class TeenDriversScreen extends StatefulWidget {
  const TeenDriversScreen({super.key});

  @override
  State<TeenDriversScreen> createState() => _TeenDriversScreenState();
}

class _TeenDriversScreenState extends State<TeenDriversScreen> {
  TeenDriverPostsController? _postsController;
  SnackbarNotifier? _snackbarNotifier;
  bool _initialized = false;

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  TeenDriverExperienceResponseModel? _latestPost(
    List<TeenDriverExperienceResponseModel> posts,
  ) {
    if (posts.isEmpty) return null;
    return posts.reduce((current, candidate) {
      final currentDate = current.createdAt ??
          current.updatedAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final candidateDate = candidate.createdAt ??
          candidate.updatedAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return candidateDate.isAfter(currentDate) ? candidate : current;
    });
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return 'Recently';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month/$day/$year';
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmedUrl = url.trim();
    return trimmedUrl.startsWith('http://') ||
        trimmedUrl.startsWith('https://');
  }

  void _openTeenDriverPosts() {
    Navigator.pushNamed(context, AppRoutes.teenDriverPosts);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    if (!Get.isRegistered<TeenDriverExperienceInterface>()) {
      Get.put<TeenDriverExperienceInterface>(
        TeenDriverExperienceInterfaceImpl(appPigeon: Get.find<AppPigeon>()),
      );
    }

    _snackbarNotifier = SnackbarNotifier(context: context);
    _postsController = TeenDriverPostsController(
      snackbarNotifier: _snackbarNotifier!,
    );
    _postsController!.addListener(_onControllerUpdate);
    _postsController!.loadPosts();
  }

  @override
  void dispose() {
    if (_postsController != null) {
      _postsController!.removeListener(_onControllerUpdate);
      _postsController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xFF3F76F6);
    final posts = _postsController?.posts ??
        const <TeenDriverExperienceResponseModel>[];
    final isLoading = _postsController?.isLoading ?? false;
    final latestPost = _latestPost(posts);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Teen Driver posts',
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Good Morning, John! 👋',
                      style: TextStyle(
                        fontSize: (size.width * 0.02).clamp(18.0, 24.0),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF222222),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  SizedBox(
                    height: (size.height * 0.045).clamp(34.0, 40.0),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.teenDriverAddExperience,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.02),
              _CardContainer(
                size: size,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Learning Progress',
                      style: TextStyle(
                        fontSize: (size.width * 0.05).clamp(16.0, 22.0),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: size.height * 0.015),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: 0.4,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE0E0E0),
                              valueColor: const AlwaysStoppedAnimation(
                                primaryColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Text(
                          '40%',
                          style: TextStyle(
                            fontSize: (size.width * 0.04).clamp(12.0, 16.0),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF444444),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.02),
                    Text(
                      'Lesson completed: 13/40',
                      style: TextStyle(
                        fontSize: (size.width * 0.043).clamp(13.0, 17.0),
                        color: const Color(0xFF444444),
                      ),
                    ),
                    SizedBox(height: size.height * 0.012),
                    Text(
                      'Quiz: 85%',
                      style: TextStyle(
                        fontSize: (size.width * 0.043).clamp(13.0, 17.0),
                        color: const Color(0xFF444444),
                      ),
                    ),
                    SizedBox(height: size.height * 0.012),
                    Text(
                      'Practice Hours: 28/470',
                      style: TextStyle(
                        fontSize: (size.width * 0.043).clamp(13.0, 17.0),
                        color: const Color(0xFF444444),
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    SizedBox(
                      width: double.infinity,
                      height: (size.height * 0.065).clamp(44.0, 54.0),
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(
                              context,
                              AppRoutes.learningCenter,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Continue Learning',
                          style: TextStyle(
                            fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.02),
              _CardContainer(
                size: size,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Stats',
                      style: TextStyle(
                        fontSize: (size.width * 0.05).clamp(16.0, 22.0),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    Row(
                      children: [
                        _StatTile(size: size, label: '13 Lessons'),
                        SizedBox(width: size.width * 0.03),
                        _StatTile(size: size, label: '28 Hours'),
                        SizedBox(width: size.width * 0.03),
                        _StatTile(size: size, label: '85% Score'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.02),
              _CardContainer(
                size: size,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's Next",
                      style: TextStyle(
                        fontSize: (size.width * 0.05).clamp(16.0, 22.0),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: size.height * 0.015),
                    Text(
                      'Night Driving Lessons',
                      style: TextStyle(
                        fontSize: (size.width * 0.047).clamp(15.0, 20.0),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: size.height * 0.008),
                    Text(
                      'Duration: 15mins',
                      style: TextStyle(
                        fontSize: (size.width * 0.043).clamp(13.0, 17.0),
                        color: const Color(0xFF555555),
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    SizedBox(
                      width: double.infinity,
                      height: (size.height * 0.06).clamp(42.0, 52.0),
                      child: ElevatedButton.icon(
                        onPressed: () => _showMessage(context, 'Start lesson'),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          'Start',
                          style: TextStyle(
                            fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent posts',
                    style: TextStyle(
                      fontSize: (size.width * 0.04).clamp(16.0, 22.0),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF222222),
                    ),
                  ),
                  TextButton(
                    onPressed: _openTeenDriverPosts,
                    child: Text(
                      'See more',
                      style: TextStyle(
                        fontSize: (size.width * 0.042).clamp(12.0, 16.0),
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _openTeenDriverPosts,
                child: _CardContainer(
                  size: size,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Teen driver posts',
                            style: TextStyle(
                              fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF222222),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: primaryColor,
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.012),
                      if (isLoading && posts.isEmpty)
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: size.width * 0.03),
                            Text(
                              'Loading posts...',
                              style: TextStyle(
                                fontSize:
                                    (size.width * 0.04).clamp(12.0, 16.0),
                                color: const Color(0xFF555555),
                              ),
                            ),
                          ],
                        )
                      else if (latestPost == null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No posts yet',
                              style: TextStyle(
                                fontSize:
                                    (size.width * 0.043).clamp(13.0, 17.0),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF222222),
                              ),
                            ),
                            SizedBox(height: size.height * 0.008),
                            Text(
                              'Tap to view all posts',
                              style: TextStyle(
                                fontSize:
                                    (size.width * 0.04).clamp(12.0, 16.0),
                                color: const Color(0xFF555555),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total posts: ${posts.length}',
                              style: TextStyle(
                                fontSize:
                                    (size.width * 0.04).clamp(12.0, 16.0),
                                color: const Color(0xFF555555),
                              ),
                            ),
                            SizedBox(height: size.height * 0.01),
                            if (_isValidImageUrl(latestPost!.mediaUrl))
                              Container(
                                height: size.height * 0.18,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDEDED),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    latestPost.mediaUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: Color(0xFF9A9A9A),
                                          size: 36,
                                        ),
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            if (_isValidImageUrl(latestPost.mediaUrl))
                              SizedBox(height: size.height * 0.012),
                            Text(
                              latestPost.title.trim().isNotEmpty
                                  ? latestPost.title
                                  : 'Latest post',
                              style: TextStyle(
                                fontSize:
                                    (size.width * 0.045).clamp(14.0, 18.0),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF222222),
                              ),
                            ),
                            SizedBox(height: size.height * 0.006),
                            Text(
                              latestPost.description.trim().isNotEmpty
                                  ? latestPost.description
                                  : 'Tap to view details',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize:
                                    (size.width * 0.04).clamp(12.0, 16.0),
                                color: const Color(0xFF555555),
                              ),
                            ),
                            SizedBox(height: size.height * 0.01),
                            Text(
                              '${latestPost.authorName.trim().isNotEmpty ? latestPost.authorName : 'Unknown'} • ${_formatShortDate(latestPost.createdAt ?? latestPost.updatedAt)}',
                              style: TextStyle(
                                fontSize:
                                    (size.width * 0.04).clamp(12.0, 16.0),
                                color: const Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),
              SizedBox(
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
              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Size size;
  final Widget child;

  const _CardContainer({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  final Size size;
  final String label;

  const _StatTile({required this.size, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEFF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (size.width * 0.04).clamp(12.0, 16.0),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF444444),
          ),
        ),
      ),
    );
  }
}
