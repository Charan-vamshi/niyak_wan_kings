import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'arrow_model.dart';

class GameState extends ChangeNotifier {
  int _currentLevel = 1;
  int _lives = 3;
  int _hintsLeft = 2;
  int _bestStreak = 0;
  int _currentStreak = 0;
  bool _isDarkTheme = true;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _showGuideLines = false;

  int get currentLevel => _currentLevel;
  int get lives => _lives;
  int get hintsLeft => _hintsLeft;
  int get bestStreak => _bestStreak;
  int get currentStreak => _currentStreak;
  bool get isDarkTheme => _isDarkTheme;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get showGuideLines => _showGuideLines;
  bool get isGameOver => _lives <= 0;
  DifficultyType get currentDifficulty => getDifficulty(_currentLevel);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLevel = prefs.getInt('currentLevel') ?? 1;
    _bestStreak = prefs.getInt('bestStreak') ?? 0;
    _isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _hapticsEnabled = prefs.getBool('hapticsEnabled') ?? true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('currentLevel', _currentLevel);
    prefs.setInt('bestStreak', _bestStreak);
    prefs.setBool('isDarkTheme', _isDarkTheme);
    prefs.setBool('soundEnabled', _soundEnabled);
    prefs.setBool('hapticsEnabled', _hapticsEnabled);
  }

  void toggleTheme() { _isDarkTheme = !_isDarkTheme; _save(); notifyListeners(); }
  void toggleSound() { _soundEnabled = !_soundEnabled; _save(); notifyListeners(); }
  void toggleHaptics() { _hapticsEnabled = !_hapticsEnabled; _save(); notifyListeners(); }
  void toggleGuideLines() { _showGuideLines = !_showGuideLines; notifyListeners(); }

  void resetLevelState() {
    _lives = 3;
    _hintsLeft = 2;
    _currentStreak = 0;
    notifyListeners();
  }

  void onCorrectTap() {
    _currentStreak++;
    if (_currentStreak > _bestStreak) { _bestStreak = _currentStreak; _save(); }
    notifyListeners();
  }

  void onWrongTap() {
    _lives--;
    _currentStreak = 0;
    notifyListeners();
  }

  void useHint() {
    if (_hintsLeft > 0) { _hintsLeft--; notifyListeners(); }
  }

  void completeLevel() {
    _currentLevel++;
    _save();
    notifyListeners();
  }

  void restartLevel() {
    _lives = 3;
    _hintsLeft = 2;
    _currentStreak = 0;
    notifyListeners();
  }
}