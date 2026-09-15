import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:ultimate_tictactoe/features/auth/services/auth_service.dart';
import 'package:ultimate_tictactoe/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    } catch (e) {
      // Ignored if already configured
    }
  });

  tearDown(() async {
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('Guest to Google merge logic - existing account (credential-already-in-use)', (tester) async {
    final authService = AuthService();
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // 1. Create the "Google User" first in the emulator
    final fakeGoogleCred = GoogleAuthProvider.credential(
      idToken: 'mock-id-token-existing',
      accessToken: 'mock-access-token',
    );

    final googleUserCred = await auth.signInWithCredential(fakeGoogleCred);
    final googleUid = googleUserCred.user!.uid;

    // Write initial stats for the registered Google user
    await firestore.collection('users').doc(googleUid).set({
      'player_stats': {
        'totalXp': 500,
        'winsVsAiEasy': 5,
        'lossesVsAiEasy': 0,
        'drawsVsAiEasy': 0,
        'winsVsAiMedium': 0,
        'lossesVsAiMedium': 0,
        'drawsVsAiMedium': 0,
        'winsVsAiHard': 0,
        'lossesVsAiHard': 0,
        'drawsVsAiHard': 0,
        'winsLocalPvp': 0,
        'lossesLocalPvp': 0,
        'drawsLocalPvp': 0,
        'currentStreak': 2,
        'maxStreak': 5,
      }
    });

    await auth.signOut();

    // 2. Sign in Anonymously (Guest)
    final anonCred = await authService.signInAnonymously();
    final anonUid = anonCred!.user!.uid;

    // Write stats for anonymous user (e.g. they played a few games)
    await firestore.collection('users').doc(anonUid).set({
      'player_stats': {
        'totalXp': 300,
        'winsVsAiEasy': 3,
        'lossesVsAiEasy': 0,
        'drawsVsAiEasy': 0,
        'winsVsAiMedium': 0,
        'lossesVsAiMedium': 0,
        'drawsVsAiMedium': 0,
        'winsVsAiHard': 0,
        'lossesVsAiHard': 0,
        'drawsVsAiHard': 0,
        'winsLocalPvp': 0,
        'lossesLocalPvp': 0,
        'drawsLocalPvp': 0,
        'currentStreak': 4, // Higher streak than Google user
        'maxStreak': 4,
      }
    });

    // 3. Trigger Guest to Google Link with the SAME credential
    // Throws 'credential-already-in-use', authService catches and merges
    await authService.signInWithGoogle(mockCredential: fakeGoogleCred);

    // 4. Assertions
    final currentUser = auth.currentUser;
    expect(currentUser, isNotNull);
    expect(currentUser!.uid, googleUid);

    // Check Firestore doc of Google User
    final mergedDoc = await firestore.collection('users').doc(googleUid).get();
    expect(mergedDoc.exists, true);

    final data = mergedDoc.data()!;
    expect(data['mergedFrom'], anonUid);

    final stats = data['player_stats'];
    expect(stats['totalXp'], 800); // 500 + 300
    expect(stats['winsVsAiEasy'], 8); // 5 + 3
    expect(stats['currentStreak'], 4); // max(2, 4)
    expect(stats['maxStreak'], 5); // max(5, 4)

    // Check Anonymous doc is deleted
    final anonDoc = await firestore.collection('users').doc(anonUid).get();
    expect(anonDoc.exists, false);
  });

  testWidgets('Guest to Google merge logic - new account (normal link)', (tester) async {
    final authService = AuthService();
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // 1. Sign in Anonymously
    final anonCred = await authService.signInAnonymously();
    final anonUid = anonCred!.user!.uid;

    // Write stats for anonymous user
    await firestore.collection('users').doc(anonUid).set({
      'player_stats': {
        'totalXp': 150,
      }
    });

    // 2. Link to a BRAND NEW Google credential
    final newGoogleCred = GoogleAuthProvider.credential(
      idToken: 'mock-id-token-brand-new',
      accessToken: 'mock-access-token',
    );

    await authService.signInWithGoogle(mockCredential: newGoogleCred);

    // 3. Assertions
    final currentUser = auth.currentUser;
    expect(currentUser, isNotNull);
    // UID should remain the same (the guest account was successfully linked)
    expect(currentUser!.uid, anonUid);

    // Assert the user has the Google provider linked
    expect(currentUser.providerData.any((p) => p.providerId == 'google.com'), isTrue);

    // Ensure the doc remains intact
    final doc = await firestore.collection('users').doc(anonUid).get();
    expect(doc.exists, true);
    expect(doc.data()!['player_stats']['totalXp'], 150);
  });
}
