import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Habit Model Tests', () {
    test('should create Habit from valid JSON', () {
      final json = {
        'id': '123',
        'name': 'Test Habit',
        'icon': 58848, // Icons.favorite
        'color': 4294198070, // Colors.red
        'history': [true, false, true, false, true],
        'archived': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final habit = Habit.fromJson(json);

      expect(habit.id, '123');
      expect(habit.name, 'Test Habit');
      expect(habit.history.length, 5);
      expect(habit.history[0], true);
    });

    test('should handle null history by creating default list', () {
      final json = {
        'id': '123',
        'name': 'Test Habit',
        'icon': 58848,
        'color': 4294198070,
        'history': null, // Null history
        'archived': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final habit = Habit.fromJson(json);

      expect(habit.history.length, 5);
      expect(habit.history.every((e) => e == false), true);
    });

    test('should pad short history list', () {
      final json = {
        'id': '123',
        'name': 'Test Habit',
        'icon': 58848,
        'color': 4294198070,
        'history': [true], // Only 1 day
        'archived': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final habit = Habit.fromJson(json);

      expect(habit.history.length, 5);
      expect(habit.history[0], true);
      expect(habit.history[1], false); // Padded
    });

    test('should handle Firestore Timestamp', () {
      final now = DateTime.now();
      final json = {
        'id': '123',
        'name': 'Test Habit',
        'icon': 58848,
        'color': 4294198070,
        'history': [],
        'archived': false,
        'createdAt': Timestamp.fromDate(now), // Firestore type
      };

      final habit = Habit.fromJson(json);

      expect(habit.createdAt.year, now.year);
      expect(habit.createdAt.month, now.month);
    });

    test('should handle missing or null fields with defaults', () {
      final json = {
        // Missing id, name, icon, color, createdAt
        'history': [],
        'archived': null,
      };

      final habit = Habit.fromJson(json);

      expect(habit.id, 'unknown');
      expect(habit.name, 'Unnamed Habit');
      expect(habit.icon, Icons.error);
      expect(habit.color, Colors.grey);
      expect(habit.history.length, 5);
      expect(habit.createdAt, isNotNull);
    });
  });
}
