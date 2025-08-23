# 🌊 AYG - Sistema de Gestión de Clientes (Agua y Gas)

Sistema web desarrollado en Flutter para la gestión de clientes, cuotas y envío automatizado de recordatorios de pago vía WhatsApp.

## 🚀 Características

- **🔐 Sistema de Autenticación**: Login/logout seguro con roles de usuario
- **👥 Gestión de Usuarios**: Administradores y usuarios regulares
- **👤 Gestión de Clientes**: CRUD completo de clientes
- **💰 Gestión de Cuotas**: Control de pagos y vencimientos
- **📱 Integración WhatsApp**: Envío de recordatorios automáticos
- **📝 Plantillas Personalizables**: Mensajes con variables dinámicas
- **🎨 Iconos Personalizados**: Sistema de iconos para plantillas
- **📊 Dashboard**: Métricas y estadísticas en tiempo real

## 🛠️ Tecnologías

- **Frontend**: Flutter Web
- **Backend**: Firebase/Firestore
- **Autenticación**: Sistema propio con encriptación SHA-256
- **Hosting**: Firebase Hosting
- **Integración**: WhatsApp Web API

## 📦 Estructura del Proyecto

```text
lib/
├── models/           # Modelos de datos (Cliente, Cuota, Usuario, etc.)
├── providers/        # Estado global (Provider pattern)
├── screens/          # Pantallas de la aplicación
├── widgets/          # Componentes reutilizables
├── services/         # Servicios (Firebase, WhatsApp)
├── utils/            # Utilidades y helpers
└── main.dart         # Punto de entrada

assets/
└── logo.png          # Logo de la aplicación
```

## 👤 Roles de Usuario

### Administrador

- ✅ Gestión completa de usuarios
- ✅ Acceso a todas las funcionalidades
- ✅ Crear/editar/eliminar usuarios
- ✅ Cambiar contraseñas

### Usuario Regular

- ✅ Gestión de clientes y cuotas
- ✅ Envío de mensajes WhatsApp
- ✅ Gestión de plantillas
- ❌ No puede gestionar usuarios

## 📱 Funcionalidades de WhatsApp

- **Recordatorios de Pago**: Mensajes automáticos para cuotas pendientes
- **Notificaciones de Vencimiento**: Alertas por pagos vencidos
- **Plantillas Personalizables**: Mensajes con variables como {nombre}, {monto}, etc.
- **Selector de Plantillas**: Interface amigable para elegir plantillas
- **Variables Dinámicas**: Sustitución automática de datos del cliente

## 🔒 Seguridad

- **Autenticación**: Sistema propio con hash SHA-256
- **Roles**: Separación clara entre admin y usuario
- **Firestore Rules**: Reglas de seguridad en base de datos
- **Validación**: Validación tanto frontend como backend

## 🎨 UI/UX

- **Material Design 3**: Interfaz moderna y consistente
- **Responsive**: Adaptable a diferentes tamaños de pantalla
- **Temas**: Colores corporativos
- **Animaciones**: Transiciones suaves
- **Accesibilidad**: Cumple estándares de accesibilidad web

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

Desarrollado con ❤️ usando Flutter
