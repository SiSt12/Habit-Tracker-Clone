import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  String id;
  String name;
  IconData icon;
  Color color;
  Map<String, bool> history;
  bool archived;
  DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.history,
    this.archived = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'history': history,
      'archived': archived,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] ?? 'unknown',
      name: json['name'] ?? 'Unnamed Habit',
      icon: json['icon'] != null 
          ? IconData(json['icon'], fontFamily: 'MaterialIcons') 
          : Icons.error,
      color: json['color'] != null 
          ? Color(json['color']) 
          : Colors.grey,
      history: _parseHistory(json['history']),
      archived: json['archived'] ?? false,
      createdAt: json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate() 
          : (json['createdAt'] != null 
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  static Map<String, bool> _parseHistory(dynamic historyJson) {
    if (historyJson == null) {
      return {};
    }
    if (historyJson is Map) {
      return Map<String, bool>.from(historyJson);
    }
    // Backward compatibility for List<bool>
    // We can't easily map old list to dates without knowing when they were checked.
    // We will just discard them or map them to "unknown" dates if critical, 
    // but for now, returning empty map is safer than guessing dates.
    // Alternatively, we could map the last 5 days to these values if we assume they are [today, yesterday, ...].
    // Let's assume the list was [day-4, day-3, day-2, yesterday, today] as per previous UI logic?
    // Actually previous UI logic was just 5 boxes. Let's start fresh to avoid confusion.
    return {}; 
  }
}
