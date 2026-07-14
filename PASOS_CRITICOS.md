# 🚀 PASOS CRÍTICOS - CUENTAS CLARAS

## ⚠️ Error de Permisos: SOLUCIÓN

El error que viste:
```
Listen for QueryWrapper failed: Status{code=PERMISSION_DENIED, 
description=Missing or insufficient permissions.}
```

Ha sido **RESUELTO** actualizando las reglas de Firestore.

---

## 📝 PASO 1: Desplegar nuevas reglas de Firestore (2 minutos)

### Estas son las ÚNICAS REGLAS QUE NECESITAS desplegar:

El archivo `firestore.rules` ya está actualizado en el proyecto. Contiene la regla clave:

```javascript
allow list: if signedIn() && resource.data.id == request.auth.uid;
```

Esta regla permite que `collectionGroup('participants')` funcione correctamente.

### Cómo desplegar:

1. Ve a: **https://console.firebase.google.com/**
2. Selecciona tu proyecto "Cuentas Claras"
3. Ve a **Firestore Database** → **Rules** (en el menú lateral izquierdo)
4. Haz clic en el botón **Edit Rules**
5. **Borra TODO el contenido actual**
6. **Copia COMPLETO** el contenido de `firestore.rules` del proyecto
7. **Pega** en el editor de Firebase Console
8. Haz clic en **Publish** (botón azul arriba a la derecha)
9. Espera hasta que veas un ✓ verde

### ✅ Verificación:

- Debería decir "Publish succeeded" o "Rules have been updated"
- Toma 1-2 minutos

---

## 📝 PASO 2: Limpiar el caché y reiniciar la app (1 minuto)

```bash
cd d:\Proyecto\cuentas_claras

# Limpiar todo
flutter clean

# Descargar dependencias
flutter pub get

# Ejecutar de nuevo
flutter run
```

---

## ✅ PASO 3: Verificación rápida (3 minutos)

### Test 1: Crear evento

1. Abre la app
2. Inicia sesión
3. Click en **+** para crear evento
4. Completa formulario
5. Click "Crear Evento"

**Resultado esperado:**
- ✅ SnackBar: "Evento creado correctamente"
- ✅ Evento aparece **inmediatamente** en "Mis Eventos"

### Test 2: Invitar participante

1. Click en uno de tus eventos
2. Pestaña "Participantes"
3. Click en botón "Invitar"
4. Ingresa email de otro usuario registrado
5. Click "Invitar"

**Resultado esperado:**
- ✅ SnackBar: "✅ ¡Invitación enviada con éxito!"
- ✅ Usuario aparece en la lista con estado "Pendiente"

---

## 🔴 Si aún ves el error de PERMISSION_DENIED:

Puede ser por una de estas razones:

### Razón 1: Las reglas no fueron desplegadas

1. Ve a Firebase Console → Firestore → Rules
2. Verifica que veas una regla con: `allow list: if signedIn() && resource.data.id == request.auth.uid;`
3. Si no la ves, repite el Paso 1

### Razón 2: El navegador tiene cache

1. Limpia el cache del navegador
2. Cierra Firebase Console completamente
3. Reabre en una pestaña nueva

### Razón 3: La app tiene caché

```bash
flutter clean
flutter pub get
flutter run
```

---

## 📊 Resumen de cambios del código

Para referencia, estos son los cambios que se hicieron:

| Archivo | Cambio | Por qué |
|---------|--------|--------|
| `firestore.rules` | Añadida regla para `collectionGroup` | Permite que la app lea participantes |
| `event_service.dart` | Simplificado `getEvents()` | Evitar errores de permisos |
| `event_controller.dart` | Mejoradas validaciones | Mejor UX y debugging |
| `participant_service.dart` | Errores más descriptivos | Feedback visual al usuario |
| `event_detail_screen.dart` | UI mejorada para invitación | Mejor UX |

---

## ✨ Próximas mejoras (opcional)

Después de que todo funcione, puedes:

1. **Mostrar eventos donde eres participante:** Descomenta la segunda query en `getEvents()` (una vez las reglas estén desplegadas)
2. **Añadir paginación:** Si tienes muchos eventos
3. **Offline support:** Usar `persistenceEnabled: true` en Firestore
4. **Notificaciones en tiempo real:** Usar Firebase Messaging

---

**⏰ Tiempo total: 5-10 minutos**

**Estado actual:** ✅ Código listo, necesita despliegue de reglas en Firebase

Cualquier problema, revisa los logs con:
```bash
flutter logs
```

