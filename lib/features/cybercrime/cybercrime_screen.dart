import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';

class CyberCrimeScreen extends StatelessWidget {
  const CyberCrimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cyber Crime Protection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: const Text(
                'Report & Protect',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a category to report a cyber crime incident or learn how to protect yourself.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            _buildCategoryGrid(),
            const SizedBox(height: 32),
            _buildEmergencyHelplines(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Financial Fraud', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
      {'name': 'Cyber Stalking', 'icon': Icons.track_changes, 'color': Colors.red},
      {'name': 'Online Bullying', 'icon': Icons.forum, 'color': Colors.orange},
      {'name': 'Identity Theft', 'icon': Icons.fingerprint, 'color': Colors.purple},
      {'name': 'Harassment', 'icon': Icons.warning, 'color': Colors.teal},
      {'name': 'Deepfake Scam', 'icon': Icons.perm_camera_mic, 'color': Colors.pinkAccent},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: InkWell(
            onTap: () => _showReportDialog(context, cat['name'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (cat['color'] as Color).withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    cat['name'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, String category) {
    final descriptionController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report $category', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe the incident in detail...',
                hintStyle: const TextStyle(color: Colors.white38),
                fillColor: AppTheme.cardColor,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Evidence (Screenshots/Videos)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                try {
                  await DioClient().dio.post(
                    ApiConstants.incidentReport,
                    data: {
                      'category': category,
                      'description': descriptionController.text.trim(),
                    },
                  );
                  if (context.mounted) Navigator.pop(context);
                } on DioException {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to submit report')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              child: const Text('SUBMIT REPORT'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyHelplines(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Emergency Cyber Helplines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        _buildHelplineCard(
          context,
          'National Cyber Crime Helpline',
          '1930',
          Icons.phone_forwarded,
        ),
        const SizedBox(height: 12),
        _buildHelplineCard(
          context,
          'Women Helpline',
          '1091',
          Icons.support_agent,
        ),
      ],
    );
  }

  Future<void> _openDialPad(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  Widget _buildHelplineCard(
    BuildContext context,
    String title,
    String number,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(number, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openDialPad(context, number),
            icon: const Icon(Icons.call, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
