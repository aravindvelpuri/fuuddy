// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class UserRepository {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<String?> getUserName(String userId) async {
//     try {
//       DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
//       return userDoc['name'] as String?;
//     } catch (e) {
//       print('Error fetching user name: $e');
//       return null;
//     }
//   }
// }