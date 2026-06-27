import 'dart:async';
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
import 'package:suraksha_women_safety_app/features/dashboard/safety_preferences_provider.dart';
import 'package:suraksha_women_safety_app/features/profile/emergency_contacts_provider.dart';
import 'package:suraksha_women_safety_app/features/profile/profile_display_provider.dart';
import 'package:suraksha_women_safety_app/features/sos/sensor_service.dart';
import 'package:suraksha_women_safety_app/features/sos/scream_detection_service.dart';
import 'package:suraksha_women_safety_app/features/sos/distress/scream_audio_classifier.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';
import 'package:suraksha_women_safety_app/localization/locale_provider.dart';
import 'package:suraksha_women_safety_app/models/user_model.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:suraksha_women_safety_app/theme/theme_mode_provider.dart';
import 'package:suraksha_women_safety_app/widgets/save_feedback_dialog.dart';

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
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid details.';
    }
    return error.toString();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _showSaveSuccess(String title, String message) async {
    if (!mounted) return;
    await showSaveSuccessDialog(
      context,
      title: title,
      message: message,
    );
  }

  Future<void> _showProfilePhotoPreview(
    ImageProvider<Object> profileImage,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isLight = Theme.of(dialogContext).brightness == Brightness.light;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: isLight
                    ? const [Colors.white, Color(0xFFF5F9FF)]
                    : const [Color(0xFF111B2E), Color(0xFF0A1321)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFDCE5F6)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image(image: profileImage, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        );
      },
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
    unawaited(
      ref
          .read(profileDisplayProvider.notifier)
          .update(name: _localName ?? '', photoPath: _localPhotoPath ?? ''),
    );
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
    unawaited(
      ref
          .read(profileDisplayProvider.notifier)
          .update(name: fullName, photoPath: localPhotoPath),
    );
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
    final impactDetectionState = ref.watch(impactDetectionProvider);
    final screamDetectionState = ref.watch(screamDetectionProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final currentLocale = ref.watch(appLocaleProvider);
    final selectedLanguage = AppLanguageX.fromLocale(currentLocale);
    final isDarkMode = themeMode == ThemeMode.dark;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final profileText = isLight ? const Color(0xFF172235) : Colors.white;
    final profileMuted = isLight ? const Color(0xFF5F6F8A) : Colors.white70;
    final ImageProvider<Object>? profileImage =
        _localPhotoPath != null && _localPhotoPath!.isNotEmpty
        ? FileImage(File(_localPhotoPath!))
        : (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
              ? NetworkImage(user.profilePhoto!)
              : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('myProfile')),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLight
                  ? const [Color(0xFFF7FAFF), Color(0xFFEAF2FF)]
                  : const [Color(0xFF09111F), Color(0xFF121C30)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? const [Color(0xFFF8FBFF), Color(0xFFF1F6FF), Color(0xFFEAF2FF)]
                : const [Color(0xFF07101F), Color(0xFF0A1528), Color(0xFF050B16)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHero(
                context,
                displayName: displayName,
                displayEmail: displayEmail,
                profileImage: profileImage,
                profileText: profileText,
                profileMuted: profileMuted,
                isLight: isLight,
                onEditPhoto: _isSaving ? null : _pickAndUploadPhoto,
                onEditDetails: _isSaving
                    ? null
                    : () => _showEditProfileDialog(
                        user,
                        displayName: displayName,
                        displayEmail: displayEmail,
                        displayPhone: displayPhone == l10n.t('notProvided')
                            ? ''
                            : displayPhone,
                      ),
              ),
              const SizedBox(height: 14),
              _buildLanguageSelector(
                context,
                selectedLanguage: selectedLanguage,
                profileText: profileText,
                profileMuted: profileMuted,
                isLight: isLight,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        ref.read(appLocaleProvider.notifier).setLanguage(value);
                      },
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLight
                        ? const [Colors.white, Color(0xFFF8FBFF)]
                        : const [Color(0xFF111B2E), Color(0xFF0D1626)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isLight
                        ? const Color(0xFFDCE5F6)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        l10n.t('darkMode'),
                        style: TextStyle(
                          color: profileText,
                          fontWeight: FontWeight.w700,
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
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.graphic_eq,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        l10n.t('screamDetection'),
                        style: TextStyle(
                          color: profileText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        screamDetectionState.monitoring
                            ? l10n.t('microphoneSafetyMonitorActive')
                            : l10n.t('microphoneSafetyMonitorInactive'),
                        style: TextStyle(color: profileMuted),
                      ),
                      value: screamDetectionState.enabled,
                      activeThumbColor: AppTheme.primaryColor,
                      onChanged: _isSaving
                          ? null
                          : (enabled) => _setScreamDetectionEnabled(enabled),
                    ),
                    if (screamDetectionState.enabled) ...[
                      ListTile(
                        leading: const Icon(
                          Icons.tune_rounded,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(
                          l10n.t('distressSensitivity'),
                          style: TextStyle(
                            color: profileText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          l10n.t('distressSensitivitySubtitle'),
                          style: TextStyle(color: profileMuted),
                        ),
                        trailing: DropdownButton<DistressSensitivity>(
                          value: screamDetectionState.sensitivity,
                          underline: const SizedBox.shrink(),
                          items: DistressSensitivity.values
                              .map(
                                (level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(
                                    l10n.t('distressSensitivity_${level.name}'),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  ref
                                      .read(screamDetectionProvider.notifier)
                                      .setSensitivity(value);
                                },
                        ),
                      ),
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.science_outlined,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(
                          l10n.t('distressTestMode'),
                          style: TextStyle(
                            color: profileText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          screamDetectionState.lastSpeechSnippet != null
                              ? '${l10n.t('distressLastHeard')}: ${screamDetectionState.lastSpeechSnippet}'
                              : l10n.t('distressTestModeSubtitle'),
                          style: TextStyle(color: profileMuted),
                        ),
                        value: screamDetectionState.testMode,
                        activeThumbColor: AppTheme.primaryColor,
                        onChanged: _isSaving
                            ? null
                            : (enabled) => ref
                                .read(screamDetectionProvider.notifier)
                                .setTestMode(enabled),
                      ),
                    ],
                    const Divider(height: 1),
                    Consumer(
                      builder: (context, ref, _) {
                        final prefs = ref.watch(safetyPreferencesProvider);
                        return SwitchListTile(
                          secondary: const Icon(
                            Icons.notifications_active_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(
                            l10n.t('journeySafetyAlerts'),
                            style: TextStyle(
                              color: profileText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            l10n.t('journeySafetyAlertsSubtitle'),
                            style: TextStyle(color: profileMuted),
                          ),
                          value: prefs.journeyAlertsEnabled,
                          activeThumbColor: AppTheme.primaryColor,
                          onChanged: prefs.loading
                              ? null
                              : (enabled) => ref
                                  .read(safetyPreferencesProvider.notifier)
                                  .setJourneyAlertsEnabled(enabled),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.car_crash,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        l10n.t('impactDetection'),
                        style: TextStyle(
                          color: profileText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        impactDetectionState.monitoring
                            ? l10n.t('motionSensorsActive')
                            : l10n.t('motionSensorsInactive'),
                        style: TextStyle(color: profileMuted),
                      ),
                      value: impactDetectionState.enabled,
                      activeThumbColor: AppTheme.primaryColor,
                      onChanged: _isSaving
                          ? null
                          : (enabled) => _setImpactDetectionEnabled(enabled),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildProfileItem(
                context,
                l10n.t('emergencyContacts'),
                '${contacts.length} ${l10n.t('contactsSaved')}',
                Icons.people_rounded,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.t('emergencyContactList'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: profileText,
                    fontWeight: FontWeight.w800,
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
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.t('addEmergencyContact')),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.12),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 58),
                ),
                label: Text(l10n.t('logoutSession')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(
    BuildContext context, {
    required String displayName,
    required String displayEmail,
    required ImageProvider<Object>? profileImage,
    required Color profileText,
    required Color profileMuted,
    required bool isLight,
    VoidCallback? onEditPhoto,
    VoidCallback? onEditDetails,
  }) {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? const [Color(0xFFFFFFFF), Color(0xFFF2F7FF), Color(0xFFE7F1FF)]
                : const [Color(0xFF121B2E), Color(0xFF0E1727), Color(0xFF08111D)],
          ),
          border: Border.all(
            color: isLight
                ? const Color(0xFFD9E6F8)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.24),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: profileImage == null
                            ? null
                            : () => _showProfilePhotoPreview(profileImage),
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.18,
                          ),
                          backgroundImage: profileImage,
                          child:
                              profileImage == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: onEditPhoto,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: profileText,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail,
                        style: TextStyle(color: profileMuted, fontSize: 13.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context).t('profileHeroCta'),
                        style: TextStyle(
                          color: profileMuted,
                          height: 1.35,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEditDetails,
                icon: const Icon(Icons.edit_document),
                label: Text(AppLocalizations.of(context).t('editProfileDetails')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context, {
    required AppLanguage selectedLanguage,
    required Color profileText,
    required Color profileMuted,
    required bool isLight,
    required ValueChanged<AppLanguage?>? onChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    final options = [
      (AppLanguage.english, l10n.t('english'), Icons.language_rounded),
      (AppLanguage.hindi, l10n.t('hindi'), Icons.translate_rounded),
      (AppLanguage.marathi, l10n.t('marathi'), Icons.auto_awesome_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isLight ? Colors.white : AppTheme.cardColor,
        border: Border.all(
          color: isLight
              ? const Color(0xFFDCE5F6)
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('languageSelectionTitle'),
            style: TextStyle(
              color: profileText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('contentLanguage'),
            style: TextStyle(color: profileMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: options
                .map(
                  (option) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: option.$1 == AppLanguage.marathi ? 0 : 8,
                      ),
                      child: _buildLanguageButton(
                        context,
                        label: option.$2,
                        icon: option.$3,
                        selected: selectedLanguage == option.$1,
                        isLight: isLight,
                        onTap: onChanged == null ? null : () => onChanged(option.$1),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required bool isLight,
    required VoidCallback? onTap,
  }) {
    final baseColor = selected ? AppTheme.primaryColor : (isLight ? const Color(0xFFF1F5FE) : const Color(0xFF0E1727));
    final textColor = selected ? Colors.white : (isLight ? const Color(0xFF172235) : Colors.white);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF1D8CF8), Color(0xFF2ED6C5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : baseColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isLight ? const Color(0xFFD4E0F3) : Colors.white.withValues(alpha: 0.08)),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.26),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF172235) : Colors.white;
    final mutedColor = isLight ? const Color(0xFF5F6F8A) : Colors.white38;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isLight ? const Color(0xFFDCE5F6) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: isLight ? 0.10 : 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
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
              if (onTap != null) Icon(Icons.chevron_right_rounded, size: 20, color: mutedColor),
            ],
          ),
        ),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight ? const Color(0xFFDCE5F6) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: isLight ? 0.10 : 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.contact_phone, color: AppTheme.primaryColor),
          ),
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
            icon: const Icon(Icons.edit_rounded, color: Colors.white70),
          ),
          IconButton(
            onPressed: _isSaving ? null : () => _deleteContact(contact.id),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
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

  Future<void> _setImpactDetectionEnabled(bool enabled) async {
    final success = await ref
        .read(impactDetectionProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;

    final state = ref.read(impactDetectionProvider);
    final message = success
        ? enabled
              ? 'Impact detection enabled.'
              : 'Impact detection disabled.'
        : state.error ?? 'Could not enable impact detection.';
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
    final l10n = AppLocalizations.of(context);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D8CF8), Color(0xFF2ED6C5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.badge_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.t('editProfile'))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.t('fullName'),
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.t('email'),
                  prefixIcon: const Icon(Icons.email_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.t('phoneNumber'),
                  prefixIcon: const Icon(Icons.call_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bloodController,
                decoration: InputDecoration(
                  labelText: l10n.t('bloodGroup'),
                  prefixIcon: const Icon(Icons.bloodtype_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.t('cancel')),
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
                if (mounted) {
                  navigator.pop();
                  await _showSaveSuccess(
                    l10n.t('profileSavedTitle'),
                    l10n.t('profileSavedMessage'),
                  );
                }
              } catch (error) {
                _showError(_extractError(error));
              }
            },
            child: Text(l10n.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddContactDialog() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    var saving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.group_add_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.t('addEmergencyContactTitle'))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  enabled: !saving,
                  decoration: InputDecoration(
                    labelText: l10n.t('name'),
                    prefixIcon: const Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  enabled: !saving,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.t('phoneNumber'),
                    prefixIcon: const Icon(Icons.call_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationController,
                  enabled: !saving,
                  decoration: InputDecoration(
                    labelText: l10n.t('relation'),
                    prefixIcon: const Icon(Icons.family_restroom_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: Text(l10n.t('cancel')),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      final relation = relationController.text.trim();
                      if (name.isEmpty || phone.isEmpty) {
                        _showError(l10n.t('nameAndPhoneRequired'));
                        return;
                      }

                      setDialogState(() => saving = true);
                      try {
                        final saved = await ref
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
                        if (!mounted) return;
                        if (!saved) {
                          _showError(l10n.t('duplicatePhoneNumber'));
                          setDialogState(() => saving = false);
                          return;
                        }

                        navigator.pop();
                        await _showSaveSuccess(
                          l10n.t('contactSavedTitle'),
                          l10n.t('contactSavedMessage'),
                        );
                      } catch (error) {
                        _showError(_extractError(error));
                        if (mounted) setDialogState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.t('save')),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _showEditContactDialog(EmergencyContact contact) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phone);
    final relationController = TextEditingController(text: contact.relation);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D8CF8), Color(0xFF2ED6C5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.t('editEmergencyContactTitle'))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.t('name'),
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.t('phoneNumber'),
                  prefixIcon: const Icon(Icons.call_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationController,
                decoration: InputDecoration(
                  labelText: l10n.t('relation'),
                  prefixIcon: const Icon(Icons.family_restroom_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final saved = await ref
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
                if (!mounted) return;
                if (!saved) {
                  _showError(l10n.t('duplicatePhoneNumber'));
                  return;
                }
                navigator.pop();
                await _showSaveSuccess(
                  l10n.t('contactSavedTitle'),
                  l10n.t('contactSavedMessage'),
                );
              } catch (error) {
                _showError(_extractError(error));
              }
            },
            child: Text(l10n.t('save')),
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
      unawaited(
        ref.read(profileDisplayProvider.notifier).update(name: fullName),
      );
      if (!mounted) return;
      await _showSaveSuccess(
        AppLocalizations.of(context).t('profileSavedTitle'),
        AppLocalizations.of(context).t('profileSavedMessage'),
      );
      unawaited(
        _syncProfileToServer(
          fullName: fullName,
          email: email,
          phone: phone,
          bloodGroup: bloodGroup,
        ),
      );
    } catch (error) {
      _showError(_extractError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncProfileToServer({
    required String fullName,
    required String email,
    required String phone,
    required String bloodGroup,
  }) async {
    try {
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
      unawaited(
        ref
            .read(profileDisplayProvider.notifier)
            .update(name: updatedUser.name),
      );
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('savedLocallyRetryLater'))),
        );
      }
    } catch (_) {
      // Keep the local save as the source of truth.
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final photoSavedLocallyMessage =
        AppLocalizations.of(context).t('photoSavedLocally');
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
      unawaited(
        ref
            .read(profileDisplayProvider.notifier)
            .update(photoPath: picked.path),
      );
      if (!mounted) return;
      await _showSaveSuccess(
        AppLocalizations.of(context).t('profileSavedTitle'),
        AppLocalizations.of(context).t('profileSavedMessage'),
      );
      unawaited(
        _syncProfilePhotoToServer(picked.path),
      );
    } catch (error) {
      _showError('$photoSavedLocallyMessage ${_extractError(error)}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncProfilePhotoToServer(String photoPath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(photoPath),
      });
      final response = await _dio.post(
        '${ApiConstants.profile}/photo',
        data: formData,
      );
      final updatedUser = UserModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      ref.read(authProvider.notifier).updateUser(updatedUser);
      unawaited(
        ref.read(profileDisplayProvider.notifier).update(photoPath: photoPath),
      );
    } catch (_) {
      // Local photo is already visible immediately.
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
