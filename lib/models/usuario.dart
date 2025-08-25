import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class Usuario {
  // Serialización para persistencia web
  Map<String, dynamic> toJson() {
    return {
      'firestoreId': firestoreId,
      'usuario': usuario,
      'passwordHash': passwordHash,
      'nombre': nombre,
      'email': email,
      'tipo': tipo.name,
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'ultimoAcceso': ultimoAcceso?.toIso8601String(),
    };
  }

  static Usuario fromJson(dynamic json) {
    if (json is String) {
      json = jsonDecode(json);
    }
    return Usuario(
      firestoreId: json['firestoreId'],
      usuario: json['usuario'],
      passwordHash: json['passwordHash'],
      nombre: json['nombre'],
      email: json['email'],
      tipo: TipoUsuario.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => TipoUsuario.usuario,
      ),
      activo: json['activo'] ?? true,
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      ultimoAcceso: json['ultimoAcceso'] != null ? DateTime.parse(json['ultimoAcceso']) : null,
    );
  }
  final String? firestoreId;
  final String usuario;
  final String passwordHash; // Hash de la contraseña, nunca la contraseña en texto plano
  final String nombre;
  final String email;
  final TipoUsuario tipo;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? ultimoAcceso;

  Usuario({
    this.firestoreId,
    required this.usuario,
    required this.passwordHash,
    required this.nombre,
    required this.email,
    required this.tipo,
    this.activo = true,
    required this.fechaCreacion,
    this.ultimoAcceso,
  });

  // Método para crear hash de contraseña
  static String crearHashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Método para verificar contraseña
  bool verificarPassword(String password) {
    return passwordHash == crearHashPassword(password);
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'usuario': usuario,
      'passwordHash': passwordHash,
      'nombre': nombre,
      'email': email,
      'tipo': tipo.name,
      'activo': activo,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'ultimoAcceso': ultimoAcceso != null ? Timestamp.fromDate(ultimoAcceso!) : null,
    };
  }

  // Crear desde Map de Firestore
  static Usuario fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Usuario(
      firestoreId: doc.id,
      usuario: data['usuario'] ?? '',
      passwordHash: data['passwordHash'] ?? '',
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      tipo: TipoUsuario.values.firstWhere(
        (t) => t.name == data['tipo'],
        orElse: () => TipoUsuario.usuario,
      ),
      activo: data['activo'] ?? true,
      fechaCreacion: data['fechaCreacion'] != null
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
      ultimoAcceso: data['ultimoAcceso'] != null
          ? (data['ultimoAcceso'] as Timestamp).toDate()
          : null,
    );
  }

  // Método copyWith
  Usuario copyWith({
    String? firestoreId,
    String? usuario,
    String? passwordHash,
    String? nombre,
    String? email,
    TipoUsuario? tipo,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? ultimoAcceso,
  }) {
    return Usuario(
      firestoreId: firestoreId ?? this.firestoreId,
      usuario: usuario ?? this.usuario,
      passwordHash: passwordHash ?? this.passwordHash,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      tipo: tipo ?? this.tipo,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
    );
  }

  bool get esAdmin => tipo == TipoUsuario.administrador;
  bool get puedeCrearUsuarios => tipo == TipoUsuario.administrador;
}

enum TipoUsuario {
  administrador,
  usuario,
}

extension TipoUsuarioExtension on TipoUsuario {
  String get descripcion {
    switch (this) {
      case TipoUsuario.administrador:
        return 'Administrador';
      case TipoUsuario.usuario:
        return 'Usuario';
    }
  }

  String get icono {
    switch (this) {
      case TipoUsuario.administrador:
        return '👑';
      case TipoUsuario.usuario:
        return '👤';
    }
  }
}
