import 'package:flutter/material.dart';

class AvatarService {
  static const avatars = [
    {'id': 'avatar_01', 'emoji': '🧑‍🎨', 'color': 0xFF1E88E5, 'name': 'Artist'},
    {'id': 'avatar_02', 'emoji': '🧑‍🚀', 'color': 0xFFE91E63, 'name': 'Astronaut'},
    {'id': 'avatar_03', 'emoji': '🧑‍🍳', 'color': 0xFF43A047, 'name': 'Chef'},
    {'id': 'avatar_04', 'emoji': '🧑‍💻', 'color': 0xFF7B1FA2, 'name': 'Coder'},
    {'id': 'avatar_05', 'emoji': '🧑‍🎤', 'color': 0xFFFF6F00, 'name': 'Singer'},
    {'id': 'avatar_06', 'emoji': '🧙', 'color': 0xFF00838F, 'name': 'Wizard'},
    {'id': 'avatar_07', 'emoji': '🦊', 'color': 0xFFEF6C00, 'name': 'Fox'},
    {'id': 'avatar_08', 'emoji': '🐼', 'color': 0xFF37474F, 'name': 'Panda'},
    {'id': 'avatar_09', 'emoji': '🦁', 'color': 0xFFF57F17, 'name': 'Lion'},
    {'id': 'avatar_10', 'emoji': '🐯', 'color': 0xFFBF360C, 'name': 'Tiger'},
    {'id': 'avatar_11', 'emoji': '🦄', 'color': 0xFFAD1457, 'name': 'Unicorn'},
    {'id': 'avatar_12', 'emoji': '🐨', 'color': 0xFF6D4C41, 'name': 'Koala'},
    {'id': 'avatar_13', 'emoji': '🐸', 'color': 0xFF33691E, 'name': 'Frog'},
    {'id': 'avatar_14', 'emoji': '🐙', 'color': 0xFF4A148C, 'name': 'Octo'},
    {'id': 'avatar_15', 'emoji': '🦝', 'color': 0xFF4E342E, 'name': 'Raccoon'},
    {'id': 'avatar_16', 'emoji': '👩‍🎤', 'color': 0xFFC2185B, 'name': 'Star'},
    {'id': 'avatar_17', 'emoji': '🧑‍🏫', 'color': 0xFF1565C0, 'name': 'Teacher'},
    {'id': 'avatar_18', 'emoji': '🧑‍🌾', 'color': 0xFF2E7D32, 'name': 'Farmer'},
    {'id': 'avatar_19', 'emoji': '🦸', 'color': 0xFFD32F2F, 'name': 'Hero'},
    {'id': 'avatar_20', 'emoji': '🥷', 'color': 0xFF263238, 'name': 'Ninja'},
  ];

  static Map<String, dynamic>? byId(String id) {
    for (final a in avatars) {
      if (a['id'] == id) return a;
    }
    return null;
  }

  static Color colorFor(String id) {
    final a = byId(id);
    if (a == null) return const Color(0xFF1E88E5);
    return Color(a['color'] as int);
  }

  static String emojiFor(String id) {
    final a = byId(id);
    return a?['emoji'] as String? ?? '🙂';
  }
}
