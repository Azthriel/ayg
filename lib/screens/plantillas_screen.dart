import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cliente_provider.dart';
import '../models/plantilla_mensaje.dart';
import '../widgets/plantilla_form_dialog.dart';

class PlantillasScreen extends StatefulWidget {
  const PlantillasScreen({super.key});

  @override
  State<PlantillasScreen> createState() => _PlantillasScreenState();
}

class _PlantillasScreenState extends State<PlantillasScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ClienteProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.plantillas.isEmpty
              ? _buildEmptyState()
              : _buildPlantillasList(provider.plantillas),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _mostrarFormularioPlantilla(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay plantillas de mensaje',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _mostrarFormularioPlantilla(context),
            icon: const Icon(Icons.add),
            label: const Text('Crear primera plantilla'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantillasList(List<PlantillaMensaje> plantillas) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<ClienteProvider>(
          context,
          listen: false,
        ).cargarPlantillas();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plantillas.length,
        itemBuilder: (context, index) {
          final plantilla = plantillas[index];
          return _buildPlantillaCard(plantilla);
        },
      ),
    );
  }

  Widget _buildPlantillaCard(PlantillaMensaje plantilla) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getTipoColor(plantilla.tipo),
          child: Icon(
            _getTipoIcon(plantilla.tipo),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          plantilla.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plantilla.tipo.descripcion),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: plantilla.activa ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                plantilla.activa ? 'Activa' : 'Inactiva',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () =>
                  _mostrarFormularioPlantilla(context, plantilla: plantilla),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminarPlantilla(context, plantilla),
              tooltip: 'Eliminar',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mensaje:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    plantilla.mensaje,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Variables disponibles
                Text(
                  'Variables disponibles:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildVariableChip('{NOMBRE}'),
                    _buildVariableChip('{NUMERO_CLIENTE}'),
                    _buildVariableChip('{NUMERO_CUOTA}'),
                    _buildVariableChip('{MONTO}'),
                    _buildVariableChip('{FECHA_VENCIMIENTO}'),
                    _buildVariableChip('{DIRECCION}'),
                    _buildVariableChip('{EMAIL}'),
                  ],
                ),
                const SizedBox(height: 16),

                // Vista previa con datos de ejemplo
                Text(
                  'Vista previa:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    _generarVistaPrevia(plantilla.mensaje),
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _probarPlantilla(plantilla),
                      icon: const Icon(Icons.send),
                      label: const Text('Probar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarFormularioPlantilla(
                        context,
                        plantilla: plantilla,
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
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

  Widget _buildVariableChip(String variable) {
    return Chip(
      label: Text(variable, style: const TextStyle(fontSize: 10)),
      backgroundColor: Colors.blue[100],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _generarVistaPrevia(String plantilla) {
    return plantilla
        .replaceAll('{NOMBRE}', 'Juan Pérez')
        .replaceAll('{NUMERO_CLIENTE}', 'C001')
        .replaceAll('{NUMERO_CUOTA}', '2')
        .replaceAll('{MONTO}', '1,500.00')
        .replaceAll('{FECHA_VENCIMIENTO}', '15/02/2025')
        .replaceAll('{DIRECCION}', 'Av. Ejemplo 123, Ciudad')
        .replaceAll('{EMAIL}', 'juan.perez@email.com');
  }

  Color _getTipoColor(TipoMensaje tipo) {
    switch (tipo) {
      case TipoMensaje.recordatorioPago:
        return Colors.blue;
      case TipoMensaje.pagoVencido:
        return Colors.red;
      case TipoMensaje.proximoVencimiento:
        return Colors.orange;
      case TipoMensaje.primeraCuota:
        return Colors.green;
      case TipoMensaje.personalizada:
        return Colors.purple;
    }
  }

  IconData _getTipoIcon(TipoMensaje tipo) {
    switch (tipo) {
      case TipoMensaje.recordatorioPago:
        return Icons.payment;
      case TipoMensaje.pagoVencido:
        return Icons.warning;
      case TipoMensaje.proximoVencimiento:
        return Icons.schedule;
      case TipoMensaje.primeraCuota:
        return Icons.inventory;
      case TipoMensaje.personalizada:
        return Icons.message;
    }
  }

  void _mostrarFormularioPlantilla(
    BuildContext context, {
    PlantillaMensaje? plantilla,
  }) {
    showDialog(
      context: context,
      builder: (context) => PlantillaFormDialog(plantilla: plantilla),
    ).then((_) {
      // Recargar plantillas después de cerrar el diálogo
      if (context.mounted) {
        Provider.of<ClienteProvider>(context, listen: false).cargarPlantillas();
      }
    });
  }

  void _confirmarEliminarPlantilla(
    BuildContext context,
    PlantillaMensaje plantilla,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro que desea eliminar la plantilla "${plantilla.nombre}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final provider = Provider.of<ClienteProvider>(
                context,
                listen: false,
              );
              final exito = await provider.eliminarPlantilla(plantilla.firestoreId!);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      exito
                          ? 'Plantilla eliminada exitosamente'
                          : 'Error al eliminar la plantilla',
                    ),
                    backgroundColor: exito ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _probarPlantilla(PlantillaMensaje plantilla) {
    final vistaPrevia = _generarVistaPrevia(plantilla.mensaje);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Probar: ${plantilla.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mensaje que se enviaría:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(vistaPrevia),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nota: Esta es una vista previa con datos de ejemplo.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Aquí podrías agregar lógica para abrir WhatsApp con el mensaje de prueba
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Para probar completamente, selecciona un cliente y cuota específicos',
                  ),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Probar en WhatsApp'),
          ),
        ],
      ),
    );
  }
}
