import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/features/auth/auth_provider.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contacts_provider.dart';
import 'package:suraksha_women_safety_app/features/sos/scream_detection_service.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/localization/locale_provider.dart';
import 'package:suraksha_women_safety_app/models/user_model.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:suraksha_women_safety_app/theme/theme_mode_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final Dio _dio = DioClient().dio;
  static const String _localNameKey = 'profile_local_name_v1';
  static const String _localEmailKey = 'profile_local_email_v1';
  static const String _localPhoneKey = 'profile_local_phone_v1';
  static const String _localBloodKey = 'profile_local_blood_v1';
  static const String _localPhotoPathKey = 'profile_local_photo_path_v1';
  bool _isSaving = false;
  String? _localName;
  String? _localEmail;
  String? _localPhone;
  String? _localBloodGroup;
  String? _localPhotoPath;
  String _extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message ?? 'Network request failed';
    }
    return error.toString();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadLocalProfile();
      await ref.read(emergencyContactsProvider.notifier).loadContacts();
    });
  }

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _localName = prefs.getString(_localNameKey);
      _localEmail = prefs.getString(_localEmailKey);
      _localPhone = prefs.getString(_localPhoneKey);
      _localBloodGroup = prefs.getString(_localBloodKey);
      _localPhotoPath = prefs.getString(_localPhotoPathKey);
    });
  }

  Future<void> _saveLocalProfile({
    required String fullName,
    required String email,
    required String phone,
    required String bloodGroup,
    String? localPhotoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localNameKey, fullName);
    await prefs.setString(_localEmailKey, email);
    await prefs.setString(_localPhoneKey, phone);
    await prefs.setString(_localBloodKey, bloodGroup);
    if (localPhotoPath != null && localPhotoPath.isNotEmpty) {
      await prefs.setString(_localPhotoPathKey, localPhotoPath);
    }
    if (!mounted) return;
    setState(() {
      _localName = fullName;
      _localEmail = email;
      _localPhone = phone;
      _localBloodGroup = bloodGroup;
      if (localPhotoPath != null && localPhotoPath.isNotEmpty) {
        _localPhotoPath = localPhotoPath;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final displayName = (_localName != null && _localName!.trim().isNotEmpty)
        ? _localName!
        : (user?.name ?? 'User Name');
    final displayEmail = (_localEmail != null && _localEmail!.trim().isNotEmpty)
        ? _localEmail!
        : (user?.email ?? 'email@example.com');
    final displayPhone = (_localPhone != null && _localPhone!.trim().isNotEmpty)
        ? _localPhone!
        : (user?.phone ?? l10n.t('notProvided'));
    final contacts = ref.watch(emergencyContactsProvider);
    final screamDetectionState = ref.watch(screamDetectionProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final currentLocale = ref.watch(appLocaleProvider);
    final selectedLanguage = AppLanguage.values.firstWhere(
      (lang) => lang.locale.languageCode == currentLocale.languageCode,
      orElse: () => AppLanguage.english,
    );
    final isDarkMode = themeMode == ThemeMode.dark;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final profileText = isLight ? const Color(0xFF172235) : Colors.white;
    final profileMuted = isLight ? const Color(0xFF5F6F8A) : Colors.white70;
    final profileCard = isLight ? Colors.white : AppTheme.cardColor;
    final profileBorder = isLight
        ? const Color(0xFFDCE5F6)
        : Colors.transparent;
    final ImageProvider<Object>? profileImage =
        _localPhotoPath != null && _localPhotoPath!.isNotEmpty
        ? FileImage(File(_localPhotoPath!))
        : (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
              ? NetworkImage(user.profilePhoto!)
              : null);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('myProfile'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            FadeInDown(
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      backgroundImage: profileImage,
                      child:
                          ((_localPhotoPath == null ||
                                  _localPhotoPath!.isEmpty) &&
                              (user?.profilePhoto == null ||
                                  user!.profilePhoto!.isEmpty))
                          ? const Icon(
                              Icons.person,
                              size: 80,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _isSaving ? null : _pickAndUploadPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ).copyWith(color: profileText),
            ),
            Text(displayEmail, style: TextStyle(color: profileMuted)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _showEditProfileDialog(
                        user,
                        displayName: displayName,
                        displayEmail: displayEmail,
                        displayPhone: displayPhone == l10n.t('notProvided')
                            ? ''
                            : displayPhone,
                      ),
                icon: const Icon(Icons.edit),
                label: Text(l10n.t('editProfileDetails')),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: profileCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: profileBorder),
              ),
              child: SwitchListTile(
                title: Text(
                  l10n.t('darkMode'),
                  style: TextStyle(
                    color: profileText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  isDarkMode
                      ? l10n.t('darkModeSubtitleOn')
                      : l10n.t('darkModeSubtitleOff'),
                  style: TextStyle(color: profileMuted),
                ),
                value: isDarkMode,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (enabled) {
                  ref
                      .read(appThemeModeProvider.notifier)
                      .setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: profileCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: profileBorder),
              ),
              child: SwitchListTile(
                secondary: const Icon(
                  Icons.graphic_eq,
                  color: AppTheme.primaryColor,
                ),
                title: Text(
                  'Scream Detection',
                  style: TextStyle(
                    color: profileText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  screamDetectionState.monitoring
                      ? 'Microphone safety monitor is active.'
                      : 'Microphone stays off while this is disabled.',
                  style: TextStyle(color: profileMuted),
                ),
                value: screamDetectionState.enabled,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: _isSaving
                    ? null
                    : (enabled) => _setScreamDetectionEnabled(enabled),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: profileCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: profileBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: AppTheme.primaryColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('language'),
                          style: TextStyle(
                            color: profileText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.t('contentLanguage'),
                          style: TextStyle(color: profileMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<AppLanguage>(
                      value: selectedLanguage,
                      dropdownColor: profileCard,
                      style: TextStyle(color: profileText),
                      iconEnabledColor: AppTheme.primaryColor,
                      onChanged: (value) {
                        if (value == null) return;
                        ref.read(appLocaleProvider.notifier).setLanguage(value);
                      },
                      items: [
                        DropdownMenuItem(
                          value: AppLanguage.english,
                          child: Text(l10n.t('english')),
                        ),
                        DropdownMenuItem(
                          value: AppLanguage.hindi,
                          child: Text(l10n.t('hindi')),
                        ),
                        DropdownMenuItem(
                          value: AppLanguage.marathi,
                          child: Text(l10n.t('marathi')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileItem(
              context,
              l10n.t('phoneNumber'),
              displayPhone,
              Icons.phone,
            ),
            const SizedBox(height: 16),
            _buildProfileItem(
              context,
              l10n.t('emergencyContacts'),
              '${contacts.length} ${l10n.t('contactsSaved')}',
              Icons.people,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.t('emergencyContactList'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: profileText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...contacts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildContactItem(c),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _showAddContactDialog,
                icon: const Icon(Icons.add),
                label: Text(l10n.t('addEmergencyContact')),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 60),
              ),
              child: Text(l10n.t('logoutSession')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF172235) : Colors.white;
    final mutedColor = isLight ? const Color(0xFF5F6F8A) : Colors.white38;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? const Color(0xFFDCE5F6) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: mutedColor, fontSize: 12)),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(EmergencyContact contact) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF172235) : Colors.white;
    final mutedColor = isLight ? const Color(0xFF5F6F8A) : Colors.white38;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? const Color(0xFFDCE5F6) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.contact_phone, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
                Text(
                  '${contact.phone} • ${contact.relation}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isSaving ? null : () => _showEditContactDialog(contact),
            icon: const Icon(Icons.edit, color: Colors.white70),
          ),
          IconButton(
            onPressed: _isSaving ? null : () => _deleteContact(contact.id),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Future<void> _setScreamDetectionEnabled(bool enabled) async {
    final success = await ref
        .read(screamDetectionProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;

    final state = ref.read(screamDetectionProvider);
    final message = success
        ? enabled
              ? 'Scream detection enabled.'
              : 'Scream detection disabled.'
        : state.error ?? 'Could not enable scream detection.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showEditProfileDialog(
    UserModel? user, {
    required String displayName,
    required String displayEmail,
    required String displayPhone,
  }) async {
    final navigator = Navigator.of(context);
    final nameController = TextEditingController(text: displayName);
    final emailController = TextEditingController(text: displayEmail);
    final phoneController = TextEditingController(text: displayPhone);
    final bloodController = TextEditingController(
      text: (_localBloodGroup != null && _localBloodGroup!.isNotEmpty)
          ? _localBloodGroup
          : (user?.bloodGroup ?? ''),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: bloodController,
              decoration: const InputDecoration(labelText: 'Blood Group'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _updateProfile(
                  fullName: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  bloodGroup: bloodController.text.trim(),
                );
                if (mounted) navigator.pop();
              } catch (error) {
                _showError(_extractError(error));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddContactDialog() async {
    final navigator = Navigator.of(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(labelText: 'Relation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final relation = relationController.text.trim();
              if (name.isEmpty || phone.isEmpty) return;
              try {
                await ref
                    .read(emergencyContactsProvider.notifier)
                    .addContact(
                      EmergencyContact(
                        id: '',
                        name: name,
                        phone: phone,
                        relation: relation.isEmpty
                            ? 'Emergency Contact'
                            : relation,
                      ),
                    );
                if (mounted) navigator.pop();
              } catch (error) {
                _showError(_extractError(error));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditContactDialog(EmergencyContact contact) async {
    final navigator = Navigator.of(context);
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phone);
    final relationController = TextEditingController(text: contact.relation);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(labelText: 'Relation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(emergencyContactsProvider.notifier)
                    .updateContact(
                      EmergencyContact(
                        id: contact.id,
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        relation: relationController.text.trim().isEmpty
                            ? 'Emergency Contact'
                            : relationController.text.trim(),
                      ),
                    );
                if (mounted) navigator.pop();
              } catch (error) {
                _showError(_extractError(error));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String bloodGroup,
  }) async {
    setState(() => _isSaving = true);
    try {
      await _saveLocalProfile(
        fullName: fullName,
        email: email,
        phone: phone,
        bloodGroup: bloodGroup,
      );
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref
            .read(authProvider.notifier)
            .updateUser(
              currentUser.copyWith(
                name: fullName,
                email: email,
                phone: phone,
                bloodGroup: bloodGroup,
              ),
            );
      }

      final response = await _dio.patch(
        ApiConstants.profile,
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'bloodGroup': bloodGroup,
        },
      );
      final updatedUser = UserModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      ref.read(authProvider.notifier).updateUser(updatedUser);
      await _saveLocalProfile(
        fullName: updatedUser.name,
        email: updatedUser.email,
        phone: updatedUser.phone,
        bloodGroup: updatedUser.bloodGroup ?? bloodGroup,
      );
    } on DioException {
      _showError('Saved locally on this device. Server sync failed.');
    } catch (_) {
      _showError('Saved locally on this device.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isSaving = true);
      await _saveLocalProfile(
        fullName: _localName ?? (ref.read(authProvider).user?.name ?? ''),
        email: _localEmail ?? (ref.read(authProvider).user?.email ?? ''),
        phone: _localPhone ?? (ref.read(authProvider).user?.phone ?? ''),
        bloodGroup:
            _localBloodGroup ?? (ref.read(authProvider).user?.bloodGroup ?? ''),
        localPhotoPath: picked.path,
      );

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path),
      });
      final response = await _dio.post(
        '${ApiConstants.profile}/photo',
        data: formData,
      );
      final updatedUser = UserModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      ref.read(authProvider.notifier).updateUser(updatedUser);
    } catch (error) {
      _showError('Photo saved locally. ${_extractError(error)}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteContact(String id) async {
    try {
      await ref.read(emergencyContactsProvider.notifier).deleteContact(id);
    } catch (error) {
      _showError(_extractError(error));
    }
  }
}
