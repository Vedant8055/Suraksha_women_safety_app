import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';

class CyberCrimeScreen extends StatelessWidget {
  const CyberCrimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(title: const Text('Cyber Crime Protection')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? const [Color(0xFFF7FAFF), Color(0xFFF1F6FF), Color(0xFFEDF3FE)]
                : const [Color(0xFF071025), Color(0xFF0A1A35), Color(0xFF08162B)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: Text(
                  'Report & Protect',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isLight ? const Color(0xFF172235) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Select a category to report a cyber crime incident or learn how to protect yourself.',
                style: TextStyle(
                  color: isLight ? const Color(0xFF5F6F8A) : Colors.white70,
                ),
              ),
              const SizedBox(height: 28),
              _buildCategoryGrid(),
              const SizedBox(height: 28),
              _buildEmergencyHelplines(context),
            ],
          ),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF121E36), Color(0xFF0F1B31)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: (cat['color'] as Color).withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 38),
                  const SizedBox(height: 10),
                  Text(
                    cat['name'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CyberIncidentSheet(category: category),
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
        const SizedBox(height: 24),
        const Text(
          'Official Nodes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _buildOfficialNodeCard(
          context,
          title: 'NATIONAL CYBER CRIME PORTAL',
          subtitle: 'REPORT ALL TYPES OF CYBER FRAUD AND CRIMES',
          url: 'https://cybercrime.gov.in',
        ),
        const SizedBox(height: 12),
        _buildOfficialNodeCard(
          context,
          title: 'CERT-IN',
          subtitle: 'COMPUTER EMERGENCY RESPONSE TEAM OF INDIA',
          url: 'https://www.cert-in.org.in',
        ),
        const SizedBox(height: 12),
        _buildOfficialNodeCard(
          context,
          title: 'RBI SACHET',
          subtitle: 'REPORT AGAINST UNAUTHORIZED DIGITAL LENDING APPS',
          url: 'https://sachet.rbi.org.in',
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

  Future<void> _openExternalLink(BuildContext context, String link) async {
    final uri = Uri.parse(link);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
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
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
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

  Widget _buildOfficialNodeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String url,
  }) {
    return InkWell(
      onTap: () => _openExternalLink(context, url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _CyberIncidentSheet extends StatefulWidget {
  const _CyberIncidentSheet({required this.category});

  final String category;

  @override
  State<_CyberIncidentSheet> createState() => _CyberIncidentSheetState();
}

class _CyberIncidentSheetState extends State<_CyberIncidentSheet> {
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _evidenceFiles = [];
  bool _isSubmitting = false;
  bool _isLoadingDraft = true;

  String get _prefsKey =>
      'cyber_report_${widget.category.toLowerCase().replaceAll(' ', '_')}';

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    _descriptionController.text = prefs.getString('${_prefsKey}_description') ?? '';
    final savedPaths = prefs.getStringList('${_prefsKey}_evidence') ?? [];
    _evidenceFiles
      ..clear()
      ..addAll(savedPaths.map(XFile.new));
    if (!mounted) return;
    setState(() => _isLoadingDraft = false);
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsKey}_description', _descriptionController.text.trim());
    await prefs.setStringList(
      '${_prefsKey}_evidence',
      _evidenceFiles.map((file) => file.path).toList(),
    );
  }

  Future<bool> _requestMediaPermission() async {
    var status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;

    status = await Permission.storage.request();
    if (status.isGranted) return true;

    status = await Permission.videos.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> _pickEvidence() async {
    final hasPermission = await _requestMediaPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery permission is required to add evidence.')),
      );
      return;
    }
    if (!mounted) return;

    final pickOption = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Upload Photos', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'photos'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.white),
              title: const Text('Upload Video', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );

    if (pickOption == null) return;

    if (pickOption == 'photos') {
      final photos = await _picker.pickMultiImage();
      if (photos.isNotEmpty) {
        setState(() => _evidenceFiles.addAll(photos));
      }
    } else {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() => _evidenceFiles.add(video));
      }
    }

    await _saveDraft();
  }

  Future<void> _submitReport() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add incident description.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dio = DioClient().dio;
      final reportResponse = await dio.post(
        ApiConstants.incidentReport,
        data: {
          'category': widget.category,
          'description': description,
        },
      );
      final incidentId = reportResponse.data['_id']?.toString();
      for (final file in _evidenceFiles) {
        if (incidentId == null || incidentId.isEmpty) break;
        final payload = FormData.fromMap({
          'incidentId': incidentId,
          'mediaType': _isVideo(file.path) ? 'video' : 'image',
          'file': await MultipartFile.fromFile(file.path, filename: file.name),
        });
        await dio.post(ApiConstants.uploadMedia, data: payload);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_prefsKey}_description');
      await prefs.remove('${_prefsKey}_evidence');

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report submitted successfully.')),
      );
    } on DioException catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_prefsKey}_description', description);
      await prefs.setStringList(
        '${_prefsKey}_evidence',
        _evidenceFiles.map((file) => file.path).toList(),
      );
      if (mounted) {
        final status = e.response?.statusCode;
        final backendMessage = e.response?.data is Map<String, dynamic>
            ? e.response?.data['message']?.toString()
            : null;
        final details = backendMessage ??
            (status == 401
                ? 'Please login again.'
                : 'Saved locally. Try again in a moment.');
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to submit online: $details')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic');
  }

  void _openImagePreview(XFile file) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.file(File(file.path), fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildEvidenceItem(XFile file, int index) {
    final isImage = _isImage(file.path);
    final isVideo = _isVideo(file.path);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: isImage
          ? GestureDetector(
              onTap: () => _openImagePreview(file),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(file.path),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.white70),
                ),
              ),
            )
          : Icon(
              isVideo ? Icons.videocam : Icons.insert_drive_file,
              color: Colors.white70,
            ),
      title: Text(
        file.name,
        style: const TextStyle(color: Colors.white70),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: isImage
          ? const Text(
              'Tap thumbnail to preview',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            )
          : null,
      trailing: IconButton(
        onPressed: () async {
          setState(() => _evidenceFiles.removeAt(index));
          await _saveDraft();
        },
        icon: const Icon(Icons.close, color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: _isLoadingDraft
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report ${widget.category}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => _saveDraft(),
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
                  onPressed: _pickEvidence,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Evidence (Screenshots/Videos)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 12),
                if (_evidenceFiles.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _evidenceFiles.length,
                      itemBuilder: (context, index) =>
                          _buildEvidenceItem(_evidenceFiles[index], index),
                    ),
                  )
                else
                  const Spacer(),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('SUBMIT REPORT'),
                ),
              ],
            ),
    );
  }
}
