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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cliente.activo ? Colors.green : Colors.grey,
          child: Text(
            cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cliente.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${cliente.numeroCliente}'),
            Text('Email: ${cliente.email}'),
            Text('Tel: ${cliente.telefono}'),
            Text('Cuotas: ${cliente.numeroCuotas} | Total: \$${cliente.montoTotal.toStringAsFixed(2)}'),
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
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }
}
