-- TNPSC Group 1 seed
-- Safe to run multiple times (ON CONFLICT DO NOTHING / idempotent checks)

DO $$
DECLARE
  v_subject_id UUID;
BEGIN
  -- Insert subject
  INSERT INTO subjects (name, icon, exam_category)
  VALUES ('TNPSC Group 1', '📋', 'TNPSC')
  ON CONFLICT (name) DO NOTHING;

  SELECT id INTO v_subject_id FROM subjects WHERE name = 'TNPSC Group 1';

  -- Insert Preliminary Exam chapters (Units I–X) only if they don't already exist
  INSERT INTO chapters (subject_id, title, order_index, content_text, is_approved)
  SELECT v_subject_id, t.title, t.order_index, t.content_text, true
  FROM (VALUES
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
     'Simplification, Percentage, HCF, LCM. Ratio and Proportion. Simple interest, Compound interest, Area, Volume, Time and Work. Logical Reasoning, Puzzles, Dice, Visual Reasoning, Alphanumeric Reasoning, Number Series.')
  ) AS t(order_index, title, content_text)
  WHERE NOT EXISTS (
    SELECT 1 FROM chapters WHERE subject_id = v_subject_id AND title = t.title
  );

  -- Main Exam chapters
  INSERT INTO chapters (subject_id, title, order_index, content_text, is_approved)
  SELECT v_subject_id, t.title, t.order_index, t.content_text, true
  FROM (VALUES
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
    (16, 'Main — Paper III, Unit II: Role and Impact of Science and Technology in Development of India',
     'Science and Technology, Role, Achievements and Developments, Applications in everyday life, Energy Conventional and Non-conventional, Oil exploration, Defence Research Organisations. Advancements in IT, Space, Computers, Robotics, Nano-Technology, Mobile Communication, Remote sensing. Health and hygiene, Human diseases, Prevention and remedies, Communicable and Non-communicable diseases, Genetic Engineering, Organ transplantation, Stem cell Technology, Medical Tourism. Achievements of Indians in Science and Technology, Latest inventions.'),
    (17, 'Main — Paper III, Unit III: Tamil Society — Its Culture and Heritage',
     'Tamil Society: Origin and expansion. Art and Culture: Literature, Music, Film, Drama, Architecture, Sculpture, Paintings and Folk Arts. Socio-economic history of Tamil Nadu from Sangam age till date. Growth of Rationalist and Dravidian movements in Tamil Nadu. Social and cultural life of contemporary Tamils: Caste, Religion, Women, Politics, Education, Economy, Trade and relationship with other countries. Tamil and other Disciplines: Mass Media, Computer.'),
    (18, 'Main — Paper IV, Unit I: Geography of India with Special Reference to Tamil Nadu',
     'Location, Physical features, Major Rivers, Weather and Climate, Monsoon, Rainfall, Natural resources: Soil, Water, Forest, Minerals, Wildlife, Agricultural pattern, Livestock, Fisheries, Industries. Social-Cultural geography, Population Growth, Density and Distribution, Racial, linguistic and major tribes. Oceanography: Bottom relief features of Indian Ocean, Arabian Sea and Bay of Bengal. Geospatial Technology: GIS and GNSS. Map: Geographical landmarks, India and its neighbours.'),
    (19, 'Main — Paper IV, Unit II: Environment, Biodiversity and Disaster Management',
     'Ecology: Structure and function of Ecosystem, Ecological succession, Biodiversity conservation, Types, Hot Spots in India. In situ and Ex situ conservation. Roles of CITES, IUCN and Convention on Biological Diversity. Environmental Pollution and Management: Air, Water, Soil, Thermal and Noise pollution. Solid and Hazardous waste management. Environmental Impact Assessment. Climate Change: Global Environmental Issues, Changes in monsoon pattern, Environmental consequences and mitigation measures, Clean and Green Energy. Environmental Laws, Policies and Treaties, Natural calamities and Disaster Management.'),
    (20, 'Main — Paper IV, Unit III: Indian Economy — Current Economic Trends',
     'Features of Indian Economy, Demographical profile, National Income, Capital formation, NEP, NITI AYOG. Agriculture: Land reforms, Green Revolution, Price Policy, PDS, Subsidy, Food Security, Agricultural Marketing, Crop Insurance, Rural credit, WTO and Agriculture. Industry: Growth, Policy, Public sector, Privatisation, Liberalization, PPP, SEZs, MSMEs, Make in India. Infrastructure: Transport, Energy, Power, Communication, R&D. Banking and Finance: Central Bank, Commercial Bank, Stock Market, Monetary Policy, RBI. Public Finance: Revenue, GST, Fiscal Policy, Finance Commission. Poverty, MGNREGA, Unemployment, Inflation, Gender issues. India''s Foreign Trade: BOP, FDI, Globalization, Global economic crisis. International Agencies: IMF, World Bank, BRICS, SAARC, ASEAN. Tamil Nadu Economy: GSDP, Agriculture, Industry, SHGs, Rural Women empowerment, Rural poverty, Environmental issues.')
  ) AS t(order_index, title, content_text)
  WHERE NOT EXISTS (
    SELECT 1 FROM chapters WHERE subject_id = v_subject_id AND title = t.title
  );

  RAISE NOTICE 'TNPSC Group 1 seed completed. Subject ID: %', v_subject_id;
END;
$$;
