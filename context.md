# PROJECT CONTEXT - Cuentas Claras

## Descripción del proyecto

**Cuentas Claras** es una aplicación móvil desarrollada en **Flutter** cuyo objetivo es facilitar la organización de eventos sociales y la gestión de gastos compartidos entre múltiples participantes.

La aplicación permitirá crear eventos, invitar participantes, registrar gastos, dividirlos mediante diferentes métodos, calcular automáticamente las deudas entre los integrantes y registrar las liquidaciones realizadas.

El objetivo principal es desarrollar un MVP funcional, intuitivo y escalable, priorizando la experiencia de usuario y la simplicidad del código antes que la implementación de arquitecturas complejas.

---

# Tecnologías

- Flutter 3.44.3
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging (implementación futura)
- Provider
- Material Design 3

---

# Arquitectura

El proyecto utiliza una arquitectura MVC sencilla y modular.

```
lib/
│
├── config/
├── controllers/
├── models/
├── services/
├── views/
├── widgets/
└── utils/
```

### Config

Contiene la configuración global de la aplicación:

- Tema
- Colores
- Assets
- Rutas

### Controllers

Gestionan la lógica de presentación y la comunicación entre las vistas y los servicios.

Los Controllers no contienen lógica de acceso directo a Firebase.

### Models

Representan las entidades del sistema y contienen la serialización (`toMap` / `fromMap`) para Firestore.

### Services

Toda interacción con Firebase debe realizarse exclusivamente desde esta capa.

Incluye operaciones relacionadas con:

- Authentication
- Firestore
- Participantes
- Eventos
- Gastos
- Deudas
- Liquidaciones

### Views

Contienen únicamente la interfaz gráfica y la interacción con el usuario.

Las vistas nunca deben comunicarse directamente con Firebase.

### Widgets

Componentes reutilizables para mantener una interfaz consistente y evitar duplicación de código.

### Utils

Funciones auxiliares, validadores y utilidades compartidas.

---

# Filosofía de desarrollo

El proyecto prioriza:

- Código sencillo y fácil de mantener.
- Funcionalidad antes que optimización prematura.
- Reutilización de componentes cuando aporte valor.
- Desarrollo incremental por funcionalidades completas.

Mientras el MVP no esté finalizado se evitarán patrones complejos que aumenten innecesariamente la dificultad del proyecto.

---

# Flujo de desarrollo

El desarrollo se realizará **por flujo de usuario**, no por módulos independientes.

Cada flujo debe quedar completamente funcional antes de comenzar el siguiente.

Ejemplo:

```
Autenticación

↓

Eventos

↓

Participantes

↓

Gastos

↓

Deudas

↓

Liquidaciones

↓

Resumen
```

Este enfoque facilita las pruebas, reduce retrabajo y mantiene una aplicación utilizable en cada etapa del desarrollo.

---

# Firebase

## Authentication

Se utiliza Firebase Authentication para:

- Registro
- Inicio de sesión
- Persistencia de sesión
- Gestión básica del usuario

Al registrarse un usuario también se crea automáticamente su documento correspondiente en la colección `users`.

---

## Firestore

Colecciones principales previstas:

```
users/

events/
    participants/
    expenses/
    debts/
    settlements/
```

Cada evento posee sus propias subcolecciones para mantener la información organizada e independiente.

---

## Seguridad

Las reglas de Firestore están configuradas para trabajar con:

- Usuarios autenticados.
- Propietarios del evento.
- Participantes aceptados.

No reemplazar estas reglas por reglas completamente abiertas.

---

## Índices

Actualmente Firestore cuenta con los siguientes índices configurados:

### 1. Índice compuesto

Colección:

events

Campos:

- creatorId (Ascending)
- createdAt (Descending)
- _name_ (Descending)

Scope:

Collection

Este índice soporta las consultas utilizadas para listar y ordenar eventos del usuario.

---

### 2. Índice automático (Single Field Exemption)

Colección:

participants

Campo:

- id

Configuración:

- Ascending: Enabled
- Descending: Enabled
- Array: Enabled

Alcance:

- Collection Scope: Enabled
- Collection Group Scope: Enabled

Este índice es generado automáticamente por Firestore y permite realizar consultas eficientes sobre la colección `participants` y consultas de tipo Collection Group cuando sean necesarias.

---

Antes de modificar consultas o agregar nuevos filtros sobre Firestore verificar si requieren la creación de índices adicionales.

---

# Convenciones del proyecto

- Utilizar Provider para gestión de estado.
- Mantener la arquitectura MVC.
- Toda comunicación con Firebase debe realizarse mediante Services.
- Evitar lógica de negocio dentro de las Views.
- Mantener los Models únicamente como representación de datos.
- Crear widgets reutilizables cuando un componente se utilice en varias pantallas.
- Priorizar código claro antes que soluciones excesivamente sofisticadas.

---

# Módulos principales

## 1. Autenticación

Funciones:

- Registro
- Inicio de sesión
- Recuperación de contraseña
- Persistencia de sesión

---

## 2. Perfil

Funciones:

- Visualización del perfil
- Edición de datos personales
- Moneda preferida

---

## 3. Gestión de Eventos

Funciones:

- Crear eventos
- Editar eventos
- Eliminar eventos
- Finalizar eventos
- Historial de eventos

---

## 4. Participantes

Funciones:

- Invitar participantes
- Eliminar participantes
- Roles (Administrador / Participante)
- Aceptar invitaciones
- Rechazar invitaciones

---

## 5. Gastos

Funciones:

- Registrar gastos
- Editar gastos
- Eliminar gastos
- Categorías
- Responsable del pago

---

## 6. División de gastos

Métodos de división:

- Equitativa
- Por porcentaje
- Por monto fijo
- Personalizada

---

## 7. Deudas

Funciones:

- Generación automática de deudas
- Balance individual
- Balance general
- Estado de cada deuda

---

## 8. Liquidaciones

Funciones:

- Registrar pagos
- Confirmar pagos
- Historial de liquidaciones

---

## 9. Resumen

Funciones:

- Total gastado
- Participantes
- Gastos registrados
- Balance general
- Deudas pendientes

---

## 10. Notificaciones

Funciones previstas:

- Invitaciones a eventos
- Recordatorios
- Confirmación de pagos
- Eventos próximos

---

# Flujo funcional esperado

```
Splash

↓

Login / Registro

↓

Home

↓

Crear Evento

↓

Detalle del Evento

↓

Participantes

↓

Registrar Gastos

↓

Calcular Balance

↓

Generar Deudas

↓

Liquidar Pagos

↓

Resumen

↓

Finalizar Evento
```

El **Detalle del Evento** funcionará como el centro de navegación de todas las funcionalidades relacionadas con un evento.

---

# Recomendaciones para asistentes de IA

Al generar código para este proyecto:

- Respetar la arquitectura MVC existente.
- Utilizar Provider como gestor de estado.
- Implementar la lógica de Firebase únicamente en Services.
- Mantener el estilo de código ya existente.
- Reutilizar widgets cuando sea posible.
- Priorizar soluciones simples, funcionales y fáciles de mantener.
- Evitar introducir dependencias o patrones de arquitectura innecesarios (Bloc, Riverpod, Clean Architecture, Repository Pattern, etc.) mientras el MVP no esté finalizado.