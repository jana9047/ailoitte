import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final firestore = FirebaseFirestore.instance;

  Future<void> addNote(Map<String, dynamic> data) async {
    await firestore.collection("notes").doc(data['id']).set(data);
  }
}