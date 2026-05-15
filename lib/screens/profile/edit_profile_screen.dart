import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _studentIdCtrl;
  late TextEditingController _bioCtrl;

  String? _selectedFaculty;
  String? _selectedProgramme;
  int? _selectedYear;
  int? _selectedSemester;
  File? _pickedImage;
  bool _removePic = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>();
    _nameCtrl = TextEditingController(text: p.displayName);
    _emailCtrl = TextEditingController(text: p.email);
    _studentIdCtrl = TextEditingController(text: p.studentId ?? '');
    _bioCtrl = TextEditingController(text: p.bio ?? '');
    _selectedFaculty = p.faculty;
    _selectedProgramme = p.degreeProgramme;
    _selectedYear = p.yearLevel;
    _selectedSemester = p.semester;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await p.loadFaculties();
      if (_selectedFaculty != null) {
        await p.loadProgrammes(_selectedFaculty!);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _studentIdCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text(
                'Take photo',
                style: TextStyle(fontFamily: 'DM Sans'),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text(
                'Choose from library',
                style: TextStyle(fontFamily: 'DM Sans'),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (context.read<ProfileProvider>().profilePicUrl != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    color: AppColors.error,
                  ),
                ),
                onTap: () => Navigator.pop(context, null),
              ),
          ],
        ),
      ),
    );

    if (result == null) {
      // Remove photo
      setState(() {
        _removePic = true;
        _pickedImage = null;
      });
      return;
    }

    final img = await picker.pickImage(source: result, imageQuality: 85);
    if (img != null) {
      setState(() {
        _pickedImage = File(img.path);
        _removePic = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final p = context.read<ProfileProvider>();
    try {
      await p.updateProfile(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        studentId: _studentIdCtrl.text.trim().isEmpty
            ? null
            : _studentIdCtrl.text.trim(),
        faculty: _selectedFaculty,
        degreeProgramme: _selectedProgramme,
        yearLevel: _selectedYear,
        semester: _selectedSemester,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        profilePicture: _pickedImage,
        removeProfilePicture: _removePic,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated ✅'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Consumer<ProfileProvider>(
            builder: (_, p, _) => TextButton(
              onPressed: p.updating ? null : _save,
              child: p.updating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (_, p, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Avatar picker ───────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primarySubtle,
                          backgroundImage: _pickedImage != null
                              ? FileImage(_pickedImage!)
                              : (!_removePic && p.profilePicUrl != null
                                    ? NetworkImage(p.profilePicUrl!)
                                          as ImageProvider
                                    : null),
                          child:
                              (_pickedImage == null &&
                                  (_removePic || p.profilePicUrl == null))
                              ? Text(
                                  p.initials,
                                  style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Full name ────────────────────────────────────────────
                _FieldLabel('Full Name', required: true),
                TextFormField(
                  controller: _nameCtrl,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    hintText: 'Your full name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    counterText: '',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // ── Email ────────────────────────────────────────────────
                _FieldLabel('Email', required: true),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'student@university.edu',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[\w.+-]+@[\w-]+\.\w+$').hasMatch(v)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Student ID (only for students) ───────────────────────
                if (!p.isLecturer) ...[
                  _FieldLabel('Student ID'),
                  TextFormField(
                    controller: _studentIdCtrl,
                    decoration: const InputDecoration(
                      hintText: 'C210123001A',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!RegExp(r'^C\d{8}[A-Z]$').hasMatch(v.trim())) {
                        return 'Format: C + 8 digits + letter (e.g. C210123001A)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Bio ──────────────────────────────────────────────────
                _FieldLabel('Bio'),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Tell others about yourself…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Faculty ──────────────────────────────────────────────
                _FieldLabel('Faculty', required: true),
                _FacultyDropdown(
                  value: _selectedFaculty,
                  faculties: p.facultyNames,
                  loading: p.facultiesLoading,
                  onChanged: (val) async {
                    setState(() {
                      _selectedFaculty = val;
                      _selectedProgramme = null;
                    });
                    if (val != null) {
                      await p.loadProgrammes(val);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // ── Programme ────────────────────────────────────────────
                _FieldLabel('Degree Programme'),
                _ProgrammeDropdown(
                  value: _selectedProgramme,
                  programmes: p.programmes,
                  loading: p.programmesLoading,
                  enabled: _selectedFaculty != null,
                  onChanged: (val) => setState(() => _selectedProgramme = val),
                ),
                const SizedBox(height: 14),

                // ── Year + Semester ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Year Level', required: true),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedYear,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: List.generate(
                              6,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(
                                  'Year ${i + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (v) => setState(() => _selectedYear = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Semester', required: true),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedSemester,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: [1, 2, 3]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      'Sem $s',
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSemester = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: p.updating ? null : _save,
                    child: p.updating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
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
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _FacultyDropdown extends StatelessWidget {
  final String? value;
  final List<String> faculties;
  final bool loading;
  final ValueChanged<String?> onChanged;

  const _FacultyDropdown({
    required this.value,
    required this.faculties,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      isExpanded: true,
      hint: const Text(
        'Select faculty',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          color: AppColors.textTertiary,
        ),
      ),
      items: faculties
          .map(
            (f) => DropdownMenuItem(
              value: f,
              child: Text(
                f,
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Please select your faculty' : null,
    );
  }
}

class _ProgrammeDropdown extends StatelessWidget {
  final String? value;
  final List<String> programmes;
  final bool loading;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const _ProgrammeDropdown({
    required this.value,
    required this.programmes,
    required this.loading,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: programmes.contains(value) ? value : null,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        fillColor: !enabled ? const Color(0xFFF8FAFC) : null,
        filled: !enabled,
      ),
      isExpanded: true,
      hint: Text(
        enabled ? 'Select programme' : 'Select a faculty first',
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          color: AppColors.textTertiary,
        ),
      ),
      items: enabled
          ? programmes
                .map(
                  (prog) => DropdownMenuItem(
                    value: prog,
                    child: Text(
                      prog,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList()
          : [],
      onChanged: enabled ? onChanged : null,
    );
  }
}
