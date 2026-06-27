class CybercrimeConstants {
  static const reportCategories = [
    'Financial Fraud',
    'Cyber Stalking',
    'Online Bullying',
    'Identity Theft',
    'Social Media Harassment',
    'Harassment',
    'Blackmail',
    'Fake Profile',
    'Deepfake Threat',
    'Deepfake Scam',
    'Fake Job Scam',
    'UPI Fraud',
  ];

  static const evidenceCategories = [
    'All',
    'Screenshot',
    'Audio',
    'Threat Message',
    'Image',
    'Transaction Proof',
    'Document',
    'Other',
  ];

  static const evidenceUploadCategories = [
    'Screenshot',
    'Audio',
    'Threat Message',
    'Image',
    'Transaction Proof',
    'Document',
    'Other',
  ];

  static String reportCategoryKey(String category) {
    switch (category) {
      case 'Financial Fraud':
        return 'catFinancialFraud';
      case 'Cyber Stalking':
        return 'catCyberStalking';
      case 'Online Bullying':
        return 'catOnlineBullying';
      case 'Identity Theft':
        return 'catIdentityTheft';
      case 'Social Media Harassment':
        return 'catSocialMediaHarassment';
      case 'Harassment':
        return 'catHarassment';
      case 'Blackmail':
        return 'catBlackmail';
      case 'Fake Profile':
        return 'catFakeProfile';
      case 'Deepfake Threat':
        return 'catDeepfakeThreat';
      case 'Deepfake Scam':
        return 'catDeepfakeScam';
      case 'Fake Job Scam':
        return 'catFakeJobScam';
      case 'UPI Fraud':
        return 'catUpiFraud';
      default:
        return 'catOther';
    }
  }

  static String evidenceCategoryKey(String category) {
    switch (category) {
      case 'All':
        return 'evidenceCatAll';
      case 'Screenshot':
        return 'evidenceCatScreenshot';
      case 'Audio':
        return 'evidenceCatAudio';
      case 'Threat Message':
        return 'evidenceCatThreatMessage';
      case 'Image':
        return 'evidenceCatImage';
      case 'Transaction Proof':
        return 'evidenceCatTransactionProof';
      case 'Document':
        return 'evidenceCatDocument';
      default:
        return 'evidenceCatOther';
    }
  }
}
