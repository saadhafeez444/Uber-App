import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber_app/models/profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserProfile> fetchUserProfile(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('profiles').doc(userId).get();

      if (!docSnapshot.exists) {
        throw Exception("User profile not found for ID: $userId");
      }

      final data = docSnapshot.data();
      if (data == null) {
        throw Exception("User profile data is null for ID: $userId");
      }

      final mappedData = {
        ...data,
        'profileImage': data['profileImageURL'], 
      };
      
      return UserProfile.fromMap(mappedData);

    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }
}