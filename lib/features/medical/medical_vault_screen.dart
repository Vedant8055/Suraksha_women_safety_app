import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';

class MedicalVaultScreen extends StatelessWidget {
  const MedicalVaultScreen({super.key});

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
            _buildMedicalSection('Blood Group', 'O Positive', Icons.bloodtype, Colors.red),
            const SizedBox(height: 16),
            _buildMedicalSection('Allergies', 'Peanuts, Penicillin', Icons.warning, Colors.orange),
            const SizedBox(height: 16),
            _buildMedicalSection('Medical Conditions', 'Asthma', Icons.medical_information, Colors.blue),
            const SizedBox(height: 16),
            _buildMedicalSection('Current Medications', 'Inhaler (as needed)', Icons.medication, Colors.green),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
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
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
