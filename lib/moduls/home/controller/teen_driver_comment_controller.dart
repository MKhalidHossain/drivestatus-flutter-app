import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/notifiers/snackbar_notifier.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../interface/teen_driver_experience_interface.dart';
import '../model/teen_driver_comment_request_model.dart';
import '../model/teen_driver_comment_response_model.dart';

class TeenDriverCommentController extends ChangeNotifier {
  final SnackbarNotifier snackbarNotifier;

  TeenDriverCommentController({required this.snackbarNotifier});

  static final Map<String, _CommunityCache> _cacheByPostId = {};
  static const String _globalCacheKey = '__global_community__';

  String _text = '';
  bool _isSubmitting = false;
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isLiking = false;
  bool _isLiked = false;
  int _likesCount = 0;
  String _likeUserName = '';
  String _currentPostId = '';
  final List<TeenDriverCommentResponseModel> _comments = [];

  String get text => _text;
  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isLiking => _isLiking;
  bool get isLiked => _isLiked;
  int get likesCount => _likesCount;
  String get likeUserName => _likeUserName;
  bool get canSubmit => _text.isNotEmpty && !_isSubmitting;
  List<TeenDriverCommentResponseModel> get comments =>
      List.unmodifiable(_comments);

  set text(String value) {
    if (value != _text) {
      _text = value.trim();
      notifyListeners();
    }
  }

  Future<void> loadComments({String postId = ''}) async {
    final trimmedPostId = postId.trim();
    final isGlobalMode = trimmedPostId.isEmpty;

    _currentPostId = trimmedPostId;
    final cacheKey = _cacheKey(trimmedPostId);
    final cached = _cacheByPostId[cacheKey];
    if (cached != null) {
      _applyCache(cached);
      _hasLoaded = true;
      notifyListeners();
    }

    _isLoading = true;
    notifyListeners();

    final currentUser = await _getCurrentUserInfo();
    final result =
        await Get.find<TeenDriverExperienceInterface>().getTeenDriverPosts();

    result.fold(
      (failure) {
        snackbarNotifier.notifyError(
          message: failure.uiMessage.isNotEmpty
              ? failure.uiMessage
              : 'Failed to load comments',
        );
      },
      (success) {
        final posts = success.data ?? [];
        if (isGlobalMode) {
          final allComments = <TeenDriverCommentResponseModel>[];
          for (final post in posts) {
            allComments.addAll(post.comments);
          }
          allComments.sort(_sortByCreatedAt);
          _comments
            ..clear()
            ..addAll(allComments);
          _likesCount = 0;
          _isLiked = false;
          _likeUserName = '';
        } else {
          List<TeenDriverCommentResponseModel> postComments = [];
          for (final post in posts) {
            if (post.id == trimmedPostId) {
              postComments = post.comments;
              _likesCount = post.likesCount;
              if (currentUser.id.isNotEmpty &&
                  post.likes.contains(currentUser.id)) {
                _isLiked = true;
                _likeUserName =
                    currentUser.name.isNotEmpty ? currentUser.name : 'You';
              } else {
                _isLiked = false;
                _likeUserName = '';
              }
              break;
            }
          }
          _comments
            ..clear()
            ..addAll(postComments);
        }
        _cacheByPostId[cacheKey] = _CommunityCache(
          comments: List<TeenDriverCommentResponseModel>.from(_comments),
          likesCount: _likesCount,
          isLiked: _isLiked,
          likeUserName: _likeUserName,
        );
      },
    );

    _isLoading = false;
    _hasLoaded = true;
    notifyListeners();
  }

  Future<TeenDriverCommentResponseModel?> submit({String postId = ''}) async {
    if (_text.isEmpty) {
      snackbarNotifier.notifyError(message: 'Please enter a comment.');
      return null;
    }
    if (_isSubmitting) {
      return null;
    }
    final trimmedPostId = postId.trim();
    final isGlobalMode = trimmedPostId.isEmpty;

    _isSubmitting = true;
    notifyListeners();

    final repository = Get.find<TeenDriverExperienceInterface>();
    final request = TeenDriverCommentRequestModel(text: _text);
    TeenDriverCommentResponseModel? createdComment;
    final result = isGlobalMode
        ? await repository.addTeenDriverGlobalComment(param: request)
        : await repository.addTeenDriverPostComment(
            postId: trimmedPostId,
            param: request,
          );

    result.fold(
      (failure) {
        snackbarNotifier.notifyError(
          message: failure.uiMessage.isNotEmpty
              ? failure.uiMessage
              : 'Failed to add comment',
        );
      },
      (success) {
        createdComment = success.data;
        snackbarNotifier.notifySuccess(message: success.message);
      },
    );

    if (createdComment != null) {
      _comments.add(createdComment!);
      _cacheCurrentState();
    }
    _isSubmitting = false;
    notifyListeners();

    return createdComment;
  }

  Future<void> likePost({required String postId}) async {
    if (_isLiking) {
      return;
    }
    if (_isLiked) {
      return;
    }
    if (postId.trim().isEmpty) {
      snackbarNotifier.notifyError(message: 'Post id is missing.');
      return;
    }

    _isLiking = true;
    notifyListeners();

    final currentUser = await _getCurrentUserInfo();
    final result = await Get.find<TeenDriverExperienceInterface>()
        .likeTeenDriverPost(postId: postId.trim());

    result.fold(
      (failure) {
        snackbarNotifier.notifyError(
          message:
              failure.uiMessage.isNotEmpty ? failure.uiMessage : 'Like failed',
        );
      },
      (success) {
        _likesCount = success.data ?? _likesCount;
        _isLiked = true;
        _likeUserName =
            currentUser.name.isNotEmpty ? currentUser.name : 'You';
        _cacheCurrentState();
      },
    );

    _isLiking = false;
    notifyListeners();
  }

  Future<_UserSnapshot> _getCurrentUserInfo() async {
    try {
      final appPigeon = Get.find<AppPigeon>();
      final status = await appPigeon.currentAuth();
      if (status is Authenticated) {
        final data = status.auth.data;
        final userMap =
            data['user'] is Map ? Map<String, dynamic>.from(data['user']) : null;
        String readString(dynamic value) => value?.toString() ?? '';
        final id = readString(
          userMap?['_id'] ??
              userMap?['id'] ??
              userMap?['userId'] ??
              data['_id'] ??
              data['id'] ??
              data['userId'],
        );
        final name = readString(
          userMap?['name'] ?? data['name'] ?? data['fullName'],
        );
        return _UserSnapshot(id: id, name: name);
            }
    } catch (_) {}
    return const _UserSnapshot(id: '', name: '');
  }

  void _applyCache(_CommunityCache cache) {
    _comments
      ..clear()
      ..addAll(cache.comments);
    _likesCount = cache.likesCount;
    _isLiked = cache.isLiked;
    _likeUserName = cache.likeUserName;
  }

  void _cacheCurrentState() {
    _cacheByPostId[_cacheKey(_currentPostId)] = _CommunityCache(
      comments: List<TeenDriverCommentResponseModel>.from(_comments),
      likesCount: _likesCount,
      isLiked: _isLiked,
      likeUserName: _likeUserName,
    );
  }

  String _cacheKey(String postId) {
    if (postId.isEmpty) {
      return _globalCacheKey;
    }
    return postId;
  }

  static int _sortByCreatedAt(
    TeenDriverCommentResponseModel a,
    TeenDriverCommentResponseModel b,
  ) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate == null && bDate == null) {
      return 0;
    }
    if (aDate == null) {
      return 1;
    }
    if (bDate == null) {
      return -1;
    }
    return aDate.compareTo(bDate);
  }
}

class _UserSnapshot {
  final String id;
  final String name;

  const _UserSnapshot({required this.id, required this.name});
}

class _CommunityCache {
  final List<TeenDriverCommentResponseModel> comments;
  final int likesCount;
  final bool isLiked;
  final String likeUserName;

  const _CommunityCache({
    required this.comments,
    required this.likesCount,
    required this.isLiked,
    required this.likeUserName,
  });
}
