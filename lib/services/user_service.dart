import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';

import '../app_config/constants.dart';
import '../app_config/service_locator.dart';
import '../entities/app_user.dart';

/// Raw Auth + `users` collection I/O. Never throws — logs and returns
/// null/false so managers decide how to surface failures.
class UserService {
  final _log = Logger('UserService');
  final _firestore = locator<FirebaseFirestore>();
  final _auth = FirebaseAuth.instance;

  bool _googleSignInInitialized = false;

  CollectionReference<AppUser> get _users =>
      _firestore.collection(Constants.COLLECTION_USERS).withConverter<AppUser>(
            fromFirestore: (snapshot, _) => AppUser.fromDoc(snapshot),
            toFirestore: (user, _) => user.toMap(),
          );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Google sign-in. Web uses the Firebase popup (no google_sign_in plugin
  /// involvement); mobile uses google_sign_in 7.x + credential exchange.
  Future<UserCredential?> signInWithGoogle() async {
    const METHOD = 'signInWithGoogle';
    _log.info('$METHOD - START');
    try {
      if (kIsWeb) {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      }
      final googleSignIn = GoogleSignIn.instance;
      if (!_googleSignInInitialized) {
        await googleSignIn.initialize();
        _googleSignInInitialized = true;
      }
      final account = await googleSignIn.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return null;
    }
  }

  Future<bool> signOut() async {
    const METHOD = 'signOut';
    _log.info('$METHOD - START');
    try {
      if (!kIsWeb && _googleSignInInitialized) {
        await GoogleSignIn.instance.signOut();
      }
      await _auth.signOut();
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  /// The `role` custom claim from the current ID token.
  /// [forceRefresh] fetches a fresh token (needed after claim changes).
  Future<String?> getRoleClaim({bool forceRefresh = false}) async {
    const METHOD = 'getRoleClaim';
    try {
      final result = await _auth.currentUser?.getIdTokenResult(forceRefresh);
      return result?.claims?['role'] as String?;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return null;
    }
  }

  Stream<AppUser?> listenToUser(String uid) =>
      _users.doc(uid).snapshots().map((snapshot) => snapshot.data());

  Stream<List<AppUser>> listenToUsers() => _users
      .orderBy('displayName')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Future<bool> updateStatus(String uid, UserStatus status) async {
    const METHOD = 'updateStatus';
    _log.info('$METHOD - START - uid: $uid status: ${status.name}');
    try {
      await _firestore.collection(Constants.COLLECTION_USERS).doc(uid).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  /// Manager-only (enforced by rules): replace a user's certification tags
  /// together with their earned-at timestamps (certId → date).
  Future<bool> updateCertifications(
    String uid,
    List<String> certIds,
    Map<String, DateTime> certTimes,
  ) async {
    const METHOD = 'updateCertifications';
    _log.info('$METHOD - START - uid: $uid certs: ${certIds.length}');
    try {
      await _firestore.collection(Constants.COLLECTION_USERS).doc(uid).update({
        'certifications': certIds,
        'certificationTimes': certTimes.map(
            (certId, date) => MapEntry(certId, Timestamp.fromDate(date))),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  /// Manager-only: place the user in the org tree (site, department, role).
  /// A null value clears that layer.
  Future<bool> updateOrgAssignment(
    String uid, {
    required Site? site,
    required Department? department,
    required JobRole? jobRole,
  }) async {
    const METHOD = 'updateOrgAssignment';
    _log.info('$METHOD - START - uid: $uid '
        '${site?.wireName}/${department?.name}/${jobRole?.name}');
    try {
      await _firestore.collection(Constants.COLLECTION_USERS).doc(uid).update({
        'site': site?.wireName ?? FieldValue.delete(),
        'department': department?.name ?? FieldValue.delete(),
        'jobRole': jobRole?.name ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  /// Manager-only: set the user's fixed training-course number (cohort).
  Future<bool> updateCourseNumber(String uid, int? courseNumber) async {
    const METHOD = 'updateCourseNumber';
    _log.info('$METHOD - START - uid: $uid course: $courseNumber');
    try {
      await _firestore.collection(Constants.COLLECTION_USERS).doc(uid).update({
        'courseNumber':
            courseNumber ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  Future<bool> addFCMToken(String uid, String token, String platform) async {
    const METHOD = 'addFCMToken';
    _log.info('$METHOD - START');
    try {
      await _firestore.collection(Constants.COLLECTION_USERS).doc(uid).update({
        'fcmTokens.$token': {
          'platform': platform,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }
}
