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
  static const String _localBloodKey = 'profile_local_blood_v1';
  static const String _localPhotoPathKey = 'profile_local_photo_path_v1';
  bool _isSaving = false;
  String? _localName;
  String? _localEmail;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        await _loadLocalProfile();
        await ref.read(emergencyContactsProvider.notifier).loadContacts();
      },
    );
  }

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _localName = prefs.getString(_localNameKey);
      _localEmail = prefs.getString(_localEmailKey);
      _localBloodGroup = prefs.getString(_localBloodKey);
      _localPhotoPath = prefs.getString(_localPhotoPathKey);
    });
  }

  Future<void> _saveLocalProfile({
    required String fullName,
    required String email,
    required String bloodGroup,
    String? localPhotoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localNameKey, fullName);
    await prefs.setString(_localEmailKey, email);
    await prefs.setString(_localBloodKey, bloodGroup);
    if (localPhotoPath != null && localPhotoPath.isNotEmpty) {
      await prefs.setString(_localPhotoPathKey, localPhotoPath);
    }
    if (!mounted) return;
    setState(() {
      _localName = fullName;
      _localEmail = email;
      _localBloodGroup = bloodGroup;
      if (localPhotoPath != null && localPhotoPath.isNotEmpty) {
        _localPhotoPath = localPhotoPath;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final displayName =
        (_localName != null && _localName!.trim().isNotEmpty) ? _localName! : (user?.name ?? 'User Name');
    final displayEmail =
        (_localEmail != null && _localEmail!.trim().isNotEmpty) ? _localEmail! : (user?.email ?? 'email@example.com');
    final contacts = ref.watch(emergencyContactsProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final ImageProvider<Object>? profileImage =
        _localPhotoPath != null && _localPhotoPath!.isNotEmpty
            ? FileImage(File(_localPhotoPath!))
            : (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                  ? NetworkImage(user.profilePhoto!)
                  : null);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
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
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      backgroundImage: profileImage,
                      child:
                          ((_localPhotoPath == null || _localPhotoPath!.isEmpty) &&
                                  (user?.profilePhoto == null || user!.profilePhoto!.isEmpty))
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
                color: Colors.white,
              ),
            ),
            Text(
              displayEmail,
              style: const TextStyle(color: Colors.white70),
            ),
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
                        ),
                icon: const Icon(Icons.edit),
                label: const Text('EDIT PROFILE DETAILS'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isDarkMode ? 'Dark Bluish Theme' : 'Soft Calm Light Theme',
                  style: const TextStyle(color: Colors.white70),
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
            _buildProfileItem('Phone Number', user?.phone ?? 'Not provided', Icons.phone),
            const SizedBox(height: 16),
            _buildProfileItem(
              'Emergency Contacts',
              '${contacts.length} Contacts Saved',
              Icons.people,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Emergency Contact List',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
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
                label: const Text('ADD EMERGENCY CONTACT'),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 60),
              ),
              child: const Text('LOGOUT SESSION'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(EmergencyContact contact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.contact_phone, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                Text(
                  '${contact.phone} • ${contact.relation}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

  Future<void> _showEditProfileDialog(
    UserModel? user, {
    required String displayName,
    required String displayEmail,
  }) async {
    final navigator = Navigator.of(context);
    final nameController = TextEditingController(text: displayName);
    final emailController = TextEditingController(text: displayEmail);
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
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(controller: bloodController, decoration: const InputDecoration(labelText: 'Blood Group')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _updateProfile(
                  fullName: nameController.text.trim(),
                  email: emailController.text.trim(),
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
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(controller: relationController, decoration: const InputDecoration(labelText: 'Relation')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final relation = relationController.text.trim();
              if (name.isEmpty || phone.isEmpty) return;
              try {
                await ref.read(emergencyContactsProvider.notifier).addContact(
                      EmergencyContact(
                        id: '',
                        name: name,
                        phone: phone,
                        relation: relation.isEmpty ? 'Emergency Contact' : relation,
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
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(controller: relationController, decoration: const InputDecoration(labelText: 'Relation')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(emergencyContactsProvider.notifier).updateContact(
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
    required String bloodGroup,
  }) async {
    setState(() => _isSaving = true);
    try {
      await _saveLocalProfile(
        fullName: fullName,
        email: email,
        bloodGroup: bloodGroup,
      );
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref.read(authProvider.notifier).updateUser(
              currentUser.copyWith(
                name: fullName,
                email: email,
                bloodGroup: bloodGroup,
              ),
            );
      }

      final response = await _dio.patch(
        ApiConstants.profile,
        data: {
          'fullName': fullName,
          'email': email,
          'bloodGroup': bloodGroup,
        },
      );
      final updatedUser = UserModel.fromJson(response.data as Map<String, dynamic>);
      ref.read(authProvider.notifier).updateUser(updatedUser);
      await _saveLocalProfile(
        fullName: updatedUser.name,
        email: updatedUser.email,
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
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;

      setState(() => _isSaving = true);
      await _saveLocalProfile(
        fullName: _localName ?? (ref.read(authProvider).user?.name ?? ''),
        email: _localEmail ?? (ref.read(authProvider).user?.email ?? ''),
        bloodGroup: _localBloodGroup ?? (ref.read(authProvider).user?.bloodGroup ?? ''),
        localPhotoPath: picked.path,
      );

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path),
      });
      final response = await _dio.post('${ApiConstants.profile}/photo', data: formData);
      final updatedUser = UserModel.fromJson(response.data as Map<String, dynamic>);
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
