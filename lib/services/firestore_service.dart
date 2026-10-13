import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Un helper delgado sobre Firestore. Cada módulo (inventario, ventas,
/// agenda) usa su propia "colección", asegurando que los datos pertenezcan
/// exclusivamente al usuario autenticado actual.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el ID del usuario actual de forma segura
  String? get _userId => _auth.currentUser?.uid;

  /// Stream en vivo de una colección filtrada estrictamente por el usuario logueado.
  Stream<List<Map<String, dynamic>>> escuchar(String coleccion) {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection(coleccion)
        .where('userId',
            isEqualTo: _userId) // <-- Filtra solo los datos del usuario actual
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Agrega un documento a Firestore inyectando automáticamente el ID del usuario actual.
  Future<void> agregar(String coleccion, Map<String, dynamic> datos) async {
    if (_userId == null) return;

    final datosConUsuario = {
      ...datos,
      'userId': _userId, // <-- Asigna la propiedad del registro al usuario
    };

    await _db.collection(coleccion).add(datosConUsuario);
  }

  /// Actualiza un documento existente.
  Future<void> actualizar(
      String coleccion, String id, Map<String, dynamic> datos) async {
    await _db.collection(coleccion).doc(id).update(datos);
  }

  /// Elimina un documento por su ID.
  Future<void> eliminar(String coleccion, String id) async {
    await _db.collection(coleccion).doc(id).delete();
  }
}
