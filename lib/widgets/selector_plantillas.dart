import 'package:flutter/material.dart';
import '../models/plantilla_mensaje.dart';

class SelectorPlantillas extends StatelessWidget {
  final List<PlantillaMensaje> plantillas;
  final Function(PlantillaMensaje) onPlantillaSeleccionada;

  const SelectorPlantillas({
    super.key,
    required this.plantillas,
    required this.onPlantillaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Plantilla'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: plantillas.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No hay plantillas disponibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: plantillas.length,
                itemBuilder: (context, index) {
                  final plantilla = plantillas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTipoColor(plantilla.tipo),
                        child: Icon(
                          _getTipoIcon(plantilla),
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
                          Text(
                            plantilla.tipo.descripcion,
                            style: TextStyle(
                              color: _getTipoColor(plantilla.tipo),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plantilla.mensaje.length > 80
                                ? '${plantilla.mensaje.substring(0, 80)}...'
                                : plantilla.mensaje,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).pop();
                        onPlantillaSeleccionada(plantilla);
                      },
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
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

  IconData _getTipoIcon(PlantillaMensaje plantilla) {
    if (plantilla.tipo == TipoMensaje.personalizada && plantilla.iconCodePoint != null) {
      return IconData(plantilla.iconCodePoint!, fontFamily: 'MaterialIcons');
    }

    switch (plantilla.tipo) {
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
}
