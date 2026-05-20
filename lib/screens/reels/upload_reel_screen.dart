import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/app_colors.dart';
import 'package:reelscholar/providers/reel_provider.dart';
import 'package:video_player/video_player.dart';

import 'widgets/video_preview_controller_factory.dart';

class UploadReelScreen extends StatefulWidget {
  const UploadReelScreen({super.key});

  @override
  State<UploadReelScreen> createState() => _UploadReelScreenState();
}

class _UploadReelScreenState extends State<UploadReelScreen> {
  XFile? _video;
  VideoPlayerController? _previewController;
  bool _previewReady = false;
  bool _previewFailed = false;

  final _captionCtrl = TextEditingController();
  final _hashtagCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _selectedTopic;

  @override
  void dispose() {
    _disposePreview();
    _captionCtrl.dispose();
    _hashtagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 1),
    );
    if (picked != null) {
      await _setVideo(picked);
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 1),
    );
    if (picked != null) {
      await _setVideo(picked);
    }
  }

  Future<void> _setVideo(XFile picked) async {
    await _disposePreview();
    if (!mounted) return;

    setState(() {
      _video = picked;
      _previewReady = false;
      _previewFailed = false;
    });

    final controller = createVideoPreviewController(picked.path);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _previewController = controller;
        _previewReady = true;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _previewController = null;
        _previewFailed = true;
      });
    }
  }

  Future<void> _disposePreview() async {
    final controller = _previewController;
    _previewController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _clearVideo() async {
    await _disposePreview();
    if (!mounted) return;
    setState(() {
      _video = null;
      _previewReady = false;
      _previewFailed = false;
    });
  }

  void _togglePreviewPlayback() {
    final controller = _previewController;
    if (controller == null || !_previewReady) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  Future<void> _post() async {
    if (_video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawCaption = _captionCtrl.text.trim();
    final tags = _hashtagCtrl.text.trim();
    final caption = tags.isNotEmpty ? '$rawCaption\n$tags' : rawCaption;

    final prov = context.read<ReelProvider>();
    final reel = await prov.uploadReel(
      video: _video!,
      caption: caption.isEmpty ? null : caption,
      topicId: _selectedTopic != null ? _selectedTopic!['id'] as int? : null,
    );

    if (!mounted) return;
    if (reel != null) {
      final message = reel.isVisible
          ? 'Reel posted!'
          : 'Reel uploaded — validating educational content. We\'ll let you know once it\'s reviewed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.uploadError ?? 'Upload failed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReelProvider>(
      builder: (_, prov, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'New Reel',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: (prov.isUploading || _video == null) ? null : _post,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: prov.isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Post',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (prov.isUploading) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.upload_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Uploading reel…',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(prov.uploadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: prov.uploadProgress,
                              minHeight: 4,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: _showPickerSheet,
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundMuted,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _video != null
                              ? AppColors.primary
                              : AppColors.borderMedium,
                          width: _video != null ? 2 : 1.5,
                        ),
                      ),
                      child: _video == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySubtle,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.video_camera_back_outlined,
                                    size: 28,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to add video',
                                  style: TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Max 60 seconds · MP4, MOV',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  GestureDetector(
                                    onTap: _togglePreviewPlayback,
                                    child: Container(
                                      color: Colors.black87,
                                      child: _buildVideoPreview(),
                                    ),
                                  ),
                                  if (_previewReady && _previewController != null)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 180),
                                          opacity: _previewController!.value.isPlaying
                                              ? 0
                                              : 1,
                                          child: Center(
                                            child: Container(
                                              width: 58,
                                              height: 58,
                                              decoration: BoxDecoration(
                                                color: Colors.black45,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow_rounded,
                                                size: 34,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              _video!.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Ready',
                                                style: TextStyle(
                                                  fontFamily: 'DM Sans',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: _clearVideo,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _previewReady
                        ? 'Tap the preview to pause or play before posting.'
                        : 'Preview loads automatically after you pick a video.',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FieldLabel('Caption'),
                  TextFormField(
                    controller: _captionCtrl,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'What concept are you teaching?',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Hashtags'),
                  TextFormField(
                    controller: _hashtagCtrl,
                    decoration: const InputDecoration(
                      hintText: '#physics #newton #forces',
                      prefixIcon: Icon(Icons.tag_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Link to Module / Topic'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.book_outlined,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedTopic != null
                                ? _selectedTopic!['name'] as String
                                : 'Search and link a module…',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              color: _selectedTopic != null
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        if (_selectedTopic != null)
                          GestureDetector(
                            onTap: () => setState(() => _selectedTopic = null),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Community Guidelines',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _Guideline('Keep content educational and relevant'),
                        const _Guideline('No copyrighted materials'),
                        const _Guideline('Videos must be under 60 seconds'),
                        const _Guideline('Be respectful and constructive'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Video',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('MP4 or MOV, max 60 seconds'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Record Video',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    final controller = _previewController;
    if (_previewReady && controller != null) {
      return Center(
        child: AspectRatio(
          aspectRatio:
              controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }

    if (_previewFailed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 44,
            color: Colors.white70,
          ),
          const SizedBox(height: 10),
          Text(
            _video?.name ?? 'Video selected',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Preview unavailable here, but the file is ready to upload.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      );
    }

    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _Guideline extends StatelessWidget {
  final String text;
  const _Guideline(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 5, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
