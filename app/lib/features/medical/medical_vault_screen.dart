import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:suraksha_women_safety_app/widgets/save_feedback_dialog.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

class MedicalVaultScreen extends StatefulWidget {
  const MedicalVaultScreen({super.key});

  @override
  State<MedicalVaultScreen> createState() => _MedicalVaultScreenState();
}

class _MedicalVaultScreenState extends State<MedicalVaultScreen> {
  static const String _bloodKey = 'medical_blood_group_v1';
  static const String _allergiesKey = 'medical_allergies_v1';
  static const String _conditionsKey = 'medical_conditions_v1';
  static const String _medicationsKey = 'medical_medications_v1';

  final Dio _dio = DioClient().dio;

  String _bloodGroup = 'O Positive';
  String _allergies = 'Peanuts, Penicillin';
  String _medicalConditions = 'Asthma';
  String _medications = 'Inhaler (as needed)';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeMedicalData();
  }

  Future<void> _initializeMedicalData() async {
    await _loadLocalMedicalData();
    await _loadMedicalDataFromServer();
  }

  Future<void> _loadLocalMedicalData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bloodGroup = prefs.getString(_bloodKey) ?? _bloodGroup;
      _allergies = prefs.getString(_allergiesKey) ?? _allergies;
      _medicalConditions =
          prefs.getString(_conditionsKey) ?? _medicalConditions;
      _medications = prefs.getString(_medicationsKey) ?? _medications;
    });
  }

  Future<void> _saveLocalMedicalData({
    required String bloodGroup,
    required String allergies,
    required String medicalConditions,
    required String medications,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bloodKey, bloodGroup);
    await prefs.setString(_allergiesKey, allergies);
    await prefs.setString(_conditionsKey, medicalConditions);
    await prefs.setString(_medicationsKey, medications);
  }

  List<String> _parseCsvList(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _toCsv(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
    }
    return '';
  }

  Future<void> _loadMedicalDataFromServer() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      final data = response.data as Map<String, dynamic>;
      final bloodGroup = (data['bloodGroup'] ?? '').toString().trim();
      final allergies = _toCsv(data['allergies']);
      final medicalConditions = _toCsv(data['medicalConditions']);
      final medications = _toCsv(data['currentMedications']);

      if (!mounted) return;
      setState(() {
        if (bloodGroup.isNotEmpty) _bloodGroup = bloodGroup;
        if (allergies.isNotEmpty) _allergies = allergies;
        if (medicalConditions.isNotEmpty) {
          _medicalConditions = medicalConditions;
        }
        if (medications.isNotEmpty) _medications = medications;
      });

      await _saveLocalMedicalData(
        bloodGroup: _bloodGroup,
        allergies: _allergies,
        medicalConditions: _medicalConditions,
        medications: _medications,
      );
    } on DioException {
      // Keep local fallback.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('medicalHealthVault')),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLight
                  ? const [Color(0xFFF8FBFF), Color(0xFFEFF5FE)]
                  : const [Color(0xFF07101F), Color(0xFF101B2E)],
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
                ? const [Color(0xFFF8FBFF), Color(0xFFF3F7FD), Color(0xFFEFF4FA)]
                : const [Color(0xFF07101F), Color(0xFF0B1627), Color(0xFF050A14)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            children: [
              FadeInDown(
                child: _buildVaultHero(context),
              ),
              const SizedBox(height: 18),
              FadeInDown(child: _buildEmergencyQR()),
              const SizedBox(height: 20),
              _buildMedicalSection(
                AppLocalizations.of(context).t('bloodGroup'),
                _bloodGroup,
                Icons.bloodtype_rounded,
                const Color(0xFFE53935),
              ),
              const SizedBox(height: 14),
              _buildMedicalSection(
                AppLocalizations.of(context).t('allergies'),
                _allergies,
                Icons.warning_amber_rounded,
                const Color(0xFFF3B13E),
              ),
              const SizedBox(height: 14),
              _buildMedicalSection(
                AppLocalizations.of(context).t('medicalConditions'),
                _medicalConditions,
                Icons.medical_information_rounded,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 14),
              _buildMedicalSection(
                AppLocalizations.of(context).t('currentMedications'),
                _medications,
                Icons.medication_rounded,
                const Color(0xFF2ED6C5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _showEditMedicalDialog,
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(AppLocalizations.of(context).t('editMedicalProfile')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaultHero(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF172235) : Colors.white;
    final mutedColor = isLight ? const Color(0xFF5F6F8A) : Colors.white70;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isLight
              ? const [Colors.white, Color(0xFFF5F9FF), Color(0xFFEAF3FF)]
              : const [Color(0xFF111B2E), Color(0xFF0E1727), Color(0xFF08111D)],
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
            color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.24),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFF3B13E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).t('medicalHealthVault'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)
                      .t('keepEmergencyMedicalInformationOrganized'),
                  style: TextStyle(
                    color: mutedColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyQR() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isLight
              ? const [Colors.white, Color(0xFFF8FBFF)]
              : const [AppTheme.cardColor, Color(0xFF0E1727)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isLight
              ? const Color(0xFFDCE5F6)
              : AppTheme.primaryColor.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).t('emergencyMedicalId'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isLight ? const Color(0xFF172235) : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE5F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.qr_code_2, size: 150, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).t('scanInCaseOfMedicalEmergency'),
            style: TextStyle(
              color: isLight ? const Color(0xFF5F6F8A) : Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSection(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isLight
              ? const [Colors.white, Color(0xFFF7FAFF)]
              : const [AppTheme.cardColor, Color(0xFF0F1A2B)],
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
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isLight ? 0.12 : 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF5F6F8A) : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value.trim().isEmpty
                      ? AppLocalizations.of(context).t('notProvided')
                      : value,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF172235) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditMedicalDialog() async {
    final navigator = Navigator.of(context);
    final bloodController = TextEditingController(text: _bloodGroup);
    final allergiesController = TextEditingController(text: _allergies);
    final conditionsController = TextEditingController(
      text: _medicalConditions,
    );
    final medsController = TextEditingController(text: _medications);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('editMedicalProfile')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bloodController,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).t('bloodGroup')),
              ),
              TextField(
                controller: allergiesController,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).t('allergies')),
              ),
              TextField(
                controller: conditionsController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).t('medicalConditions'),
                ),
              ),
              TextField(
                controller: medsController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).t('currentMedications'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text(AppLocalizations.of(context).t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveMedicalProfile(
                bloodGroup: bloodController.text.trim(),
                allergies: allergiesController.text.trim(),
                medicalConditions: conditionsController.text.trim(),
                medications: medsController.text.trim(),
              );
              if (mounted) navigator.pop();
            },
            child: Text(AppLocalizations.of(context).t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMedicalProfile({
    required String bloodGroup,
    required String allergies,
    required String medicalConditions,
    required String medications,
  }) async {
    setState(() => _isSaving = true);
    try {
      await _saveLocalMedicalData(
        bloodGroup: bloodGroup,
        allergies: allergies,
        medicalConditions: medicalConditions,
        medications: medications,
      );

      if (!mounted) return;
      setState(() {
        _bloodGroup = bloodGroup;
        _allergies = allergies;
        _medicalConditions = medicalConditions;
        _medications = medications;
      });
      await showSaveSuccessDialog(
        context,
        title: AppLocalizations.of(context).t('medicalProfileSaved'),
        message: AppLocalizations.of(context).t('medicalDetailsReady'),
      );
      unawaited(
        _syncMedicalProfileToServer(
          bloodGroup: bloodGroup,
          allergies: allergies,
          medicalConditions: medicalConditions,
          medications: medications,
        ),
      );
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context).t('savedLocallyOnThisDevice'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncMedicalProfileToServer({
    required String bloodGroup,
    required String allergies,
    required String medicalConditions,
    required String medications,
  }) async {
    try {
      await _dio.patch(
        ApiConstants.profile,
        data: {
          'bloodGroup': bloodGroup,
          'allergies': _parseCsvList(allergies),
          'medicalConditions': _parseCsvList(medicalConditions),
          'currentMedications': _parseCsvList(medications),
        },
      );
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .t('medicalProfileSavedLocallySyncRetryLater'))),
        );
      }
    } catch (_) {
      // Local save remains available even if sync fails.
    }
  }
}
