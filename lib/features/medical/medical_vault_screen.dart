import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

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
      _medicalConditions = prefs.getString(_conditionsKey) ?? _medicalConditions;
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
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).join(', ');
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
        if (medicalConditions.isNotEmpty) _medicalConditions = medicalConditions;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Health Vault')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            FadeInDown(child: _buildEmergencyQR()),
            const SizedBox(height: 32),
            _buildMedicalSection('Blood Group', _bloodGroup, Icons.bloodtype, Colors.red),
            const SizedBox(height: 16),
            _buildMedicalSection('Allergies', _allergies, Icons.warning, Colors.orange),
            const SizedBox(height: 16),
            _buildMedicalSection(
              'Medical Conditions',
              _medicalConditions,
              Icons.medical_information,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildMedicalSection(
              'Current Medications',
              _medications,
              Icons.medication,
              Colors.green,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _showEditMedicalDialog,
              icon: const Icon(Icons.edit),
              label: const Text('EDIT MEDICAL PROFILE'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyQR() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Emergency Medical ID',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.qr_code_2, size: 150, color: Colors.black),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan in case of medical emergency',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSection(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                Text(
                  value.trim().isEmpty ? 'Not provided' : value,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
    final conditionsController = TextEditingController(text: _medicalConditions);
    final medsController = TextEditingController(text: _medications);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medical Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bloodController,
                decoration: const InputDecoration(labelText: 'Blood Group'),
              ),
              TextField(
                controller: allergiesController,
                decoration: const InputDecoration(labelText: 'Allergies'),
              ),
              TextField(
                controller: conditionsController,
                decoration: const InputDecoration(labelText: 'Medical Conditions'),
              ),
              TextField(
                controller: medsController,
                decoration: const InputDecoration(labelText: 'Current Medications'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => navigator.pop(), child: const Text('Cancel')),
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
            child: const Text('Save'),
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

      await _dio.patch(
        ApiConstants.profile,
        data: {
          'bloodGroup': bloodGroup,
          'allergies': _parseCsvList(allergies),
          'medicalConditions': _parseCsvList(medicalConditions),
          'currentMedications': _parseCsvList(medications),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical profile saved and synced.')),
        );
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally on this device.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
