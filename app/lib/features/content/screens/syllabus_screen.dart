import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../widgets/lang_toggle_button.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

class _Unit {
  final String num;
  final String title;
  final String tamilTitle;
  final Color color;
  final List<String> topics;
  final List<String> tamilTopics;
  const _Unit({
    required this.num,
    required this.title,
    required this.tamilTitle,
    required this.color,
    required this.topics,
    this.tamilTopics = const [],
  });
}

class _Paper {
  final String num;
  final String title;
  final String tamilTitle;
  final String standard;
  final String tamilStandard;
  final Color color;
  final List<_Unit> units;
  const _Paper({
    required this.num,
    required this.title,
    required this.tamilTitle,
    required this.standard,
    required this.tamilStandard,
    required this.color,
    required this.units,
  });
}

// ─── Preliminary Exam Units ───────────────────────────────────────────────────

final _prelimUnits = <_Unit>[
  _Unit(
    num: 'I',
    title: 'General Science',
    tamilTitle: 'பொது அறிவியல்',
    color: const Color(0xFF4F46E5),
    topics: [
      'Scientific Knowledge & Scientific Temper — Power of Reasoning, Rote Learning vs Conceptual Learning, Science as a tool to understand the past, present and future',
      'Nature of Universe — General Scientific Laws, Mechanics, Properties of Matter, Force, Motion and Energy — Everyday application of Mechanics, Electricity & Magnetism, Light, Sound, Heat, Nuclear Physics, Laser, Electronics and Communications',
      'Elements and Compounds, Acids, Bases, Salts, Petroleum Products, Fertilisers, Pesticides',
      'Main concepts of Life Science — Classification of Living Organisms, Evolution, Genetics, Physiology, Nutrition, Health and Hygiene, Human Diseases',
      'Environment and Ecology',
    ],
    tamilTopics: [
      'விஞ்ஞான அறிவும் விஞ்ஞான மனப்பான்மையும் — சிந்திக்கும் திறன், மனப்பாடம் vs கருத்தியல் கற்றல், கடந்த காலம், நிகழ்காலம், எதிர்காலம் புரிந்துகொள்ள அறிவியல்',
      'அண்டவெளியின் தன்மை — பொது விஞ்ஞான விதிகள், இயக்கவியல், பொருளின் பண்புகள், விசை, இயக்கம் மற்றும் ஆற்றல் — மின்சாரம் மற்றும் காந்தவியல், ஒளி, ஒலி, வெப்பம், அணுக்கரு இயற்பியல், லேசர், மின்னணுவியல் மற்றும் தகவல் தொடர்பு',
      'தனிமங்கள் மற்றும் கலவைகள், அமிலங்கள், காரங்கள், உப்புகள், பெட்ரோலிய தயாரிப்புகள், உரங்கள், பூச்சிக்கொல்லிகள்',
      'உயிர் அறிவியலின் முக்கிய கோட்பாடுகள் — உயிரினங்களின் வகைப்பாடு, பரிணாமம், மரபியல், உடலியல், ஊட்டச்சத்து, சுகாதாரம், மனித நோய்கள்',
      'சுற்றுச்சூழல் மற்றும் சூழலியல்',
    ],
  ),
  _Unit(
    num: 'II',
    title: 'Current Events',
    tamilTitle: 'நடப்பு நிகழ்வுகள்',
    color: const Color(0xFFF59E0B),
    topics: [
      'History — Latest diary of events, National symbols, Profile of States, Eminent personalities and places in news, Sports, Books and authors',
      'Polity — Political parties and political system in India, Public awareness and General administration, Welfare oriented Government schemes, Problems in Public Delivery Systems',
      'Geography — Geographical landmarks',
      'Economics — Current socio-economic issues',
      'Science — Latest inventions in Science and Technology',
      'Prominent Personalities in various spheres — Arts, Science, Literature and Philosophy',
    ],
    tamilTopics: [
      'வரலாறு — சமீபத்திய நிகழ்வுகள், தேசிய சின்னங்கள், மாநில சுயவிவரங்கள், பிரபல ஆளுமைகளும் இடங்களும், விளையாட்டு, புத்தகங்கள் மற்றும் ஆசிரியர்கள்',
      'அரசியல் — இந்தியாவில் அரசியல் கட்சிகள் மற்றும் அரசியல் அமைப்பு, பொது விழிப்புணர்வு மற்றும் பொது நிர்வாகம், நலன்புரி அரசு திட்டங்கள், பொதுச் சேவை வழங்கலில் உள்ள சிக்கல்கள்',
      'புவியியல் — புவியியல் அடையாளங்கள்',
      'பொருளாதாரம் — நடப்பு சமூக-பொருளாதார சிக்கல்கள்',
      'அறிவியல் — அறிவியல் மற்றும் தொழில்நுட்பத்தில் சமீபத்திய கண்டுபிடிப்புகள்',
      'கலை, அறிவியல், இலக்கியம் மற்றும் தத்துவத்துறைகளில் புகழ்பெற்ற ஆளுமைகள்',
    ],
  ),
  _Unit(
    num: 'III',
    title: 'Geography of India',
    tamilTitle: 'இந்தியப் புவியியல்',
    color: const Color(0xFF059669),
    topics: [
      'Location — Physical features, Monsoon, Rainfall, Weather and Climate, Water Resources, Rivers in India, Soil, Minerals and Natural Resources, Forest and Wildlife, Agricultural pattern',
      'Transport — Communication',
      'Social Geography — Population density and distribution, Racial and Linguistic Groups, Major Tribes',
      'Natural calamity — Disaster Management — Environmental pollution: Reasons and preventive measures — Climate change — Green energy',
    ],
    tamilTopics: [
      'இடம் — இயற்கை அமைப்பு, பருவமழை, மழையளவு, வானிலை மற்றும் காலநிலை, நீர் வளங்கள், இந்திய நதிகள், மண், தாதுக்கள் மற்றும் இயற்கை வளங்கள், காடுகள் மற்றும் வனவிலங்குகள், விவசாய முறை',
      'போக்குவரத்து — தகவல் தொடர்பு',
      'சமூக புவியியல் — மக்கள்தொகை அடர்த்தி மற்றும் பரவல், இன மற்றும் மொழி குழுக்கள், முக்கிய பழங்குடியினர்',
      'இயற்கை பேரழிவு — பேரிடர் மேலாண்மை — சுற்றுச்சூழல் மாசுபாடு: காரணங்கள் மற்றும் தடுப்பு நடவடிக்கைகள் — காலநிலை மாற்றம் — பசுமை ஆற்றல்',
    ],
  ),
  _Unit(
    num: 'IV',
    title: 'History and Culture of India',
    tamilTitle: 'இந்திய வரலாறும் பண்பாடும்',
    color: const Color(0xFFD97706),
    topics: [
      'Indus Valley Civilization — Guptas, Delhi Sultans, Mughals and Marathas — Age of Vijayanagaram and Bahmani Kingdoms — South Indian History',
      'Change and Continuity in the Socio-Cultural History of India',
      'Characteristics of Indian Culture, Unity in Diversity — Race, Language, Custom',
      'India as a Secular State, Social Harmony',
    ],
    tamilTopics: [
      'சிந்து சமவெளி நாகரிகம் — குப்தர்கள், டெல்லி சுல்தான்கள், முகலாயர்கள் மற்றும் மராத்தியர்கள் — விஜயநகர மற்றும் பஹ்மனி இராச்சியங்கள் — தென்னிந்திய வரலாறு',
      'இந்தியாவின் சமூக-கலாச்சார வரலாற்றில் மாற்றம் மற்றும் தொடர்ச்சி',
      'இந்திய கலாச்சாரத்தின் பண்புகள், பன்முகத்தன்மையில் ஒற்றுமை — இனம், மொழி, வழக்கம்',
      'இந்தியா ஒரு மதச்சார்பற்ற நாடாக, சமூக நல்லிணக்கம்',
    ],
  ),
  _Unit(
    num: 'V',
    title: 'Indian Polity',
    tamilTitle: 'இந்திய அரசியல் அமைப்பு',
    color: const Color(0xFF7C3AED),
    topics: [
      'Constitution of India — Preamble to the Constitution — Salient features — Union, State and Union Territory',
      'Citizenship, Fundamental Rights, Fundamental Duties, Directive Principles of State Policy',
      'Union Executive, Union Legislature — State Executive, State Legislature — Local Governments, Panchayat Raj',
      'Spirit of Federalism: Centre - State Relationships',
      'Election — Judiciary in India — Rule of Law',
      'Corruption in Public Life — Anti-corruption measures — Lokpal and Lok Ayukta — Right to Information — Empowerment of Women — Consumer Protection Forums, Human Rights Charter',
    ],
    tamilTopics: [
      'இந்திய அரசியலமைப்பு — முன்னுரை — முக்கிய அம்சங்கள் — ஒன்றியம், மாநிலம் மற்றும் யூனியன் பிரதேசம்',
      'குடியுரிமை, அடிப்படை உரிமைகள், அடிப்படை கடமைகள், மாநில கொள்கையின் வழிகாட்டுதல் கோட்பாடுகள்',
      'ஒன்றிய நிறைவேற்றுப் பிரிவு, ஒன்றிய சட்டமன்றம் — மாநில நிறைவேற்றுப் பிரிவு, மாநில சட்டமன்றம் — உள்ளாட்சி அமைப்புகள், பஞ்சாயத்து ராஜ்',
      'கூட்டாட்சி உணர்வு: மத்திய-மாநில உறவுகள்',
      'தேர்தல் — இந்தியாவில் நீதித்துறை — சட்டத்தின் ஆட்சி',
      'பொதுவாழ்வில் ஊழல் — ஊழல் தடுப்பு நடவடிக்கைகள் — லோக்பால் மற்றும் லோக் ஆயுக்தா — தகவல் அறியும் உரிமை — பெண்கள் அதிகாரமளித்தல் — நுகர்வோர் பாதுகாப்பு மன்றங்கள், மனித உரிமைகள் சாசனம்',
    ],
  ),
  _Unit(
    num: 'VI',
    title: 'Indian Economy',
    tamilTitle: 'இந்தியப் பொருளாதாரம்',
    color: const Color(0xFF0891B2),
    topics: [
      'Nature of Indian Economy — Five year plan models — Planning Commission and NITI Aayog',
      'Sources of revenue — Reserve Bank of India — Fiscal Policy and Monetary Policy — Finance Commission — Resource sharing between Union and State Governments — Goods and Services Tax',
      'Structure of Indian Economy and Employment Generation, Land Reforms and Agriculture — Application of Science and Technology in Agriculture — Industrial growth — Rural Welfare Oriented Programmes — Social Problems (Population, Education, Health, Employment, Poverty)',
    ],
    tamilTopics: [
      'இந்திய பொருளாதாரத்தின் தன்மை — ஐந்தாண்டு திட்ட மாதிரிகள் — திட்டக் கமிஷன் மற்றும் நீதி ஆயோக்',
      'வருவாய் ஆதாரங்கள் — இந்திய ரிசர்வ் வங்கி — நிதி கொள்கை மற்றும் பணவியல் கொள்கை — நிதி கமிஷன் — மத்திய-மாநில வருவாய் பகிர்வு — பொருட்கள் மற்றும் சேவை வரி',
      'இந்திய பொருளாதார அமைப்பும் வேலைவாய்ப்பும் — நில சீர்திருத்தங்கள் மற்றும் விவசாயம் — தொழில் வளர்ச்சி — ஊரக நலன்புரி திட்டங்கள் — சமூக சிக்கல்கள் (மக்கள்தொகை, கல்வி, சுகாதாரம், வேலைவாய்ப்பின்மை, வறுமை)',
    ],
  ),
  _Unit(
    num: 'VII',
    title: 'Indian National Movement',
    tamilTitle: 'இந்திய தேசிய இயக்கம்',
    color: const Color(0xFFDC2626),
    topics: [
      'National Renaissance — Early uprising against British rule — Indian National Congress — Emergence of leaders: B.R.Ambedkar, Bhagat Singh, Bharathiar, V.O.Chidambaranar, Jawaharlal Nehru, Kamarajar, Mahatma Gandhi, Maulana Abul Kalam Azad, Thanthai Periyar, Rajaji, Subash Chandra Bose, Rabindranath Tagore and others',
      'Different modes of Agitation: Growth of Satyagraha and Militant Movements',
      'Communalism and Partition',
    ],
    tamilTopics: [
      'தேசிய விழிப்புணர்வு — பிரிட்டிஷ் ஆட்சிக்கு எதிரான ஆரம்பகால கிளர்ச்சிகள் — இந்திய தேசிய காங்கிரஸ் — தலைவர்களின் தோற்றம்: அம்பேத்கர், பகத் சிங், பாரதியார், வ.உ.சிதம்பரனார், நேரு, காமராஜர், மகாத்மா காந்தி, மவுலானா அபுல் கலாம் ஆசாத், தந்தை பெரியார், ராஜாஜி, சுபாஷ் சந்திரபோஸ், ரவீந்திரநாத் தாகூர் மற்றும் பலர்',
      'போராட்டத்தின் பல்வேறு வழிகள்: சத்தியாக்கிரகம் மற்றும் தீவிரவாத இயக்கங்களின் வளர்ச்சி',
      'வகுப்புவாதம் மற்றும் நாடு பிரிவு',
    ],
  ),
  _Unit(
    num: 'VIII',
    title: 'History, Culture & Socio-Political Movements in Tamil Nadu',
    tamilTitle: 'தமிழ்நாடு வரலாறு, பண்பாடு மற்றும் சமூக-அரசியல் இயக்கங்கள்',
    color: const Color(0xFFDB2777),
    topics: [
      'History of Tamil Society, related Archaeological discoveries, Tamil Literature from Sangam Age till contemporary times',
      'Thirukkural: Significance as a Secular Literature, Relevance to Everyday Life, Impact on Humanity, Universal Values (Equality, Humanism), Relevance to Socio-Politico-Economic affairs, Philosophical content',
      'Role of Tamil Nadu in freedom struggle — Early agitations against British Rule — Role of women in freedom struggle',
      'Evolution of 19th and 20th Century Socio-Political Movements — Justice Party, Growth of Rationalism — Self Respect Movement, Dravidian Movement — Contributions of Thanthai Periyar and Perarignar Anna',
    ],
    tamilTopics: [
      'தமிழ் சமூக வரலாறு, தொல்பொருளாய்வுக் கண்டுபிடிப்புகள், சங்க காலம் முதல் இன்று வரை தமிழ் இலக்கியம்',
      'திருக்குறள்: மதச்சார்பற்ற இலக்கியமாக முக்கியத்துவம், அன்றாட வாழ்வில் பொருத்தம், மனிதகுலத்தில் தாக்கம், உலகளாவிய மதிப்புகள் (சமத்துவம், மனிதநேயம்), தத்துவ உள்ளடக்கம்',
      'விடுதலை போரில் தமிழ்நாட்டின் பங்கு — பிரிட்டிஷ் ஆட்சிக்கு எதிரான ஆரம்பகால போராட்டங்கள் — விடுதலை போரில் பெண்களின் பங்கு',
      '19-ஆம் மற்றும் 20-ஆம் நூற்றாண்டு சமூக-அரசியல் இயக்கங்கள்: நீதிக் கட்சி, பகுத்தறிவு இயக்கம், சுயமரியாதை இயக்கம், திராவிட இயக்கம் — தந்தை பெரியார் மற்றும் பேரறிஞர் அண்ணாவின் பங்களிப்புகள்',
    ],
  ),
  _Unit(
    num: 'IX',
    title: 'Development Administration in Tamil Nadu',
    tamilTitle: 'தமிழ்நாட்டில் வளர்ச்சி நிர்வாகம்',
    color: const Color(0xFF0E7490),
    topics: [
      'Human Development Indicators in Tamil Nadu and comparative assessment across the Country — Impact of Social Reform Movements in the Socio-Economic Development of Tamil Nadu',
      'Political parties and Welfare schemes for various sections of people — Rationale behind Reservation Policy — Economic trends in Tamil Nadu — Role and impact of social welfare schemes',
      'Social Justice and Social Harmony as the Cornerstones of Socio-Economic Development',
      'Education and Health Systems in Tamil Nadu',
      'Geography of Tamil Nadu and its impact on Economic growth',
      'Achievements of Tamil Nadu in various fields',
      'e-Governance in Tamil Nadu',
    ],
    tamilTopics: [
      'தமிழ்நாட்டில் மனித வளர்ச்சி குறியீடுகள் மற்றும் நாட்டளாவிய ஒப்பீடு — சமூக சீர்திருத்த இயக்கங்களின் தாக்கம்',
      'பல்வேறு தரப்பினருக்கான அரசியல் கட்சிகள் மற்றும் நலன்புரி திட்டங்கள் — இட ஒதுக்கீட்டு கொள்கையின் நியாயம் — தமிழ்நாட்டின் பொருளாதார போக்குகள் — சமூக நலன்புரி திட்டங்களின் பங்கு மற்றும் தாக்கம்',
      'சமூக நீதி மற்றும் சமூக நல்லிணக்கம் சமூக-பொருளாதார வளர்ச்சியின் அடிப்படைகளாக',
      'தமிழ்நாட்டில் கல்வி மற்றும் சுகாதார அமைப்புகள்',
      'தமிழ்நாட்டின் புவியியலும் பொருளாதார வளர்ச்சியில் அதன் தாக்கமும்',
      'பல்வேறு துறைகளில் தமிழ்நாட்டின் சாதனைகள்',
      'தமிழ்நாட்டில் மின்-ஆட்சி',
    ],
  ),
  _Unit(
    num: 'X',
    title: 'Aptitude & Mental Ability',
    tamilTitle: 'திறனாய்வு மற்றும் மனக்கணக்கு',
    color: const Color(0xFFCA8A04),
    topics: [
      'Simplification — Percentage — HCF — LCM',
      'Ratio and Proportion',
      'Simple interest — Compound interest — Area — Volume — Time and Work',
      'Logical Reasoning — Puzzles — Dice — Visual Reasoning — Alphanumeric Reasoning — Number Series',
    ],
    tamilTopics: [
      'எளிமைப்படுத்தல் — சதவீதம் — மீ.பொ.வ — மீ.சொ.ம',
      'விகிதம் மற்றும் விகித சமம்',
      'தனிவட்டி — கூட்டுவட்டி — பரப்பளவு — கனளவு — நேரம் மற்றும் வேலை',
      'தருக்க சிந்தனை — புதிர்கள் — தாயங்கள் — காட்சி சிந்தனை — எழுத்து-எண் சிந்தனை — எண் தொடர்',
    ],
  ),
];

// ─── Main Exam Papers ─────────────────────────────────────────────────────────

final _mainPapers = <_Paper>[
  _Paper(
    num: 'I',
    title: 'Compulsory Tamil Language',
    tamilTitle: 'கட்டாயத் தமிழ் மொழி',
    standard: 'SSLC Standard — Qualifying Test',
    tamilStandard: '10-ஆம் வகுப்பு தரம் — தகுதித் தேர்வு',
    color: const Color(0xFFDC2626),
    units: [
      _Unit(
        num: '',
        title: 'Tamil Language Qualification Test',
        tamilTitle: 'தமிழ் மொழி தகுதித் தேர்வு',
        color: const Color(0xFFDC2626),
        topics: [
          'Translation (Tamil to English and English to Tamil)',
          'Précis Writing',
          'Comprehension',
          'Expansion from Brief Notes',
          'Essay writing on Thirukkural topics',
          'Official Letter Writing',
          'Tamil Language Knowledge',
        ],
        tamilTopics: [
          'தமிழிலிருந்து ஆங்கிலத்திலும் ஆங்கிலத்திலிருந்து தமிழிலும் மொழிபெயர்ப்பு',
          'சுருக்கவெழுத்து',
          'புரிதல்',
          'சுருக்கக் குறிப்புகளிலிருந்து விரிவாக்கம்',
          'திருக்குறள் தலைப்புகளில் கட்டுரை எழுதல்',
          'அலுவல் கடிதம் எழுதல்',
          'தமிழ் மொழி அறிவு',
        ],
      ),
    ],
  ),
  _Paper(
    num: 'II',
    title: 'General Studies',
    tamilTitle: 'பொது ஆய்வு',
    standard: 'Degree Standard',
    tamilStandard: 'பட்டப்படிப்பு தரம்',
    color: const Color(0xFF4F46E5),
    units: [
      _Unit(
        num: 'I',
        title: 'Modern History of India and Indian Culture',
        tamilTitle: 'இந்தியாவின் நவீன வரலாறும் இந்தியப் பண்பாடும்',
        color: const Color(0xFF4F46E5),
        topics: [
          'Advent of European invasion — Expansion and consolidation of British rule — Early uprisings — 1857 Revolt — Indian National Congress — Growth of militant movements — National leaders (Gandhi, Nehru, Tagore, Netaji, Ambedkar, Patel, Maulana Abul Kalam Azad) — Era of Acts & Pacts — Second World War and final phase of freedom struggle — Communalism and Partition',
          'Effect of British rule on socio-economic factors — National renaissance — Socio-religious reform movements',
          'India since independence — Characteristics of Indian culture — Unity in diversity — India: a secular state — Role of Tamil Nadu in freedom struggle (Bharathiar, VOC, Subramania Siva, Rajaji, Periyar) — Political parties and Welfare schemes',
          'Latest diary of events (National & International) — National symbols — Eminent personalities in news — Sports & Games — Books & Authors — Awards & Honours',
        ],
        tamilTopics: [
          'ஐரோப்பிய படையெடுப்பின் தொடக்கம் — பிரிட்டிஷ் ஆட்சியின் விரிவாக்கம் மற்றும் உறுதிப்படுத்தல் — ஆரம்பகால கிளர்ச்சிகள் — 1857 புரட்சி — தேசிய காங்கிரஸ் — தீவிர இயக்கங்கள் — தேசிய தலைவர்கள்: காந்தி, நேரு, தாகூர், நேதாஜி, அம்பேத்கர், படேல், மவுலானா அபுல் கலாம் ஆசாத் — சட்டங்கள் மற்றும் ஒப்பந்தங்களின் காலம் — இரண்டாம் உலகப் போரும் விடுதலை போரின் இறுதிக் கட்டமும் — நாடு பிரிவு',
          'பிரிட்டிஷ் ஆட்சியின் சமூக-பொருளாதார தாக்கம் — தேசிய விழிப்புணர்வு — சமூக-மத சீர்திருத்த இயக்கங்கள்',
          'சுதந்திரத்திற்குப் பிறகு இந்தியா — இந்திய கலாச்சாரத்தின் பண்புகள் — பன்முகத்தன்மையில் ஒற்றுமை — இந்தியா: மதச்சார்பற்ற நாடு — விடுதலை போரில் தமிழ்நாட்டின் பங்கு: பாரதியார், வ.உ.சி., சுப்பிரமணிய சிவா, ராஜாஜி, பெரியார்',
          'சமீபத்திய நிகழ்வுகள் (தேசிய மற்றும் சர்வதேசிய) — தேசிய சின்னங்கள் — விளையாட்டு — புத்தகங்கள் மற்றும் ஆசிரியர்கள் — விருதுகள்',
        ],
      ),
      _Unit(
        num: 'II',
        title: 'Social Issues in India and Tamil Nadu',
        tamilTitle: 'இந்தியா மற்றும் தமிழ்நாட்டில் சமூகப் பிரச்சினைகள்',
        color: const Color(0xFF7C3AED),
        topics: [
          'Population Explosion — Unemployment — Child Abuse & Child Labour — Poverty — Rural and Urban Sanitation — Illiteracy',
          'Women Empowerment — Role of Government — Social injustice to Women — Domestic violence, Dowry, Sexual assault — Role of women\'s organisations',
          'Social changes in India — Urbanization and its impact — Violence, Terrorism and Communal violence — Regional Disparities — Problems of Minorities — Human Rights',
          'Education — Social Development — Community Development Programmes — Employment Guarantee Schemes — Self Employment & Entrepreneurship — Role of NGOs — Government Policy on Health — Welfare Schemes for vulnerable sections',
        ],
        tamilTopics: [
          'மக்கள்தொகை வெடிப்பு — வேலைவாய்ப்பின்மை — குழந்தை துஷ்பிரயோகம் மற்றும் குழந்தை தொழிலாளர் — வறுமை — கிராம மற்றும் நகர் சுகாதாரம் — கல்வியறிவின்மை',
          'பெண்கள் அதிகாரமளித்தல் — அரசாங்கத்தின் பங்கு — பெண்களுக்கு சமூக அநீதி — குடும்ப வன்முறை, வரதட்சணை, பாலியல் வன்கொடுமை — பெண்கள் நிறுவனங்களின் பங்கு',
          'இந்தியாவில் சமூக மாற்றங்கள் — நகரமயமாக்கல் மற்றும் அதன் தாக்கம் — வன்முறை, பயங்கரவாதம், வகுப்புவாத வன்முறை — பிராந்திய ஏற்றத்தாழ்வுகள் — சிறுபான்மையினர் பிரச்சினைகள் — மனித உரிமைகள்',
          'கல்வி — சமூக வளர்ச்சி — சமூக மேம்பாட்டு திட்டங்கள் — வேலைவாய்ப்பு உறுதி திட்டங்கள் — சுய தொழில் — தன்னார்வ நிறுவனங்களின் பங்கு — அரசு சுகாதாரக் கொள்கை — பாதிக்கப்படக்கூடிய பிரிவினருக்கான நலன்புரி திட்டங்கள்',
        ],
      ),
      _Unit(
        num: 'III',
        title: 'General Aptitude & Mental Ability  (SSLC Standard)',
        tamilTitle: 'பொது திறனாய்வு மற்றும் மனக்கணக்கு (10-ஆம் வகுப்பு தரம்)',
        color: const Color(0xFFCA8A04),
        topics: [
          'Data collection, compilation and presentation — Tables, Graphs, Diagrams — Percentage, HCF, LCM, Ratio & Proportion — Simple & Compound Interest — Area, Volume, Time and Work — Probability',
          'Information Technology — Basic terms, Communications — Application of ICT — Decision making and problem solving — Basics of Computers & Computer terminology',
        ],
        tamilTopics: [
          'தரவு சேகரிப்பு, தொகுத்தல் மற்றும் வழங்கல் — அட்டவணைகள், வரைபடங்கள், வரைவு படங்கள் — சதவீதம், மீ.பொ.வ, மீ.சொ.ம, விகிதம் மற்றும் விகித சமம் — தனி மற்றும் கூட்டு வட்டி — பரப்பளவு, கனளவு, நேரம் மற்றும் வேலை — நிகழ்தகவு',
          'தகவல் தொழில்நுட்பம் — அடிப்படை சொற்கள், தகவல் தொடர்பு — ICT பயன்பாடுகள் — முடிவெடுத்தல் மற்றும் சிக்கல் தீர்வு — கணினி அடிப்படைகள் மற்றும் கணினி சொற்கள்',
        ],
      ),
    ],
  ),
  _Paper(
    num: 'III',
    title: 'General Studies',
    tamilTitle: 'பொது ஆய்வு',
    standard: 'Degree Standard',
    tamilStandard: 'பட்டப்படிப்பு தரம்',
    color: const Color(0xFF059669),
    units: [
      _Unit(
        num: 'I',
        title: 'Indian Polity and Emerging Political Trends',
        tamilTitle: 'இந்திய அரசியல் அமைப்பும் வளர்ந்து வரும் அரசியல் போக்குகளும்',
        color: const Color(0xFF7C3AED),
        topics: [
          'Constitution of India: Historical background, Preamble, Fundamental Rights & Duties, DPSP, Schedules',
          'Union Executive: President, Vice-President, Prime Minister, Council of Ministers, Attorney General of India',
          'Union Legislature: Parliament — Lok Sabha and Rajya Sabha — Composition, Powers, Functions and Legislative procedures',
          'Union Judiciary: Structure, Powers and Functions of the Supreme Court — Judicial Review — Latest Verdicts',
          'State Executive: Governor, Chief Minister, Council of Ministers, Advocate General; State Legislature — Organization, Powers and Functions',
          'State Judiciary: High Courts, District Courts; Local Government: 73rd and 74th Constitutional Amendment Act, 1992',
          'Federalism: Centre-State Relations (Administrative, Legislative, Financial) — Union Territories: Evolution of States',
          'Civil Services in India: Historical background, Classification, Recruitment & Training; State Services',
          'Official Language, Constitutional Amendments, Special Status to J&K (Art 370)',
          'Political Parties: National & Regional parties, Pressure Groups, Public Opinion, Mass Media, NGOs',
          'Anti-Corruption measures: CVC, Lok Adalats, Ombudsman, RTI Act — Minister-Secretary Relationship',
          'Constitutional and Non-Constitutional Bodies; Defence, National Security and Terrorism; World Organisations',
          'India\'s Foreign Policy: Relations with neighbouring countries — Security and defence — Nuclear Policy — Indian Diaspora',
        ],
        tamilTopics: [
          'இந்திய அரசியலமைப்பு: வரலாற்று பின்னணி, முன்னுரை, அடிப்படை உரிமைகள் மற்றும் கடமைகள், DPSP, அட்டவணைகள்',
          'ஒன்றிய நிறைவேற்றுப் பிரிவு: ஜனாதிபதி, துணை ஜனாதிபதி, பிரதமர், அமைச்சரவை, அட்டர்னி ஜெனரல்',
          'ஒன்றிய சட்டமன்றம்: பாராளுமன்றம் — லோக்சபா மற்றும் ராஜ்யசபா — அமைப்பு, அதிகாரங்கள், செயல்பாடுகள் மற்றும் சட்டமியற்றும் நடைமுறைகள்',
          'ஒன்றிய நீதிமன்றம்: உச்ச நீதிமன்றத்தின் அமைப்பு, அதிகாரங்கள் மற்றும் செயல்பாடுகள் — நீதித் திறனாய்வு — சமீபத்திய தீர்ப்புகள்',
          'மாநில நிறைவேற்றுப் பிரிவு: ஆளுநர், முதலமைச்சர், அமைச்சரவை, ஆட்வகேட் ஜெனரல்; மாநில சட்டமன்றம் — அமைப்பு, அதிகாரங்கள் மற்றும் செயல்பாடுகள்',
          'மாநில நீதிமன்றம்: உயர் நீதிமன்றங்கள், மாவட்ட நீதிமன்றங்கள்; உள்ளாட்சி: 73-வது மற்றும் 74-வது அரசியலமைப்பு திருத்தம், 1992',
          'கூட்டாட்சி: மத்திய-மாநில உறவுகள் (நிர்வாக, சட்டமியற்றும், நிதி) — யூனியன் பிரதேசங்கள்: மாநிலங்களின் பரிணாமம்',
          'இந்தியாவில் குடிமைச் சேவைகள்: வரலாற்று பின்னணி, வகைப்பாடு, ஆட்சேர்ப்பு மற்றும் பயிற்சி; மாநில சேவைகள்',
          'அதிகாரப்பூர்வ மொழி, அரசியலமைப்பு திருத்தங்கள், ஜம்மு-காஷ்மீருக்கு சிறப்பு அந்தஸ்து (பிரிவு 370)',
          'அரசியல் கட்சிகள்: தேசிய மற்றும் பிராந்திய கட்சிகள், அழுத்தக் குழுக்கள், மக்கள் கருத்து, ஊடகங்கள், தன்னார்வ நிறுவனங்கள்',
          'ஊழல் தடுப்பு நடவடிக்கைகள்: CVC, லோக் அதாலத்கள், ஓம்புட்ஸ்மேன், RTI சட்டம் — அமைச்சர்-செயலாளர் உறவு',
          'அரசியலமைப்பு மற்றும் அரசியலமைப்பு சாரா அமைப்புகள்; பாதுகாப்பு, தேசிய பாதுகாப்பு மற்றும் பயங்கரவாதம்; உலக நிறுவனங்கள்',
          'இந்தியாவின் வெளியுறவுக் கொள்கை: அண்டை நாட்டு உறவுகள் — பாதுகாப்பு — அணு கொள்கை — இந்திய வாழ் வெளிநாட்டு இந்தியர்கள்',
        ],
      ),
      _Unit(
        num: 'II',
        title: 'Role and Impact of Science and Technology in Development of India',
        tamilTitle: 'இந்தியாவின் வளர்ச்சியில் அறிவியல் மற்றும் தொழில்நுட்பத்தின் பங்களிப்பு',
        color: const Color(0xFF0891B2),
        topics: [
          'Science and Technology — Role, Achievements and Developments — Applications in everyday life — Energy (Conventional and Non-conventional) — Oil exploration — Defence Research Organisations',
          'Advancements in IT, Space, Computers, Robotics, Nano-Technology — Mobile Communication — Remote sensing and its benefits',
          'Health and hygiene — Human diseases — Prevention and remedies — Communicable and Non-communicable diseases — Genetic Engineering — Organ transplantation — Stem cell Technology — Medical Tourism',
          'Achievements of Indians in the fields of Science and Technology — Latest inventions in science & technology',
        ],
        tamilTopics: [
          'அறிவியல் மற்றும் தொழில்நுட்பம் — பங்கு, சாதனைகள், வளர்ச்சி — அன்றாட வாழ்வில் பயன்பாடுகள் — ஆற்றல் (மரபு மற்றும் மரபுசாரா) — எண்ணெய் ஆய்வு — பாதுகாப்பு ஆராய்ச்சி நிறுவனங்கள்',
          'தகவல் தொழில்நுட்பம், விண்வெளி, கணினிகள், ரோபோக்கள், நானோ தொழில்நுட்பம் — மொபைல் தகவல் தொடர்பு — தொலைவு உணர்தலும் அதன் நன்மைகளும்',
          'சுகாதாரம் மற்றும் நலன் — மனித நோய்கள் — தடுப்பு மற்றும் சிகிச்சை — தொற்று மற்றும் தொற்றா நோய்கள் — மரபணு பொறியியல் — உறுப்பு மாற்று — கோல் செல் தொழில்நுட்பம் — மருத்துவ சுற்றுலா',
          'அறிவியல் மற்றும் தொழில்நுட்பத்தில் இந்தியர்களின் சாதனைகள் — சமீபத்திய கண்டுபிடிப்புகள்',
        ],
      ),
      _Unit(
        num: 'III',
        title: 'Tamil Society — Its Culture and Heritage',
        tamilTitle: 'தமிழ் சமூகம் — பண்பாடு மற்றும் பாரம்பரியம்',
        color: const Color(0xFFDB2777),
        topics: [
          'Tamil Society: Origin and expansion',
          'Art and Culture: Literature, Music, Film, Drama, Architecture, Sculpture, Paintings and Folk Arts',
          'Socio-economic history of Tamil Nadu from Sangam age till date',
          'Growth of Rationalist and Dravidian movements in Tamil Nadu — Their role in the socio-economic development of Tamil Nadu',
          'Social and cultural life of contemporary Tamils: Caste, Religion, Women, Politics, Education, Economy, Trade and relationship with other countries',
          'Tamil and other Disciplines: Mass Media, Computer etc.',
        ],
        tamilTopics: [
          'தமிழ் சமூகம்: தோற்றம் மற்றும் விரிவாக்கம்',
          'கலை மற்றும் பண்பாடு: இலக்கியம், இசை, திரைப்படம், நாடகம், கட்டிடக் கலை, சிற்பம், ஓவியம் மற்றும் நாட்டுப்புற கலைகள்',
          'சங்க காலம் முதல் இன்று வரை தமிழ்நாட்டின் சமூக-பொருளாதார வரலாறு',
          'தமிழ்நாட்டில் பகுத்தறிவு இயக்கம் மற்றும் திராவிட இயக்கங்களின் வளர்ச்சி — தமிழ்நாட்டின் சமூக-பொருளாதார வளர்ச்சியில் அவற்றின் பங்கு',
          'சமகால தமிழரின் சமூக மற்றும் கலாச்சார வாழ்க்கை: சாதி, மதம், பெண்கள், அரசியல், கல்வி, பொருளாதாரம், வர்த்தகம் மற்றும் பிற நாடுகளுடன் உறவு',
          'தமிழும் பிற துறைகளும்: ஊடகங்கள், கணினி முதலியன',
        ],
      ),
    ],
  ),
  _Paper(
    num: 'IV',
    title: 'General Studies',
    tamilTitle: 'பொது ஆய்வு',
    standard: 'Degree Standard',
    tamilStandard: 'பட்டப்படிப்பு தரம்',
    color: const Color(0xFF0E7490),
    units: [
      _Unit(
        num: 'I',
        title: 'Geography of India with Special Reference to Tamil Nadu',
        tamilTitle: 'இந்திய புவியியல் — தமிழ்நாட்டில் சிறப்பு குறிப்பு',
        color: const Color(0xFF059669),
        topics: [
          'Location — Physical features — Major Rivers — Weather & Climate — Monsoon, Rainfall — Natural resources (Soil, Water, Forest, Minerals, Wildlife) — Agricultural pattern — Livestock — Fisheries — Industries — Social-Cultural geography — Population (Growth, Density and Distribution) — Racial, linguistic and major tribes',
          'Oceanography — Bottom relief features of Indian Ocean, Arabian Sea and Bay of Bengal',
          'Basics of Geospatial Technology: Geographical Information System (GIS) and Global Navigation Satellite System (GNSS)',
          'Map: Geographical landmarks — India and its neighbours',
        ],
        tamilTopics: [
          'இடம் — இயற்கை அமைப்பு — முக்கிய நதிகள் — வானிலை மற்றும் காலநிலை — பருவமழை, மழையளவு — இயற்கை வளங்கள் (மண், நீர், காடு, தாதுக்கள், வனவிலங்குகள்) — விவசாய முறை — கால்நடை — மீன்வளம் — தொழிற்சாலைகள் — சமூக-கலாச்சார புவியியல் — மக்கள்தொகை (வளர்ச்சி, அடர்த்தி மற்றும் பரவல) — இனம், மொழி மற்றும் முக்கிய பழங்குடியினர்',
          'கடலியல் — இந்திய பெருங்கடல், அரபிக் கடல் மற்றும் வங்காள விரிகுடாவின் கடல் அடித்தள அமைப்பு',
          'புவி-இடஞ்சார் தொழில்நுட்பத்தின் அடிப்படைகள்: புவி தகவல் அமைப்பு (GIS) மற்றும் உலகளாவிய வழிசெலுத்தல் செயற்கைக்கோள் அமைப்பு (GNSS)',
          'வரைபடம்: புவியியல் அடையாளங்கள் — இந்தியாவும் அதன் அண்டை நாடுகளும்',
        ],
      ),
      _Unit(
        num: 'II',
        title: 'Environment, Biodiversity and Disaster Management',
        tamilTitle: 'சுற்றுச்சூழல், உயிரி பன்முகத்தன்மை மற்றும் பேரிடர் மேலாண்மை',
        color: const Color(0xFF16A34A),
        topics: [
          'Ecology: Structure and function of Ecosystem — Ecological succession — Biodiversity conservation (Types, Hot Spots in India) — In situ and Ex situ conservation — Roles of CITES, IUCN & Convention on Biological Diversity (CBD)',
          'Environmental Pollution and Management: Air, Water, Soil, Thermal and Noise pollution — Solid and Hazardous waste management — Environmental Impact Assessment (EIA) — Environmental Clearance — Environmental Auditing',
          'Climate Change: Global Environmental Issues — Changes in monsoon pattern — Environmental consequences and mitigation measures — Clean and Green Energy — Environmental Sustainability',
          'Environmental Laws, Policies & Treaties in India and Global scenario — Natural calamities and Disaster Management — Environmental Health and Sanitation',
        ],
        tamilTopics: [
          'சூழலியல்: சுற்றுச்சூழல் அமைப்பின் கட்டமைப்பு மற்றும் செயல்பாடு — சூழல் வாரிசேற்றம் — உயிரி பன்முகத்தன்மை பாதுகாப்பு (வகைகள், இந்தியாவில் சூடான பகுதிகள்) — in situ மற்றும் ex situ பாதுகாப்பு — CITES, IUCN மற்றும் உயிரி பன்முகத்தன்மை மாநாட்டின் பங்கு',
          'சுற்றுச்சூழல் மாசுபாடும் மேலாண்மையும்: காற்று, நீர், மண், வெப்ப மற்றும் ஒலி மாசுபாடு — திடக்கழிவு மேலாண்மை — சுற்றுச்சூழல் தாக்க மதிப்பீடு — சுற்றுச்சூழல் தணிக்கை',
          'காலநிலை மாற்றம்: உலகளாவிய சுற்றுச்சூழல் சிக்கல்கள் — பருவமழை மாற்றங்கள் — சுற்றுச்சூழல் விளைவுகள் மற்றும் தணிப்பு நடவடிக்கைகள் — பசுமை ஆற்றல் — சுற்றுச்சூழல் நிலைத்தன்மை',
          'இந்தியாவிலும் உலகளாவிய அளவிலும் சுற்றுச்சூழல் சட்டங்கள், கொள்கைகள் மற்றும் ஒப்பந்தங்கள் — இயற்கை பேரழிவுகள் மற்றும் பேரிடர் மேலாண்மை — சுற்றுச்சூழல் சுகாதாரம்',
        ],
      ),
      _Unit(
        num: 'III',
        title: 'Indian Economy — Current Economic Trends',
        tamilTitle: 'இந்தியப் பொருளாதாரம் — நடப்பு பொருளாதார போக்குகள்',
        color: const Color(0xFF0891B2),
        topics: [
          'Features of Indian Economy — Demographical profile — National Income — Capital formation — NEP — NITI AYOG — National Development Council',
          'Agriculture — Role, Land reforms, New Agricultural Strategy, Green Revolution — Price Policy, PDS, Subsidy, Food Security — Agricultural Marketing, Crop Insurance, Labour — Rural credit & indebtedness — WTO & Agriculture',
          'Industry — Growth, Policy — Public sector and disinvestment — Privatisation and Liberalization — PPP — SEZs — MSMEs — Make in India',
          'Infrastructure in India — Transport System — Energy — Power — Communication — Social Infrastructure — Science & Technology — R&D',
          'Banking & Finance — Central Bank — Commercial Bank — NBFIs — Stock Market — Financial Reforms — Financial Stability — Monetary Policy — RBI & Autonomy',
          'Public Finance — Sources of Revenue — Tax & Non-Tax Revenue — Canons of taxation — GST — Public expenditure — Public debt — Finance Commission — Fiscal Policy',
          'Issues in Indian Economy — Poverty & inequality — Poverty alleviation programmes — MGNREGA — Unemployment — Inflation — Sustainable economic growth — Gender issues',
          'India\'s Foreign Trade — BOP, EX-IM Policy, FOREX Market, FDI — Globalization & its impact — Global economic crisis & impact on Indian economy',
          'International Agencies — IMF, World Bank, BRICS, SAARC, ASEAN',
          'Tamil Nadu Economy — Gross State Domestic Product — Economic growth trends — Agriculture — Industry & entrepreneurship — Infrastructure — SHGs & Rural Women empowerment — Rural poverty — Environmental issues — Recent government welfare programmes',
        ],
        tamilTopics: [
          'இந்திய பொருளாதாரத்தின் தன்மை — மக்கள்தொகை சுயவிவரம் — தேசிய வருமானம் — மூலதன உருவாக்கம் — NEP — நீதி ஆயோக் — தேசிய வளர்ச்சி கவுன்சில்',
          'விவசாயம் — பங்கு, நில சீர்திருத்தங்கள், புதிய விவசாய உத்தி, பசுமை புரட்சி — விலைக் கொள்கை, PDS, மானியம், உணவு பாதுகாப்பு — விவசாய சந்தை, பயிர் காப்பீடு — கிராம கடன் — WTO மற்றும் விவசாயம்',
          'தொழில் — வளர்ச்சி, கொள்கை — பொதுத்துறை மற்றும் தனியார்மயம் — PPP — SEZs — MSMEs — Make in India',
          'இந்தியாவில் உள்கட்டமைப்பு — போக்குவரத்து அமைப்பு — ஆற்றல் — மின்சாரம் — தகவல் தொடர்பு — ஆராய்ச்சி மற்றும் மேம்பாடு',
          'வங்கி மற்றும் நிதி — மத்திய வங்கி — வணிக வங்கி — பங்குச் சந்தை — நிதிக் கொள்கைகள் — RBI தன்னாட்சி',
          'பொது நிதி — வருவாய் ஆதாரங்கள் — வரி மற்றும் வரியல்லாத வருமானம் — வரியிடுதல் நியதிகள் — GST — பொது கடன் — நிதிக் கமிஷன் — நிதி கொள்கை',
          'இந்தியப் பொருளாதார சிக்கல்கள் — வறுமை மற்றும் ஏற்றத்தாழ்வு — வறுமை ஒழிப்பு திட்டங்கள் — MGNREGA — வேலைவாய்ப்பின்மை — பணவீக்கம் — பாலின சிக்கல்கள்',
          'இந்தியாவின் வெளிவாணிகம் — BOP — ஏற்றுமதி-இறக்குமதி கொள்கை — FOREX சந்தை — FDI — உலகமயமாக்கல் — உலகளாவிய பொருளாதார நெருக்கடி',
          'சர்வதேச நிறுவனங்கள் — IMF, உலக வங்கி, BRICS, SAARC, ASEAN',
          'தமிழ்நாடு பொருளாதாரம் — மொத்த மாநில உள்நாட்டு உற்பத்தி — விவசாயம் — தொழில் மற்றும் தொழில்முனைவு — உள்கட்டமைப்பு — SHGs மற்றும் ஊரக மகளிர் — ஊரக வறுமை — சுற்றுச்சூழல் சிக்கல்கள் — சமீபத்திய நல திட்டங்கள்',
        ],
      ),
    ],
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class SyllabusScreen extends ConsumerWidget {
  const SyllabusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(studyLangProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TNPSC Group 1',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.3)),
              Text(isTamil ? 'தேர்வு பாடத்திட்டம்' : 'Exam Syllabus',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
            ],
          ),
          actions: const [
            LangToggleButton(),
            SizedBox(width: 10),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Preliminary Exam'),
              Tab(text: 'Main Exam'),
            ],
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
        body: TabBarView(
          children: [
            _PrelimTab(isTamil: isTamil),
            _MainExamTab(isTamil: isTamil),
          ],
        ),
      ),
    );
  }
}

// ─── Tabs ─────────────────────────────────────────────────────────────────────

class _PrelimTab extends StatelessWidget {
  final bool isTamil;
  const _PrelimTab({required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
      children: [
        _ExamInfoCard(
          emoji: '📝',
          title: isTamil ? 'முன்னோடித் தேர்வு' : 'Preliminary Examination',
          subtitle: isTamil
              ? 'ஒருங்கிணைந்த சிவில் சேவைத் தேர்வு — I'
              : 'Combined Civil Services Examination — I',
          stats: isTamil
              ? ['குறியீடு: 003', '200 வினாக்கள்', '300 மதிப்பெண்கள்', 'பட்டப்படிப்பு தரம்', 'பலவுள் ஒன்று வகை']
              : ['Code No: 003', '200 Questions', '300 Marks', 'Degree Standard', 'Objective Type'],
          color: const Color(0xFF4338CA),
        ),
        const SizedBox(height: 4),
        ..._prelimUnits.map((u) => _UnitCard(unit: u, isTamil: isTamil)),
      ],
    );
  }
}

class _MainExamTab extends StatelessWidget {
  final bool isTamil;
  const _MainExamTab({required this.isTamil});

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[
      _ExamInfoCard(
        emoji: '✍️',
        title: isTamil ? 'முதன்மைத் தேர்வு' : 'Main Examination',
        subtitle: isTamil ? '4 தாள்கள் — கட்டுரை / விவரிப்பு வகை' : '4 Papers — Written / Descriptive Type',
        stats: isTamil
            ? ['தாள் I: 10-ஆம் வகுப்பு', 'தாள் II–IV: பட்டப்படிப்பு', 'கட்டுரை வகை விடைகள்']
            : ['Paper I: SSLC Std', 'Papers II–IV: Degree Std', 'Essay Type Answers'],
        color: const Color(0xFF0E7490),
      ),
    ];

    for (final paper in _mainPapers) {
      widgets.add(_PaperHeader(paper: paper, isTamil: isTamil));
      for (final unit in paper.units) {
        widgets.add(_UnitCard(
          unit: unit,
          isTamil: isTamil,
          showTranslateIcon: unit.num.isEmpty,
        ));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
      children: widgets,
    );
  }
}

// ─── Info card ────────────────────────────────────────────────────────────────

class _ExamInfoCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<String> stats;
  final Color color;
  const _ExamInfoCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: stats
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Paper section header ─────────────────────────────────────────────────────

class _PaperHeader extends StatelessWidget {
  final _Paper paper;
  final bool isTamil;
  const _PaperHeader({required this.paper, required this.isTamil});

  @override
  Widget build(BuildContext context) {
    final displayTitle = isTamil ? paper.tamilTitle : paper.title;
    final displayStd = isTamil ? paper.tamilStandard : paper.standard;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 14, 0, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: paper.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: paper.color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: paper.color,
                borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text('P${paper.num}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${isTamil ? "தாள்" : "Paper"} ${paper.num} — $displayTitle',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: paper.color,
                        fontSize: 13.5)),
                Text(displayStd,
                    style: TextStyle(
                        color: paper.color.withValues(alpha: 0.7),
                        fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Unit expandable card ─────────────────────────────────────────────────────

class _UnitCard extends StatefulWidget {
  final _Unit unit;
  final bool isTamil;
  final bool showTranslateIcon;
  const _UnitCard({
    required this.unit,
    required this.isTamil,
    this.showTranslateIcon = false,
  });

  @override
  State<_UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<_UnitCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final displayTitle =
        widget.isTamil && u.tamilTitle.isNotEmpty ? u.tamilTitle : u.title;
    final displayTopics =
        widget.isTamil && u.tamilTopics.isNotEmpty ? u.tamilTopics : u.topics;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? u.color.withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
          width: _expanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _expanded
                ? u.color.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: _expanded ? 14 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.hardEdge,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (v) => setState(() => _expanded = v),
            tilePadding: const EdgeInsets.fromLTRB(14, 4, 12, 4),
            leading: widget.showTranslateIcon
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: u.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.translate_rounded, color: u.color, size: 22),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: u.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.isTamil ? 'அலகு' : 'Unit',
                            style: TextStyle(
                                color: u.color,
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                height: 1.1)),
                        Text(u.num,
                            style: TextStyle(
                                color: u.color,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                      ],
                    ),
                  ),
            title: Text(displayTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF111827))),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${displayTopics.length} ${widget.isTamil ? "தலைப்புகள்" : "topic${displayTopics.length > 1 ? "s" : ""}"}',
                style: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ),
            trailing: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child:
                  Icon(Icons.expand_more_rounded, color: u.color, size: 26),
            ),
            childrenPadding: EdgeInsets.zero,
            children: [
              Divider(height: 1, color: u.color.withValues(alpha: 0.15)),
              ...displayTopics.asMap().entries.map(
                    (e) => _TopicRow(
                        topic: e.value, index: e.key, color: u.color),
                  ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Topic bullet row ─────────────────────────────────────────────────────────

class _TopicRow extends StatelessWidget {
  final String topic;
  final int index;
  final Color color;
  const _TopicRow(
      {required this.topic, required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, index == 0 ? 12 : 2, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(topic,
                style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: Color(0xFF374151))),
          ),
        ],
      ),
    );
  }
}
