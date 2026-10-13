import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get usuarioActual => _auth.currentUser;
  Stream<User?> get cambiosDeSesion => _auth.authStateChanges();

  // Guarda o actualiza el usuario en Firestore sin importar con qué método entró
  Future<void> _guardarUsuarioEnFirestore(User user, String? nombre) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
        {
          'email': user.email,
          'nombreEmprendimiento': nombre ?? user.displayName ?? 'Usuario nuevo',
          'fechaRegistro': FieldValue.serverTimestamp(),
        },
        SetOptions(
            merge:
                true)); // merge evita sobreescribir la fecha si vuelve a iniciar sesión
  }

  Future<User?> registroConEmailYPassword(
      String email, String password, String nombreEmprendimiento) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      await credential.user!.updateDisplayName(nombreEmprendimiento);
      await credential.user!.reload();

      await _guardarUsuarioEnFirestore(credential.user!, nombreEmprendimiento);
    }
    return _auth.currentUser;
  }

  Future<User?> iniciarSesionConGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      // 1. Autenticar con Google
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication authGoogle = googleUser.authentication;

      // 2. TU LÓGICA ORIGINAL PARA OBTENER EL ACCESSTOKEN
      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      // 3. Crear credencial con los tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: authGoogle.idToken,
      );

      // 4. Iniciar sesión en Firebase
      final resultado = await _auth.signInWithCredential(credential);

      // 5. Guardar en Firestore para tu panel de administrador
      if (resultado.user != null) {
        await _guardarUsuarioEnFirestore(
            resultado.user!, resultado.user!.displayName);
      }

      return resultado.user;
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
      return null;
    }
  }

  Future<User?> iniciarSesionConFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final credential =
            FacebookAuthProvider.credential(accessToken.tokenString);
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          await _guardarUsuarioEnFirestore(
              userCredential.user!, userCredential.user!.displayName);
        }
        return userCredential.user;
      } else {
        throw 'Inicio de sesión cancelado o fallido en Facebook.';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw 'Este correo ya está registrado con otro método.';
      }
      throw 'Error de Firebase: ${e.message}';
    } catch (e) {
      throw 'Ocurrió un error inesperado: $e';
    }
  }

  Future<void> cerrarSesion() async {
    await GoogleSignIn.instance.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}
