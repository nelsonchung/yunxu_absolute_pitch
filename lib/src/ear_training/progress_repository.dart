import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'note_library.dart';

class ProgressRepository {
  static const _storageKey = 'yunxu_ear_training_progress_v1';
  static const _introSeenKey = 'yunxu_intro_seen_v1';

  Future<ProgressSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return const ProgressSnapshot.empty();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return ProgressSnapshot.fromJson(decoded);
    } catch (_) {
      return const ProgressSnapshot.empty();
    }
  }

  Future<void> save(ProgressSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(snapshot.toJson()));
  }

  Future<bool> hasSeenIntro() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_introSeenKey) ?? false;
  }

  Future<void> markIntroSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_introSeenKey, true);
  }
}
