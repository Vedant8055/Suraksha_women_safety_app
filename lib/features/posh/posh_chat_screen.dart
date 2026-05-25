import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

class POSHLegalPortalScreen extends StatefulWidget {
  const POSHLegalPortalScreen({super.key});

  @override
  State<POSHLegalPortalScreen> createState() => _POSHLegalPortalScreenState();
}

class _POSHLegalPortalScreenState extends State<POSHLegalPortalScreen> {
  final Dio _dio = DioClient().dio;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POSH Legal Portal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: const Text(
                'POSH Legal Portal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Access complete POSH Act guidance and file a structured complaint from one place.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor),
                      SizedBox(width: 10),
                      Text(
                        'POSH Act Guide',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Detailed guide includes: origin of the law, scope, definitions, IC process, timelines, evidence, conciliation, inquiry, police escalation, penalties, false complaints boundaries, and practical implementation checklist.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const POSHActGuideScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('OPEN DETAILED POSH ACT GUIDE'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'File Workplace Complaint',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use this to prepare and submit a detailed complaint record. In immediate danger, call 112 first.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            _complaintFormCard(context),
          ],
        ),
      ),
    );
  }

  Widget _complaintFormCard(BuildContext context) {
    final complainantNameController = TextEditingController();
    final complainantPhoneController = TextEditingController();
    final complainantEmailController = TextEditingController();
    final accusedNameController = TextEditingController();
    final companyController = TextEditingController();
    final incidentDateController = TextEditingController();
    final incidentLocationController = TextEditingController();
    final witnessesController = TextEditingController();
    final detailsController = TextEditingController();

    InputDecoration fieldDecoration(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          TextField(
            controller: complainantNameController,
            decoration: fieldDecoration('Your Full Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: complainantPhoneController,
            keyboardType: TextInputType.phone,
            decoration: fieldDecoration('Your Phone Number'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: complainantEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: fieldDecoration('Your Email Address'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: accusedNameController,
            decoration: fieldDecoration('Accused Person Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: companyController,
            decoration: fieldDecoration('Company / Workplace Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: incidentDateController,
            decoration: fieldDecoration('Incident Date (DD/MM/YYYY)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: incidentLocationController,
            decoration: fieldDecoration('Incident Location'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: witnessesController,
            decoration: fieldDecoration('Witnesses (if any)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: detailsController,
            maxLines: 5,
            decoration: fieldDecoration('Detailed Incident Description'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting
                  ? null
                  : () async {
                      final complainantName = complainantNameController.text.trim();
                      final complainantPhone = complainantPhoneController.text.trim();
                      final complainantEmail = complainantEmailController.text.trim();
                      final accusedName = accusedNameController.text.trim();
                      final workplace = companyController.text.trim();
                      final incidentDate = incidentDateController.text.trim();
                      final incidentLocation = incidentLocationController.text.trim();
                      final witnesses = witnessesController.text.trim();
                      final details = detailsController.text.trim();

                      if (complainantName.isEmpty ||
                          complainantPhone.isEmpty ||
                          accusedName.isEmpty ||
                          details.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required details.')),
                        );
                        return;
                      }

                      final compiledDescription = '''
POSH Workplace Complaint (Police Filing Intent)
Complainant: $complainantName
Phone: $complainantPhone
Email: ${complainantEmail.isEmpty ? 'Not provided' : complainantEmail}
Accused: $accusedName
Workplace: ${workplace.isEmpty ? 'Not provided' : workplace}
Incident Date: ${incidentDate.isEmpty ? 'Not provided' : incidentDate}
Incident Location: ${incidentLocation.isEmpty ? 'Not provided' : incidentLocation}
Witnesses: ${witnesses.isEmpty ? 'None provided' : witnesses}
Complaint Details: $details
''';

                      setState(() => _submitting = true);
                      try {
                        await _dio.post(
                          ApiConstants.incidentReport,
                          data: {
                            'category': 'POSH Workplace Complaint',
                            'description': compiledDescription,
                          },
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Complaint submitted successfully.')),
                          );
                        }
                      } on DioException {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Submission failed. Please try again.'),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              icon: const Icon(Icons.report_gmailerrorred),
              label: Text(_submitting ? 'Submitting...' : 'SUBMIT COMPLAINT'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
            ),
          ),
        ],
      ),
    );
  }
}

class POSHActGuideScreen extends StatelessWidget {
  const POSHActGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detailed POSH Act Guide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _GuideIntro(),
          SizedBox(height: 12),
          _GuideSection(
            title: '1. Background And Objective',
            body:
                'The Sexual Harassment of Women at Workplace (Prevention, Prohibition and Redressal) Act, 2013 (POSH Act) was enacted to provide a legal framework for prevention and redressal of sexual harassment at workplaces. It operationalizes constitutional protections of equality, dignity, and safe working conditions.',
          ),
          _GuideSection(
            title: '2. Where It Applies',
            body:
                'It applies across public and private sectors, organized and unorganized workplaces, NGOs, educational institutions, hospitals, sports setups, dwelling places employing domestic workers, and any place visited during employment including transportation provided by employer.',
          ),
          _GuideSection(
            title: '3. Who Is Protected',
            body:
                'Primary statutory protection is for women at workplace: employees, trainees, interns, volunteers, contract workers, temporary staff, and visitors in workplace context. Organizations should still maintain gender-neutral internal ethics policies where possible, but statutory POSH framework specifically protects women.',
          ),
          _GuideSection(
            title: '4. What Counts As Sexual Harassment',
            body:
                'Includes unwelcome physical contact or advances, demand/request for sexual favors, sexually colored remarks, showing pornography, and any unwelcome conduct of sexual nature (verbal, non-verbal, digital). Repeated inappropriate messages, intimidation, retaliation after refusal, and hostile work environment patterns can also be relevant.',
          ),
          _GuideSection(
            title: '5. Internal Committee (IC) Requirements',
            body:
                'Every employer with 10 or more employees must constitute an Internal Committee. Typical composition includes Presiding Officer (senior woman employee), at least two employee members committed to women’s causes/legal awareness/social work, and one external member from NGO/association familiar with sexual harassment issues.',
          ),
          _GuideSection(
            title: '6. Complaint Timeline And Format',
            body:
                'Complaint is usually filed in writing within 3 months from incident (or last incident in continuing pattern). IC may allow extension for valid reasons. Complaint should mention parties, dates/times, location, detailed facts, witnesses, documents/screenshots/chats/emails and relief sought.',
          ),
          _GuideSection(
            title: '7. Conciliation And Inquiry',
            body:
                'Before inquiry, complainant may request conciliation (no monetary settlement should be basis). If conciliation fails or is not chosen, IC conducts formal inquiry with principles of natural justice: both sides heard, opportunity to present evidence, written proceedings, and reasoned findings.',
          ),
          _GuideSection(
            title: '8. Interim Relief During Proceedings',
            body:
                'Complainant can request interim measures such as transfer, leave, reporting line change, no-contact instructions, temporary work-from-home adjustments, or security support. These measures protect safety while inquiry is ongoing and should not amount to penalizing complainant.',
          ),
          _GuideSection(
            title: '9. Inquiry Outcome And Employer Action',
            body:
                'If allegations are proved, IC recommends action as per service rules: warning, written apology, counseling, adverse entry, withholding promotion/increment, termination, or compensation as permitted. Employer should act on recommendations within statutory timelines and document compliance.',
          ),
          _GuideSection(
            title: '10. Police Complaint And Criminal Law',
            body:
                'POSH inquiry is internal redressal and does not replace criminal remedies. If facts disclose criminal offenses (assault, stalking, voyeurism, threats etc.), complainant can file FIR/police complaint. In immediate danger, prioritize emergency response and police contact.',
          ),
          _GuideSection(
            title: '11. Confidentiality Rules',
            body:
                'Identity of complainant/respondent, witness details, inquiry contents, recommendations, and action details should be kept confidential except as required by law. Breach of confidentiality can attract disciplinary consequences.',
          ),
          _GuideSection(
            title: '12. False Complaints: Correct Legal Position',
            body:
                'Law does not punish merely because allegation was not proved. Action for malicious complaint requires clear evidence of deliberate falsehood or forged evidence. Lack of evidence, inconsistencies due to trauma, or inability to prove beyond internal standard should not be treated as malicious.',
          ),
          _GuideSection(
            title: '13. How Not To Misuse The Act',
            body:
                'Do not file knowingly fabricated allegations, tamper evidence, coach witnesses to lie, or use complaint mechanism for unrelated personal/professional disputes. Honest reporting with good faith, even if difficult to prove, is not misuse. Maintain factual, date-wise narrative and authentic records.',
          ),
          _GuideSection(
            title: '14. Employer Compliance Checklist',
            body:
                'Constitute IC correctly, publish POSH policy, conduct regular awareness training, display complaint channel prominently, maintain inquiry documentation, submit annual reports where applicable, and ensure no retaliation against complainant/witnesses.',
          ),
          _GuideSection(
            title: '15. Practical Evidence Checklist',
            body:
                'Preserve original chats/emails/call logs, take timestamped screenshots, note dates and context, list witnesses, record prior complaints/escalations, keep medical/mental health records if relevant, and maintain a chronological incident diary.',
          ),
          _GuideSection(
            title: '16. Appeals And Further Remedies',
            body:
                'Where service rules or law allow, parties may challenge inquiry outcomes through appellate channels. Complainants can also seek external legal remedies through labor authorities/courts or criminal process depending on facts.',
          ),
          _GuideSection(
            title: '17. Good-Faith Use Of POSH Portal',
            body:
                'Use this portal to create detailed records, submit structured complaints, and prepare for IC/police processes. In life-threatening situations, do not wait for documentation workflow; call emergency services immediately.',
          ),
          SizedBox(height: 12),
          _GuideDisclaimer(),
        ],
      ),
    );
  }
}

class _GuideIntro extends StatelessWidget {
  const _GuideIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'This guide is educational and operational. It helps you understand process, boundaries, documentation, and escalation under the POSH framework in India.',
        style: TextStyle(color: Colors.white70, height: 1.35),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final String body;

  const _GuideSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 10),
      collapsedBackgroundColor: AppTheme.cardColor,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        Text(
          body,
          style: const TextStyle(color: Colors.white70, height: 1.35),
        ),
      ],
    );
  }
}

class _GuideDisclaimer extends StatelessWidget {
  const _GuideDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4E2B18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Legal Disclaimer: This guide is not a substitute for case-specific legal advice. For critical matters, consult a qualified lawyer, HR-POSH expert, or competent authority.',
        style: TextStyle(color: Color(0xFFFFE6D5), height: 1.35),
      ),
    );
  }
}
