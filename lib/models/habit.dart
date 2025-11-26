import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  String id;
  String name;
  IconData icon;
  Color color;
  List<bool> history;
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

  static List<bool> _parseHistory(dynamic historyJson) {
    if (historyJson == null || historyJson is! List) {
      return List.filled(5, false);
    }
    final list = historyJson.map((e) => e as bool).toList();
    if (list.length < 5) {
      return [...list, ...List.filled(5 - list.length, false)];
    }
    return list;
  }
}
