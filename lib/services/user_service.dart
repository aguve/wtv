import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;

  UserService(this.uid);

  /// Actualiza el nombre de perfil (profileName) del usuario en Firestore.
  Future<void> updateProfileName(String newProfileName) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileName': newProfileName,
      });
      print("Nombre de perfil actualizado correctamente.");
    } catch (e) {
      print("Error al actualizar el nombre de perfil: $e");
    }
  }

  /// Actualiza la imagen de perfil (profileImage) del usuario en Firestore.
  Future<void> updateProfileImage(String newProfileImageUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImage': newProfileImageUrl,
      });
      print("Imagen de perfil actualizada correctamente.");
    } catch (e) {
      print("Error al actualizar la imagen de perfil: $e");
    }
  }

  /// Crea un documento para el usuario en la colección de Firestore
  /// con los datos iniciales de profileName y profileImage.
  Future<void> createUserDocument(
      {required String profileName, required String profileImage}) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'profileName': profileName,
        'profileImage': profileImage,
      });
      print("Documento de usuario creado correctamente.");
    } catch (e) {
      print("Error al crear el documento de usuario: $e");
    }
  }

  /// Crea el documento de usuario en Firestore si no existe
  Future<void> createUserDocumentIfNotExists({
    required String profileName,
    required String profileImage,
  }) async {
    try {
      // Revisa si el documento del usuario ya existe en la colección
      final docRef = _firestore.collection('users').doc(uid);
      final docSnapshot = await docRef.get();

      // Si no existe, lo crea con los datos proporcionados
      if (!docSnapshot.exists) {
        await docRef.set({
          'profileName': profileName,
          'profileImage': profileImage,
        });
        print("Documento de usuario creado correctamente.");
      } else {
        print("El documento de usuario ya existe.");
      }
    } catch (e) {
      print("Error al verificar o crear el documento de usuario: $e");
    }
  }
}
