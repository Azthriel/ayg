import 'package:flutter/material.dart';
import '../models/cliente.dart';

class ClienteListItem extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ClienteListItem({
    super.key,
    required this.cliente,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cliente.activo ? null : Colors.grey.shade200,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cliente.activo ? Colors.green : Colors.grey,
          child: cliente.activo
              ? Text(
                  cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(Icons.block, color: Colors.white),
        ),
        title: Row(
          children: [
            Text(
              cliente.nombre,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cliente.activo ? Colors.black : Colors.grey,
              ),
            ),
            if (!cliente.activo)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'INACTIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${cliente.numeroCliente}', style: TextStyle(color: cliente.activo ? Colors.black : Colors.grey)),
            Text('Email: ${cliente.email}', style: TextStyle(color: cliente.activo ? Colors.black : Colors.grey)),
            Text('Tel: ${cliente.telefono}', style: TextStyle(color: cliente.activo ? Colors.black : Colors.grey)),
            Text('Cuotas: ${cliente.numeroCuotas} | Total: \$${cliente.montoTotal.toStringAsFixed(2)}', style: TextStyle(color: cliente.activo ? Colors.black : Colors.grey)),
            if (cliente.observaciones != null && cliente.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cliente.observaciones!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cliente.activo) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Eliminar (marcar inactivo)',
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                onPressed: onEdit, // Usar onEdit para reactivar
                tooltip: 'Reactivar',
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Eliminar definitivamente',
              ),
            ],
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }
}
