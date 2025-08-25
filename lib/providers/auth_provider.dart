import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    restoreSession();
  }
  // Persistencia para Flutter web
  Future<void> restoreSession() async {
    // Usar window.localStorage para Flutter web
    try {
      final storage = (WidgetsBinding.instance.platformDispatcher as dynamic).window.localStorage;
      final usuarioJson = storage['usuarioActual'];
      if (usuarioJson != null) {
        final usuario = Usuario.fromJson(usuarioJson);
        _usuarioActual = usuario;
        notifyListeners();
      }
    } catch (_) {}
  }
  Usuario? _usuarioActual;
  bool _isLoading = false;
  String? _error;

  Usuario? get usuarioActual => _usuarioActual;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _usuarioActual != null;
  bool get isAdmin => _usuarioActual?.esAdmin ?? false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para iniciar sesión
  Future<bool> login(String usuario, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Buscar usuario en Firestore
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('usuario', isEqualTo: usuario)
          .where('activo', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _setError('Usuario no encontrado o inactivo');
        return false;
      }

      final doc = querySnapshot.docs.first;
      final usuarioEncontrado = Usuario.fromFirestore(doc);

      // Verificar contraseña
      if (!usuarioEncontrado.verificarPassword(password)) {
        _setError('Contraseña incorrecta');
        return false;
      }

      // Actualizar último acceso
      await _firestore.collection('usuarios').doc(doc.id).update({
        'ultimoAcceso': Timestamp.fromDate(DateTime.now()),
      });

      _usuarioActual = usuarioEncontrado.copyWith(ultimoAcceso: DateTime.now());

      // Guardar usuario en localStorage (Flutter web)
      try {
        final storage = (WidgetsBinding.instance.platformDispatcher as dynamic).window.localStorage;
        storage['usuarioActual'] = _usuarioActual!.toJson();
      } catch (_) {}

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al iniciar sesión: $e');
      return false;
    }
  }

  // Método para cerrar sesión
  void logout() {
    _usuarioActual = null;
    _clearError();
    // Eliminar usuario de localStorage (Flutter web)
    try {
      final storage = (WidgetsBinding.instance.platformDispatcher as dynamic).window.localStorage;
      storage.remove('usuarioActual');
    } catch (_) {}
    notifyListeners();
  }

  // Método para crear nuevo usuario (solo admins)
  Future<bool> crearUsuario({
    required String usuario,
    required String password,
    required String nombre,
    required String email,
    required TipoUsuario tipo,
  }) async {
    if (!isAdmin) {
      _setError('No tienes permisos para crear usuarios');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Verificar si el usuario ya existe
      final existingUser = await _firestore
          .collection('usuarios')
          .where('usuario', isEqualTo: usuario)
          .get();

      if (existingUser.docs.isNotEmpty) {
        _setError('El nombre de usuario ya existe');
        return false;
      }

      // Crear nuevo usuario
      final nuevoUsuario = Usuario(
        usuario: usuario,
        passwordHash: Usuario.crearHashPassword(password),
        nombre: nombre,
        email: email,
        tipo: tipo,
        fechaCreacion: DateTime.now(),
      );

      await _firestore.collection('usuarios').add(nuevoUsuario.toFirestore());

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear usuario: $e');
      return false;
    }
  }

  // Método para obtener todos los usuarios (solo admins)
  Future<List<Usuario>> obtenerUsuarios() async {
    if (!isAdmin) {
      throw Exception('No tienes permisos para ver usuarios');
    }

    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .orderBy('fechaCreacion', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Usuario.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  // Método para activar/desactivar usuario
  Future<bool> toggleUsuarioActivo(String usuarioId, bool activo) async {
    if (!isAdmin) {
      _setError('No tienes permisos para modificar usuarios');
      return false;
    }

    try {
      await _firestore.collection('usuarios').doc(usuarioId).update({
        'activo': activo,
      });
      return true;
    } catch (e) {
      _setError('Error al modificar usuario: $e');
      return false;
    }
  }

  // Método para cambiar contraseña
  Future<bool> cambiarPassword(
    String passwordActual,
    String passwordNuevo,
  ) async {
    if (_usuarioActual == null) {
      _setError('No hay usuario autenticado');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Verificar contraseña actual
      if (!_usuarioActual!.verificarPassword(passwordActual)) {
        _setError('Contraseña actual incorrecta');
        return false;
      }

      // Actualizar contraseña
      final nuevoHash = Usuario.crearHashPassword(passwordNuevo);
      await _firestore
          .collection('usuarios')
          .doc(_usuarioActual!.firestoreId)
          .update({'passwordHash': nuevoHash});

      _usuarioActual = _usuarioActual!.copyWith(passwordHash: nuevoHash);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al cambiar contraseña: $e');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
