import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/player_stats.dart';
import '../models/game_enums.dart';
import '../logic/match_referee.dart'; // Added Import for MatchOutcome
import 'persistence_service.dart';

class StatsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PersistenceService _persistence = PersistenceService();

  PlayerStats _stats = const PlayerStats();
  PlayerStats get stats => _stats;

  String? get _userId => _auth.currentUser?.uid;

  StatsService() {
    _loadLocalStats();
    // Listen for auth changes to load Firestore stats if user logs in
    _auth.authStateChanges().listen(
      (user) {
        if (user != null && !user.isAnonymous) {
          _syncWithFirestore(user.uid);
        } else {
          // Reset stats to clean zeroed state for guest/anonymous or logged out users
          _stats = const PlayerStats();
          notifyListeners();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print("Error in authStateChanges stream: $error");
        }
      },
    );
  }

  Future<void> _loadLocalStats() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      _stats = const PlayerStats();
      notifyListeners();
      return;
    }
    try {
      final localData = await _persistence.loadAll();
      if (localData.containsKey('player_stats')) {
        final statsJson = Map<String, dynamic>.from(localData['player_stats']);
        _stats = PlayerStats.fromJson(statsJson);
      } else {
        // Fallback for existing scores if they exist
        final scoreX = localData['scoreX'] ?? 0;
        final scoreO = localData['scoreO'] ?? 0;
        if (scoreX > 0 || scoreO > 0) {
          _stats = PlayerStats(winsLocalPvp: scoreX, lossesLocalPvp: scoreO);
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error loading local stats: $e");
      }
    }
  }

  Future<void> _syncWithFirestore(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('player_stats')) {
          final statsJson = Map<String, dynamic>.from(data['player_stats']);
          final firestoreStats = PlayerStats.fromJson(statsJson);
          
          // Merge stats: Keep the one with more XP progress
          if (firestoreStats.totalXp > _stats.totalXp) {
            _stats = firestoreStats;
            await _persistence.save({'player_stats': _stats.toJson()});
            notifyListeners();
          } else if (_stats.totalXp > firestoreStats.totalXp) {
            // Push local stats up
            await _firestore.collection('users').doc(uid).update({
              'player_stats': _stats.toJson(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error syncing with Firestore: $e");
      }
    }
  }

  Future<void> recordMatchOutcome({
    required GameMode gameMode,
    required AiDifficulty aiDifficulty,
    required MatchOutcome outcome,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      // Keep game statistics, scores, etc. empty/locked for guest/unregistered users
      return;
    }
    int xpEarned = 0;
    PlayerStats newStats = _stats;

    int nextStreak = _stats.currentStreak;
    int nextMaxStreak = _stats.maxStreak;

    if (outcome == MatchOutcome.winX) {
      nextStreak = _stats.currentStreak + 1;
      if (nextStreak > nextMaxStreak) {
        nextMaxStreak = nextStreak;
      }
    } else if (outcome == MatchOutcome.winO) {
      nextStreak = 0;
    }

    if (gameMode == GameMode.playerVsAi) {
      // Human is Player X, AI is Player O
      if (outcome == MatchOutcome.winX) {
        // Win vs AI
        if (aiDifficulty == AiDifficulty.easy) {
          xpEarned = 100;
          newStats = _stats.copyWith(
            winsVsAiEasy: _stats.winsVsAiEasy + 1,
            totalXp: _stats.totalXp + xpEarned,
            currentStreak: nextStreak,
            maxStreak: nextMaxStreak,
          );
        } else if (aiDifficulty == AiDifficulty.medium) {
          xpEarned = 150;
          newStats = _stats.copyWith(
            winsVsAiMedium: _stats.winsVsAiMedium + 1,
            totalXp: _stats.totalXp + xpEarned,
            currentStreak: nextStreak,
            maxStreak: nextMaxStreak,
          );
        } else if (aiDifficulty == AiDifficulty.hard) {
          xpEarned = 200;
          newStats = _stats.copyWith(
            winsVsAiHard: _stats.winsVsAiHard + 1,
            totalXp: _stats.totalXp + xpEarned,
            currentStreak: nextStreak,
            maxStreak: nextMaxStreak,
          );
        }
      } else if (outcome == MatchOutcome.winO) {
        // Loss vs AI
        if (aiDifficulty == AiDifficulty.easy) {
          xpEarned = 20;
          newStats = _stats.copyWith(
            lossesVsAiEasy: _stats.lossesVsAiEasy + 1,
            totalXp: _stats.totalXp + xpEarned,
            currentStreak: nextStreak,
            maxStreak: nextMaxStreak,
          );
        } else if (aiDifficulty == AiDifficulty.medium) {
          xpEarned = 30;
          newStats = _stats.copyWith(
            lossesVsAiMedium: _stats.lossesVsAiMedium + 1,
            totalXp: _stats.totalXp + xpEarned,
            currentStreak: nextStreak,
            maxStreak: nextMaxStreak,
          );
        } else if (aiDifficulty == AiDifficulty.hard) {
          xpEarned = 40;
          newStats = _stats.copyWith(
            lossesVsAiHard: _stats.lossesVsAiHard + 1,
            totalXp: _stats.totalXp + xpEarned,
            currentStreak: nextStreak,
            maxStreak: nextMaxStreak,
          );
        }
      } else if (outcome == MatchOutcome.draw) {
        // Draw vs AI
        if (aiDifficulty == AiDifficulty.easy) {
          xpEarned = 40;
          newStats = _stats.copyWith(
            drawsVsAiEasy: _stats.drawsVsAiEasy + 1,
            totalXp: _stats.totalXp + xpEarned,
            currentStreak: nextStreak,
            maxStreak: nextMaxStreak,
          );
        } else if (aiDifficulty == AiDifficulty.medium) {
          xpEarned = 60;
          newStats = _stats.copyWith(
            drawsVsAiMedium: _stats.drawsVsAiMedium + 1,
            totalXp: _stats.totalXp + xpEarned,
            currentStreak: nextStreak,
            maxStreak: nextMaxStreak,
          );
        } else if (aiDifficulty == AiDifficulty.hard) {
          xpEarned = 80;
          newStats = _stats.copyWith(
            drawsVsAiHard: _stats.drawsVsAiHard + 1,
            totalXp: _stats.totalXp + xpEarned,
            currentStreak: nextStreak,
            maxStreak: nextMaxStreak,
          );
        }
      }
    } else {
      // Local PvP
      if (outcome == MatchOutcome.winX) {
        xpEarned = 50;
        newStats = _stats.copyWith(
          winsLocalPvp: _stats.winsLocalPvp + 1,
          totalXp: _stats.totalXp + xpEarned,
          currentStreak: nextStreak,
          maxStreak: nextMaxStreak,
        );
      } else if (outcome == MatchOutcome.winO) {
        xpEarned = 50;
        newStats = _stats.copyWith(
          lossesLocalPvp: _stats.lossesLocalPvp + 1, // X loses, O wins locally
          totalXp: _stats.totalXp + xpEarned,
          currentStreak: nextStreak,
          maxStreak: nextMaxStreak,
        );
      } else if (outcome == MatchOutcome.draw) {
        xpEarned = 25;
        newStats = _stats.copyWith(
          drawsLocalPvp: _stats.drawsLocalPvp + 1,
          totalXp: _stats.totalXp + xpEarned,
          currentStreak: nextStreak,
          maxStreak: nextMaxStreak,
        );
      }
    }

    _stats = newStats;
    notifyListeners();

    // Save locally
    await _persistence.save({'player_stats': _stats.toJson()});

    // Save to Firestore if user is authenticated
    final uid = _userId;
    if (uid != null) {
      try {
        final userDoc = _firestore.collection('users').doc(uid);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(userDoc);
          if (!snapshot.exists) {
            transaction.set(userDoc, {
              'player_stats': _stats.toJson(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.update(userDoc, {
              'player_stats': _stats.toJson(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print("Error saving stats to Firestore: $e");
        }
      }
    }
  }

  Future<void> mergeAnonymousStats(String oldUid) async {
    final newUid = _userId;
    if (newUid == null || oldUid == newUid) return;

    final oldUserDoc = _firestore.collection('users').doc(oldUid);
    final newUserDoc = _firestore.collection('users').doc(newUid);

    try {
      await _firestore.runTransaction((transaction) async {
        final oldSnapshot = await transaction.get(oldUserDoc);
        if (!oldSnapshot.exists) return;

        final oldData = oldSnapshot.data()!;
        final newSnapshot = await transaction.get(newUserDoc);

        PlayerStats oldStats = const PlayerStats();
        if (oldData.containsKey('player_stats')) {
          oldStats = PlayerStats.fromJson(Map<String, dynamic>.from(oldData['player_stats']));
        }

        if (!newSnapshot.exists) {
          transaction.set(newUserDoc, {
            ...oldData,
            'mergedFrom': oldUid,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          final newData = newSnapshot.data()!;
          PlayerStats newStats = _stats;
          if (newData.containsKey('player_stats')) {
            newStats = PlayerStats.fromJson(Map<String, dynamic>.from(newData['player_stats']));
          }

          final mergedStats = PlayerStats(
            totalXp: newStats.totalXp + oldStats.totalXp,
            winsVsAiEasy: newStats.winsVsAiEasy + oldStats.winsVsAiEasy,
            lossesVsAiEasy: newStats.lossesVsAiEasy + oldStats.lossesVsAiEasy,
            drawsVsAiEasy: newStats.drawsVsAiEasy + oldStats.drawsVsAiEasy,
            winsVsAiMedium: newStats.winsVsAiMedium + oldStats.winsVsAiMedium,
            lossesVsAiMedium: newStats.lossesVsAiMedium + oldStats.lossesVsAiMedium,
            drawsVsAiMedium: newStats.drawsVsAiMedium + oldStats.drawsVsAiMedium,
            winsVsAiHard: newStats.winsVsAiHard + oldStats.winsVsAiHard,
            lossesVsAiHard: newStats.lossesVsAiHard + oldStats.lossesVsAiHard,
            drawsVsAiHard: newStats.drawsVsAiHard + oldStats.drawsVsAiHard,
            winsLocalPvp: newStats.winsLocalPvp + oldStats.winsLocalPvp,
            lossesLocalPvp: newStats.lossesLocalPvp + oldStats.lossesLocalPvp,
            drawsLocalPvp: newStats.drawsLocalPvp + oldStats.drawsLocalPvp,
          );

          _stats = mergedStats;
          notifyListeners();
          await _persistence.save({'player_stats': _stats.toJson()});

          transaction.update(newUserDoc, {
            'player_stats': _stats.toJson(),
            'mergedFrom': oldUid,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
        transaction.delete(oldUserDoc);
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error merging anonymous stats: $e");
      }
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get userStats {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    // Avoid live snapshots on Windows due to Native C++ SDK background threading bugs
    if (!kIsWeb && Platform.isWindows) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .handleError((error) {
      if (kDebugMode) {
        print("Error listening to userStats stream: $error");
      }
    });
  }

  Future<void> updateCustomStats(PlayerStats updatedStats) async {
    _stats = updatedStats;
    notifyListeners();
    
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      // Guests don't persist stats
      return;
    }
    
    // Save locally
    await _persistence.save({'player_stats': _stats.toJson()});
    
    // Save to Firestore
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'player_stats': _stats.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print("Error saving custom stats to Firestore: $e");
      }
    }
  }
}

