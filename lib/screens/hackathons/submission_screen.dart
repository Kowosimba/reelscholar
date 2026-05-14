// lib/screens/hackathons/submission_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/hackathon_provider.dart';
import 'package:reelscholar/models/hackathon_models.dart';

class SubmissionScreen extends StatefulWidget {
  final String hackId;
  const SubmissionScreen({super.key, required this.hackId});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _repoCtrl = TextEditingController();
  final _demoCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  bool _saving = false;
  bool _finalising = false;

  @override
  void initState() {
    super.initState();
    final sub =
        context.read<HackathonProvider>().submission;
    if (sub != null) _prefill(sub);
  }

  void _prefill(HackSubmission sub) {
    _nameCtrl.text = sub.projectName;
    _descCtrl.text = sub.description;
    _repoCtrl.text = sub.repoUrl ?? '';
    _demoCtrl.text = sub.demoUrl ?? '';
    _videoCtrl.text = sub.videoUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _repoCtrl.dispose();
    _demoCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<HackathonProvider>().saveSubmission(
            widget.hackId,
            projectName: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            repoUrl: _repoCtrl.text.trim().isEmpty
                ? null
                : _repoCtrl.text.trim(),
            demoUrl: _demoCtrl.text.trim().isEmpty
                ? null
                : _demoCtrl.text.trim(),
            videoUrl: _videoCtrl.text.trim().isEmpty
                ? null
                : _videoCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Draft saved ✅'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finalise() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Finalise Submission?',
            style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        content: const Text(
          'Once finalised, you cannot edit your submission. Make sure everything is ready.',
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Finalise',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _finalising = true);
    final p = context.read<HackathonProvider>();
    try {
      await p.finaliseSubmission(widget.hackId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Submission finalised! 🚀'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _finalising = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<HackathonProvider>().submission;
    final isLocked = sub?.isFinalised == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Submission',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (!isLocked)
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text(
                'Save Draft',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status banner
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Submission finalised — no further edits',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                _FieldLabel('Project Name', required: true),
                TextFormField(
                  controller: _nameCtrl,
                  maxLength: 120,
                  enabled: !isLocked,
                  decoration: const InputDecoration(
                    hintText: 'e.g. EduReel — Video Learning Platform',
                    counterText: '',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 16),

                _FieldLabel('Description', required: true),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 5,
                  enabled: !isLocked,
                  decoration: const InputDecoration(
                    hintText: 'Describe your project (min 100 chars)…',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    if (v.trim().length < 100) {
                      return 'At least 100 characters required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _FieldLabel('Repository URL'),
                TextFormField(
                  controller: _repoCtrl,
                  enabled: !isLocked,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://github.com/your/repo',
                    prefixIcon: Icon(Icons.code_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                _FieldLabel('Demo URL'),
                TextFormField(
                  controller: _demoCtrl,
                  enabled: !isLocked,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://your-demo.com',
                    prefixIcon: Icon(Icons.open_in_browser_rounded,
                        size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                _FieldLabel('Video URL'),
                TextFormField(
                  controller: _videoCtrl,
                  enabled: !isLocked,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://youtube.com/watch?v=…',
                    prefixIcon:
                        Icon(Icons.play_circle_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 32),

                if (!isLocked) ...[
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white))
                          : const Text(
                              'Save Draft',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _finalising ? null : _finalise,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.primary),
                      ),
                      child: _finalising
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary))
                          : const Text(
                              '🚀 Finalise Submission',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(text,
              style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          if (required)
            const Text(' *',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
