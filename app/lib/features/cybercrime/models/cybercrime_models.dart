class ScamAnalysisResult {
  final String riskLevel;
  final String threatSummary;
  final List<String> recommendedActions;
  final List<String> safetyTips;
  final String? extractedText;
  final String? analysisSource;

  const ScamAnalysisResult({
    required this.riskLevel,
    required this.threatSummary,
    required this.recommendedActions,
    required this.safetyTips,
    this.extractedText,
    this.analysisSource,
  });

  factory ScamAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ScamAnalysisResult(
      riskLevel: json['riskLevel']?.toString() ?? 'LOW',
      threatSummary: json['threatSummary']?.toString() ?? 'No summary available.',
      recommendedActions: (json['recommendedActions'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      safetyTips: (json['safetyTips'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      extractedText: json['extractedText']?.toString(),
      analysisSource: json['analysisSource']?.toString(),
    );
  }
}

class CyberReportResult {
  final String id;
  final String firStyleReport;
  final String? pdfBase64;

  const CyberReportResult({
    required this.id,
    required this.firStyleReport,
    this.pdfBase64,
  });

  factory CyberReportResult.fromJson(Map<String, dynamic> json) {
    return CyberReportResult(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firStyleReport:
          json['firStyleReport']?.toString() ??
          json['complaintSummary']?.toString() ??
          'Report generated.',
      pdfBase64: json['pdfBase64']?.toString(),
    );
  }
}

class CyberReportListItem {
  final String id;
  final String category;
  final String description;
  final bool isDraft;
  final String status;
  final String? firStyleReport;
  final String? pdfBase64;
  final DateTime createdAt;

  const CyberReportListItem({
    required this.id,
    required this.category,
    required this.description,
    required this.isDraft,
    required this.status,
    this.firStyleReport,
    this.pdfBase64,
    required this.createdAt,
  });

  factory CyberReportListItem.fromJson(Map<String, dynamic> json) {
    return CyberReportListItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      category: json['category']?.toString() ?? 'Cyber Report',
      description: json['description']?.toString() ?? '',
      isDraft: json['isDraft'] == true,
      status: json['status']?.toString() ?? 'Reported',
      firStyleReport: json['firStyleReport']?.toString(),
      pdfBase64: json['pdfBase64']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class CyberReportDetail {
  final CyberReportListItem report;
  final List<EvidenceItem> evidence;

  const CyberReportDetail({
    required this.report,
    required this.evidence,
  });

  factory CyberReportDetail.fromJson(Map<String, dynamic> json) {
    final reportJson = json['report'];
    final evidenceJson = json['evidence'];
    return CyberReportDetail(
      report: CyberReportListItem.fromJson(
        reportJson is Map
            ? Map<String, dynamic>.from(reportJson)
            : Map<String, dynamic>.from(json),
      ),
      evidence: evidenceJson is List
          ? evidenceJson
              .whereType<Map>()
              .map((item) => EvidenceItem.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }
}

class LearningProgressSnapshot {
  final List<String> completedTopicIds;
  final int safetyScore;
  final List<String> badges;

  const LearningProgressSnapshot({
    this.completedTopicIds = const [],
    this.safetyScore = 0,
    this.badges = const [],
  });

  factory LearningProgressSnapshot.fromJson(Map<String, dynamic> json) {
    return LearningProgressSnapshot(
      completedTopicIds: (json['completedTopicIds'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      safetyScore: (json['safetyScore'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class EvidenceItem {
  final String id;
  final String title;
  final String category;
  final bool encrypted;
  final bool privateMode;
  final DateTime uploadedAt;
  final List<String> tags;
  final String? fileType;
  final String? reportId;
  final String? reportCategory;

  const EvidenceItem({
    required this.id,
    required this.title,
    required this.category,
    required this.encrypted,
    required this.privateMode,
    required this.uploadedAt,
    required this.tags,
    this.fileType,
    this.reportId,
    this.reportCategory,
  });

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    return EvidenceItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? 'Evidence',
      category: json['category']?.toString() ?? 'Other',
      encrypted: json['encrypted'] != false,
      privateMode: json['privateMode'] == true,
      uploadedAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      tags: (json['tags'] as List? ?? const []).map((item) => item.toString()).toList(),
      fileType: json['fileType']?.toString(),
      reportId: json['reportId']?.toString(),
      reportCategory: json['reportCategory']?.toString(),
    );
  }
}

class DownloadedEvidence {
  final List<int> bytes;
  final String fileName;
  final String mimeType;

  const DownloadedEvidence({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });
}

class LearningTopic {
  final String id;
  final String title;
  final String summary;
  final List<String> tips;
  final List<QuizQuestion> quiz;

  const LearningTopic({
    required this.id,
    required this.title,
    required this.summary,
    required this.tips,
    required this.quiz,
  });

  factory LearningTopic.fromJson(Map<String, dynamic> json) {
    return LearningTopic(
      id: json['id']?.toString() ?? json['title']?.toString() ?? 'topic',
      title: json['title']?.toString() ?? 'Learning Topic',
      summary: json['summary']?.toString() ?? '',
      tips: (json['tips'] as List? ?? const []).map((item) => item.toString()).toList(),
      quiz: (json['quiz'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => QuizQuestion.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question']?.toString() ?? 'Question',
      options: (json['options'] as List? ?? const ['Yes', 'No'])
          .map((item) => item.toString())
          .toList(),
      answerIndex: (json['answerIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeepfakeResources {
  final String title;
  final List<InfoSection> sections;
  final List<HelplineEntry> helplines;

  const DeepfakeResources({
    required this.title,
    required this.sections,
    this.helplines = const [],
  });

  factory DeepfakeResources.fromJson(Map<String, dynamic> json) {
    return DeepfakeResources(
      title: json['title']?.toString() ?? 'Deepfake Awareness',
      sections: (json['sections'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => InfoSection.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      helplines: (json['helplines'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => HelplineEntry.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class HelplineEntry {
  final String label;
  final String value;

  const HelplineEntry({required this.label, required this.value});

  factory HelplineEntry.fromJson(Map<String, dynamic> json) {
    return HelplineEntry(
      label: json['label']?.toString() ?? 'Helpline',
      value: json['value']?.toString() ?? '',
    );
  }
}

class InfoSection {
  final String title;
  final String body;

  const InfoSection({required this.title, required this.body});

  factory InfoSection.fromJson(Map<String, dynamic> json) {
    return InfoSection(
      title: json['title']?.toString() ?? 'Information',
      body: json['body']?.toString() ?? '',
    );
  }
}
