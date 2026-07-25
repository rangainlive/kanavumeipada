import 'minigame_contract.dart';
import 'reflex/bang_bang_game.dart';

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
  'bang_bang_2': (challengeId, onFinish) =>
      BangBangGame(challengeId: challengeId, onFinish: onFinish),
};
