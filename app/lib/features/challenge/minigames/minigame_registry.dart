import 'minigame_contract.dart';
import 'reflex/bang_bang_game.dart';
import 'arcade/mosquito_game.dart';
import 'arcade/apple_shootout_game.dart';
import 'arcade/knife_throw_game.dart';
import 'arcade/frog_leap_game.dart';
import 'arcade/autobahn_game.dart';
import 'arcade/road_safety_dodge_game.dart';
import 'puzzle/counting_stars_game.dart';
import 'puzzle/puzzle_good_game.dart';
import 'puzzle/deal_or_no_deal_game.dart';
import 'puzzle/cave_puzzle_game.dart';

class MiniGameMeta {
  final String labelEn;
  final String labelTa;
  final String emoji;
  const MiniGameMeta({required this.labelEn, required this.labelTa, required this.emoji});

  String label(bool isTamil) => isTamil ? labelTa : labelEn;
}

/// Single source of truth for minigame display strings — the backend only
/// ever sends the raw `minigame_key`. Keys must match backend/src/routes/challenge.routes.ts.
const Map<String, MiniGameMeta> kMiniGameMeta = {
  'bang_bang_2': MiniGameMeta(labelEn: 'Quickdraw', labelTa: 'விரைவு துப்பாக்கி', emoji: '🔫'),
  'mosquito': MiniGameMeta(labelEn: 'Mosquito Swat', labelTa: 'கொசு அடி', emoji: '🦟'),
  'counting_stars': MiniGameMeta(labelEn: 'Counting Stars', labelTa: 'நட்சத்திர எண்ணிக்கை', emoji: '⭐'),
  'puzzle_good': MiniGameMeta(labelEn: 'How Smart Are You', labelTa: 'நீங்கள் எவ்வளவு புத்திசாலி', emoji: '🧠'),
  'autobahn': MiniGameMeta(labelEn: 'Autobahn', labelTa: 'ஆட்டோபான்', emoji: '🚗'),
  'apple_shootout': MiniGameMeta(labelEn: 'Apple Shootout', labelTa: 'ஆப்பிள் சுடுதல்', emoji: '🏹'),
  'frog_leap': MiniGameMeta(labelEn: 'Frog Leap', labelTa: 'தவளை தாவல்', emoji: '🐸'),
  'knife_throw': MiniGameMeta(labelEn: 'Knife Throw', labelTa: 'கத்தி எறிதல்', emoji: '🔪'),
  'road_safety_dodge': MiniGameMeta(labelEn: 'Road Safety Dodge', labelTa: 'சாலை பாதுகாப்பு', emoji: '🚧'),
  'deal_or_no_deal': MiniGameMeta(labelEn: 'Deal or No Deal', labelTa: 'ஒப்பந்தமா இல்லையா', emoji: '💼'),
  'cave_puzzle': MiniGameMeta(labelEn: 'Cave Escape', labelTa: 'குகை தப்பித்தல்', emoji: '🕳️'),
};

/// Maps a minigame_key to its game widget. Keys not yet built are simply
/// absent here — MiniGameHostScreen renders a "Coming soon" placeholder
/// for those instead of crashing.
final Map<String, MiniGameBuilder> kMiniGameRegistry = {
  'bang_bang_2': (challengeId, config, onFinish) =>
      BangBangGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'mosquito': (challengeId, config, onFinish) =>
      MosquitoGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'apple_shootout': (challengeId, config, onFinish) =>
      AppleShootoutGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'knife_throw': (challengeId, config, onFinish) =>
      KnifeThrowGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'frog_leap': (challengeId, config, onFinish) =>
      FrogLeapGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'autobahn': (challengeId, config, onFinish) =>
      AutobahnGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'road_safety_dodge': (challengeId, config, onFinish) =>
      RoadSafetyDodgeGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'counting_stars': (challengeId, config, onFinish) =>
      CountingStarsGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'puzzle_good': (challengeId, config, onFinish) =>
      PuzzleGoodGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'deal_or_no_deal': (challengeId, config, onFinish) =>
      DealOrNoDealGame(challengeId: challengeId, config: config, onFinish: onFinish),
  'cave_puzzle': (challengeId, config, onFinish) =>
      CavePuzzleGame(challengeId: challengeId, config: config, onFinish: onFinish),
};
