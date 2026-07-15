-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(20),
  email VARCHAR(255) UNIQUE,
  password_hash VARCHAR(255),
  name VARCHAR(255),
  avatar_url VARCHAR(500),
  google_id VARCHAR(255),
  exam_target VARCHAR(100),
  state VARCHAR(100),
  language VARCHAR(20) DEFAULT 'en',
  coins_balance INT DEFAULT 0,
  xp INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migrations: idempotent, safe to run on any existing DB instance
ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);
ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255);
ALTER TABLE IF EXISTS users ALTER COLUMN phone DROP NOT NULL;

-- AI question generation columns
ALTER TABLE IF EXISTS questions ADD COLUMN IF NOT EXISTS explanation TEXT;
ALTER TABLE IF EXISTS questions ADD COLUMN IF NOT EXISTS bloom_level VARCHAR(20) DEFAULT 'remember';
ALTER TABLE IF EXISTS chapters ADD COLUMN IF NOT EXISTS content_text TEXT;
ALTER TABLE IF EXISTS chapters ADD COLUMN IF NOT EXISTS title_tamil VARCHAR(255);

-- Previous Year Questions (PYQ) + bilingual question/option text
ALTER TABLE IF EXISTS questions ADD COLUMN IF NOT EXISTS text_tamil TEXT;
ALTER TABLE IF EXISTS questions ADD COLUMN IF NOT EXISTS is_pyq BOOLEAN DEFAULT false;
ALTER TABLE IF EXISTS questions ADD COLUMN IF NOT EXISTS topic VARCHAR(255);
ALTER TABLE IF EXISTS questions ADD COLUMN IF NOT EXISTS exam_name VARCHAR(255);
ALTER TABLE IF EXISTS questions ADD COLUMN IF NOT EXISTS exam_year INT;
ALTER TABLE IF EXISTS questions ADD COLUMN IF NOT EXISTS answer_marked BOOLEAN DEFAULT false;
ALTER TABLE IF EXISTS question_options ADD COLUMN IF NOT EXISTS text_tamil TEXT;

CREATE INDEX IF NOT EXISTS idx_questions_is_pyq ON questions(is_pyq) WHERE is_pyq = true;

-- User Streaks table
CREATE TABLE IF NOT EXISTS user_streaks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_activity_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Subjects table
CREATE TABLE IF NOT EXISTS subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL UNIQUE,
  icon VARCHAR(255),
  exam_category VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Chapters table
CREATE TABLE IF NOT EXISTS chapters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  order_index INT DEFAULT 0,
  content_text TEXT,
  content_url VARCHAR(500),
  is_approved BOOLEAN DEFAULT false,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Questions table
CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chapter_id UUID NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  difficulty INT DEFAULT 1,
  source VARCHAR(100),
  created_by_user_id UUID REFERENCES users(id),
  ai_generated BOOLEAN DEFAULT false,
  is_approved BOOLEAN DEFAULT false,
  helpful_count INT DEFAULT 0,
  flagged_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Question Options table
CREATE TABLE IF NOT EXISTS question_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Question Ratings table
CREATE TABLE IF NOT EXISTS question_ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_helpful BOOLEAN,
  is_flagged BOOLEAN,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(question_id, user_id)
);

-- Tests table
CREATE TABLE IF NOT EXISTS tests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chapter_id UUID NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES users(id),
  type VARCHAR(50) DEFAULT 'practice',
  title VARCHAR(255),
  description TEXT,
  time_limit_sec INT,
  question_count INT,
  is_published BOOLEAN DEFAULT false,
  published_at TIMESTAMP,
  target_exam VARCHAR(100),
  target_state VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Test Questions junction table
CREATE TABLE IF NOT EXISTS test_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  test_id UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  position INT NOT NULL,
  UNIQUE(test_id, question_id)
);

-- Test Attempts table
CREATE TABLE IF NOT EXISTS test_attempts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  test_id UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  score INT,
  total_questions INT,
  time_taken_sec INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attempt Answers table
CREATE TABLE IF NOT EXISTS attempt_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attempt_id UUID NOT NULL REFERENCES test_attempts(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  selected_option_id UUID REFERENCES question_options(id),
  time_taken_ms INT,
  is_correct BOOLEAN,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Challenges table
CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  test_id UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES users(id),
  entry_fee_coins INT NOT NULL,
  prize_pool_coins INT DEFAULT 0,
  max_participants INT,
  start_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  end_at TIMESTAMP NOT NULL,
  status VARCHAR(50) DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Challenge Participants table
CREATE TABLE IF NOT EXISTS challenge_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  attempt_id UUID REFERENCES test_attempts(id),
  rank INT,
  prize_won_coins INT DEFAULT 0,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(challenge_id, user_id)
);

-- Wallet Transactions table
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  amount_coins INT NOT NULL,
  reference_id VARCHAR(255),
  description TEXT,
  status VARCHAR(50) DEFAULT 'success',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment Orders table
CREATE TABLE IF NOT EXISTS payment_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  razorpay_order_id VARCHAR(255) UNIQUE,
  amount_inr DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Feed Posts table
CREATE TABLE IF NOT EXISTS feed_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_type VARCHAR(50) NOT NULL,
  ref_id UUID,
  ref_type VARCHAR(50),
  body_text TEXT,
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Post Likes table
CREATE TABLE IF NOT EXISTS post_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES feed_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(post_id, user_id)
);

-- Post Comments table
CREATE TABLE IF NOT EXISTS post_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES feed_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Follows table
CREATE TABLE IF NOT EXISTS user_follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  followee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(follower_id, followee_id),
  CHECK (follower_id != followee_id)
);

-- Achievements table
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  icon VARCHAR(255),
  xp_reward INT DEFAULT 0,
  coins_reward INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Achievements table
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, achievement_id)
);

-- Indexes (IF NOT EXISTS supported in PG 9.5+)
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_exam_target ON users(exam_target);
CREATE INDEX IF NOT EXISTS idx_chapters_subject_id ON chapters(subject_id);
CREATE INDEX IF NOT EXISTS idx_questions_chapter_id ON questions(chapter_id);
CREATE INDEX IF NOT EXISTS idx_tests_creator_id ON tests(creator_id);
CREATE INDEX IF NOT EXISTS idx_tests_chapter_id ON tests(chapter_id);
CREATE INDEX IF NOT EXISTS idx_test_attempts_user_id ON test_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_test_attempts_test_id ON test_attempts(test_id);
CREATE INDEX IF NOT EXISTS idx_challenges_creator_id ON challenges(creator_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_user_id ON challenge_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_feed_posts_user_id ON feed_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_feed_posts_created_at ON feed_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_follows_follower_id ON user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_followee_id ON user_follows(followee_id);

-- ─── TNPSC Group 1 Seed (idempotent) ─────────────────────────────────────────
DO $$
DECLARE
  v_subject_id UUID;
BEGIN
  INSERT INTO subjects (name, icon, exam_category)
  VALUES ('TNPSC Group 1', '📋', 'TNPSC')
  ON CONFLICT (name) DO NOTHING;

  SELECT id INTO v_subject_id FROM subjects WHERE name = 'TNPSC Group 1';

  INSERT INTO chapters (subject_id, title, order_index, content_text, is_approved)
  SELECT v_subject_id, t.title, t.ord, t.content_text, true FROM (VALUES
    (1,  'Prelim — Unit I: General Science',
     'Scientific Knowledge and Scientific Temper. Power of Reasoning. Rote Learning vs Conceptual Learning. Science as a tool to understand the past, present and future. Nature of Universe, General Scientific Laws, Mechanics, Properties of Matter, Force, Motion and Energy. Everyday application of Mechanics, Electricity and Magnetism, Light, Sound, Heat, Nuclear Physics, Laser, Electronics and Communications. Elements and Compounds, Acids, Bases, Salts, Petroleum Products, Fertilisers, Pesticides. Main concepts of Life Science, Classification of Living Organisms, Evolution, Genetics, Physiology, Nutrition, Health and Hygiene, Human Diseases. Environment and Ecology.'),
    (2,  'Prelim — Unit II: Current Events',
     'History: Latest diary of events, National symbols, Profile of States, Eminent personalities and places in news, Sports, Books and authors. Polity: Political parties and political system in India, Public awareness and General administration, Welfare oriented Government schemes and their utility, Problems in Public Delivery Systems. Geography: Geographical landmarks. Economics: Current socio-economic issues. Science: Latest inventions in Science and Technology. Prominent Personalities in various spheres: Arts, Science, Literature and Philosophy.'),
    (3,  'Prelim — Unit III: Geography of India',
     'Location, Physical features, Monsoon, Rainfall, Weather and Climate, Water Resources, Rivers in India, Soil, Minerals and Natural Resources, Forest and Wildlife, Agricultural pattern. Transport and Communication. Social Geography: Population density and distribution, Racial and Linguistic Groups, Major Tribes. Natural calamity, Disaster Management, Environmental pollution: Reasons and preventive measures, Climate change, Green energy.'),
    (4,  'Prelim — Unit IV: History and Culture of India',
     'Indus Valley Civilization, Guptas, Delhi Sultans, Mughals and Marathas, Age of Vijayanagaram and Bahmani Kingdoms, South Indian History. Change and Continuity in the Socio-Cultural History of India. Characteristics of Indian Culture, Unity in Diversity: Race, Language, Custom. India as a Secular State, Social Harmony.'),
    (5,  'Prelim — Unit V: Indian Polity',
     'Constitution of India, Preamble to the Constitution, Salient features of the Constitution, Union, State and Union Territory. Citizenship, Fundamental Rights, Fundamental Duties, Directive Principles of State Policy. Union Executive, Union Legislature, State Executive, State Legislature, Local Governments, Panchayat Raj. Spirit of Federalism: Centre-State Relationships. Election, Judiciary in India, Rule of Law. Corruption in Public Life, Anti-corruption measures, Lokpal and Lok Ayukta, Right to Information, Empowerment of Women, Consumer Protection Forums, Human Rights Charter.'),
    (6,  'Prelim — Unit VI: Indian Economy',
     'Nature of Indian Economy, Five year plan models, Planning Commission and NITI Aayog. Sources of revenue, Reserve Bank of India, Fiscal Policy and Monetary Policy, Finance Commission, Resource sharing between Union and State Governments, Goods and Services Tax. Structure of Indian Economy and Employment Generation, Land Reforms and Agriculture, Application of Science and Technology in Agriculture, Industrial growth, Rural Welfare Oriented Programmes, Social Problems: Population, Education, Health, Employment, Poverty.'),
    (7,  'Prelim — Unit VII: Indian National Movement',
     'National Renaissance, Early uprising against British rule, Indian National Congress, Emergence of leaders: B.R.Ambedkar, Bhagat Singh, Bharathiar, V.O.Chidambaranar, Jawaharlal Nehru, Kamarajar, Mahatma Gandhi, Maulana Abul Kalam Azad, Thanthai Periyar, Rajaji, Subash Chandra Bose, Rabindranath Tagore and others. Different modes of Agitation: Growth of Satyagraha and Militant Movements. Communalism and Partition.'),
    (8,  'Prelim — Unit VIII: History, Culture & Socio-Political Movements in Tamil Nadu',
     'History of Tamil Society, related Archaeological discoveries, Tamil Literature from Sangam Age till contemporary times. Thirukkural: Significance as a Secular Literature, Relevance to Everyday Life, Impact on Humanity, Universal Values including Equality and Humanism, Relevance to Socio-Politico-Economic affairs, Philosophical content. Role of Tamil Nadu in freedom struggle, Early agitations against British Rule, Role of women in freedom struggle. Evolution of 19th and 20th Century Socio-Political Movements in Tamil Nadu: Justice Party, Growth of Rationalism, Self Respect Movement, Dravidian Movement, Contributions of Thanthai Periyar and Perarignar Anna.'),
    (9,  'Prelim — Unit IX: Development Administration in Tamil Nadu',
     'Human Development Indicators in Tamil Nadu and comparative assessment across the Country. Impact of Social Reform Movements in the Socio-Economic Development of Tamil Nadu. Political parties and Welfare schemes for various sections of people, Rationale behind Reservation Policy and access to Social Resources, Economic trends in Tamil Nadu, Role and impact of social welfare schemes in the Socio-Economic Development of Tamil Nadu. Social Justice and Social Harmony as the Cornerstones of Socio-Economic Development. Education and Health Systems in Tamil Nadu. Geography of Tamil Nadu and its impact on Economic growth. Achievements of Tamil Nadu in various fields. e-Governance in Tamil Nadu.'),
    (10, 'Prelim — Unit X: Aptitude & Mental Ability',
     'Simplification, Percentage, HCF, LCM. Ratio and Proportion. Simple interest, Compound interest, Area, Volume, Time and Work. Logical Reasoning, Puzzles, Dice, Visual Reasoning, Alphanumeric Reasoning, Number Series.'),
    (11, 'Main — Paper I: Compulsory Tamil Language (SSLC Standard)',
     'Translation from Tamil to English and English to Tamil. Precis Writing. Comprehension. Expansion from Brief Notes. Essay writing on Thirukkural topics. Official Letter Writing. Tamil Language Knowledge. This is a qualifying paper at SSLC standard; marks are not counted for ranking.'),
    (12, 'Main — Paper II, Unit I: Modern History of India and Indian Culture',
     'Advent of European invasion, Expansion and consolidation of British rule, Early uprisings, 1857 Revolt, Indian National Congress, Growth of militant movements, National leaders including Gandhi, Nehru, Tagore, Netaji, Ambedkar, Patel, Maulana Abul Kalam Azad. Era of Acts and Pacts, Second World War and final phase of freedom struggle, Communalism and Partition. Effect of British rule on socio-economic factors, National renaissance, Socio-religious reform movements. India since independence, Characteristics of Indian culture, Unity in diversity, India as a secular state, Role of Tamil Nadu in freedom struggle. Latest diary of events National and International, National symbols, Sports, Books, Authors, Awards.'),
    (13, 'Main — Paper II, Unit II: Social Issues in India and Tamil Nadu',
     'Population Explosion, Unemployment, Child Abuse and Child Labour, Poverty, Rural and Urban Sanitation, Illiteracy. Women Empowerment, Role of Government, Social injustice to Women, Domestic violence, Dowry, Sexual assault, Role of women''s organisations. Social changes in India, Urbanization and its impact, Violence, Terrorism and Communal violence, Regional Disparities, Problems of Minorities, Human Rights. Education, Social Development, Community Development Programmes, Employment Guarantee Schemes, Self Employment and Entrepreneurship, Role of NGOs, Government Policy on Health, Welfare Schemes for vulnerable sections.'),
    (14, 'Main — Paper II, Unit III: General Aptitude & Mental Ability (SSLC Standard)',
     'Data collection, compilation and presentation: Tables, Graphs, Diagrams. Percentage, HCF, LCM, Ratio and Proportion, Simple and Compound Interest, Area, Volume, Time and Work, Probability. Information Technology, Basic terms, Communications, Application of ICT, Decision making and problem solving, Basics of Computers and Computer terminology.'),
    (15, 'Main — Paper III, Unit I: Indian Polity and Emerging Political Trends',
     'Constitution of India: Historical background, Preamble, Fundamental Rights and Duties, DPSP, Schedules. Union Executive: President, Vice-President, Prime Minister, Council of Ministers, Attorney General. Union Legislature: Parliament, Lok Sabha, Rajya Sabha. Union Judiciary: Supreme Court, Judicial Review. State Executive, State Legislature, State Judiciary. Local Government: 73rd and 74th Constitutional Amendment Act, 1992. Federalism: Centre-State Relations. Civil Services, Official Language, Amendments, Art 370. Political Parties, Pressure Groups, NGOs. Anti-Corruption measures: CVC, Lok Adalats, RTI Act. India''s Foreign Policy, Nuclear Policy, Indian Diaspora.'),
    (16, 'Main — Paper III, Unit II: Role and Impact of Science and Technology',
     'Science and Technology, Role, Achievements and Developments, Applications in everyday life, Energy Conventional and Non-conventional, Oil exploration, Defence Research Organisations. Advancements in IT, Space, Computers, Robotics, Nano-Technology, Mobile Communication, Remote sensing. Health and hygiene, Human diseases, Prevention and remedies, Communicable and Non-communicable diseases, Genetic Engineering, Organ transplantation, Stem cell Technology, Medical Tourism. Achievements of Indians in Science and Technology, Latest inventions.'),
    (17, 'Main — Paper III, Unit III: Tamil Society — Its Culture and Heritage',
     'Tamil Society: Origin and expansion. Art and Culture: Literature, Music, Film, Drama, Architecture, Sculpture, Paintings and Folk Arts. Socio-economic history of Tamil Nadu from Sangam age till date. Growth of Rationalist and Dravidian movements in Tamil Nadu. Social and cultural life of contemporary Tamils: Caste, Religion, Women, Politics, Education, Economy, Trade and relationship with other countries. Tamil and other Disciplines: Mass Media, Computer.'),
    (18, 'Main — Paper IV, Unit I: Geography of India with Special Reference to Tamil Nadu',
     'Location, Physical features, Major Rivers, Weather and Climate, Monsoon, Rainfall, Natural resources: Soil, Water, Forest, Minerals, Wildlife, Agricultural pattern, Livestock, Fisheries, Industries. Social-Cultural geography, Population Growth, Density and Distribution, Racial, linguistic and major tribes. Oceanography: Bottom relief features of Indian Ocean, Arabian Sea and Bay of Bengal. Geospatial Technology: GIS and GNSS. Map: Geographical landmarks, India and its neighbours.'),
    (19, 'Main — Paper IV, Unit II: Environment, Biodiversity and Disaster Management',
     'Ecology: Structure and function of Ecosystem, Ecological succession, Biodiversity conservation, Types, Hot Spots in India. In situ and Ex situ conservation. Roles of CITES, IUCN and Convention on Biological Diversity. Environmental Pollution and Management: Air, Water, Soil, Thermal and Noise pollution. Solid and Hazardous waste management. Environmental Impact Assessment. Climate Change: Global Environmental Issues, Changes in monsoon pattern, Environmental consequences and mitigation measures, Clean and Green Energy. Environmental Laws, Policies and Treaties, Natural calamities and Disaster Management.'),
    (20, 'Main — Paper IV, Unit III: Indian Economy — Current Economic Trends',
     'Features of Indian Economy, Demographical profile, National Income, Capital formation, NEP, NITI AYOG. Agriculture: Land reforms, Green Revolution, Price Policy, PDS, Subsidy, Food Security, Agricultural Marketing, Crop Insurance, Rural credit, WTO and Agriculture. Industry: Growth, Policy, Public sector, Privatisation, Liberalization, PPP, SEZs, MSMEs, Make in India. Infrastructure: Transport, Energy, Power, Communication, R&D. Banking and Finance: Central Bank, Commercial Bank, Stock Market, Monetary Policy, RBI. Public Finance: Revenue, GST, Fiscal Policy, Finance Commission. Poverty, MGNREGA, Unemployment, Inflation, Gender issues. India''s Foreign Trade: BOP, FDI, Globalization, Global economic crisis. International Agencies: IMF, World Bank, BRICS, SAARC, ASEAN. Tamil Nadu Economy: GSDP, Agriculture, Industry, SHGs, Rural Women empowerment, Rural poverty, Environmental issues, Recent government welfare programmes.')
  ) AS t(ord, title, content_text)
  WHERE NOT EXISTS (
    SELECT 1 FROM chapters WHERE subject_id = v_subject_id AND title = t.title
  );

  -- Backfill Tamil titles (idempotent: only sets where NULL)
  UPDATE chapters c SET title_tamil = t.title_tamil
  FROM (VALUES
    ('Prelim — Unit I: General Science',                                        'முன்னோட்ட — அலகு I: பொது அறிவியல்'),
    ('Prelim — Unit II: Current Events',                                        'முன்னோட்ட — அலகு II: நடப்பு நிகழ்வுகள்'),
    ('Prelim — Unit III: Geography of India',                                   'முன்னோட்ட — அலகு III: இந்திய புவியியல்'),
    ('Prelim — Unit IV: History and Culture of India',                          'முன்னோட்ட — அலகு IV: இந்திய வரலாறும் கலாச்சாரமும்'),
    ('Prelim — Unit V: Indian Polity',                                          'முன்னோட்ட — அலகு V: இந்திய அரசியல்'),
    ('Prelim — Unit VI: Indian Economy',                                        'முன்னோட்ட — அலகு VI: இந்திய பொருளாதாரம்'),
    ('Prelim — Unit VII: Indian National Movement',                             'முன்னோட்ட — அலகு VII: இந்திய தேசிய இயக்கம்'),
    ('Prelim — Unit VIII: History, Culture & Socio-Political Movements in Tamil Nadu', 'முன்னோட்ட — அலகு VIII: தமிழ்நாட்டின் வரலாறு, கலாச்சாரம் & சமூக-அரசியல் இயக்கங்கள்'),
    ('Prelim — Unit IX: Development Administration in Tamil Nadu',              'முன்னோட்ட — அலகு IX: தமிழ்நாட்டில் வளர்ச்சி நிர்வாகம்'),
    ('Prelim — Unit X: Aptitude & Mental Ability',                             'முன்னோட்ட — அலகு X: திறன் மற்றும் மனவலிமை'),
    ('Main — Paper I: Compulsory Tamil Language (SSLC Standard)',               'முதன்மை — தாள் I: கட்டாய தமிழ் மொழி (SSLC தரம்)'),
    ('Main — Paper II, Unit I: Modern History of India and Indian Culture',     'முதன்மை — தாள் II, அலகு I: இந்தியாவின் நவீன வரலாறும் இந்திய கலாச்சாரமும்'),
    ('Main — Paper II, Unit II: Social Issues in India and Tamil Nadu',         'முதன்மை — தாள் II, அலகு II: இந்தியா மற்றும் தமிழ்நாட்டில் சமூக பிரச்சினைகள்'),
    ('Main — Paper II, Unit III: General Aptitude & Mental Ability (SSLC Standard)', 'முதன்மை — தாள் II, அலகு III: பொது திறன் மற்றும் மனவலிமை (SSLC தரம்)'),
    ('Main — Paper III, Unit I: Indian Polity and Emerging Political Trends',   'முதன்மை — தாள் III, அலகு I: இந்திய அரசியல் மற்றும் வளர்ந்து வரும் அரசியல் போக்குகள்'),
    ('Main — Paper III, Unit II: Role and Impact of Science and Technology',    'முதன்மை — தாள் III, அலகு II: அறிவியல் மற்றும் தொழில்நுட்பத்தின் பங்கும் தாக்கமும்'),
    ('Main — Paper III, Unit III: Tamil Society — Its Culture and Heritage',    'முதன்மை — தாள் III, அலகு III: தமிழ் சமூகம் — அதன் கலாச்சாரமும் பாரம்பரியமும்'),
    ('Main — Paper IV, Unit I: Geography of India with Special Reference to Tamil Nadu', 'முதன்மை — தாள் IV, அலகு I: தமிழ்நாட்டை மையமாகக் கொண்ட இந்திய புவியியல்'),
    ('Main — Paper IV, Unit II: Environment, Biodiversity and Disaster Management', 'முதன்மை — தாள் IV, அலகு II: சுற்றுச்சூழல், உயிரியல் பன்முகத்தன்மை மற்றும் பேரிடர் மேலாண்மை'),
    ('Main — Paper IV, Unit III: Indian Economy — Current Economic Trends',     'முதன்மை — தாள் IV, அலகு III: இந்திய பொருளாதாரம் — நடப்பு பொருளாதார போக்குகள்')
  ) AS t(en_title, title_tamil)
  WHERE c.subject_id = v_subject_id AND c.title = t.en_title AND c.title_tamil IS NULL;
END;
$$;
