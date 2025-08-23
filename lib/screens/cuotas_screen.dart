import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cliente_provider.dart';
import '../models/cuota.dart';
import '../models/cliente.dart';
import '../models/plantilla_mensaje.dart';
import '../utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class CuotasScreen extends StatefulWidget {
  const CuotasScreen({super.key});

  @override
  State<CuotasScreen> createState() => _CuotasScreenState();
}

class _CuotasScreenState extends State<CuotasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, Cliente?> _clientesCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usar el método específico que carga TODAS las cuotas
      Provider.of<ClienteProvider>(
        context,
        listen: false,
      ).cargarTodasLasCuotas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Cuotas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.warning), text: 'Vencidas'),
            Tab(icon: Icon(Icons.schedule), text: 'Próximas'),
            Tab(icon: Icon(Icons.payment), text: 'Todas'),
          ],
        ),
      ),
      body: Consumer<ClienteProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCuotasList(provider.cuotasVencidas, 'vencidas'),
              _buildCuotasList(provider.cuotasProximas, 'proximas'),
              _buildCuotasList(provider.cuotas, 'todas'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCuotasList(List<Cuota> cuotas, String tipo) {
    if (cuotas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getEmptyIcon(tipo), size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(tipo),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<ClienteProvider>(
          context,
          listen: false,
        ).cargarTodasLasCuotas();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cuotas.length,
        itemBuilder: (context, index) {
          final cuota = cuotas[index];
          return FutureBuilder<Cliente?>(
            future: _getCliente(cuota.clienteId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Cargando...'),
                  ),
                );
              }

              final cliente = snapshot.data;
              if (cliente == null) {
                return const SizedBox.shrink();
              }

              return _buildCuotaCard(cuota, cliente);
            },
          );
        },
      ),
    );
  }

  Widget _buildCuotaCard(Cuota cuota, Cliente cliente) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final esVencida = cuota.estaVencida;
    final esProxima = cuota.venceProximamente;

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    IconData statusIcon = Icons.payment;
    Color statusColor = Colors.blue;

    if (cuota.pagada) {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      borderColor = Colors.green.shade300;
    } else if (esVencida) {
      statusIcon = Icons.warning;
      statusColor = Colors.red;
      borderColor = Colors.red.shade300;
      cardColor = Colors.red.shade50;
    } else if (esProxima) {
      statusIcon = Icons.schedule;
      statusColor = Colors.orange;
      borderColor = Colors.orange.shade300;
      cardColor = Colors.orange.shade50;
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(statusIcon, color: Colors.white, size: 20),
        ),
        title: Text(
          '${cliente.nombre} - Cuota ${cuota.numeroCuota}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${cliente.numeroCliente}'),
            Text('Vence: ${dateFormat.format(cuota.fechaVencimiento)}'),
            Text(
              'Monto: ${CurrencyFormatter.formatCurrency(cuota.monto)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!cuota.pagada)
              IconButton(
                icon: const Icon(Icons.message, color: Colors.blue),
                onPressed: () => _mostrarOpcionesWhatsApp(cuota, cliente),
                tooltip: 'Enviar WhatsApp',
              ),
            IconButton(
              icon: Icon(
                cuota.pagada ? Icons.undo : Icons.check,
                color: cuota.pagada ? Colors.orange : Colors.green,
              ),
              onPressed: () => _togglePagada(cuota),
              tooltip: cuota.pagada
                  ? 'Marcar como pendiente'
                  : 'Marcar como pagada',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Teléfono:', cliente.telefono),
                _buildDetailRow('Email:', cliente.email),
                _buildDetailRow('Dirección:', cliente.direccion),
                if (cuota.pagada && cuota.fechaPago != null)
                  _buildDetailRow(
                    'Fecha de Pago:',
                    dateFormat.format(cuota.fechaPago!),
                  ),
                if (cuota.observaciones != null &&
                    cuota.observaciones!.isNotEmpty)
                  _buildDetailRow('Observaciones:', cuota.observaciones!),

                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!cuota.pagada) ...[
                      ElevatedButton.icon(
                        onPressed: () => _enviarRecordatorio(cuota, cliente),
                        icon: const Icon(Icons.send),
                        label: const Text('Recordatorio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (esVencida)
                        ElevatedButton.icon(
                          onPressed: () =>
                              _enviarNotificacionVencida(cuota, cliente),
                          icon: const Icon(Icons.warning),
                          label: const Text('Vencida'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _editarObservaciones(cuota),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Observaciones'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<Cliente?> _getCliente(String clienteId) async {
    if (_clientesCache.containsKey(clienteId)) {
      return _clientesCache[clienteId];
    }

    final provider = Provider.of<ClienteProvider>(context, listen: false);
    final clientes = provider.clientes;
    final cliente = clientes
        .where((c) => c.firestoreId == clienteId)
        .firstOrNull;

    _clientesCache[clienteId] = cliente;
    return cliente;
  }

  void _mostrarOpcionesWhatsApp(Cuota cuota, Cliente cliente) {
    final provider = Provider.of<ClienteProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Enviar mensaje de WhatsApp',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: provider.plantillas.length,
                  itemBuilder: (context, index) {
                    final plantilla = provider.plantillas[index];
                    return _buildPlantillaListTile(plantilla, cuota, cliente);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantillaListTile(PlantillaMensaje plantilla, Cuota cuota, Cliente cliente) {
    // Determinar el icono y color basado en el tipo
    IconData iconData;
    Color iconColor;
    
    if (plantilla.tipo == TipoMensaje.personalizada && plantilla.iconCodePoint != null) {
      iconData = IconData(plantilla.iconCodePoint!, fontFamily: 'MaterialIcons');
      iconColor = Colors.purple;
    } else {
      switch (plantilla.tipo) {
        case TipoMensaje.recordatorioPago:
          iconData = Icons.payment;
          iconColor = Colors.blue;
          break;
        case TipoMensaje.pagoVencido:
          iconData = Icons.warning;
          iconColor = Colors.red;
          break;
        case TipoMensaje.proximoVencimiento:
          iconData = Icons.schedule;
          iconColor = Colors.orange;
          break;
        case TipoMensaje.primeraCuota:
          iconData = Icons.inventory;
          iconColor = Colors.green;
          break;
        case TipoMensaje.personalizada:
          iconData = Icons.message;
          iconColor = Colors.purple;
          break;
      }
    }

    // Generar vista previa del mensaje
    String mensajePreview = plantilla.mensaje;
    
    // Reemplazar variables básicas para la vista previa
    mensajePreview = mensajePreview
        .replaceAll('{nombre}', cliente.nombre)
        .replaceAll('{monto}', '\$${cuota.monto.toStringAsFixed(2)}')
        .replaceAll('{fecha_vencimiento}', cuota.fechaVencimiento.day.toString());
    
    // Truncar si es muy largo
    if (mensajePreview.length > 80) {
      mensajePreview = '${mensajePreview.substring(0, 77)}...';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          plantilla.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTipoLabel(plantilla.tipo),
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mensajePreview,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          _enviarMensajeConPlantilla(cuota, cliente, plantilla);
        },
      ),
    );
  }

  String _getTipoLabel(TipoMensaje tipo) {
    switch (tipo) {
      case TipoMensaje.recordatorioPago:
        return 'Recordatorio de Pago';
      case TipoMensaje.pagoVencido:
        return 'Pago Vencido';
      case TipoMensaje.proximoVencimiento:
        return 'Próximo Vencimiento';
      case TipoMensaje.primeraCuota:
        return 'Primera Cuota - Materiales';
      case TipoMensaje.personalizada:
        return 'Plantilla Personalizada';
    }
  }

  Future<void> _enviarMensajeConPlantilla(
    Cuota cuota,
    Cliente cliente,
    PlantillaMensaje plantilla,
  ) async {
    final provider = Provider.of<ClienteProvider>(context, listen: false);
    final exito = await provider.enviarMensajeConPlantilla(
      cliente,
      cuota,
      plantilla,
    );

    _mostrarResultadoEnvio(exito, plantilla.nombre);
  }

  Future<void> _enviarRecordatorio(Cuota cuota, Cliente cliente) async {
    final provider = Provider.of<ClienteProvider>(context, listen: false);
    final exito = await provider.enviarRecordatorioPago(cliente, cuota);

    _mostrarResultadoEnvio(exito, 'recordatorio');
  }

  Future<void> _enviarNotificacionVencida(Cuota cuota, Cliente cliente) async {
    final provider = Provider.of<ClienteProvider>(context, listen: false);
    final exito = await provider.enviarNotificacionVencida(cliente, cuota);

    _mostrarResultadoEnvio(exito, 'notificación de vencimiento');
  }

  void _mostrarResultadoEnvio(bool exito, String tipoMensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exito
              ? 'WhatsApp abierto para enviar $tipoMensaje'
              : 'Error al abrir WhatsApp para $tipoMensaje',
        ),
        backgroundColor: exito ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _togglePagada(Cuota cuota) async {
    final provider = Provider.of<ClienteProvider>(context, listen: false);

    if (cuota.pagada) {
      // Marcar como pendiente
      final cuotaActualizada = cuota.copyWith(pagada: false, fechaPago: null);
      await provider.actualizarCuota(cuotaActualizada);
    } else {
      // Marcar como pagada
      await provider.marcarCuotaComoPagada(cuota);
    }
  }

  Future<void> _editarObservaciones(Cuota cuota) async {
    final controller = TextEditingController(text: cuota.observaciones ?? '');

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observaciones'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Observaciones',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado != null && mounted) {
      final provider = Provider.of<ClienteProvider>(context, listen: false);
      final cuotaActualizada = cuota.copyWith(observaciones: resultado);
      await provider.actualizarCuota(cuotaActualizada);
    }
  }

  IconData _getEmptyIcon(String tipo) {
    switch (tipo) {
      case 'vencidas':
        return Icons.check_circle_outline;
      case 'proximas':
        return Icons.schedule;
      default:
        return Icons.payment;
    }
  }

  String _getEmptyMessage(String tipo) {
    switch (tipo) {
      case 'vencidas':
        return 'No hay cuotas vencidas';
      case 'proximas':
        return 'No hay cuotas próximas a vencer';
      default:
        return 'No hay cuotas registradas';
    }
  }
}
