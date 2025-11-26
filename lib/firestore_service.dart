import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  FirestoreService(this.userId);

  // Collection Reference
  CollectionReference get _habitsCollection =>
      _db.collection('users').doc(userId).collection('habits');

  // Stream of Habits
  Stream<List<Map<String, dynamic>>> getHabitsStream() {
    return _habitsCollection.orderBy('createdAt').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is part of the map
        return data;
      }).toList();
    });
  }

  // Add Habit
  Future<void> addHabit(String name, int iconCode, int colorValue) async {
    await _habitsCollection.add({
      'name': name,
      'icon': iconCode,
      'color': colorValue,
      'history': [false, false, false, false, false], // Initial 5 days
      'archived': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Habit History
  Future<void> updateHabitHistory(String habitId, List<bool> history) async {
    await _habitsCollection.doc(habitId).update({
      'history': history,
    });
  }

  // Toggle Archive
  Future<void> toggleArchive(String habitId, bool currentStatus) async {
    await _habitsCollection.doc(habitId).update({
      'archived': !currentStatus,
    });
  }

  // Update Habit Details
  Future<void> updateHabit(String habitId, String name, int iconCode, int colorValue) async {
    await _habitsCollection.doc(habitId).update({
      'name': name,
      'icon': iconCode,
      'color': colorValue,
    });
  }
}
