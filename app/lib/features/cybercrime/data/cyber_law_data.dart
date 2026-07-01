import 'package:flutter/material.dart';

/// Trilingual content for a single cyber law topic.
class CyberLawContent {
  const CyberLawContent({
    required this.title,
    required this.short,
    required this.overview,
    required this.acts,
    required this.punishments,
    required this.whatToDo,
    required this.whereToReport,
  });

  final String title;
  final String short;
  final String overview;
  final List<String> acts;
  final List<String> punishments;
  final List<String> whatToDo;
  final List<String> whereToReport;
}

/// A single cyber crime law topic with icon, colour, and EN/HI/MR content.
class CyberLawTopic {
  const CyberLawTopic({
    required this.id,
    required this.icon,
    required this.color,
    required this.en,
    required this.hi,
    required this.mr,
  });

  final String id;
  final IconData icon;
  final Color color;
  final CyberLawContent en;
  final CyberLawContent hi;
  final CyberLawContent mr;

  CyberLawContent contentFor(String langCode) {
    switch (langCode) {
      case 'hi':
        return hi;
      case 'mr':
        return mr;
      default:
        return en;
    }
  }
}

/// Complete offline library of 12 cyber crime law topics (EN + HI + MR).
const List<CyberLawTopic> kCyberLawTopics = [
  // ──────────────────────────────────────────────────────
  // 1. Financial Fraud & UPI Fraud
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'financialFraud',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFEF4444),
    en: CyberLawContent(
      title: 'Financial Fraud & UPI Fraud',
      short: 'IT Act §66C, §66D  •  BNS §318',
      overview:
          'Financial cybercrime includes UPI fraud, OTP theft, credit/debit card fraud, online banking scams, and investment fraud. Criminals use social engineering, phishing calls, and fake apps to steal money. India loses billions annually to such crimes.',
      acts: [
        'IT Act 2000 – Sec 43: Unauthorized access causing data/financial damage; civil compensation up to ₹1 crore payable by offender',
        'IT Act 2000 – Sec 66: Computer-related fraud offences; up to 3 years imprisonment + fine ₹5 lakh',
        'IT Act 2000 – Sec 66C: Identity theft using digital means (e.g. stolen Aadhaar/password); up to 3 years + fine ₹1 lakh',
        'IT Act 2000 – Sec 66D: Cheating by impersonation via computer/internet; up to 3 years + fine ₹1 lakh',
        'BNS 2023 – Sec 318 (formerly IPC §420): Cheating and dishonestly inducing delivery of property; up to 7 years imprisonment',
        'Payment & Settlement Systems Act 2007: Governs regulation of digital payment fraud and UPI ecosystem',
        'RBI Zero-Liability Policy (2017): Customer fully refunded if fraud is reported within 3 working days',
      ],
      punishments: [
        'Sec 66C (Identity Theft): Up to 3 years imprisonment AND/OR fine up to ₹1 lakh',
        'Sec 66D (Impersonation Fraud): Up to 3 years imprisonment AND/OR fine up to ₹1 lakh',
        'BNS Sec 318 / IPC §420 (Cheating): Up to 7 years imprisonment + fine',
        'Sec 43 (Unauthorized Access): Civil liability — compensation up to ₹1 crore payable by offender to victim',
        'Bank Liability: Bank must refund if fraud is reported within 3 days (RBI Circular 2017)',
      ],
      whatToDo: [
        'IMMEDIATELY call your bank\'s 24×7 fraud helpline and request account freeze — every minute counts',
        'NEVER share OTP, PIN, CVV, Aadhaar, or password — banks and government NEVER ask for these',
        'Save all evidence: screenshots, chat messages, transaction IDs, call recordings, and SMS',
        'File complaint at cybercrime.gov.in within 24 hours — early reporting maximises fund recovery',
        'Call Cyber Crime Helpline 1930 (24×7, toll-free) for immediate assistance and bank freeze initiation',
        'Note down the cybercrime complaint acknowledgement number for all future follow-ups',
      ],
      whereToReport: [
        'National Cyber Crime Reporting Portal: cybercrime.gov.in',
        'Cyber Crime Helpline: 1930 (24×7, toll-free)',
        'RBI Banking Ombudsman: cms.rbi.org.in',
        'Your Bank\'s Fraud Helpline (printed on card or passbook)',
        'Nearest Cyber Crime Police Station — file FIR under BNS §318',
      ],
    ),
    hi: CyberLawContent(
      title: 'वित्तीय धोखाधड़ी और UPI फ्रॉड',
      short: 'IT Act §66C, §66D  •  BNS §318',
      overview:
          'वित्तीय साइबर अपराध में UPI फ्रॉड, OTP चोरी, क्रेडिट/डेबिट कार्ड धोखाधड़ी, ऑनलाइन बैंकिंग स्कैम और फर्जी निवेश घोटाले शामिल हैं। अपराधी सोशल इंजीनियरिंग, फर्जी कॉल और नकली ऐप के ज़रिए पीड़ितों का पैसा चुराते हैं।',
      acts: [
        'IT अधिनियम 2000 – धारा 43: अनाधिकृत पहुंच से डेटा/वित्तीय नुकसान; ₹1 करोड़ तक दीवानी मुआवज़ा',
        'IT अधिनियम 2000 – धारा 66: कंप्यूटर आधारित धोखाधड़ी; 3 साल तक कारावास + ₹5 लाख जुर्माना',
        'IT अधिनियम 2000 – धारा 66C: डिजिटल माध्यम से पहचान चोरी; 3 साल + ₹1 लाख जुर्माना',
        'IT अधिनियम 2000 – धारा 66D: कंप्यूटर से प्रतिरूपण करके धोखा; 3 साल + ₹1 लाख जुर्माना',
        'BNS 2023 – धारा 318 (पूर्व IPC §420): धोखाधड़ी एवं संपत्ति हड़पना; 7 साल तक कारावास',
        'भुगतान एवं निपटान प्रणाली अधिनियम 2007: UPI और डिजिटल भुगतान धोखाधड़ी का विनियमन',
        'RBI शून्य देनदारी नीति (2017): 3 कार्यदिवसों में रिपोर्ट करने पर पूरी राशि वापस',
      ],
      punishments: [
        'धारा 66C (पहचान चोरी): 3 साल तक कारावास और/या ₹1 लाख तक जुर्माना',
        'धारा 66D (प्रतिरूपण धोखाधड़ी): 3 साल तक कारावास और/या ₹1 लाख तक जुर्माना',
        'BNS धारा 318 / IPC §420 (धोखाधड़ी): 7 साल तक कारावास + जुर्माना',
        'धारा 43 (अनाधिकृत पहुंच): अपराधी द्वारा पीड़ित को ₹1 करोड़ तक दीवानी मुआवज़ा',
        'बैंक दायित्व: 3 दिन में रिपोर्ट करने पर RBI के तहत राशि वापस',
      ],
      whatToDo: [
        'तुरंत बैंक की 24×7 धोखाधड़ी हेल्पलाइन पर कॉल करें और खाता फ्रीज़ करवाएं',
        'कभी OTP, PIN, CVV या आधार साझा न करें — बैंक या सरकार ये कभी नहीं मांगती',
        'सभी स्क्रीनशॉट, संदेश, ट्रांज़ैक्शन ID और कॉल रिकॉर्डिंग सुरक्षित रखें',
        '24 घंटे के भीतर cybercrime.gov.in पर शिकायत करें — जल्दी कार्रवाई होगी',
        'साइबर क्राइम हेल्पलाइन 1930 पर कॉल करें — 24×7 निःशुल्क सहायता',
        'शिकायत की पावती संख्या (Acknowledgement Number) संभालकर रखें',
      ],
      whereToReport: [
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'साइबर क्राइम हेल्पलाइन: 1930 (24×7, टोल फ्री)',
        'RBI बैंकिंग लोकपाल: cms.rbi.org.in',
        'आपके बैंक की धोखाधड़ी हेल्पलाइन (कार्ड/पासबुक पर)',
        'निकटतम साइबर क्राइम पुलिस थाना — BNS §318 के तहत FIR दर्ज करें',
      ],
    ),
    mr: CyberLawContent(
      title: 'आर्थिक फसवणूक आणि UPI घोटाळा',
      short: 'IT Act §66C, §66D  •  BNS §318',
      overview:
          'आर्थिक सायबर गुन्ह्यांमध्ये UPI घोटाळा, OTP चोरी, क्रेडिट/डेबिट कार्ड फसवणूक, ऑनलाइन बँकिंग घोटाळे आणि बनावट गुंतवणूक योजना यांचा समावेश आहे. गुन्हेगार सोशल इंजिनीअरिंग, बनावट कॉल आणि बनावट अॅपद्वारे पीडितांचे पैसे लुटतात.',
      acts: [
        'IT कायदा 2000 – कलम 43: अनाधिकृत प्रवेशामुळे नुकसान; ₹1 कोटीपर्यंत नुकसानभरपाई (दिवाणी)',
        'IT कायदा 2000 – कलम 66: संगणक आधारित फसवणूक; 3 वर्षांपर्यंत कारावास + ₹5 लाख दंड',
        'IT कायदा 2000 – कलम 66C: डिजिटल माध्यमातून ओळख चोरी; 3 वर्षे + ₹1 लाख दंड',
        'IT कायदा 2000 – कलम 66D: संगणकाद्वारे तोतयागिरी करून फसवणूक; 3 वर्षे + ₹1 लाख दंड',
        'BNS 2023 – कलम 318 (पूर्वी IPC §420): फसवणूक व मालमत्ता लुटणे; 7 वर्षांपर्यंत कारावास',
        'पेमेंट अँड सेटलमेंट सिस्टम्स कायदा 2007: UPI व डिजिटल पेमेंट घोटाळ्यांचे नियमन',
        'RBI शून्य दायित्व धोरण (2017): 3 कार्यदिवसांत तक्रार केल्यास संपूर्ण रक्कम परत',
      ],
      punishments: [
        'कलम 66C (ओळख चोरी): 3 वर्षांपर्यंत कारावास आणि/किंवा ₹1 लाखांपर्यंत दंड',
        'कलम 66D (तोतयागिरी फसवणूक): 3 वर्षांपर्यंत कारावास आणि/किंवा ₹1 लाखांपर्यंत दंड',
        'BNS कलम 318 / IPC §420 (फसवणूक): 7 वर्षांपर्यंत कारावास + दंड',
        'कलम 43 (अनाधिकृत प्रवेश): आरोपीकडून पीडितास ₹1 कोटीपर्यंत नुकसानभरपाई',
        'बँक दायित्व: 3 दिवसांत तक्रार केल्यास RBI मार्गदर्शकतत्त्वांनुसार रक्कम परत',
      ],
      whatToDo: [
        'तात्काळ बँकेच्या 24×7 फसवणूक हेल्पलाइनवर कॉल करा आणि खाते फ्रीझ करण्यास सांगा',
        'कधीही OTP, PIN, CVV किंवा आधार तपशील सामायिक करू नका — बँका हे कधीही विचारत नाहीत',
        'सर्व स्क्रीनशॉट, संदेश, व्यवहार ID आणि कॉल रेकॉर्डिंग पुरावे म्हणून जपा',
        '24 तासांच्या आत cybercrime.gov.in वर तक्रार करा — जलद कार्यवाही होते',
        'सायबर क्राइम हेल्पलाइन 1930 वर कॉल करा — 24×7 निःशुल्क मदत',
        'तक्रारीचा पावती क्रमांक भविष्यातील पाठपुराव्यासाठी सुरक्षित ठेवा',
      ],
      whereToReport: [
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'सायबर क्राइम हेल्पलाइन: 1930 (24×7, टोल फ्री)',
        'RBI बँकिंग लोकपाल: cms.rbi.org.in',
        'आपल्या बँकेची फसवणूक हेल्पलाइन (कार्ड/पासबुकवर)',
        'जवळचे सायबर क्राइम पोलिस स्थानक — BNS §318 अंतर्गत FIR',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 2. Cyber Stalking
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'cyberStalking',
    icon: Icons.location_searching_rounded,
    color: Color(0xFF8B5CF6),
    en: CyberLawContent(
      title: 'Cyber Stalking',
      short: 'BNS §78  •  IT Act §66E, §67',
      overview:
          'Cyber stalking involves repeatedly following, monitoring, harassing, or threatening someone online through email, social media, WhatsApp, or GPS tracking without consent. It causes fear, distress, and psychological harm. Women and minors are disproportionately targeted.',
      acts: [
        'BNS 2023 – Sec 78 (formerly IPC §354D): Stalking offence including following online or tracking digital communications — specific criminal provision for women',
        'IT Act 2000 – Sec 66E: Capturing or publishing private images without consent (voyeurism) — up to 3 years + ₹2 lakh fine',
        'IT Act 2000 – Sec 67: Publishing obscene or harassing material in electronic form',
        'IT Act 2000 – Sec 72: Breach of confidentiality and privacy by misusing access to information',
        'Protection of Women from Domestic Violence Act 2005: Cyber stalking by an intimate partner is also covered',
        'IT (Intermediary Guidelines & Digital Media Ethics Code) Rules 2021: Social media platforms must act on stalking/harassment complaints within 36 hours',
      ],
      punishments: [
        'BNS Sec 78 – First conviction: Imprisonment up to 3 years + fine',
        'BNS Sec 78 – Second or subsequent conviction: Imprisonment up to 5 years + fine (NON-BAILABLE — no bail without court order)',
        'IT Act Sec 66E (Voyeurism): Up to 3 years imprisonment + fine up to ₹2 lakh',
        'IT Act Sec 72 (Privacy Breach): Up to 2 years imprisonment + fine up to ₹1 lakh',
        'Court can also issue a restraining order prohibiting stalker from contacting the victim',
      ],
      whatToDo: [
        'Document ALL incidents with screenshots, timestamps, URLs, and sender details — systematic record is key',
        'Block the stalker immediately on all platforms, but save all evidence BEFORE blocking',
        'Report the harassing account to the platform — platforms must act within 36 hours (IT Rules 2021)',
        'Seek a court-issued restraining order if the stalker is a known person',
        'Inform trusted friends and family for additional physical safety measures',
        'File FIR at nearest police station or complaint at cybercrime.gov.in under BNS §78',
      ],
      whereToReport: [
        'National Cyber Crime Portal: cybercrime.gov.in',
        'Cyber Crime Helpline: 1930 (24×7)',
        'Women Helpline: 181 (free, 24×7)',
        'Nearest Police Station — FIR under BNS §78',
        'NCW Helpline: 7827170170 (National Commission for Women)',
      ],
    ),
    hi: CyberLawContent(
      title: 'साइबर स्टॉकिंग',
      short: 'BNS §78  •  IT Act §66E, §67',
      overview:
          'साइबर स्टॉकिंग में ऑनलाइन बार-बार पीछा करना, निगरानी करना, परेशान करना या धमकियां देना शामिल है। यह ईमेल, सोशल मीडिया, WhatsApp या जीपीएस ट्रैकिंग के ज़रिए बिना सहमति के किया जाता है। इससे पीड़ित को मानसिक पीड़ा और भय होता है।',
      acts: [
        'BNS 2023 – धारा 78 (पूर्व IPC §354D): ऑनलाइन पीछा करना या डिजिटल संचार पर नज़र रखना — महिलाओं के लिए विशेष आपराधिक प्रावधान',
        'IT अधिनियम 2000 – धारा 66E: बिना सहमति के निजी तस्वीरें खींचना/प्रकाशित करना; 3 साल + ₹2 लाख जुर्माना',
        'IT अधिनियम 2000 – धारा 67: ऑनलाइन अश्लील या परेशान करने वाली सामग्री प्रकाशित करना',
        'IT अधिनियम 2000 – धारा 72: गोपनीयता और निजता का उल्लंघन',
        'घरेलू हिंसा से महिलाओं की सुरक्षा अधिनियम 2005: अंतरंग साथी द्वारा साइबर स्टॉकिंग भी इसमें शामिल',
        'IT नियम 2021: सोशल मीडिया प्लेटफॉर्म को 36 घंटे में कार्रवाई करनी होगी',
      ],
      punishments: [
        'BNS धारा 78 – पहला अपराध: 3 साल तक कारावास + जुर्माना',
        'BNS धारा 78 – दूसरा या बाद का अपराध: 5 साल तक कारावास + जुर्माना (गैर-जमानती)',
        'IT Act धारा 66E (दृश्यरतिकता): 3 साल तक कारावास + ₹2 लाख तक जुर्माना',
        'IT Act धारा 72 (गोपनीयता उल्लंघन): 2 साल तक कारावास + ₹1 लाख जुर्माना',
        'न्यायालय स्टॉकर को पीड़ित से संपर्क करने से रोकने का आदेश भी दे सकता है',
      ],
      whatToDo: [
        'सभी घटनाओं का दस्तावेज़ीकरण करें — स्क्रीनशॉट, टाइमस्टैम्प, URL और प्रेषक विवरण',
        'स्टॉकर को ब्लॉक करने से पहले सभी सबूत सुरक्षित करें, फिर ब्लॉक करें',
        'प्लेटफॉर्म पर खाते की रिपोर्ट करें — 36 घंटे में कार्रवाई होनी चाहिए',
        'यदि स्टॉकर जाना-पहचाना व्यक्ति है तो न्यायालय से प्रतिबंध आदेश लें',
        'भरोसेमंद परिवार और मित्रों को स्थिति की जानकारी दें',
        'BNS §78 के तहत नजदीकी पुलिस थाने में FIR या cybercrime.gov.in पर शिकायत करें',
      ],
      whereToReport: [
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'साइबर क्राइम हेल्पलाइन: 1930 (24×7)',
        'महिला हेल्पलाइन: 181 (निःशुल्क, 24×7)',
        'निकटतम पुलिस थाना — BNS §78 के तहत FIR',
        'NCW हेल्पलाइन: 7827170170 (राष्ट्रीय महिला आयोग)',
      ],
    ),
    mr: CyberLawContent(
      title: 'सायबर स्टॉकिंग',
      short: 'BNS §78  •  IT Act §66E, §67',
      overview:
          'सायबर स्टॉकिंगमध्ये ऑनलाइन वारंवार पाठलाग करणे, निगराणी ठेवणे, त्रास देणे किंवा धमक्या देणे यांचा समावेश आहे. हे ईमेल, सोशल मीडिया, WhatsApp किंवा GPS ट्रॅकिंगद्वारे संमतीशिवाय केले जाते. पीडितास भीती, त्रास आणि मानसिक वेदना होतात.',
      acts: [
        'BNS 2023 – कलम 78 (पूर्वी IPC §354D): ऑनलाइन पाठलाग किंवा डिजिटल संचारावर नजर ठेवणे — महिलांसाठी विशेष गुन्हेगारी तरतूद',
        'IT कायदा 2000 – कलम 66E: संमतीशिवाय खाजगी प्रतिमा टिपणे/प्रकाशित करणे; 3 वर्षे + ₹2 लाख दंड',
        'IT कायदा 2000 – कलम 67: ऑनलाइन अश्लील किंवा त्रासदायक साहित्य प्रकाशित करणे',
        'IT कायदा 2000 – कलम 72: गोपनीयता आणि खाजगीपणाचे उल्लंघन',
        'घरगुती हिंसाचारापासून महिलांचे संरक्षण कायदा 2005: जोडीदाराद्वारे सायबर स्टॉकिंग देखील समाविष्ट',
        'IT नियम 2021: सोशल मीडिया प्लॅटफॉर्मने 36 तासांत कार्यवाही करणे बंधनकारक',
      ],
      punishments: [
        'BNS कलम 78 – पहिला गुन्हा: 3 वर्षांपर्यंत कारावास + दंड',
        'BNS कलम 78 – दुसरा किंवा त्यानंतरचा गुन्हा: 5 वर्षांपर्यंत कारावास + दंड (अजामीनपात्र)',
        'IT Act कलम 66E (दृश्यरतिकता): 3 वर्षांपर्यंत कारावास + ₹2 लाखांपर्यंत दंड',
        'IT Act कलम 72 (गोपनीयता उल्लंघन): 2 वर्षांपर्यंत कारावास + ₹1 लाख दंड',
        'न्यायालय स्टॉकरला पीडितेशी संपर्क करण्यापासून रोखणारा आदेशही देऊ शकते',
      ],
      whatToDo: [
        'सर्व घटनांचे दस्तऐवजीकरण करा — स्क्रीनशॉट, टाइमस्टॅम्प, URL आणि प्रेषक तपशील',
        'स्टॉकरला ब्लॉक करण्यापूर्वी सर्व पुरावे सुरक्षित करा, मग ब्लॉक करा',
        'प्लॅटफॉर्मवर खात्याची तक्रार करा — 36 तासांत कार्यवाही होणे आवश्यक आहे',
        'स्टॉकर ओळखीचा असल्यास न्यायालयाकडून प्रतिबंधात्मक आदेश मिळवा',
        'विश्वासू कुटुंब आणि मित्रांना परिस्थितीची माहिती द्या',
        'BNS §78 अंतर्गत जवळच्या पोलिस स्थानकात FIR किंवा cybercrime.gov.in वर तक्रार करा',
      ],
      whereToReport: [
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'सायबर क्राइम हेल्पलाइन: 1930 (24×7)',
        'महिला हेल्पलाइन: 181 (मोफत, 24×7)',
        'जवळचे पोलिस स्थानक — BNS §78 अंतर्गत FIR',
        'NCW हेल्पलाइन: 7827170170 (राष्ट्रीय महिला आयोग)',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 3. Online Harassment & Bullying
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'onlineHarassment',
    icon: Icons.sentiment_very_dissatisfied_rounded,
    color: Color(0xFFF97316),
    en: CyberLawContent(
      title: 'Online Harassment & Bullying',
      short: 'BNS §351, §356  •  IT Rules 2021',
      overview:
          'Online harassment includes repeated abusive messages, threats, hate speech, defamation, trolling, and doxxing (exposing private information). It targets victims on social media, WhatsApp, email, and other platforms, causing psychological harm. Platforms are legally bound to act within 36 hours.',
      acts: [
        'BNS 2023 – Sec 351 (formerly IPC §506): Criminal intimidation — threatening victim with injury, property damage, or reputation harm online',
        'BNS 2023 – Sec 356 (formerly IPC §499, §500): Defamation — publishing false facts to damage reputation online',
        'BNS 2023 – Sec 308(1) (formerly IPC §384): Extortion — coercing victim through threats to extract money or compliance',
        'IT Act 2000 – Sec 67: Publishing obscene, harassing, or threatening content in electronic form',
        'IT (Intermediary Guidelines) Rules 2021: Platforms must remove reported harmful content within 36 hours; sexual content within 24 hours',
        'IT Act 2000 – Sec 66A: Struck down by Supreme Court in Shreya Singhal v. UOI (2015) — IPC/BNS provisions remain valid and applicable',
      ],
      punishments: [
        'BNS Sec 351 (Criminal Intimidation): Up to 2 years imprisonment + fine; up to 7 years if threat is of death or grievous hurt',
        'BNS Sec 356 (Defamation): Up to 2 years simple imprisonment + fine',
        'IT Act Sec 67 (Harassing Online Publication): Up to 3 years + fine ₹5 lakh on first conviction; up to 5 years + ₹10 lakh on second conviction',
        'Platform Liability: Platforms can be sued for damages if they fail to remove reported content within mandated timelines',
      ],
      whatToDo: [
        'Screenshot and save all harassing messages, posts, and comments with timestamps and URLs immediately',
        'Report the account and content to the platform using the "Report" feature — platform must act in 36 hours',
        'Do NOT engage with or respond to the harasser — silence is safer and doesn\'t escalate the situation',
        'Build a systematic record of all harassment instances (pattern of repeated conduct strengthens your legal case)',
        'File complaint at cybercrime.gov.in if platform fails to remove content within 36 hours',
        'If threats are credible or severe, contact police immediately — criminal intimidation is a cognisable offence',
      ],
      whereToReport: [
        'National Cyber Crime Portal: cybercrime.gov.in',
        'Cyber Crime Helpline: 1930',
        'Platform\'s Trust & Safety / Report feature (Instagram, Facebook, Twitter/X, etc.)',
        'NCW Online Complaint: ncwapps.nic.in (for women victims)',
        'Nearest Police Station — FIR under BNS §351 for serious threats',
      ],
    ),
    hi: CyberLawContent(
      title: 'ऑनलाइन उत्पीड़न और साइबरबुलिंग',
      short: 'BNS §351, §356  •  IT नियम 2021',
      overview:
          'ऑनलाइन उत्पीड़न में बार-बार अपमानजनक संदेश, धमकियां, घृणास्पद भाषण, मानहानि, ट्रोलिंग और व्यक्तिगत जानकारी उजागर करना (डॉक्सिंग) शामिल है। इससे पीड़ित को मानसिक पीड़ा होती है। प्लेटफॉर्म को 36 घंटे में कार्रवाई करना कानूनन अनिवार्य है।',
      acts: [
        'BNS 2023 – धारा 351 (पूर्व IPC §506): आपराधिक धमकी — ऑनलाइन चोट, संपत्ति नुकसान या बदनामी की धमकी',
        'BNS 2023 – धारा 356 (पूर्व IPC §499, §500): मानहानि — ऑनलाइन प्रतिष्ठा को नुकसान पहुंचाने के लिए झूठी बातें फैलाना',
        'BNS 2023 – धारा 308(1) (पूर्व IPC §384): जबरन वसूली — धमकी देकर पैसे या अनुपालन निकालना',
        'IT अधिनियम 2000 – धारा 67: इलेक्ट्रॉनिक माध्यम में अश्लील या परेशान करने वाली सामग्री प्रकाशित करना',
        'IT नियम 2021: प्लेटफॉर्म को 36 घंटे में हानिकारक सामग्री हटानी होगी; यौन सामग्री 24 घंटे में',
      ],
      punishments: [
        'BNS धारा 351 (आपराधिक धमकी): 2 साल तक कारावास + जुर्माना; मृत्यु या गंभीर चोट की धमकी पर 7 साल तक',
        'BNS धारा 356 (मानहानि): 2 साल तक सरल कारावास + जुर्माना',
        'IT Act धारा 67 (हानिकारक ऑनलाइन प्रकाशन): पहला अपराध — 3 साल + ₹5 लाख; दूसरा — 5 साल + ₹10 लाख',
        'प्लेटफॉर्म दायित्व: निर्धारित समय में सामग्री न हटाने पर प्लेटफॉर्म पर मुकदमा संभव',
      ],
      whatToDo: [
        'तुरंत सभी परेशान करने वाले संदेश, पोस्ट और टिप्पणियां टाइमस्टैम्प के साथ स्क्रीनशॉट करें',
        'प्लेटफॉर्म पर खाते और सामग्री की रिपोर्ट करें — 36 घंटे में कार्रवाई होनी चाहिए',
        'उत्पीड़क से बिल्कुल जवाब न दें — चुप रहना सुरक्षित है',
        'सभी उत्पीड़न की घटनाओं का व्यवस्थित रिकॉर्ड रखें — पैटर्न आपके मामले को मजबूत करता है',
        'यदि प्लेटफॉर्म 36 घंटे में कार्रवाई न करे तो cybercrime.gov.in पर शिकायत करें',
        'यदि धमकियां गंभीर हैं तो तुरंत पुलिस से संपर्क करें',
      ],
      whereToReport: [
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'साइबर क्राइम हेल्पलाइन: 1930',
        'प्लेटफॉर्म की रिपोर्ट सुविधा (Instagram, Facebook आदि)',
        'NCW ऑनलाइन शिकायत: ncwapps.nic.in (महिला पीड़ितों के लिए)',
        'निकटतम पुलिस थाना — BNS §351 के तहत FIR',
      ],
    ),
    mr: CyberLawContent(
      title: 'ऑनलाइन छळवणूक आणि सायबर बुलिंग',
      short: 'BNS §351, §356  •  IT नियम 2021',
      overview:
          'ऑनलाइन छळवणुकीत वारंवार अपमानकारक संदेश, धमक्या, द्वेषपूर्ण भाषण, बदनामी, ट्रोलिंग आणि खाजगी माहिती उघड करणे (डॉक्सिंग) यांचा समावेश आहे. यामुळे पीडितास मानसिक त्रास होतो. प्लॅटफॉर्मला 36 तासांत कार्यवाही करणे कायद्याने बंधनकारक आहे.',
      acts: [
        'BNS 2023 – कलम 351 (पूर्वी IPC §506): गुन्हेगारी धमकी — ऑनलाइन दुखापत, मालमत्ता नुकसान किंवा बदनामीची धमकी',
        'BNS 2023 – कलम 356 (पूर्वी IPC §499, §500): बदनामी — ऑनलाइन प्रतिष्ठा हानीसाठी खोट्या गोष्टी पसरवणे',
        'BNS 2023 – कलम 308(1) (पूर्वी IPC §384): खंडणी — धमकी देऊन पैसे किंवा अनुपालन उकळणे',
        'IT कायदा 2000 – कलम 67: इलेक्ट्रॉनिक माध्यमात अश्लील किंवा त्रासदायक साहित्य प्रकाशित करणे',
        'IT नियम 2021: प्लॅटफॉर्मने 36 तासांत हानिकारक साहित्य काढणे बंधनकारक; लैंगिक साहित्य 24 तासांत',
      ],
      punishments: [
        'BNS कलम 351 (गुन्हेगारी धमकी): 2 वर्षांपर्यंत कारावास + दंड; मृत्यू/गंभीर दुखापतीच्या धमकीसाठी 7 वर्षांपर्यंत',
        'BNS कलम 356 (बदनामी): 2 वर्षांपर्यंत साधा कारावास + दंड',
        'IT Act कलम 67 (हानिकारक ऑनलाइन प्रकाशन): पहिला गुन्हा — 3 वर्षे + ₹5 लाख; दुसरा — 5 वर्षे + ₹10 लाख',
        'प्लॅटफॉर्म दायित्व: ठरलेल्या वेळेत साहित्य न काढल्यास प्लॅटफॉर्मवर दावा शक्य',
      ],
      whatToDo: [
        'तात्काळ सर्व त्रासदायक संदेश, पोस्ट आणि टिप्पण्या टाइमस्टॅम्पसह स्क्रीनशॉट करा',
        'प्लॅटफॉर्मवर खाते आणि साहित्याची तक्रार करा — 36 तासांत कार्यवाही व्हायला हवी',
        'छळ करणाऱ्याला बिल्कुल प्रतिसाद देऊ नका — शांत राहणे सुरक्षित आहे',
        'सर्व छळवणुकीच्या घटनांची व्यवस्थित नोंद ठेवा — पॅटर्न तुमचा कायदेशीर मामला मजबूत करतो',
        'प्लॅटफॉर्मने 36 तासांत कार्यवाही न केल्यास cybercrime.gov.in वर तक्रार करा',
        'धमक्या गंभीर असल्यास तात्काळ पोलिसांशी संपर्क साधा',
      ],
      whereToReport: [
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'सायबर क्राइम हेल्पलाइन: 1930',
        'प्लॅटफॉर्मची तक्रार सुविधा (Instagram, Facebook इ.)',
        'NCW ऑनलाइन तक्रार: ncwapps.nic.in (महिला पीडितांसाठी)',
        'जवळचे पोलिस स्थानक — BNS §351 अंतर्गत FIR',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 4. Identity Theft
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'identityTheft',
    icon: Icons.person_off_rounded,
    color: Color(0xFFEC4899),
    en: CyberLawContent(
      title: 'Identity Theft',
      short: 'IT Act §66C, §66D  •  BNS §319',
      overview:
          'Identity theft involves stealing personal data — Aadhaar, PAN, bank details, passwords — to impersonate the victim for financial gain, fraud, or other crimes. Attackers open accounts, take loans, or conduct transactions in the victim\'s name without their knowledge.',
      acts: [
        'IT Act 2000 – Sec 66C: Dishonestly or fraudulently using someone\'s electronic signature, password, or unique identification feature — specific identity theft provision',
        'IT Act 2000 – Sec 66D: Cheating by personation using a computer resource or communication device',
        'BNS 2023 – Sec 319 (formerly IPC §419): Cheating by personation — impersonating another real person',
        'BNS 2023 – Sec 318 (formerly IPC §420): Cheating and dishonestly inducing delivery of property',
        'BNS 2023 – Sec 336(3) (formerly IPC §465): Forgery — creating false electronic documents using stolen identity',
        'Aadhaar Act 2016 – Sec 29, 37: Unauthorized use or disclosure of Aadhaar identity information; up to 3 years + ₹10,000 fine',
        'DPDP Act 2023: Organizations holding personal data have strict protection obligations; fines up to ₹250 crore',
      ],
      punishments: [
        'IT Act Sec 66C (Identity Theft): Up to 3 years imprisonment AND/OR fine up to ₹1 lakh',
        'IT Act Sec 66D (Cheating by Impersonation): Up to 3 years imprisonment AND/OR fine up to ₹1 lakh',
        'BNS Sec 319 (Cheating by Personation): Up to 3 years imprisonment + fine',
        'BNS Sec 318 (Cheating): Up to 7 years imprisonment + fine',
        'BNS Sec 336 (Forgery): Up to 2 years imprisonment + fine',
        'Aadhaar Act Sec 37: Up to 3 years imprisonment + fine up to ₹10,000',
      ],
      whatToDo: [
        'Change ALL passwords immediately — email, bank, social media, Aadhaar, and all other accounts',
        'Check your CIBIL or credit report for unauthorized loans, credit cards, or credit inquiries in your name',
        'Report Aadhaar misuse to UIDAI helpline 1947 immediately and request lock/freeze of biometric data',
        'Inform your bank to freeze accounts and dispute any unauthorized transactions',
        'File complaint at cybercrime portal with all evidence of misuse',
        'Get a police FIR copy — banks and credit agencies require FIR to reverse fraudulent entries',
      ],
      whereToReport: [
        'National Cyber Crime Portal: cybercrime.gov.in',
        'Cyber Crime Helpline: 1930',
        'UIDAI Aadhaar Helpline: 1947',
        'RBI Ombudsman (for banking fraud): cms.rbi.org.in',
        'Credit Bureau — CIBIL / Experian: to flag fraudulent credit entries',
        'Nearest Police Station for FIR under IT Act §66C',
      ],
    ),
    hi: CyberLawContent(
      title: 'पहचान की चोरी',
      short: 'IT Act §66C, §66D  •  BNS §319',
      overview:
          'पहचान की चोरी में आधार, पैन, बैंक विवरण, पासवर्ड जैसे व्यक्तिगत डेटा चुराकर पीड़ित का रूप धारण करना शामिल है। अपराधी पीड़ित के नाम पर खाते खोलते हैं, ऋण लेते हैं या लेनदेन करते हैं।',
      acts: [
        'IT अधिनियम 2000 – धारा 66C: किसी की इलेक्ट्रॉनिक पहचान (पासवर्ड/डिजिटल हस्ताक्षर) का बेईमानी से उपयोग — विशेष पहचान चोरी प्रावधान',
        'IT अधिनियम 2000 – धारा 66D: कंप्यूटर का उपयोग करके प्रतिरूपण द्वारा धोखा',
        'BNS 2023 – धारा 319 (पूर्व IPC §419): प्रतिरूपण द्वारा धोखाधड़ी',
        'BNS 2023 – धारा 318 (पूर्व IPC §420): धोखाधड़ी एवं संपत्ति हड़पना',
        'BNS 2023 – धारा 336(3) (पूर्व IPC §465): जालसाजी — चुराई गई पहचान से झूठे दस्तावेज़ बनाना',
        'आधार अधिनियम 2016 – धारा 29, 37: आधार जानकारी का अनाधिकृत उपयोग या प्रकटीकरण; 3 साल + ₹10,000 जुर्माना',
        'DPDP अधिनियम 2023: संगठनों पर कड़े डेटा संरक्षण दायित्व; ₹250 करोड़ तक जुर्माना',
      ],
      punishments: [
        'IT Act धारा 66C (पहचान चोरी): 3 साल तक कारावास और/या ₹1 लाख तक जुर्माना',
        'IT Act धारा 66D (प्रतिरूपण धोखाधड़ी): 3 साल तक कारावास और/या ₹1 लाख तक जुर्माना',
        'BNS धारा 319 (प्रतिरूपण): 3 साल तक कारावास + जुर्माना',
        'BNS धारा 318 (धोखाधड़ी): 7 साल तक कारावास + जुर्माना',
        'BNS धारा 336 (जालसाजी): 2 साल तक कारावास + जुर्माना',
        'आधार Act धारा 37: 3 साल तक कारावास + ₹10,000 जुर्माना',
      ],
      whatToDo: [
        'सभी पासवर्ड तुरंत बदलें — ईमेल, बैंक, सोशल मीडिया, आधार और अन्य खाते',
        'CIBIL या क्रेडिट रिपोर्ट जांचें — अपने नाम पर अनाधिकृत ऋण या क्रेडिट कार्ड खोजें',
        'आधार दुरुपयोग की सूचना UIDAI हेल्पलाइन 1947 पर दें और बायोमेट्रिक लॉक करें',
        'बैंक को सूचित कर खाता फ्रीज़ करें और अनाधिकृत लेनदेन का विवाद करें',
        'सभी सबूतों के साथ साइबर क्राइम पोर्टल पर शिकायत दर्ज करें',
        'पुलिस FIR की कॉपी लें — बैंक और क्रेडिट एजेंसियां इसे ज़रूरी मानती हैं',
      ],
      whereToReport: [
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'साइबर क्राइम हेल्पलाइन: 1930',
        'UIDAI आधार हेल्पलाइन: 1947',
        'RBI लोकपाल (बैंकिंग धोखाधड़ी): cms.rbi.org.in',
        'क्रेडिट ब्यूरो — CIBIL/Experian: धोखाधड़ी की प्रविष्टियां हटाने के लिए',
        'निकटतम पुलिस थाना — IT Act §66C के तहत FIR',
      ],
    ),
    mr: CyberLawContent(
      title: 'ओळख चोरी',
      short: 'IT Act §66C, §66D  •  BNS §319',
      overview:
          'ओळख चोरीत आधार, PAN, बँक तपशील, पासवर्ड यासारखी वैयक्तिक माहिती चोरून पीडितेचे तोतयेपण करणे समाविष्ट आहे. गुन्हेगार पीडिताच्या नावाने खाती उघडतात, कर्जे घेतात किंवा व्यवहार करतात.',
      acts: [
        'IT कायदा 2000 – कलम 66C: एखाद्याची इलेक्ट्रॉनिक ओळख (पासवर्ड/डिजिटल स्वाक्षरी) बेप्रामाणिकपणे वापरणे — विशेष ओळख चोरी तरतूद',
        'IT कायदा 2000 – कलम 66D: संगणकाद्वारे तोतयागिरी करून फसवणूक',
        'BNS 2023 – कलम 319 (पूर्वी IPC §419): तोतयागिरीद्वारे फसवणूक',
        'BNS 2023 – कलम 318 (पूर्वी IPC §420): फसवणूक व मालमत्ता लुटणे',
        'BNS 2023 – कलम 336(3) (पूर्वी IPC §465): बनावट — चोरलेल्या ओळखीने खोटे दस्तऐवज तयार करणे',
        'आधार कायदा 2016 – कलम 29, 37: आधार माहितीचा अनाधिकृत वापर किंवा प्रकटीकरण; 3 वर्षे + ₹10,000 दंड',
        'DPDP कायदा 2023: संस्थांवर कठोर डेटा संरक्षण बंधने; ₹250 कोटीपर्यंत दंड',
      ],
      punishments: [
        'IT Act कलम 66C (ओळख चोरी): 3 वर्षांपर्यंत कारावास आणि/किंवा ₹1 लाखांपर्यंत दंड',
        'IT Act कलम 66D (तोतयागिरी फसवणूक): 3 वर्षांपर्यंत कारावास आणि/किंवा ₹1 लाखांपर्यंत दंड',
        'BNS कलम 319 (तोतयागिरी): 3 वर्षांपर्यंत कारावास + दंड',
        'BNS कलम 318 (फसवणूक): 7 वर्षांपर्यंत कारावास + दंड',
        'BNS कलम 336 (बनावट): 2 वर्षांपर्यंत कारावास + दंड',
        'आधार Act कलम 37: 3 वर्षांपर्यंत कारावास + ₹10,000 दंड',
      ],
      whatToDo: [
        'सर्व पासवर्ड तात्काळ बदला — ईमेल, बँक, सोशल मीडिया, आधार आणि इतर खाती',
        'CIBIL किंवा क्रेडिट रिपोर्ट तपासा — आपल्या नावावर अनाधिकृत कर्जे किंवा क्रेडिट कार्ड शोधा',
        'आधार गैरवापराची माहिती UIDAI हेल्पलाइन 1947 ला द्या आणि बायोमेट्रिक लॉक करा',
        'बँकेला सूचित करून खाते फ्रीझ करा आणि अनाधिकृत व्यवहारांवर आक्षेप घ्या',
        'सर्व पुराव्यांसह सायबर क्राइम पोर्टलवर तक्रार दाखल करा',
        'पोलिस FIR ची प्रत घ्या — बँका आणि क्रेडिट एजन्सींना ती आवश्यक असते',
      ],
      whereToReport: [
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'सायबर क्राइम हेल्पलाइन: 1930',
        'UIDAI आधार हेल्पलाइन: 1947',
        'RBI लोकपाल (बँकिंग फसवणूक): cms.rbi.org.in',
        'क्रेडिट ब्युरो — CIBIL/Experian: फसवणुकीच्या नोंदी काढण्यासाठी',
        'जवळचे पोलिस स्थानक — IT Act §66C अंतर्गत FIR',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 5. Blackmail & Sextortion
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'blackmail',
    icon: Icons.lock_person_rounded,
    color: Color(0xFFDC2626),
    en: CyberLawContent(
      title: 'Blackmail & Sextortion',
      short: 'IT Act §67, §67A  •  BNS §308, §73',
      overview:
          'Blackmail and sextortion involve threatening to publish intimate, private, or compromising images/videos unless the victim pays money or complies with demands. Often starts with fake relationships online to obtain private content. This is a rapidly growing crime targeting people of all ages.',
      acts: [
        'IT Act 2000 – Sec 67: Publishing or transmitting obscene material in electronic form — criminal offence',
        'IT Act 2000 – Sec 67A: Publishing or transmitting material containing sexually explicit acts — stricter punishment',
        'IT Act 2000 – Sec 66E: Capturing, publishing or transmitting images of a person\'s private area without consent (voyeurism)',
        'BNS 2023 – Sec 308 (formerly IPC §384): Extortion — putting a person in fear to dishonestly induce them to deliver property or money',
        'BNS 2023 – Sec 73 (formerly IPC §354C): Voyeurism — watching or capturing intimate images of a woman',
        'POCSO Act 2012: If victim is a minor (under 18 years), far stricter provisions apply — mandatory reporting required',
      ],
      punishments: [
        'IT Act Sec 67 (Obscene Online Material): First conviction — up to 3 years + fine ₹5 lakh; second conviction — up to 5 years + fine ₹10 lakh',
        'IT Act Sec 67A (Sexually Explicit Material): First conviction — up to 5 years + fine ₹10 lakh; second conviction — up to 7 years + fine ₹10 lakh',
        'IT Act Sec 66E (Privacy Violation/Voyeurism): Up to 3 years imprisonment + fine up to ₹2 lakh',
        'BNS Sec 308 (Extortion): Up to 3 years imprisonment + fine; up to 10 years for armed extortion',
        'BNS Sec 73 (Voyeurism): First conviction — 1 to 3 years; second conviction — 3 to 7 years imprisonment',
      ],
      whatToDo: [
        'DO NOT pay any money — payment only encourages more demands and provides NO guarantee of safety',
        'DO NOT send more images, videos, or comply with any further demands under ANY circumstances',
        'Document all threats immediately: screenshots of all messages, chats, calls with timestamps',
        'Report the content to the platform for emergency takedown — most platforms have a 24-hour priority process',
        'File cybercrime complaint IMMEDIATELY — police can initiate emergency platform takedown orders',
        'Seek mental health support — this is a traumatic criminal attack and you deserve professional help',
        'If victim is a minor, contact Childline 1098 immediately',
      ],
      whereToReport: [
        'National Cyber Crime Portal: cybercrime.gov.in',
        'Cyber Crime Helpline: 1930 (24×7 — TREAT AS EMERGENCY)',
        'Women Helpline: 181',
        'Childline: 1098 (if minor is involved)',
        'Nearest Police Station — FIR under IT Act §67A + BNS §308',
      ],
    ),
    hi: CyberLawContent(
      title: 'ब्लैकमेल और सेक्सटॉर्शन',
      short: 'IT Act §67, §67A  •  BNS §308, §73',
      overview:
          'ब्लैकमेल और सेक्सटॉर्शन में पीड़ित की अंतरंग या समझौता करने वाली तस्वीरें/वीडियो प्रकाशित करने की धमकी देकर पैसे या अनुपालन मांगा जाता है। अक्सर नकली ऑनलाइन रिश्ते बनाकर निजी सामग्री प्राप्त की जाती है। यह सभी उम्र के लोगों को प्रभावित करने वाला तेज़ी से बढ़ता अपराध है।',
      acts: [
        'IT अधिनियम 2000 – धारा 67: इलेक्ट्रॉनिक माध्यम में अश्लील सामग्री प्रकाशित/प्रसारित करना',
        'IT अधिनियम 2000 – धारा 67A: यौन स्पष्ट सामग्री प्रकाशित/प्रसारित करना — कड़ी सज़ा',
        'IT अधिनियम 2000 – धारा 66E: बिना सहमति के निजी क्षेत्र की तस्वीरें खींचना/प्रकाशित करना',
        'BNS 2023 – धारा 308 (पूर्व IPC §384): जबरन वसूली — डर पैदा करके पैसे या संपत्ति हड़पना',
        'BNS 2023 – धारा 73 (पूर्व IPC §354C): दृश्यरतिकता — महिला की अंतरंग तस्वीरें खींचना/वितरित करना',
        'POCSO अधिनियम 2012: यदि पीड़ित नाबालिग (18 वर्ष से कम) है तो बहुत कड़े प्रावधान लागू',
      ],
      punishments: [
        'IT Act धारा 67 (अश्लील ऑनलाइन सामग्री): पहला — 3 साल + ₹5 लाख; दूसरा — 5 साल + ₹10 लाख',
        'IT Act धारा 67A (यौन स्पष्ट सामग्री): पहला — 5 साल + ₹10 लाख; दूसरा — 7 साल + ₹10 लाख',
        'IT Act धारा 66E (गोपनीयता उल्लंघन): 3 साल तक कारावास + ₹2 लाख जुर्माना',
        'BNS धारा 308 (जबरन वसूली): 3 साल तक कारावास + जुर्माना; हथियार के साथ 10 साल तक',
        'BNS धारा 73 (दृश्यरतिकता): पहला — 1 से 3 साल; दूसरा — 3 से 7 साल कारावास',
      ],
      whatToDo: [
        'कभी पैसे न दें — पैसे देने से और मांग बढ़ती है, कोई गारंटी नहीं मिलती',
        'किसी भी परिस्थिति में और तस्वीरें/वीडियो न भेजें और मांगों का पालन न करें',
        'सभी धमकियों का दस्तावेज़ीकरण करें — टाइमस्टैम्प के साथ संदेश, चैट स्क्रीनशॉट',
        'प्लेटफॉर्म पर सामग्री की आपातकालीन रिपोर्ट करें — 24 घंटे की प्राथमिकता प्रक्रिया',
        'तुरंत साइबर क्राइम शिकायत दर्ज करें — पुलिस प्लेटफॉर्म पर आपातकालीन टेकडाउन का आदेश दे सकती है',
        'मानसिक स्वास्थ्य सहायता लें — यह एक आपराधिक हमला है, आप अकेले नहीं हैं',
        'यदि पीड़ित नाबालिग है तो तुरंत चाइल्डलाइन 1098 से संपर्क करें',
      ],
      whereToReport: [
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'साइबर क्राइम हेल्पलाइन: 1930 (24×7 — आपातकालीन)',
        'महिला हेल्पलाइन: 181',
        'चाइल्डलाइन: 1098 (यदि नाबालिग पीड़ित हो)',
        'निकटतम पुलिस थाना — IT Act §67A + BNS §308 के तहत FIR',
      ],
    ),
    mr: CyberLawContent(
      title: 'ब्लॅकमेल आणि सेक्सटॉर्शन',
      short: 'IT Act §67, §67A  •  BNS §308, §73',
      overview:
          'ब्लॅकमेल आणि सेक्सटॉर्शनमध्ये पीडिताच्या अंतरंग किंवा समझोत्याच्या प्रतिमा/व्हिडिओ प्रकाशित करण्याची धमकी देऊन पैसे किंवा अनुपालनाची मागणी केली जाते. बहुतेकदा बनावट ऑनलाइन नाते जोडून खाजगी साहित्य मिळवले जाते.',
      acts: [
        'IT कायदा 2000 – कलम 67: इलेक्ट्रॉनिक माध्यमात अश्लील साहित्य प्रकाशित/प्रसारित करणे',
        'IT कायदा 2000 – कलम 67A: लैंगिकदृष्ट्या स्पष्ट साहित्य प्रकाशित/प्रसारित करणे — कठोर शिक्षा',
        'IT कायदा 2000 – कलम 66E: संमतीशिवाय खाजगी भागाच्या प्रतिमा टिपणे/प्रकाशित करणे',
        'BNS 2023 – कलम 308 (पूर्वी IPC §384): खंडणी — भीती निर्माण करून पैसे किंवा मालमत्ता उकळणे',
        'BNS 2023 – कलम 73 (पूर्वी IPC §354C): दृश्यरतिकता — महिलेच्या अंतरंग प्रतिमा टिपणे/वितरित करणे',
        'POCSO कायदा 2012: पीडित अल्पवयीन (18 वर्षांखालील) असल्यास अत्यंत कठोर तरतुदी लागू',
      ],
      punishments: [
        'IT Act कलम 67 (अश्लील ऑनलाइन साहित्य): पहिला — 3 वर्षे + ₹5 लाख; दुसरा — 5 वर्षे + ₹10 लाख',
        'IT Act कलम 67A (लैंगिक साहित्य): पहिला — 5 वर्षे + ₹10 लाख; दुसरा — 7 वर्षे + ₹10 लाख',
        'IT Act कलम 66E (गोपनीयता उल्लंघन): 3 वर्षांपर्यंत कारावास + ₹2 लाख दंड',
        'BNS कलम 308 (खंडणी): 3 वर्षांपर्यंत कारावास + दंड; शस्त्रासह 10 वर्षांपर्यंत',
        'BNS कलम 73 (दृश्यरतिकता): पहिला — 1 ते 3 वर्षे; दुसरा — 3 ते 7 वर्षे कारावास',
      ],
      whatToDo: [
        'कधीही पैसे देऊ नका — पैसे दिल्याने आणखी मागण्या वाढतात, कोणतीही हमी नाही',
        'कोणत्याही परिस्थितीत आणखी प्रतिमा/व्हिडिओ पाठवू नका आणि मागण्यांचे पालन करू नका',
        'सर्व धमक्यांचे दस्तऐवजीकरण करा — टाइमस्टॅम्पसह संदेश, चॅट स्क्रीनशॉट',
        'प्लॅटफॉर्मवर साहित्याची आपातकालीन तक्रार करा — 24 तासांची प्राधान्य प्रक्रिया',
        'तात्काळ सायबर क्राइम तक्रार दाखल करा — पोलिस प्लॅटफॉर्मवर आपातकालीन टेकडाऊन आदेश देऊ शकतात',
        'मानसिक आरोग्य सहाय्य घ्या — हा एक गुन्हेगारी हल्ला आहे, तुम्ही एकटे नाही',
        'पीडित अल्पवयीन असल्यास तात्काळ चाइल्डलाइन 1098 शी संपर्क करा',
      ],
      whereToReport: [
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'सायबर क्राइम हेल्पलाइन: 1930 (24×7 — आपातकालीन)',
        'महिला हेल्पलाइन: 181',
        'चाइल्डलाइन: 1098 (अल्पवयीन पीडित असल्यास)',
        'जवळचे पोलिस स्थानक — IT Act §67A + BNS §308 अंतर्गत FIR',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 6. Fake Profile & Impersonation
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'fakeProfile',
    icon: Icons.face_retouching_off_rounded,
    color: Color(0xFF0EA5E9),
    en: CyberLawContent(
      title: 'Fake Profile & Impersonation',
      short: 'IT Act §66D  •  BNS §319, §336',
      overview:
          'Fake profiles involve creating fraudulent social media accounts impersonating real people to deceive others, damage reputation, or conduct financial fraud. Catfishing uses fake identities to emotionally manipulate victims, often leading to blackmail or money theft.',
      acts: [
        'IT Act 2000 – Sec 66D: Cheating by personation using a computer resource or communication device — directly applicable to fake profiles',
        'IT Act 2000 – Sec 66C: Identity theft — using someone\'s name, photo, or identity without consent',
        'BNS 2023 – Sec 319 (formerly IPC §419): Cheating by personation — impersonating a real person',
        'BNS 2023 – Sec 336(2) (formerly IPC §468): Forgery for the purpose of cheating via fake identity',
        'BNS 2023 – Sec 356 (formerly IPC §499): Defamation — using fake profile to post harmful content about the victim',
        'IT (Intermediary Guidelines) Rules 2021: Social media platforms must verify accounts and remove fake profiles within 36 hours of complaint',
      ],
      punishments: [
        'IT Act Sec 66C (Identity Theft): Up to 3 years + fine up to ₹1 lakh',
        'IT Act Sec 66D (Cheating by Personation): Up to 3 years + fine up to ₹1 lakh',
        'BNS Sec 319 (Cheating by Personation): Up to 3 years imprisonment + fine',
        'BNS Sec 336 (Forgery): Up to 2 years imprisonment + fine',
        'BNS Sec 356 (Defamation via fake profile): Up to 2 years simple imprisonment + fine',
      ],
      whatToDo: [
        'Report the fake profile to the platform IMMEDIATELY using the "Impersonation" report category',
        'Send a formal legal notice to the platform demanding takedown and cessation of impersonation',
        'Gather evidence: screenshots of the fake profile, posts, and any messages sent using it',
        'Alert your friends and contacts not to engage with or share content from the fake profile',
        'File complaint at cybercrime portal — platforms must act within 36 hours under IT Rules 2021',
        'If reputation is damaged, you may also pursue a civil defamation suit',
      ],
      whereToReport: [
        'National Cyber Crime Portal: cybercrime.gov.in',
        'Cyber Crime Helpline: 1930',
        'Platform\'s impersonation reporting feature (Instagram/Facebook/Twitter use "Pretending to be someone" category)',
        'Nearest Police Station — FIR under BNS §319 or §66D',
        'NCW (if a woman\'s profile is impersonated): ncwapps.nic.in',
      ],
    ),
    hi: CyberLawContent(
      title: 'नकली प्रोफाइल और प्रतिरूपण',
      short: 'IT Act §66D  •  BNS §319, §336',
      overview:
          'नकली प्रोफाइल में असली लोगों की नकल करने वाले फर्जी सोशल मीडिया खाते बनाए जाते हैं ताकि दूसरों को धोखा दिया जा सके, प्रतिष्ठा को नुकसान हो या वित्तीय धोखाधड़ी की जाए। कैटफिशिंग में नकली पहचान से भावनात्मक हेरफेर किया जाता है जो अक्सर ब्लैकमेल में बदल जाता है।',
      acts: [
        'IT अधिनियम 2000 – धारा 66D: कंप्यूटर का उपयोग करके प्रतिरूपण द्वारा धोखा — नकली प्रोफाइल पर सीधे लागू',
        'IT अधिनियम 2000 – धारा 66C: पहचान चोरी — बिना सहमति के किसी का नाम, फोटो या पहचान उपयोग',
        'BNS 2023 – धारा 319 (पूर्व IPC §419): प्रतिरूपण द्वारा धोखाधड़ी',
        'BNS 2023 – धारा 336(2) (पूर्व IPC §468): धोखाधड़ी के उद्देश्य से जालसाजी',
        'BNS 2023 – धारा 356 (पूर्व IPC §499): मानहानि — नकली प्रोफाइल से पीड़ित के बारे में हानिकारक सामग्री पोस्ट करना',
        'IT नियम 2021: सोशल मीडिया प्लेटफॉर्म को शिकायत के 36 घंटे में नकली प्रोफाइल हटानी होगी',
      ],
      punishments: [
        'IT Act धारा 66C (पहचान चोरी): 3 साल तक कारावास + ₹1 लाख जुर्माना',
        'IT Act धारा 66D (प्रतिरूपण धोखाधड़ी): 3 साल तक कारावास + ₹1 लाख जुर्माना',
        'BNS धारा 319 (प्रतिरूपण): 3 साल तक कारावास + जुर्माना',
        'BNS धारा 336 (जालसाजी): 2 साल तक कारावास + जुर्माना',
        'BNS धारा 356 (मानहानि): 2 साल तक सरल कारावास + जुर्माना',
      ],
      whatToDo: [
        'तुरंत प्लेटफॉर्म पर नकली प्रोफाइल की "प्रतिरूपण" श्रेणी में रिपोर्ट करें',
        'प्लेटफॉर्म को औपचारिक कानूनी नोटिस भेजें — प्रोफाइल हटाने की मांग करें',
        'सबूत इकट्ठा करें: नकली प्रोफाइल, पोस्ट और संदेशों के स्क्रीनशॉट',
        'अपने दोस्तों और संपर्कों को नकली प्रोफाइल से न जुड़ने की सलाह दें',
        'साइबर क्राइम पोर्टल पर शिकायत दर्ज करें — IT नियम 2021 के तहत 36 घंटे में कार्रवाई',
        'यदि प्रतिष्ठा को नुकसान हुआ है तो दीवानी मानहानि का मुकदमा भी दायर कर सकते हैं',
      ],
      whereToReport: [
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'साइबर क्राइम हेल्पलाइन: 1930',
        'प्लेटफॉर्म की प्रतिरूपण रिपोर्टिंग सुविधा (Instagram/Facebook — "किसी का रूप धारण" श्रेणी)',
        'निकटतम पुलिस थाना — BNS §319 या §66D के तहत FIR',
        'NCW (महिला प्रोफाइल का प्रतिरूपण): ncwapps.nic.in',
      ],
    ),
    mr: CyberLawContent(
      title: 'बनावट प्रोफाइल आणि तोतयागिरी',
      short: 'IT Act §66D  •  BNS §319, §336',
      overview:
          'बनावट प्रोफाइलमध्ये खऱ्या लोकांची नकल करणारी बनावट सोशल मीडिया खाती तयार केली जातात ज्यामुळे इतरांची फसवणूक होते, प्रतिष्ठेचे नुकसान होते किंवा आर्थिक फसवणूक होते. कॅटफिशिंगमध्ये बनावट ओळखीने भावनिक हेरफेर केले जाते जे अनेकदा ब्लॅकमेलमध्ये बदलते.',
      acts: [
        'IT कायदा 2000 – कलम 66D: संगणकाद्वारे तोतयागिरी करून फसवणूक — बनावट प्रोफाइलला थेट लागू',
        'IT कायदा 2000 – कलम 66C: ओळख चोरी — संमतीशिवाय एखाद्याचे नाव, फोटो किंवा ओळख वापरणे',
        'BNS 2023 – कलम 319 (पूर्वी IPC §419): तोतयागिरीद्वारे फसवणूक',
        'BNS 2023 – कलम 336(2) (पूर्वी IPC §468): फसवणुकीच्या उद्देशाने बनावट',
        'BNS 2023 – कलम 356 (पूर्वी IPC §499): बदनामी — बनावट प्रोफाइलद्वारे हानिकारक साहित्य पोस्ट करणे',
        'IT नियम 2021: सोशल मीडिया प्लॅटफॉर्मने तक्रारीनंतर 36 तासांत बनावट प्रोफाइल काढणे बंधनकारक',
      ],
      punishments: [
        'IT Act कलम 66C (ओळख चोरी): 3 वर्षांपर्यंत कारावास + ₹1 लाख दंड',
        'IT Act कलम 66D (तोतयागिरी फसवणूक): 3 वर्षांपर्यंत कारावास + ₹1 लाख दंड',
        'BNS कलम 319 (तोतयागिरी): 3 वर्षांपर्यंत कारावास + दंड',
        'BNS कलम 336 (बनावट): 2 वर्षांपर्यंत कारावास + दंड',
        'BNS कलम 356 (बदनामी): 2 वर्षांपर्यंत साधा कारावास + दंड',
      ],
      whatToDo: [
        'तात्काळ प्लॅटफॉर्मवर बनावट प्रोफाइलची "तोतयागिरी" श्रेणीत तक्रार करा',
        'प्लॅटफॉर्मला औपचारिक कायदेशीर नोटीस पाठवा — प्रोफाइल काढण्याची मागणी करा',
        'पुरावे गोळा करा: बनावट प्रोफाइल, पोस्ट आणि संदेशांचे स्क्रीनशॉट',
        'आपल्या मित्र आणि संपर्कांना बनावट प्रोफाइलशी संवाद न साधण्याचा सल्ला द्या',
        'सायबर क्राइम पोर्टलवर तक्रार करा — IT नियम 2021 अंतर्गत 36 तासांत कार्यवाही',
        'प्रतिष्ठेचे नुकसान झाल्यास दिवाणी बदनामीचा दावाही दाखल करता येतो',
      ],
      whereToReport: [
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'सायबर क्राइम हेल्पलाइन: 1930',
        'प्लॅटफॉर्मची तोतयागिरी तक्रार सुविधा (Instagram/Facebook — "दुसऱ्याचे भासवणे" श्रेणी)',
        'जवळचे पोलिस स्थानक — BNS §319 किंवा §66D अंतर्गत FIR',
        'NCW (महिला प्रोफाइलची तोतयागिरी): ncwapps.nic.in',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 7. Deepfake & Morphed Images
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'deepfakeThreat',
    icon: Icons.camera_alt_rounded,
    color: Color(0xFF7C3AED),
    en: CyberLawContent(
      title: 'Deepfake & Morphed Images',
      short: 'IT Act §67A, §66E  •  BNS §77',
      overview:
          'Deepfake technology uses AI to superimpose a person\'s face onto explicit or compromising content. Morphed images digitally alter genuine photos to create defamatory or sexual fake content. Both are tools of harassment, blackmail, and reputation destruction, increasingly weaponised against women.',
      acts: [
        'IT Act 2000 – Sec 66E: Capturing, publishing, or transmitting images of a person\'s private area without consent',
        'IT Act 2000 – Sec 67: Publishing or transmitting obscene content in electronic form — applicable to deepfakes',
        'IT Act 2000 – Sec 67A: Publishing sexually explicit content — applies to AI-generated deepfakes and morphed images',
        'BNS 2023 – Sec 77 (formerly IPC §354C): Voyeurism — capturing or distributing intimate images without consent',
        'BNS 2023 – Sec 356 (formerly IPC §499, §500): Defamation via deepfake content',
        'IT Amendment Rules 2023 (Rule 3(1)(b)(vii)): Platforms MUST NOT host synthetic/deepfake content designed to mislead',
        'DPDP Act 2023: Unauthorized use of biometric or facial data for AI generation violates data protection law',
        'POCSO Act 2012 + IT Act Sec 67B: Deepfakes involving minors attract the strictest penalties including death',
      ],
      punishments: [
        'IT Act Sec 67A (Sexually Explicit Deepfake): First conviction — up to 5 years + fine ₹10 lakh; second — up to 7 years + ₹10 lakh',
        'IT Act Sec 66E (Privacy Violation): Up to 3 years imprisonment + fine up to ₹2 lakh',
        'BNS Sec 77 (Voyeurism): First conviction — 1 to 3 years; second conviction — 3 to 7 years',
        'IT Act Sec 67 (Obscene Deepfake): First conviction — up to 3 years + fine ₹5 lakh',
        'Additional charges of defamation (BNS §356) and extortion (BNS §308) if used for blackmail',
      ],
      whatToDo: [
        'Do NOT share or forward the deepfake content — sharing spreads harm and may make you liable',
        'Report the content to the platform IMMEDIATELY for emergency content removal',
        'File cybercrime complaint — police can issue urgent takedown orders to platforms within 24 hours',
        'Document everything: URLs, source accounts, messages threatening to spread content, timestamps',
        'Contact a cyber lawyer for an emergency injunction if content is spreading rapidly across platforms',
        'Report AI tools/apps used to generate the deepfake to MEITY',
        'Seek mental health support — this is a criminal attack on your dignity',
      ],
      whereToReport: [
        'National Cyber Crime Portal: cybercrime.gov.in',
        'Cyber Crime Helpline: 1930 (Emergency)',
        'MEITY Grievance Portal: meity.gov.in',
        'Women Helpline: 181',
        'Childline: 1098 (if minor is targeted)',
        'Nearest Police Station for FIR under IT Act §67A + §66E',
      ],
    ),
    hi: CyberLawContent(
      title: 'डीपफेक और मॉर्फड तस्वीरें',
      short: 'IT Act §67A, §66E  •  BNS §77',
      overview:
          'डीपफेक तकनीक AI का उपयोग करके किसी व्यक्ति का चेहरा स्पष्ट या समझौता करने वाली सामग्री पर लगाती है। मॉर्फड तस्वीरें असली फोटो को डिजिटल रूप से बदलकर मानहानिकारक या यौन फर्जी सामग्री बनाती हैं। दोनों उत्पीड़न, ब्लैकमेल और प्रतिष्ठा नष्ट करने के हथियार हैं।',
      acts: [
        'IT अधिनियम 2000 – धारा 66E: बिना सहमति के निजी क्षेत्र की तस्वीरें खींचना/प्रकाशित करना',
        'IT अधिनियम 2000 – धारा 67: अश्लील सामग्री प्रकाशित/प्रसारित करना — डीपफेक पर लागू',
        'IT अधिनियम 2000 – धारा 67A: यौन स्पष्ट सामग्री प्रकाशित/प्रसारित करना — AI डीपफेक पर लागू',
        'BNS 2023 – धारा 77 (पूर्व IPC §354C): दृश्यरतिकता — बिना सहमति के अंतरंग तस्वीरें खींचना/वितरित करना',
        'BNS 2023 – धारा 356 (पूर्व IPC §499, §500): डीपफेक सामग्री के माध्यम से मानहानि',
        'IT संशोधन नियम 2023: प्लेटफॉर्म सिंथेटिक/डीपफेक सामग्री होस्ट नहीं कर सकते',
        'DPDP अधिनियम 2023: AI जनरेशन के लिए बायोमेट्रिक डेटा का अनाधिकृत उपयोग उल्लंघन है',
        'POCSO + IT Act §67B: नाबालिग से जुड़े डीपफेक पर मृत्युदंड तक की सज़ा',
      ],
      punishments: [
        'IT Act धारा 67A (यौन डीपफेक): पहला — 5 साल + ₹10 लाख; दूसरा — 7 साल + ₹10 लाख',
        'IT Act धारा 66E (गोपनीयता उल्लंघन): 3 साल तक कारावास + ₹2 लाख जुर्माना',
        'BNS धारा 77 (दृश्यरतिकता): पहला — 1 से 3 साल; दूसरा — 3 से 7 साल कारावास',
        'IT Act धारा 67 (अश्लील डीपफेक): 3 साल तक + ₹5 लाख जुर्माना',
        'ब्लैकमेल के लिए उपयोग होने पर मानहानि (BNS §356) और जबरन वसूली (BNS §308) के अतिरिक्त आरोप',
      ],
      whatToDo: [
        'डीपफेक सामग्री को साझा या अग्रेषित न करें — साझा करने से नुकसान बढ़ता है',
        'तुरंत प्लेटफॉर्म पर आपातकालीन रिपोर्ट करें — सामग्री हटाने की मांग करें',
        'साइबर क्राइम शिकायत दर्ज करें — पुलिस 24 घंटे में टेकडाउन आदेश दे सकती है',
        'URL, सोर्स खाते, संदेश और टाइमस्टैम्प सहित सब कुछ दस्तावेज़ करें',
        'यदि सामग्री तेज़ी से फैल रही है तो साइबर वकील से आपातकालीन निषेधाज्ञा लें',
        'डीपफेक बनाने वाले AI टूल की भी MEITY पर रिपोर्ट करें',
        'मानसिक स्वास्थ्य सहायता लें — यह आपकी गरिमा पर आपराधिक हमला है',
      ],
      whereToReport: [
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'साइबर क्राइम हेल्पलाइन: 1930 (आपातकालीन)',
        'MEITY शिकायत पोर्टल: meity.gov.in',
        'महिला हेल्पलाइन: 181',
        'चाइल्डलाइन: 1098 (यदि नाबालिग लक्ष्य है)',
        'निकटतम पुलिस थाना — IT Act §67A + §66E के तहत FIR',
      ],
    ),
    mr: CyberLawContent(
      title: 'डीपफेक आणि मॉर्फड प्रतिमा',
      short: 'IT Act §67A, §66E  •  BNS §77',
      overview:
          'डीपफेक तंत्रज्ञान AI वापरून एखाद्याचा चेहरा स्पष्ट किंवा समझोत्याच्या साहित्यावर लावते. मॉर्फड प्रतिमा खऱ्या फोटोंमध्ये बदल करून बदनामीकारक किंवा लैंगिक बनावट साहित्य तयार करतात. दोन्ही छळवणूक, ब्लॅकमेल आणि प्रतिष्ठा नष्ट करण्याची साधने आहेत.',
      acts: [
        'IT कायदा 2000 – कलम 66E: संमतीशिवाय खाजगी भागाच्या प्रतिमा टिपणे/प्रकाशित करणे',
        'IT कायदा 2000 – कलम 67: अश्लील साहित्य प्रकाशित/प्रसारित करणे — डीपफेकला लागू',
        'IT कायदा 2000 – कलम 67A: लैंगिकदृष्ट्या स्पष्ट साहित्य — AI डीपफेकला लागू',
        'BNS 2023 – कलम 77 (पूर्वी IPC §354C): दृश्यरतिकता — संमतीशिवाय अंतरंग प्रतिमा टिपणे/वितरित करणे',
        'BNS 2023 – कलम 356 (पूर्वी IPC §499, §500): डीपफेक साहित्याद्वारे बदनामी',
        'IT सुधारणा नियम 2023: प्लॅटफॉर्म सिंथेटिक/डीपफेक साहित्य होस्ट करू शकत नाहीत',
        'DPDP कायदा 2023: AI निर्मितीसाठी बायोमेट्रिक डेटाचा अनाधिकृत वापर उल्लंघन आहे',
      ],
      punishments: [
        'IT Act कलम 67A (लैंगिक डीपफेक): पहिला — 5 वर्षे + ₹10 लाख; दुसरा — 7 वर्षे + ₹10 लाख',
        'IT Act कलम 66E (गोपनीयता उल्लंघन): 3 वर्षांपर्यंत कारावास + ₹2 लाख दंड',
        'BNS कलम 77 (दृश्यरतिकता): पहिला — 1 ते 3 वर्षे; दुसरा — 3 ते 7 वर्षे कारावास',
        'IT Act कलम 67 (अश्लील डीपफेक): 3 वर्षांपर्यंत + ₹5 लाख दंड',
        'ब्लॅकमेलसाठी वापरल्यास बदनामी (BNS §356) आणि खंडणी (BNS §308) चे अतिरिक्त आरोप',
      ],
      whatToDo: [
        'डीपफेक साहित्य सामायिक किंवा अग्रेषित करू नका — सामायिक केल्याने हानी वाढते',
        'तात्काळ प्लॅटफॉर्मवर आपातकालीन तक्रार करा — साहित्य काढण्याची मागणी करा',
        'सायबर क्राइम तक्रार दाखल करा — पोलिस 24 तासांत टेकडाऊन आदेश देऊ शकतात',
        'URL, स्रोत खाती, संदेश आणि टाइमस्टॅम्पसह सर्व काही नोंदवा',
        'साहित्य वेगाने पसरत असल्यास सायबर वकिलाकडून आपातकालीन मनाई हुकूम मिळवा',
        'डीपफेक तयार करणाऱ्या AI टूलची MEITY ला तक्रार करा',
        'मानसिक आरोग्य सहाय्य घ्या — हा तुमच्या प्रतिष्ठेवर गुन्हेगारी हल्ला आहे',
      ],
      whereToReport: [
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'सायबर क्राइम हेल्पलाइन: 1930 (आपातकालीन)',
        'MEITY तक्रार पोर्टल: meity.gov.in',
        'महिला हेल्पलाइन: 181',
        'चाइल्डलाइन: 1098 (अल्पवयीन लक्ष्य असल्यास)',
        'जवळचे पोलिस स्थानक — IT Act §67A + §66E अंतर्गत FIR',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 8. Phishing & Data Theft
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'phishing',
    icon: Icons.phishing_rounded,
    color: Color(0xFF059669),
    en: CyberLawContent(
      title: 'Phishing & Data Theft',
      short: 'IT Act §43, §66, §66B',
      overview:
          'Phishing tricks victims into revealing passwords, card numbers, or OTPs through fake emails, websites, SMS, or calls mimicking real institutions. Data theft is unauthorized access to stored personal or financial data. India\'s CERT-In handles national-level cybersecurity incidents.',
      acts: [
        'IT Act 2000 – Sec 43: Unauthorized access to computer, network, or data — civil compensation up to ₹1 crore',
        'IT Act 2000 – Sec 66: Computer-related offences — dishonest or fraudulent access/data manipulation — criminal provision',
        'IT Act 2000 – Sec 66B: Dishonestly receiving or retaining any stolen computer resource or data',
        'IT Act 2000 – Sec 43A: Organizations must implement reasonable security practices for sensitive personal data; failure = liability to pay compensation to victims',
        'DPDP Act 2023: Strict data protection obligations; fines up to ₹250 crore for organizations',
        'RBI Cybersecurity Framework: Banks must report data breaches to RBI within 6 hours',
        'CERT-In Directions 2022: Organizations must report cybersecurity incidents to CERT-In within 6 hours',
      ],
      punishments: [
        'IT Act Sec 66 (Computer Fraud): Up to 3 years imprisonment + fine up to ₹5 lakh',
        'IT Act Sec 66B (Receiving Stolen Data): Up to 3 years imprisonment + fine up to ₹1 lakh',
        'IT Act Sec 43 (Unauthorized Access): Civil compensation up to ₹1 crore payable to victim (not criminal)',
        'IT Act Sec 43A (Corporate Negligence): Organisation ordered to pay compensation to affected individuals',
        'DPDP Act 2023: Organizations face fines up to ₹250 crore for data breaches caused by negligence',
      ],
      whatToDo: [
        'NEVER click links in unsolicited emails, SMS, or WhatsApp messages — always type website addresses manually',
        'Verify website URLs carefully — fake sites differ by one letter (e.g. hdfcbank.com vs hdfc-bank.com)',
        'If you accidentally shared credentials, change all passwords immediately on every account',
        'Contact your bank IMMEDIATELY if financial details were exposed',
        'Scan your device for malware using a reputable antivirus tool',
        'Organizations must report the breach to CERT-In within 6 hours and affected users must be notified',
      ],
      whereToReport: [
        'National Cyber Crime Portal: cybercrime.gov.in',
        'Cyber Crime Helpline: 1930',
        'CERT-In (Indian Computer Emergency Response Team): cert-in.org.in | incidents@cert-in.org.in',
        'Your Bank\'s Fraud Helpline (on card or passbook)',
        'Nearest Cyber Crime Police Station for FIR under IT Act §66',
      ],
    ),
    hi: CyberLawContent(
      title: 'फिशिंग और डेटा चोरी',
      short: 'IT Act §43, §66, §66B',
      overview:
          'फिशिंग में फर्जी ईमेल, वेबसाइट, SMS या कॉल के ज़रिए पीड़ित को पासवर्ड, कार्ड नंबर या OTP बताने के लिए बरगलाया जाता है। डेटा चोरी में बिना सहमति के संग्रहीत व्यक्तिगत या वित्तीय डेटा तक अनाधिकृत पहुंच होती है। CERT-In राष्ट्रीय स्तर की साइबर सुरक्षा घटनाओं को संभालता है।',
      acts: [
        'IT अधिनियम 2000 – धारा 43: अनाधिकृत पहुंच; ₹1 करोड़ तक दीवानी मुआवज़ा',
        'IT अधिनियम 2000 – धारा 66: कंप्यूटर आधारित धोखाधड़ी या डेटा हेरफेर — आपराधिक प्रावधान',
        'IT अधिनियम 2000 – धारा 66B: चोरी किए गए कंप्यूटर डेटा को बेईमानी से प्राप्त या रखना',
        'IT अधिनियम 2000 – धारा 43A: संगठनों को संवेदनशील डेटा के लिए उचित सुरक्षा प्रथाएं लागू करनी होंगी',
        'DPDP अधिनियम 2023: कड़े डेटा संरक्षण दायित्व; ₹250 करोड़ तक जुर्माना',
        'RBI साइबर सुरक्षा ढांचा: बैंकों को 6 घंटे में RBI को डेटा उल्लंघन की रिपोर्ट देनी होगी',
        'CERT-In निर्देश 2022: संगठनों को 6 घंटे में CERT-In को साइबर सुरक्षा घटना की रिपोर्ट करनी होगी',
      ],
      punishments: [
        'IT Act धारा 66 (कंप्यूटर धोखाधड़ी): 3 साल तक कारावास + ₹5 लाख जुर्माना',
        'IT Act धारा 66B (चोरी डेटा प्राप्त करना): 3 साल तक कारावास + ₹1 लाख जुर्माना',
        'IT Act धारा 43 (अनाधिकृत पहुंच): ₹1 करोड़ तक दीवानी मुआवज़ा (आपराधिक नहीं)',
        'IT Act धारा 43A (कॉर्पोरेट लापरवाही): संगठन को पीड़ितों को मुआवज़ा देने का आदेश',
        'DPDP अधिनियम 2023: डेटा उल्लंघन पर संगठनों पर ₹250 करोड़ तक जुर्माना',
      ],
      whatToDo: [
        'अनचाहे ईमेल, SMS या WhatsApp संदेशों में लिंक पर कभी क्लिक न करें — URL हमेशा मैन्युअल टाइप करें',
        'वेबसाइट URL ध्यान से जांचें — नकली साइटें एक अक्षर से भिन्न होती हैं',
        'यदि गलती से क्रेडेंशियल साझा हो गए तो सभी पासवर्ड तुरंत बदलें',
        'वित्तीय विवरण उजागर होने पर तुरंत बैंक से संपर्क करें',
        'एक प्रतिष्ठित एंटीवायरस टूल से डिवाइस स्कैन करें',
        'संगठनों को 6 घंटे में CERT-In को उल्लंघन की रिपोर्ट देनी होगी',
      ],
      whereToReport: [
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'साइबर क्राइम हेल्पलाइन: 1930',
        'CERT-In: cert-in.org.in | incidents@cert-in.org.in',
        'आपके बैंक की धोखाधड़ी हेल्पलाइन',
        'निकटतम साइबर क्राइम पुलिस थाना — IT Act §66 के तहत FIR',
      ],
    ),
    mr: CyberLawContent(
      title: 'फिशिंग आणि डेटा चोरी',
      short: 'IT Act §43, §66, §66B',
      overview:
          'फिशिंगमध्ये बनावट ईमेल, वेबसाइट, SMS किंवा कॉलद्वारे पीडितास पासवर्ड, कार्ड क्रमांक किंवा OTP सांगण्यासाठी फसवले जाते. डेटा चोरीत संग्रहित वैयक्तिक किंवा आर्थिक डेटामध्ये संमतीशिवाय अनाधिकृत प्रवेश होतो. CERT-In राष्ट्रीय स्तरावरील सायबर सुरक्षा घटना हाताळते.',
      acts: [
        'IT कायदा 2000 – कलम 43: अनाधिकृत प्रवेश; ₹1 कोटीपर्यंत दिवाणी नुकसानभरपाई',
        'IT कायदा 2000 – कलम 66: संगणक आधारित फसवणूक किंवा डेटा फेरफार — गुन्हेगारी तरतूद',
        'IT कायदा 2000 – कलम 66B: चोरलेला संगणक डेटा बेप्रामाणिकपणे प्राप्त करणे किंवा ठेवणे',
        'IT कायदा 2000 – कलम 43A: संस्थांनी संवेदनशील डेटासाठी योग्य सुरक्षा पद्धती लागू कराव्यात',
        'DPDP कायदा 2023: कठोर डेटा संरक्षण बंधने; ₹250 कोटीपर्यंत दंड',
        'CERT-In निर्देश 2022: संस्थांनी 6 तासांत CERT-In ला सायबर सुरक्षा घटनेची तक्रार करणे बंधनकारक',
      ],
      punishments: [
        'IT Act कलम 66 (संगणक फसवणूक): 3 वर्षांपर्यंत कारावास + ₹5 लाख दंड',
        'IT Act कलम 66B (चोरलेला डेटा प्राप्त करणे): 3 वर्षांपर्यंत कारावास + ₹1 लाख दंड',
        'IT Act कलम 43 (अनाधिकृत प्रवेश): ₹1 कोटीपर्यंत दिवाणी नुकसानभरपाई (गुन्हेगारी नव्हे)',
        'IT Act कलम 43A (कॉर्पोरेट निष्काळजीपणा): संस्थेला पीडितांना नुकसानभरपाई देण्याचा आदेश',
        'DPDP कायदा 2023: डेटा उल्लंघनावर संस्थांना ₹250 कोटीपर्यंत दंड',
      ],
      whatToDo: [
        'अनाहूत ईमेल, SMS किंवा WhatsApp संदेशांतील दुव्यांवर कधीही क्लिक करू नका — URL नेहमी स्वतः टाइप करा',
        'वेबसाइट URL काळजीपूर्वक तपासा — बनावट साइट्स एका अक्षराने वेगळ्या असतात',
        'चुकून क्रेडेन्शियल सामायिक झाल्यास तात्काळ सर्व पासवर्ड बदला',
        'आर्थिक तपशील उघड झाल्यास तात्काळ बँकेशी संपर्क करा',
        'प्रतिष्ठित अँटीव्हायरस टूलने डिव्हाइस स्कॅन करा',
        'संस्थांनी 6 तासांत CERT-In ला उल्लंघनाची तक्रार देणे अनिवार्य आहे',
      ],
      whereToReport: [
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'सायबर क्राइम हेल्पलाइन: 1930',
        'CERT-In: cert-in.org.in | incidents@cert-in.org.in',
        'आपल्या बँकेची फसवणूक हेल्पलाइन',
        'जवळचे सायबर क्राइम पोलिस स्थानक — IT Act §66 अंतर्गत FIR',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 9. Child Safety & POCSO
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'childSafety',
    icon: Icons.child_care_rounded,
    color: Color(0xFF2563EB),
    en: CyberLawContent(
      title: 'Child Safety Online & POCSO',
      short: 'POCSO 2012  •  IT Act §67B  •  BNS §94',
      overview:
          'Cybercrimes against children include Child Sexual Abuse Material (CSAM), online grooming, solicitation for sexual acts, cyberbullying, and exploitation through social media. India\'s POCSO Act provides strong legal protection for all children below 18 years. Reporting is MANDATORY by law for everyone — failure to report is itself a punishable crime.',
      acts: [
        'IT Act 2000 – Sec 67B: Publishing, transmitting, or browsing child sexual abuse material (CSAM) — strict liability, no intent required',
        'POCSO Act 2012: Comprehensive protection for children under 18 from sexual offences, including online grooming and solicitation',
        'POCSO Amendment Act 2019: Introduced death penalty for aggravated penetrative sexual assault of children',
        'BNS 2023 – Sec 94: Child sexual exploitation and online grooming provisions in new criminal code',
        'IT Act 2000 – Sec 67A: Sexually explicit material involving minors — additional charge',
        'POCSO Act Sec 19: ANY PERSON who has knowledge of a POCSO offence MUST report it to police immediately — failure is punishable with up to 6 months imprisonment',
        'Juvenile Justice Act 2015: Care and protection of child victims',
      ],
      punishments: [
        'IT Act Sec 67B (CSAM): First conviction — up to 5 years + fine ₹10 lakh; second conviction — up to 7 years + fine ₹10 lakh',
        'POCSO – Penetrative Sexual Assault: Minimum 7 years; aggravated cases — minimum 10 years to life imprisonment',
        'POCSO Amendment 2019 – Aggravated Sexual Assault on Children: Death penalty possible in worst cases',
        'POCSO – Sexual Harassment of Child: Minimum 3 years imprisonment',
        'POCSO Sec 19 – Failure to Report: Up to 6 months imprisonment (MANDATORY REPORTING OBLIGATION)',
      ],
      whatToDo: [
        'Report IMMEDIATELY without any delay — every minute matters for child safety',
        'Do NOT delete any evidence — screenshots, chat history, links, and files are critical for securing conviction',
        'Do NOT confront the perpetrator directly — it may alert them and they may destroy evidence',
        'Contact Childline 1098 immediately for intervention, support, and counseling',
        'File complaint at cybercrime.gov.in — CSAM complaints are treated as the HIGHEST PRIORITY',
        'Seek immediate medical and psychological support for the child victim',
        'As a bystander, you are legally REQUIRED to report — silence makes you complicit',
      ],
      whereToReport: [
        'National Cyber Crime Portal: cybercrime.gov.in (CSAM is highest priority — processed fastest)',
        'Childline: 1098 (free, 24×7 — for children in any danger)',
        'NCPCR: 1800-121-2830 (National Commission for Protection of Child Rights)',
        'Local Police Station (FIR under POCSO is mandatory — police MUST register it)',
        'Cyber Crime Helpline: 1930',
      ],
    ),
    hi: CyberLawContent(
      title: 'बाल सुरक्षा और POCSO',
      short: 'POCSO 2012  •  IT Act §67B  •  BNS §94',
      overview:
          'बच्चों के विरुद्ध साइबर अपराधों में बाल यौन शोषण सामग्री (CSAM), ऑनलाइन ग्रूमिंग, यौन कार्यों के लिए प्रलोभन और सोशल मीडिया के माध्यम से शोषण शामिल है। भारत का POCSO अधिनियम 18 वर्ष से कम सभी बच्चों को मज़बूत कानूनी सुरक्षा देता है। रिपोर्टिंग सभी के लिए कानूनन अनिवार्य है — न करने पर सज़ा हो सकती है।',
      acts: [
        'IT अधिनियम 2000 – धारा 67B: बाल यौन शोषण सामग्री (CSAM) प्रकाशित/प्रसारित/देखना — सख्त दायित्व',
        'POCSO अधिनियम 2012: 18 वर्ष से कम बच्चों को यौन अपराधों से व्यापक सुरक्षा, ऑनलाइन ग्रूमिंग सहित',
        'POCSO संशोधन अधिनियम 2019: बच्चों पर गंभीर यौन हमले के लिए मृत्युदंड का प्रावधान',
        'BNS 2023 – धारा 94: बाल यौन शोषण और ऑनलाइन ग्रूमिंग के प्रावधान',
        'IT अधिनियम 2000 – धारा 67A: नाबालिग से जुड़ी यौन स्पष्ट सामग्री — अतिरिक्त आरोप',
        'POCSO धारा 19: POCSO अपराध की जानकारी रखने वाला कोई भी व्यक्ति पुलिस को तुरंत रिपोर्ट करने के लिए बाध्य है — न करने पर 6 माह तक कारावास',
      ],
      punishments: [
        'IT Act धारा 67B (CSAM): पहला — 5 साल + ₹10 लाख; दूसरा — 7 साल + ₹10 लाख',
        'POCSO – लैंगिक भेदक हमला: न्यूनतम 7 साल; गंभीर मामलों में न्यूनतम 10 साल से आजीवन कारावास',
        'POCSO संशोधन 2019 – बच्चों पर गंभीर हमला: सबसे गंभीर मामलों में मृत्युदंड संभव',
        'POCSO – बाल यौन उत्पीड़न: न्यूनतम 3 साल कारावास',
        'POCSO धारा 19 – रिपोर्ट न करना: 6 माह तक कारावास (रिपोर्टिंग अनिवार्य है)',
      ],
      whatToDo: [
        'बिना किसी देरी के तुरंत रिपोर्ट करें — बाल सुरक्षा में हर मिनट महत्वपूर्ण है',
        'कोई सबूत न मिटाएं — स्क्रीनशॉट, चैट इतिहास, लिंक और फ़ाइलें सज़ा दिलाने में महत्वपूर्ण हैं',
        'अपराधी से सीधे सामना न करें — वे सबूत नष्ट कर सकते हैं',
        'चाइल्डलाइन 1098 से तुरंत संपर्क करें — हस्तक्षेप, सहायता और परामर्श के लिए',
        'cybercrime.gov.in पर शिकायत करें — CSAM शिकायतें सर्वोच्च प्राथमिकता पर संसाधित होती हैं',
        'बच्चे के लिए तुरंत चिकित्सा और मनोवैज्ञानिक सहायता लें',
        'दर्शक के रूप में भी, आप रिपोर्ट करने के लिए कानूनन बाध्य हैं',
      ],
      whereToReport: [
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in (CSAM — सर्वोच्च प्राथमिकता)',
        'चाइल्डलाइन: 1098 (निःशुल्क, 24×7)',
        'NCPCR: 1800-121-2830 (राष्ट्रीय बाल अधिकार संरक्षण आयोग)',
        'स्थानीय पुलिस थाना (POCSO के तहत FIR दर्ज करना अनिवार्य)',
        'साइबर क्राइम हेल्पलाइन: 1930',
      ],
    ),
    mr: CyberLawContent(
      title: 'बाल सुरक्षा आणि POCSO',
      short: 'POCSO 2012  •  IT Act §67B  •  BNS §94',
      overview:
          'मुलांविरुद्ध सायबर गुन्ह्यांमध्ये बाल लैंगिक शोषण साहित्य (CSAM), ऑनलाइन ग्रूमिंग, लैंगिक कृत्यांसाठी आमिष आणि सोशल मीडियाद्वारे शोषण यांचा समावेश आहे. POCSO कायदा 18 वर्षांखालील सर्व मुलांना मजबूत कायदेशीर संरक्षण देतो. तक्रार करणे सर्वांसाठी कायद्याने अनिवार्य आहे.',
      acts: [
        'IT कायदा 2000 – कलम 67B: बाल लैंगिक शोषण साहित्य (CSAM) प्रकाशित/प्रसारित/पाहणे — कठोर दायित्व',
        'POCSO कायदा 2012: 18 वर्षांखालील मुलांना लैंगिक गुन्ह्यांपासून सर्वसमावेशक संरक्षण, ऑनलाइन ग्रूमिंगसह',
        'POCSO सुधारणा कायदा 2019: मुलांवर गंभीर लैंगिक अत्याचारासाठी मृत्युदंडाची तरतूद',
        'BNS 2023 – कलम 94: बाल लैंगिक शोषण आणि ऑनलाइन ग्रूमिंगच्या तरतुदी',
        'POCSO कलम 19: POCSO गुन्ह्याची माहिती असणाऱ्या कोणत्याही व्यक्तीने पोलिसांना तात्काळ तक्रार करणे बंधनकारक — न केल्यास 6 महिन्यांपर्यंत कारावास',
      ],
      punishments: [
        'IT Act कलम 67B (CSAM): पहिला — 5 वर्षे + ₹10 लाख; दुसरा — 7 वर्षे + ₹10 लाख',
        'POCSO – लैंगिक अत्याचार: किमान 7 वर्षे; गंभीर प्रकरणी किमान 10 वर्षे ते जन्मठेप',
        'POCSO सुधारणा 2019 – गंभीर अत्याचार: अत्यंत गंभीर प्रकरणी मृत्युदंड शक्य',
        'POCSO – बाल लैंगिक छळ: किमान 3 वर्षे कारावास',
        'POCSO कलम 19 – तक्रार न करणे: 6 महिन्यांपर्यंत कारावास (तक्रार करणे अनिवार्य)',
      ],
      whatToDo: [
        'कोणताही विलंब न करता तात्काळ तक्रार करा — बाल सुरक्षेत प्रत्येक मिनिट महत्त्वाचा',
        'कोणताही पुरावा नष्ट करू नका — स्क्रीनशॉट, चॅट इतिहास, दुवे आणि फायली शिक्षेसाठी महत्त्वपूर्ण',
        'गुन्हेगाराशी थेट सामना करू नका — ते पुरावे नष्ट करू शकतात',
        'चाइल्डलाइन 1098 शी तात्काळ संपर्क करा — हस्तक्षेप, सहाय्य आणि समुपदेशनासाठी',
        'cybercrime.gov.in वर तक्रार करा — CSAM तक्रारींवर सर्वोच्च प्राधान्याने कार्यवाही',
        'बाल पीडितास तात्काळ वैद्यकीय आणि मानसशास्त्रीय सहाय्य द्या',
        'साक्षीदार म्हणूनही तुम्हाला कायद्याने तक्रार करणे बंधनकारक आहे',
      ],
      whereToReport: [
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in (CSAM — सर्वोच्च प्राधान्य)',
        'चाइल्डलाइन: 1098 (मोफत, 24×7)',
        'NCPCR: 1800-121-2830 (राष्ट्रीय बाल हक्क संरक्षण आयोग)',
        'स्थानिक पोलिस स्थानक (POCSO अंतर्गत FIR नोंदवणे अनिवार्य)',
        'सायबर क्राइम हेल्पलाइन: 1930',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 10. Right to Privacy Online
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'privacyRights',
    icon: Icons.privacy_tip_rounded,
    color: Color(0xFF0D9488),
    en: CyberLawContent(
      title: 'Right to Privacy Online',
      short: 'DPDP Act 2023  •  Article 21  •  IT Act §72',
      overview:
          'Every Indian citizen has a fundamental Right to Privacy under Article 21 of the Constitution (affirmed by the Supreme Court in K.S. Puttaswamy vs Union of India, 2017). Online privacy covers protection from unauthorized data collection, sharing personal information without consent, doxxing, and data breaches by organizations.',
      acts: [
        'Constitution of India – Article 21: Right to Life includes Right to Privacy — K.S. Puttaswamy Judgment (2017) is landmark precedent',
        'Digital Personal Data Protection (DPDP) Act 2023: Landmark data protection law — right to know what data is collected, right to correction, right to erasure ("right to be forgotten")',
        'IT Act 2000 – Sec 72: Breach of confidentiality and privacy by a person having authorized access to data — criminal provision',
        'IT Act 2000 – Sec 72A: Disclosure of information in breach of lawful contract — additional provision',
        'IT Act 2000 – Sec 43A: Corporate bodies processing sensitive personal data must implement reasonable security practices',
        'IT Rules 2021: Companies must publish a privacy policy and appoint a Grievance Officer in India (reachable within 24 hours)',
        'Aadhaar Act 2016 – Sec 28, 29: Strict protection of Aadhaar identity information from unauthorized disclosure',
      ],
      punishments: [
        'IT Act Sec 72 (Breach of Confidentiality): Up to 2 years imprisonment + fine up to ₹1 lakh',
        'IT Act Sec 72A (Wrongful Disclosure): Up to 3 years imprisonment + fine up to ₹5 lakh',
        'DPDP Act 2023 – Individual Violations: Penalty for data fiduciaries up to ₹250 crore per breach',
        'IT Act Sec 43A (Corporate Negligence): Organization ordered to compensate affected individuals',
        'Aadhaar Act Sec 37 (Unauthorized Disclosure): Up to 3 years imprisonment + fine up to ₹10,000',
      ],
      whatToDo: [
        'You have the RIGHT to know what personal data any company holds about you — send a formal written request',
        'You have the RIGHT to request correction or deletion of your data under DPDP Act 2023',
        'Contact the company\'s Grievance Officer first (mandatory under IT Rules 2021, must respond in 24 hours)',
        'If the company refuses to act, file a complaint with MEITY\'s Data Protection Board',
        'For Aadhaar-related privacy breach, contact UIDAI at 1947 and request biometric lock',
        'If a private individual shared your data without consent, file a cybercrime complaint under IT Act §72',
      ],
      whereToReport: [
        'MEITY (Ministry of Electronics & IT): meity.gov.in',
        'Cyber Crime Portal: cybercrime.gov.in (for §72/§72A violations)',
        'Company\'s Grievance Officer (mandatory under IT Rules 2021)',
        'UIDAI Helpline (Aadhaar privacy): 1947',
        'Data Protection Board of India (under DPDP Act 2023 — once fully operational)',
        'Nearest Police Station for criminal privacy violations under IT Act §72',
      ],
    ),
    hi: CyberLawContent(
      title: 'ऑनलाइन गोपनीयता का अधिकार',
      short: 'DPDP Act 2023  •  अनुच्छेद 21  •  IT Act §72',
      overview:
          'संविधान के अनुच्छेद 21 के तहत प्रत्येक भारतीय नागरिक को गोपनीयता का मौलिक अधिकार है (सर्वोच्च न्यायालय — K.S. पुट्टास्वामी बनाम भारत संघ, 2017)। ऑनलाइन गोपनीयता में अनाधिकृत डेटा संग्रह, बिना सहमति के व्यक्तिगत जानकारी साझा करना, डॉक्सिंग और संगठनों द्वारा डेटा उल्लंघन से सुरक्षा शामिल है।',
      acts: [
        'संविधान – अनुच्छेद 21: जीवन के अधिकार में गोपनीयता का अधिकार शामिल — K.S. पुट्टास्वामी निर्णय (2017)',
        'डिजिटल व्यक्तिगत डेटा संरक्षण (DPDP) अधिनियम 2023: डेटा जानने, सुधार और मिटाने ("भुलाए जाने का अधिकार") का अधिकार',
        'IT अधिनियम 2000 – धारा 72: अनाधिकृत पहुंच वाले व्यक्ति द्वारा गोपनीयता उल्लंघन — आपराधिक प्रावधान',
        'IT अधिनियम 2000 – धारा 72A: कानूनी अनुबंध के उल्लंघन में जानकारी का प्रकटीकरण',
        'IT अधिनियम 2000 – धारा 43A: संवेदनशील व्यक्तिगत डेटा को संसाधित करने वाले संगठनों के लिए उचित सुरक्षा प्रथाएं अनिवार्य',
        'IT नियम 2021: कंपनियों को गोपनीयता नीति प्रकाशित करनी होगी और भारत में शिकायत अधिकारी नियुक्त करना होगा',
        'आधार अधिनियम 2016 – धारा 28, 29: आधार जानकारी के अनाधिकृत प्रकटीकरण पर कड़े प्रतिबंध',
      ],
      punishments: [
        'IT Act धारा 72 (गोपनीयता उल्लंघन): 2 साल तक कारावास + ₹1 लाख जुर्माना',
        'IT Act धारा 72A (गलत प्रकटीकरण): 3 साल तक कारावास + ₹5 लाख जुर्माना',
        'DPDP अधिनियम 2023 – संगठन उल्लंघन: डेटा संचालकों पर प्रति उल्लंघन ₹250 करोड़ तक जुर्माना',
        'IT Act धारा 43A (कॉर्पोरेट लापरवाही): संगठन को प्रभावित व्यक्तियों को मुआवज़ा देने का आदेश',
        'आधार Act धारा 37 (अनाधिकृत प्रकटीकरण): 3 साल तक कारावास + ₹10,000 जुर्माना',
      ],
      whatToDo: [
        'आपका अधिकार है: किसी भी कंपनी से जानें कि वे आपका कौन सा डेटा रखती हैं — लिखित अनुरोध भेजें',
        'DPDP अधिनियम 2023 के तहत अपना डेटा सुधारने या मिटाने का अनुरोध करें',
        'पहले कंपनी के शिकायत अधिकारी से संपर्क करें (IT नियम 2021 के तहत 24 घंटे में जवाब देना होगा)',
        'यदि कंपनी कार्रवाई न करे तो MEITY के डेटा संरक्षण बोर्ड में शिकायत करें',
        'आधार गोपनीयता उल्लंघन पर UIDAI को 1947 पर कॉल करें और बायोमेट्रिक लॉक करें',
        'किसी निजी व्यक्ति ने बिना सहमति डेटा साझा किया हो तो IT Act §72 के तहत साइबर क्राइम शिकायत करें',
      ],
      whereToReport: [
        'MEITY (इलेक्ट्रॉनिक्स और IT मंत्रालय): meity.gov.in',
        'साइबर क्राइम पोर्टल: cybercrime.gov.in (§72/§72A उल्लंघन के लिए)',
        'कंपनी का शिकायत अधिकारी (IT नियम 2021 के तहत अनिवार्य)',
        'UIDAI हेल्पलाइन (आधार गोपनीयता): 1947',
        'भारत का डेटा संरक्षण बोर्ड (DPDP अधिनियम 2023 के तहत)',
        'निकटतम पुलिस थाना — IT Act §72 के तहत आपराधिक गोपनीयता उल्लंघन',
      ],
    ),
    mr: CyberLawContent(
      title: 'ऑनलाइन गोपनीयतेचा हक्क',
      short: 'DPDP Act 2023  •  अनुच्छेद 21  •  IT Act §72',
      overview:
          'राज्यघटनेच्या अनुच्छेद 21 अंतर्गत प्रत्येक भारतीय नागरिकास गोपनीयतेचा मूलभूत हक्क आहे (सर्वोच्च न्यायालय — K.S. पुट्टस्वामी वि. भारत संघ, 2017). ऑनलाइन गोपनीयतेत अनाधिकृत डेटा संग्रह, संमतीशिवाय वैयक्तिक माहिती सामायिक करणे, डॉक्सिंग आणि संस्थांकडून डेटा उल्लंघनापासून संरक्षण समाविष्ट आहे.',
      acts: [
        'राज्यघटना – अनुच्छेद 21: जीवनाच्या हक्कात गोपनीयतेचा हक्क समाविष्ट — K.S. पुट्टस्वामी निकाल (2017)',
        'डिजिटल वैयक्तिक डेटा संरक्षण (DPDP) कायदा 2023: डेटा जाणण्याचा, सुधारण्याचा आणि मिटवण्याचा ("विसरण्याचा हक्क") हक्क',
        'IT कायदा 2000 – कलम 72: अधिकृत प्रवेश असणाऱ्या व्यक्तीद्वारे गोपनीयता उल्लंघन — गुन्हेगारी तरतूद',
        'IT कायदा 2000 – कलम 72A: कायदेशीर करारनाम्याच्या उल्लंघनात माहिती प्रकट करणे',
        'IT कायदा 2000 – कलम 43A: संवेदनशील वैयक्तिक डेटा प्रक्रिया करणाऱ्या संस्थांसाठी योग्य सुरक्षा पद्धती अनिवार्य',
        'IT नियम 2021: कंपन्यांनी गोपनीयता धोरण प्रकाशित करणे आणि भारतात तक्रार अधिकारी नियुक्त करणे बंधनकारक',
        'आधार कायदा 2016 – कलम 28, 29: आधार माहितीच्या अनाधिकृत प्रकटीकरणावर कठोर निर्बंध',
      ],
      punishments: [
        'IT Act कलम 72 (गोपनीयता उल्लंघन): 2 वर्षांपर्यंत कारावास + ₹1 लाख दंड',
        'IT Act कलम 72A (चुकीचे प्रकटीकरण): 3 वर्षांपर्यंत कारावास + ₹5 लाख दंड',
        'DPDP कायदा 2023 – संस्था उल्लंघन: डेटा फिड्यूशियरींना प्रति उल्लंघन ₹250 कोटीपर्यंत दंड',
        'IT Act कलम 43A (कॉर्पोरेट निष्काळजीपणा): संस्थेला प्रभावित व्यक्तींना नुकसानभरपाई देण्याचा आदेश',
        'आधार Act कलम 37 (अनाधिकृत प्रकटीकरण): 3 वर्षांपर्यंत कारावास + ₹10,000 दंड',
      ],
      whatToDo: [
        'तुम्हाला हक्क आहे: कोणत्याही कंपनीकडून जाणून घ्या की ती तुमचा कोणता डेटा ठेवते — लेखी विनंती करा',
        'DPDP कायदा 2023 अंतर्गत तुमचा डेटा सुधारण्याची किंवा मिटवण्याची विनंती करा',
        'आधी कंपनीच्या तक्रार अधिकाऱ्याशी संपर्क करा (IT नियम 2021 अंतर्गत 24 तासांत उत्तर देणे बंधनकारक)',
        'कंपनीने कार्यवाही न केल्यास MEITY च्या डेटा संरक्षण मंडळात तक्रार करा',
        'आधार गोपनीयता उल्लंघनासाठी UIDAI ला 1947 वर कॉल करा आणि बायोमेट्रिक लॉक करा',
        'एखाद्या खाजगी व्यक्तीने संमतीशिवाय डेटा सामायिक केल्यास IT Act §72 अंतर्गत सायबर क्राइम तक्रार करा',
      ],
      whereToReport: [
        'MEITY (इलेक्ट्रॉनिक्स आणि IT मंत्रालय): meity.gov.in',
        'सायबर क्राइम पोर्टल: cybercrime.gov.in (§72/§72A उल्लंघनासाठी)',
        'कंपनीचा तक्रार अधिकारी (IT नियम 2021 अंतर्गत अनिवार्य)',
        'UIDAI हेल्पलाइन (आधार गोपनीयता): 1947',
        'भारताचे डेटा संरक्षण मंडळ (DPDP कायदा 2023 अंतर्गत)',
        'जवळचे पोलिस स्थानक — IT Act §72 अंतर्गत गुन्हेगारी गोपनीयता उल्लंघन',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 11. Ransomware & Hacking
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'ransomware',
    icon: Icons.computer_rounded,
    color: Color(0xFFCA8A04),
    en: CyberLawContent(
      title: 'Ransomware & Hacking',
      short: 'IT Act §66, §66B, §70',
      overview:
          'Ransomware is malware that encrypts victim\'s data and demands cryptocurrency payment to restore access. Hacking involves unauthorized access to computer systems, networks, or accounts. Both target individuals, businesses, hospitals, and government systems. NEVER pay the ransom — it funds criminals and recovery is not guaranteed.',
      acts: [
        'IT Act 2000 – Sec 43: Unauthorized access, damage, or destruction of computer data — civil compensation up to ₹1 crore',
        'IT Act 2000 – Sec 66: Computer-related offences — dishonest or fraudulent acts causing damage to computer or data',
        'IT Act 2000 – Sec 66B: Receiving or retaining stolen computer resource or data dishonestly',
        'IT Act 2000 – Sec 65: Tampering with computer source documents — specific provision for source code manipulation',
        'IT Act 2000 – Sec 70: Attack on Protected Systems (government, critical infrastructure like power grids, banks) — up to 10 years',
        'CERT-In Directions 2022: Organizations MUST report ransomware and any cybersecurity incident to CERT-In within 6 hours',
      ],
      punishments: [
        'IT Act Sec 66 (Hacking/Computer Fraud): Up to 3 years imprisonment + fine up to ₹5 lakh',
        'IT Act Sec 66B (Receiving Stolen Data): Up to 3 years imprisonment + fine up to ₹1 lakh',
        'IT Act Sec 70 (Protected System Attack): Up to 10 years imprisonment + fine',
        'IT Act Sec 65 (Tampering with Source Code): Up to 3 years imprisonment + fine up to ₹2 lakh',
        'IT Act Sec 43 (Unauthorized Access): Civil compensation up to ₹1 crore payable to victim',
      ],
      whatToDo: [
        'ISOLATE the infected device IMMEDIATELY — disconnect from internet and ALL networks to stop spread',
        'DO NOT pay the ransom — paying funds criminals and does NOT guarantee file recovery',
        'Do NOT attempt to decrypt files yourself — incorrect attempts cause permanent data loss',
        'Photograph the ransom note and all error messages as evidence before taking any action',
        'Contact CERT-In immediately: cert-in.org.in — they provide free technical assistance for recovery',
        'Restore from clean, offline backups if available — this is why regular backups are absolutely critical',
        'File FIR with cybercrime police — provide all technical details, system logs, and payment demand evidence',
      ],
      whereToReport: [
        'CERT-In: cert-in.org.in | incidents@cert-in.org.in (MANDATORY within 6 hours for organizations)',
        'National Cyber Crime Portal: cybercrime.gov.in',
        'Cyber Crime Helpline: 1930',
        'Nearest Cyber Crime Police Station for FIR under IT Act §66',
        'For critical infrastructure attacks: NCIIPC — nciipc.gov.in',
      ],
    ),
    hi: CyberLawContent(
      title: 'रैनसमवेयर और हैकिंग',
      short: 'IT Act §66, §66B, §70',
      overview:
          'रैनसमवेयर एक मैलवेयर है जो पीड़ित के डेटा को एन्क्रिप्ट करता है और क्रिप्टोकरेंसी भुगतान मांगता है। हैकिंग में कंप्यूटर सिस्टम, नेटवर्क या खातों में अनाधिकृत पहुंच होती है। कभी रैनसम न दें — यह अपराधियों को धन देता है और रिकवरी की कोई गारंटी नहीं।',
      acts: [
        'IT अधिनियम 2000 – धारा 43: अनाधिकृत पहुंच, डेटा नुकसान या विनाश; ₹1 करोड़ तक दीवानी मुआवज़ा',
        'IT अधिनियम 2000 – धारा 66: कंप्यूटर आधारित आपराधिक कृत्य — बेईमानी से डेटा को नुकसान',
        'IT अधिनियम 2000 – धारा 66B: चोरी किए गए कंप्यूटर डेटा को बेईमानी से प्राप्त या रखना',
        'IT अधिनियम 2000 – धारा 65: कंप्यूटर स्रोत दस्तावेज़ों से छेड़छाड़',
        'IT अधिनियम 2000 – धारा 70: संरक्षित प्रणालियों पर हमला (सरकार, बिजली ग्रिड, बैंक); 10 साल तक कारावास',
        'CERT-In निर्देश 2022: संगठनों को 6 घंटे में CERT-In को रैनसमवेयर की रिपोर्ट करनी होगी',
      ],
      punishments: [
        'IT Act धारा 66 (हैकिंग/कंप्यूटर धोखाधड़ी): 3 साल तक कारावास + ₹5 लाख जुर्माना',
        'IT Act धारा 66B (चोरी डेटा प्राप्त करना): 3 साल तक कारावास + ₹1 लाख जुर्माना',
        'IT Act धारा 70 (संरक्षित प्रणाली हमला): 10 साल तक कारावास + जुर्माना',
        'IT Act धारा 65 (स्रोत कोड से छेड़छाड़): 3 साल तक कारावास + ₹2 लाख जुर्माना',
        'IT Act धारा 43 (अनाधिकृत पहुंच): ₹1 करोड़ तक दीवानी मुआवज़ा',
      ],
      whatToDo: [
        'संक्रमित डिवाइस को तुरंत अलग करें — इंटरनेट और सभी नेटवर्क से डिस्कनेक्ट करें',
        'रैनसम कभी न दें — पैसे देने से अपराधियों को मदद मिलती है, रिकवरी की कोई गारंटी नहीं',
        'खुद से डिक्रिप्ट करने की कोशिश न करें — गलत कोशिश से डेटा स्थायी रूप से नष्ट हो सकता है',
        'रैनसम नोट और सभी त्रुटि संदेशों की तस्वीर लें — ये सबूत हैं',
        'तुरंत CERT-In से संपर्क करें: cert-in.org.in — वे मुफ्त तकनीकी सहायता प्रदान करते हैं',
        'यदि साफ बैकअप उपलब्ध है तो उससे डेटा रिस्टोर करें — इसीलिए नियमित बैकअप ज़रूरी है',
        'तकनीकी विवरण, सिस्टम लॉग और भुगतान मांग के साथ साइबर क्राइम FIR दर्ज करें',
      ],
      whereToReport: [
        'CERT-In: cert-in.org.in | incidents@cert-in.org.in (संगठनों के लिए 6 घंटे में अनिवार्य)',
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'साइबर क्राइम हेल्पलाइन: 1930',
        'निकटतम साइबर क्राइम पुलिस थाना — IT Act §66 के तहत FIR',
        'महत्वपूर्ण अवसंरचना हमलों के लिए: NCIIPC — nciipc.gov.in',
      ],
    ),
    mr: CyberLawContent(
      title: 'रॅन्समवेअर आणि हॅकिंग',
      short: 'IT Act §66, §66B, §70',
      overview:
          'रॅन्समवेअर एक मॅलवेअर आहे जो पीडिताचा डेटा एन्क्रिप्ट करतो आणि क्रिप्टोकरन्सी पेमेंट मागतो. हॅकिंगमध्ये संगणक प्रणाली, नेटवर्क किंवा खात्यांमध्ये अनाधिकृत प्रवेश होतो. खंडणी कधीही देऊ नका — यामुळे गुन्हेगारांना निधी मिळतो आणि डेटा परतीची कोणतीही हमी नाही.',
      acts: [
        'IT कायदा 2000 – कलम 43: अनाधिकृत प्रवेश, डेटा नुकसान किंवा विनाश; ₹1 कोटीपर्यंत दिवाणी नुकसानभरपाई',
        'IT कायदा 2000 – कलम 66: संगणक आधारित गुन्हेगारी कृत्य — बेप्रामाणिकपणे डेटाचे नुकसान',
        'IT कायदा 2000 – कलम 66B: चोरलेला संगणक डेटा बेप्रामाणिकपणे प्राप्त करणे किंवा ठेवणे',
        'IT कायदा 2000 – कलम 65: संगणक स्रोत दस्तऐवजांशी छेडछाड',
        'IT कायदा 2000 – कलम 70: संरक्षित प्रणालींवर हल्ला (सरकार, वीज ग्रिड, बँका); 10 वर्षांपर्यंत कारावास',
        'CERT-In निर्देश 2022: संस्थांनी 6 तासांत CERT-In ला रॅन्समवेअरची तक्रार करणे अनिवार्य',
      ],
      punishments: [
        'IT Act कलम 66 (हॅकिंग/संगणक फसवणूक): 3 वर्षांपर्यंत कारावास + ₹5 लाख दंड',
        'IT Act कलम 66B (चोरलेला डेटा प्राप्त करणे): 3 वर्षांपर्यंत कारावास + ₹1 लाख दंड',
        'IT Act कलम 70 (संरक्षित प्रणाली हल्ला): 10 वर्षांपर्यंत कारावास + दंड',
        'IT Act कलम 65 (स्रोत कोडशी छेडछाड): 3 वर्षांपर्यंत कारावास + ₹2 लाख दंड',
        'IT Act कलम 43 (अनाधिकृत प्रवेश): ₹1 कोटीपर्यंत दिवाणी नुकसानभरपाई',
      ],
      whatToDo: [
        'संक्रमित डिव्हाइस तात्काळ वेगळे करा — इंटरनेट आणि सर्व नेटवर्कपासून डिस्कनेक्ट करा',
        'खंडणी कधीही देऊ नका — पैसे दिल्याने गुन्हेगारांना मदत होते, डेटा परतीची हमी नाही',
        'स्वतः डिक्रिप्ट करण्याचा प्रयत्न करू नका — चुकीच्या प्रयत्नाने डेटा कायमचा नष्ट होऊ शकतो',
        'रॅन्सम नोट आणि सर्व त्रुटी संदेशांचे फोटो घ्या — हे पुरावे आहेत',
        'तात्काळ CERT-In शी संपर्क करा: cert-in.org.in — ते मोफत तांत्रिक सहाय्य देतात',
        'स्वच्छ बॅकअप उपलब्ध असल्यास त्यातून डेटा पुनर्संचयित करा — म्हणूनच नियमित बॅकअप अत्यावश्यक',
        'तांत्रिक तपशील, सिस्टम लॉग आणि पेमेंट मागणीसह सायबर क्राइम FIR दाखल करा',
      ],
      whereToReport: [
        'CERT-In: cert-in.org.in | incidents@cert-in.org.in (संस्थांसाठी 6 तासांत अनिवार्य)',
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'सायबर क्राइम हेल्पलाइन: 1930',
        'जवळचे सायबर क्राइम पोलिस स्थानक — IT Act §66 अंतर्गत FIR',
        'महत्त्वाच्या पायाभूत सुविधांवर हल्ल्यांसाठी: NCIIPC — nciipc.gov.in',
      ],
    ),
  ),

  // ──────────────────────────────────────────────────────
  // 12. Cyber Terrorism
  // ──────────────────────────────────────────────────────
  CyberLawTopic(
    id: 'cyberTerrorism',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFFB91C1C),
    en: CyberLawContent(
      title: 'Cyber Terrorism',
      short: 'IT Act §66F  •  UAPA 1967  •  BNS §113',
      overview:
          'Cyber terrorism involves using digital means to threaten, destabilize, or harm government systems, critical infrastructure (power grids, financial systems, hospitals), or spread terror online. It also includes online radicalization and funding terrorism via digital channels. Section 66F carries life imprisonment — one of the harshest penalties in IT Act.',
      acts: [
        'IT Act 2000 – Sec 66F: Cyber terrorism — unauthorized access to protected systems with intent to threaten unity, integrity, sovereignty, or security of India OR to strike terror — LIFE IMPRISONMENT',
        'Unlawful Activities (Prevention) Act (UAPA) 1967: Covers online promotion of terrorism, recruitment, radicalization, and financing of terrorist activities',
        'BNS 2023 – Sec 113: Terrorism offences in the new criminal code',
        'IT Act 2000 – Sec 70: Protected systems — designated government and critical national infrastructure (power, banking, defence)',
        'National Cyber Security Policy 2013: Framework for protection of critical information infrastructure',
      ],
      punishments: [
        'IT Act Sec 66F (Cyber Terrorism): LIFE IMPRISONMENT — the most severe punishment in the IT Act',
        'UAPA offences: Ranging from 5 years to life imprisonment depending on the nature of the act',
        'BNS Sec 113 (Terrorism): Death penalty or life imprisonment in severe cases; minimum 5 years for lesser offences',
        'IT Act Sec 70 (Protected System Attack): Up to 10 years imprisonment + fine',
        'UAPA Sec 20 (Membership of Terrorist Organization): Up to 10 years imprisonment',
      ],
      whatToDo: [
        'Report suspicious online content promoting terrorism IMMEDIATELY — do NOT engage, share, or like it',
        'Preserve URL, screenshots, and account details of suspicious content as evidence',
        'Report simultaneously to the platform AND to law enforcement',
        'If your organization suffers a cyberattack targeting critical systems, isolate affected systems immediately',
        'Organizations MUST contact CERT-In within 6 hours (mandatory legal requirement)',
        'Do NOT attempt to counter-hack or investigate independently — leave it to authorities',
      ],
      whereToReport: [
        'CERT-In: cert-in.org.in | incidents@cert-in.org.in (MANDATORY 6-hour reporting for organizations)',
        'National Investigation Agency (NIA): nia.gov.in',
        'Local Police and State Cyber Crime Cell',
        'National Cyber Crime Portal: cybercrime.gov.in',
        'Emergency: Call 112 (Police)',
      ],
    ),
    hi: CyberLawContent(
      title: 'साइबर आतंकवाद',
      short: 'IT Act §66F  •  UAPA 1967  •  BNS §113',
      overview:
          'साइबर आतंकवाद में सरकारी प्रणालियों, महत्वपूर्ण अवसंरचना (बिजली ग्रिड, वित्तीय प्रणाली, अस्पताल) को नुकसान पहुंचाने या ऑनलाइन आतंक फैलाने के लिए डिजिटल साधनों का उपयोग शामिल है। धारा 66F — IT अधिनियम में सबसे कड़ी सज़ा — आजीवन कारावास।',
      acts: [
        'IT अधिनियम 2000 – धारा 66F: साइबर आतंकवाद — भारत की एकता, अखंडता, संप्रभुता या सुरक्षा को खतरे में डालने के इरादे से संरक्षित प्रणालियों तक अनाधिकृत पहुंच — आजीवन कारावास',
        'गैरकानूनी गतिविधि (रोकथाम) अधिनियम (UAPA) 1967: ऑनलाइन आतंकवाद प्रचार, भर्ती, कट्टरपंथीकरण और वित्तपोषण को कवर करता है',
        'BNS 2023 – धारा 113: नई आपराधिक संहिता में आतंकवाद के प्रावधान',
        'IT अधिनियम 2000 – धारा 70: संरक्षित प्रणालियां — सरकार और महत्वपूर्ण राष्ट्रीय अवसंरचना',
        'राष्ट्रीय साइबर सुरक्षा नीति 2013: महत्वपूर्ण सूचना अवसंरचना की सुरक्षा का ढांचा',
      ],
      punishments: [
        'IT Act धारा 66F (साइबर आतंकवाद): आजीवन कारावास — IT अधिनियम में सबसे कड़ी सज़ा',
        'UAPA अपराध: कृत्य की प्रकृति के आधार पर 5 साल से आजीवन कारावास',
        'BNS धारा 113 (आतंकवाद): गंभीर मामलों में मृत्युदंड या आजीवन; कम गंभीर में न्यूनतम 5 साल',
        'IT Act धारा 70 (संरक्षित प्रणाली हमला): 10 साल तक कारावास + जुर्माना',
        'UAPA धारा 20 (आतंकी संगठन की सदस्यता): 10 साल तक कारावास',
      ],
      whatToDo: [
        'आतंकवाद को बढ़ावा देने वाली संदिग्ध ऑनलाइन सामग्री तुरंत रिपोर्ट करें — बिल्कुल संलग्न न हों',
        'सबूत के रूप में URL, स्क्रीनशॉट और संदिग्ध खाते की जानकारी सुरक्षित रखें',
        'प्लेटफॉर्म और कानून प्रवर्तन दोनों को एक साथ रिपोर्ट करें',
        'यदि आपका संगठन महत्वपूर्ण प्रणालियों पर साइबर हमले का सामना कर रहा है तो प्रभावित सिस्टम तुरंत अलग करें',
        'संगठनों को 6 घंटे में CERT-In को सूचित करना अनिवार्य है',
        'काउंटर-हैक या स्वतंत्र जांच न करें — अधिकारियों पर छोड़ें',
      ],
      whereToReport: [
        'CERT-In: cert-in.org.in | incidents@cert-in.org.in (संगठनों के लिए 6 घंटे में अनिवार्य)',
        'राष्ट्रीय जांच एजेंसी (NIA): nia.gov.in',
        'स्थानीय पुलिस और राज्य साइबर क्राइम सेल',
        'राष्ट्रीय साइबर क्राइम पोर्टल: cybercrime.gov.in',
        'आपातकाल: 112 पर कॉल करें',
      ],
    ),
    mr: CyberLawContent(
      title: 'सायबर दहशतवाद',
      short: 'IT Act §66F  •  UAPA 1967  •  BNS §113',
      overview:
          'सायबर दहशतवादात सरकारी प्रणाली, महत्त्वाच्या पायाभूत सुविधा (वीज ग्रिड, आर्थिक प्रणाली, रुग्णालये) ला हानी पोहोचवण्यासाठी किंवा ऑनलाइन दहशत पसरवण्यासाठी डिजिटल साधनांचा वापर केला जातो. कलम 66F — IT कायद्यातील सर्वात कठोर शिक्षा — जन्मठेप.',
      acts: [
        'IT कायदा 2000 – कलम 66F: सायबर दहशतवाद — भारताची एकता, अखंडता, सार्वभौमत्व किंवा सुरक्षिततेला धोका पोहोचवण्याच्या हेतूने संरक्षित प्रणालींमध्ये अनाधिकृत प्रवेश — जन्मठेप',
        'बेकायदेशीर कृत्ये (प्रतिबंध) कायदा (UAPA) 1967: ऑनलाइन दहशतवाद प्रचार, भरती, कट्टरपंथीकरण आणि निधीपुरवठ्याला लागू',
        'BNS 2023 – कलम 113: नव्या गुन्हेगारी संहितेतील दहशतवाद तरतुदी',
        'IT कायदा 2000 – कलम 70: संरक्षित प्रणाली — सरकार आणि महत्त्वाच्या राष्ट्रीय पायाभूत सुविधा',
        'राष्ट्रीय सायबर सुरक्षा धोरण 2013: महत्त्वाच्या माहिती पायाभूत सुविधांच्या संरक्षणाची चौकट',
      ],
      punishments: [
        'IT Act कलम 66F (सायबर दहशतवाद): जन्मठेप — IT कायद्यातील सर्वात कठोर शिक्षा',
        'UAPA गुन्हे: कृत्याच्या स्वरूपानुसार 5 वर्षांपासून जन्मठेप',
        'BNS कलम 113 (दहशतवाद): गंभीर प्रकरणी मृत्युदंड किंवा जन्मठेप; कमी गंभीरसाठी किमान 5 वर्षे',
        'IT Act कलम 70 (संरक्षित प्रणाली हल्ला): 10 वर्षांपर्यंत कारावास + दंड',
        'UAPA कलम 20 (दहशतवादी संघटनेचे सदस्यत्व): 10 वर्षांपर्यंत कारावास',
      ],
      whatToDo: [
        'दहशतवादाला प्रोत्साहन देणारे संशयास्पद ऑनलाइन साहित्य तात्काळ तक्रार करा — बिल्कुल सहभागी होऊ नका',
        'पुरावा म्हणून URL, स्क्रीनशॉट आणि संशयास्पद खात्याचा तपशील सुरक्षित ठेवा',
        'प्लॅटफॉर्म आणि कायद्याची अंमलबजावणी दोन्हींना एकाच वेळी तक्रार करा',
        'तुमच्या संस्थेवर महत्त्वाच्या प्रणालींवर सायबर हल्ला झाल्यास प्रभावित प्रणाली तात्काळ वेगळ्या करा',
        'संस्थांनी 6 तासांत CERT-In ला सूचित करणे कायद्याने अनिवार्य आहे',
        'काउंटर-हॅक किंवा स्वतंत्र तपास करण्याचा प्रयत्न करू नका — अधिकाऱ्यांवर सोडा',
      ],
      whereToReport: [
        'CERT-In: cert-in.org.in | incidents@cert-in.org.in (संस्थांसाठी 6 तासांत अनिवार्य)',
        'राष्ट्रीय तपास संस्था (NIA): nia.gov.in',
        'स्थानिक पोलिस आणि राज्य सायबर क्राइम सेल',
        'राष्ट्रीय सायबर क्राइम पोर्टल: cybercrime.gov.in',
        'आपातकाल: 112 वर कॉल करा',
      ],
    ),
  ),
];
