import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> updateWinCount(Player winner) async {
    final uid = _userId;
    if (uid == null) return;

    final userDoc = _firestore.collection('users').doc(uid);
    
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        
        if (!snapshot.exists) {
          transaction.set(userDoc, {
            'winsX': winner == Player.X ? 1 : 0,
            'winsO': winner == Player.O ? 1 : 0,
            'totalGames': 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          final data = snapshot.data()!;
          final int currentWinsX = data['winsX'] ?? 0;
          final int currentWinsO = data['winsO'] ?? 0;
          final int currentTotal = data['totalGames'] ?? 0;

          transaction.update(userDoc, {
            'winsX': winner == Player.X ? currentWinsX + 1 : currentWinsX,
            'winsO': winner == Player.O ? currentWinsO + 1 : currentWinsO,
            'totalGames': currentTotal + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Potentially silent error or log to analytics
    }
  }

  Future<void> mergeAnonymousStats(String oldUid) async {
    final newUid = _userId;
    if (newUid == null || oldUid == newUid) return;

    final oldUserDoc = _firestore.collection('users').doc(oldUid);
    final newUserDoc = _firestore.collection('users').doc(newUid);

    await _firestore.runTransaction((transaction) async {
      final oldSnapshot = await transaction.get(oldUserDoc);
      if (!oldSnapshot.exists) return;

      final oldData = oldSnapshot.data()!;
      final newSnapshot = await transaction.get(newUserDoc);

      if (!newSnapshot.exists) {
        transaction.set(newUserDoc, {
          ...oldData,
          'mergedFrom': oldUid,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        final newData = newSnapshot.data()!;
        transaction.update(newUserDoc, {
          'winsX': (newData['winsX'] ?? 0) + (oldData['winsX'] ?? 0),
          'winsO': (newData['winsO'] ?? 0) + (oldData['winsO'] ?? 0),
          'totalGames': (newData['totalGames'] ?? 0) + (oldData['totalGames'] ?? 0),
          'mergedFrom': oldUid,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      transaction.delete(oldUserDoc);
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get userStats {
    final uid = _userId;
    if (uid == null) return const Stream.empty();
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
