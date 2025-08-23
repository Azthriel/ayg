// ignore_for_file: avoid_print

import 'package:url_launcher/url_launcher.dart';
import '../models/cliente.dart';
import '../models/cuota.dart';
import '../models/plantilla_mensaje.dart';
import '../services/firestore_service.dart';
import '../utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  /// Envía un mensaje de WhatsApp usando la URL scheme de WhatsApp
  Future<bool> enviarMensaje(String telefono, String mensaje) async {
    try {
      print('🔄 Iniciando envío de WhatsApp...');
      print('📱 Teléfono original: $telefono');
      print(
        '💬 Mensaje: ${mensaje.length > 100 ? '${mensaje.substring(0, 100)}...' : mensaje}',
      );

      // Limpiar el número de teléfono (eliminar espacios, guiones, etc.)
      String telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
      print('📱 Teléfono limpio: $telefonoLimpio');

      // Asegurarse de que el número tenga el formato correcto
      if (!telefonoLimpio.startsWith('+')) {
        // Asumiendo números argentinos, agregar código de país
        if (telefonoLimpio.startsWith('9')) {
          telefonoLimpio = '+54$telefonoLimpio';
        } else if (telefonoLimpio.startsWith('11') ||
            telefonoLimpio.startsWith('221') ||
            telefonoLimpio.startsWith('351')) {
          telefonoLimpio = '+549$telefonoLimpio';
        } else {
          telefonoLimpio = '+54$telefonoLimpio';
        }
      }
      print('📱 Teléfono final: $telefonoLimpio');

      // Codificar el mensaje para URL
      String mensajeCodificado = Uri.encodeComponent(mensaje);
      print('💬 Mensaje codificado: ${mensajeCodificado.length} caracteres');

      // Crear la URL de WhatsApp
      String url = 'https://wa.me/$telefonoLimpio?text=$mensajeCodificado';
      print(
        '🔗 URL generada: ${url.length > 150 ? '${url.substring(0, 150)}...' : url}',
      );

      // Intentar abrir WhatsApp
      print('🔍 Verificando si se puede abrir la URL...');
      if (await canLaunchUrl(Uri.parse(url))) {
        print('✅ URL válida, abriendo WhatsApp...');
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        print('✅ WhatsApp abierto exitosamente');
        return true;
      } else {
        print('❌ No se puede abrir la URL');
        throw Exception('No se pudo abrir WhatsApp - URL no válida');
      }
    } catch (e, stackTrace) {
      print('❌ Error al enviar mensaje de WhatsApp: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Reemplaza las variables en el mensaje con los datos del cliente y cuota
  String _reemplazarVariables(String plantilla, Cliente cliente, Cuota cuota) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return plantilla
        // Formato con llaves mayúsculas (formato original)
        .replaceAll('{NOMBRE}', cliente.nombre)
        .replaceAll('{NUMERO_CLIENTE}', cliente.numeroCliente)
        .replaceAll('{NUMERO_CUOTA}', cuota.numeroCuota.toString())
        .replaceAll('{MONTO}', CurrencyFormatter.formatCurrency(cuota.monto))
        .replaceAll(
          '{FECHA_VENCIMIENTO}',
          dateFormat.format(cuota.fechaVencimiento),
        )
        .replaceAll('{DIRECCION}', cliente.direccion)
        .replaceAll('{EMAIL}', cliente.email)
        // Formato con llaves minúsculas (formato alternativo)
        .replaceAll('{nombre}', cliente.nombre)
        .replaceAll('{numeroCliente}', cliente.numeroCliente)
        .replaceAll('{numeroCuota}', cuota.numeroCuota.toString())
        .replaceAll(
          '{monto}',
          CurrencyFormatter.formatNumberCompact(cuota.monto),
        )
        .replaceAll(
          '{fechaVencimiento}',
          dateFormat.format(cuota.fechaVencimiento),
        )
        .replaceAll('{direccion}', cliente.direccion)
        .replaceAll('{email}', cliente.email)
        // Formato con símbolo de peso
        .replaceAll('\${monto}', CurrencyFormatter.formatCurrency(cuota.monto));
  }

  /// Envía recordatorio de pago usando plantilla
  Future<bool> enviarRecordatorioPago(Cliente cliente, Cuota cuota) async {
    print('💬 WhatsAppService: enviarRecordatorioPago iniciado');
    print('💬 Cliente: ${cliente.nombre}');
    print('💬 Cuota: ${cuota.numeroCuota}');
    
    try {
      print('💬 🔍 Buscando plantilla para recordatorio de pago...');
      final plantilla = await _firestoreService.getPlantillaByTipo(
        TipoMensaje.recordatorioPago,
      );
      
      if (plantilla == null) {
        print('💬 ❌ ERROR: No se encontró plantilla para recordatorio de pago');
        throw Exception('No se encontró plantilla para recordatorio de pago');
      }
      
      print('💬 ✅ Plantilla encontrada: ${plantilla.nombre}');
      print('💬 🔄 Reemplazando variables en el mensaje...');
      final mensaje = _reemplazarVariables(plantilla.mensaje, cliente, cuota);
      print('💬 ✅ Mensaje procesado, enviando...');
      
      final resultado = await enviarMensaje(cliente.telefono, mensaje);
      print('💬 Resultado final enviarRecordatorioPago: $resultado');
      return resultado;
    } catch (e) {
      print('💬 ❌ ERROR CRÍTICO en enviarRecordatorioPago: $e');
      print('💬 ❌ Tipo de error: ${e.runtimeType}');
      return false;
    }
  }

  /// Envía notificación de pago vencido
  Future<bool> enviarNotificacionVencida(Cliente cliente, Cuota cuota) async {
    print('💬 WhatsAppService: enviarNotificacionVencida iniciado');
    
    try {
      print('💬 🔍 Buscando plantilla para pago vencido...');
      final plantilla = await _firestoreService.getPlantillaByTipo(
        TipoMensaje.pagoVencido,
      );
      
      if (plantilla == null) {
        print('💬 ❌ ERROR: No se encontró plantilla para pago vencido');
        throw Exception('No se encontró plantilla para pago vencido');
      }
      
      print('💬 ✅ Plantilla encontrada, procesando mensaje...');
      final mensaje = _reemplazarVariables(plantilla.mensaje, cliente, cuota);
      final resultado = await enviarMensaje(cliente.telefono, mensaje);
      print('💬 Resultado enviarNotificacionVencida: $resultado');
      return resultado;
    } catch (e) {
      print('💬 ❌ ERROR en enviarNotificacionVencida: $e');
      return false;
    }
  }

  /// Envía notificación de próximo vencimiento
  Future<bool> enviarNotificacionProximoVencimiento(
    Cliente cliente,
    Cuota cuota,
  ) async {
    print('💬 WhatsAppService: enviarNotificacionProximoVencimiento iniciado');
    
    try {
      print('💬 🔍 Buscando plantilla para próximo vencimiento...');
      final plantilla = await _firestoreService.getPlantillaByTipo(
        TipoMensaje.proximoVencimiento,
      );
      
      if (plantilla == null) {
        print('💬 ❌ ERROR: No se encontró plantilla para próximo vencimiento');
        throw Exception('No se encontró plantilla para próximo vencimiento');
      }
      
      print('💬 ✅ Plantilla encontrada, procesando mensaje...');
      final mensaje = _reemplazarVariables(plantilla.mensaje, cliente, cuota);
      final resultado = await enviarMensaje(cliente.telefono, mensaje);
      print('💬 Resultado enviarNotificacionProximoVencimiento: $resultado');
      return resultado;
    } catch (e) {
      print('💬 ❌ ERROR en enviarNotificacionProximoVencimiento: $e');
      return false;
    }
  }

  /// Envía notificación de primera cuota (entrega de materiales)
  Future<bool> enviarNotificacionPrimeraCuota(
    Cliente cliente,
    Cuota cuota,
  ) async {
    print('💬 WhatsAppService: enviarNotificacionPrimeraCuota iniciado');
    
    try {
      print('💬 🔍 Buscando plantilla para primera cuota...');
      final plantilla = await _firestoreService.getPlantillaByTipo(
        TipoMensaje.primeraCuota,
      );
      
      if (plantilla == null) {
        print('💬 ❌ ERROR: No se encontró plantilla para primera cuota');
        throw Exception('No se encontró plantilla para primera cuota');
      }
      
      print('💬 ✅ Plantilla encontrada, procesando mensaje...');
      final mensaje = _reemplazarVariables(plantilla.mensaje, cliente, cuota);
      final resultado = await enviarMensaje(cliente.telefono, mensaje);
      print('💬 Resultado enviarNotificacionPrimeraCuota: $resultado');
      return resultado;
    } catch (e) {
      print('💬 ❌ ERROR en enviarNotificacionPrimeraCuota: $e');
      return false;
    }
  }

  /// Envía mensajes masivos para cuotas vencidas
  /// Genera mensajes masivos para copiar/pegar manualmente
  Future<List<Map<String, String>>> generarMensajesMasivos() async {
    final mensajes = <Map<String, String>>[];

    try {
      print('🔍 WhatsApp Masivo - Generando lista de mensajes...');
      
      // Obtener cuotas vencidas
      final cuotasVencidas = await _firestoreService.getCuotasVencidas();
      print('📋 WhatsApp Masivo - Cuotas vencidas encontradas: ${cuotasVencidas.length}');

      for (var cuota in cuotasVencidas) {
        final cliente = await _firestoreService.getClienteById(cuota.clienteId);
        if (cliente != null && cliente.activo) {
          final plantilla = await _firestoreService.getPlantillaByTipo(TipoMensaje.pagoVencido);
          if (plantilla != null) {
            final mensaje = _reemplazarVariables(plantilla.mensaje, cliente, cuota);
            final telefonoLimpio = cliente.telefono.replaceAll(RegExp(r'[^\d+]'), '');
            final url = 'https://wa.me/$telefonoLimpio?text=${Uri.encodeComponent(mensaje)}';
            
            mensajes.add({
              'cliente': '${cliente.nombre} (${cliente.numeroCliente})',
              'telefono': cliente.telefono,
              'mensaje': mensaje,
              'tipo': 'Pago Vencido',
              'whatsappUrl': url,
            });
          }
        }
      }

      // Obtener cuotas próximas a vencer
      final cuotasProximas = await _firestoreService.getCuotasProximasAVencer();
      print('📋 WhatsApp Masivo - Cuotas próximas encontradas: ${cuotasProximas.length}');

      for (var cuota in cuotasProximas) {
        final cliente = await _firestoreService.getClienteById(cuota.clienteId);
        if (cliente != null && cliente.activo) {
          final plantilla = await _firestoreService.getPlantillaByTipo(TipoMensaje.proximoVencimiento);
          if (plantilla != null) {
            final mensaje = _reemplazarVariables(plantilla.mensaje, cliente, cuota);
            final telefonoLimpio = cliente.telefono.replaceAll(RegExp(r'[^\d+]'), '');
            final url = 'https://wa.me/$telefonoLimpio?text=${Uri.encodeComponent(mensaje)}';
            
            mensajes.add({
              'cliente': '${cliente.nombre} (${cliente.numeroCliente})',
              'telefono': cliente.telefono,
              'mensaje': mensaje,
              'tipo': 'Próximo Vencimiento',
              'whatsappUrl': url,
            });
          }
        }
      }

      print('✅ WhatsApp Masivo - Total mensajes generados: ${mensajes.length}');
    } catch (e) {
      print('💥 Error generando mensajes masivos: $e');
    }

    return mensajes;
  }

  Future<List<String>> enviarRecordatoriosMasivos() async {
    final resultados = <String>[];

    try {
      // Obtener cuotas vencidas
      final cuotasVencidas = await _firestoreService.getCuotasVencidas();

      for (var cuota in cuotasVencidas) {
        final cliente = await _firestoreService.getClienteById(cuota.clienteId);
        if (cliente != null && cliente.activo) {
          try {
            final exito = await enviarNotificacionVencida(cliente, cuota);
            if (exito) {
              resultados.add(
                '✅ Enviado a ${cliente.nombre} (${cliente.numeroCliente})',
              );
            } else {
              resultados.add(
                '❌ Error enviando a ${cliente.nombre} (${cliente.numeroCliente})',
              );
            }
          } catch (e) {
            resultados.add('❌ Error con ${cliente.nombre}: $e');
          }

          // Pequeña pausa entre mensajes para no saturar
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      // Obtener cuotas próximas a vencer
      final cuotasProximas = await _firestoreService.getCuotasProximasAVencer();

      for (var cuota in cuotasProximas) {
        final cliente = await _firestoreService.getClienteById(cuota.clienteId);
        if (cliente != null && cliente.activo) {
          try {
            final exito = await enviarNotificacionProximoVencimiento(
              cliente,
              cuota,
            );
            if (exito) {
              resultados.add(
                '✅ Recordatorio enviado a ${cliente.nombre} (${cliente.numeroCliente})',
              );
            } else {
              resultados.add(
                '❌ Error enviando recordatorio a ${cliente.nombre} (${cliente.numeroCliente})',
              );
            }
          } catch (e) {
            resultados.add(
              '❌ Error con recordatorio para ${cliente.nombre}: $e',
            );
          }

          // Pequeña pausa entre mensajes
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      resultados.add('❌ Error general: $e');
    }

    return resultados;
  }

  /// Valida formato de número de teléfono
  bool validarTelefono(String telefono) {
    // Remover espacios y caracteres especiales
    String telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');

    // Verificar que tenga al menos 10 dígitos
    if (telefonoLimpio.length < 10) return false;

    // Verificar formato argentino básico
    if (telefonoLimpio.startsWith('+54')) {
      return telefonoLimpio.length >= 13; // +54 + 9 + número
    } else if (telefonoLimpio.startsWith('54')) {
      return telefonoLimpio.length >= 12; // 54 + 9 + número
    } else {
      return telefonoLimpio.length >= 10; // Número local
    }
  }

  /// Formatea número de teléfono para mostrar
  String formatearTelefono(String telefono) {
    String telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');

    if (telefonoLimpio.startsWith('+549')) {
      // Formato: +54 9 11 1234-5678
      if (telefonoLimpio.length >= 13) {
        return '+54 9 ${telefonoLimpio.substring(4, 6)} ${telefonoLimpio.substring(6, 10)}-${telefonoLimpio.substring(10)}';
      }
    } else if (telefonoLimpio.startsWith('+54')) {
      // Formato: +54 11 1234-5678
      if (telefonoLimpio.length >= 12) {
        return '+54 ${telefonoLimpio.substring(3, 5)} ${telefonoLimpio.substring(5, 9)}-${telefonoLimpio.substring(9)}';
      }
    }

    return telefono; // Retornar original si no se puede formatear
  }
}
