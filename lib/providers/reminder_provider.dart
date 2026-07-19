import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/medication_reminder.dart';

/// Firestore-backed medication reminders, scoped per signed-in
/// customer (each person only ever sees and edits their own pill
/// schedule — see firestore.rules).
class ReminderProvider extends ChangeNotifier {
  ReminderProvider() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<MedicationReminder> _reminders = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<MedicationReminder> get reminders => List.unmodifiable(_reminders);

  List<MedicationReminder> remindersFor(DateTime date) {
    // All active reminders apply every day until removed, so "for a
    // date" is just the full list — kept as a method so the Reminders
    // screen can filter by day without knowing that detail.
    return reminders;
  }

  void _onAuthChanged(User? user) {
    _sub?.cancel();
    if (user == null) {
      _reminders = [];
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _sub = _db
        .collection('medication_reminders')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {});
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _reminders = snapshot.docs
        .map((d) => MedicationReminder.fromMap(d.id, d.data()))
        .toList()
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addReminder({
    required String drugName,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Cannot add a reminder while signed out.');
    final ref = _db.collection('medication_reminders').doc();
    final reminder = MedicationReminder(
      id: ref.id,
      ownerId: uid,
      drugName: drugName,
      dosage: dosage,
      hour: hour,
      minute: minute,
    );
    await ref.set(reminder.toMap());
  }

  Future<void> toggleTaken(MedicationReminder reminder, DateTime date) async {
    final key = MedicationReminder.keyFor(date);
    final isTaken = reminder.isTakenOn(date);
    await _db.collection('medication_reminders').doc(reminder.id).update({
      'takenOnDates': isTaken
          ? FieldValue.arrayRemove([key])
          : FieldValue.arrayUnion([key]),
    });
  }

  Future<void> deleteReminder(String id) async {
    await _db.collection('medication_reminders').doc(id).delete();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}