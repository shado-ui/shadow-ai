import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _historyKey = 'chat_history';
  static const String _favoritesKey = 'favorites';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> saveHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final data = messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_historyKey, data);
  }

  Future<List<ChatMessage>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_historyKey) ?? [];
    return data.map((s) => ChatMessage.fromJson(jsonDecode(s))).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> saveFavorite(ChatMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_favoritesKey) ?? [];
    existing.add(jsonEncode(message.toJson()));
    await prefs.setStringList(_favoritesKey, existing);
  }

  Future<List<ChatMessage>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_favoritesKey) ?? [];
    return data.map((s) => ChatMessage.fromJson(jsonDecode(s))).toList();
  }
}

