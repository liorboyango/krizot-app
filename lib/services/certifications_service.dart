import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../app_config/constants.dart';
import '../app_config/service_locator.dart';
import '../entities/certification.dart';

class CertificationsService {
  final _log = Logger('CertificationsService');
  final _firestore = locator<FirebaseFirestore>();

  CollectionReference<Certification> get _certifications => _firestore
      .collection(Constants.COLLECTION_CERTIFICATIONS)
      .withConverter<Certification>(
        fromFirestore: (snapshot, _) => Certification.fromDoc(snapshot),
        toFirestore: (certification, _) => certification.toMap(),
      );

  Stream<List<Certification>> listenToCertifications() => _certifications
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Future<String?> createCertification(Certification certification) async {
    const METHOD = 'createCertification';
    _log.info('$METHOD - START - ${certification.name}');
    try {
      final map = certification.toMap()
        ..['createdAt'] = FieldValue.serverTimestamp();
      final doc = await _firestore
          .collection(Constants.COLLECTION_CERTIFICATIONS)
          .add(map);
      return doc.id;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return null;
    }
  }

  Future<bool> updateCertification(Certification certification) async {
    const METHOD = 'updateCertification';
    _log.info('$METHOD - START - ${certification.id}');
    try {
      await _firestore
          .collection(Constants.COLLECTION_CERTIFICATIONS)
          .doc(certification.id)
          .update(certification.toMap());
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }

  Future<bool> deleteCertification(String certificationId) async {
    const METHOD = 'deleteCertification';
    _log.info('$METHOD - START - $certificationId');
    try {
      await _firestore
          .collection(Constants.COLLECTION_CERTIFICATIONS)
          .doc(certificationId)
          .delete();
      return true;
    } catch (e) {
      _log.severe('$METHOD - Error: $e');
      return false;
    }
  }
}
