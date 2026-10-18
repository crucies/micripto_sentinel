# 📜 Bitácora de Versiones — MiCripto Sentinel

## [V.0.1.6] - 2026-10-18
### Centinela Autónomo Dinámico (Nube Web + Binance 25s), 6 Órdenes Vivas (Dual RENDER) y Barra de Progreso Táctica
- **Mandato y Diagnóstico de Richard:**
  1. *"No me parece adecuado tener que modificar la app movil cada que actualizemos las ordenes... deberia haber un boton en la pagina web que actualice las ordenes en la app"*
  2. *"En la app movil... la consulta de precio deberia ser automatica... sin presionar boton... no tendria sentido la app si depende de que yo presione un boton para ver si se cumplio alguna alerta"*
  3. *"Mate... en las tarjetas de monedas... en la parte superior esta el nombre de la moneda... Limit Sell y el precio... abajo hay una linea que divide esta informacion con el resto... esa linea me gustaria sea un indicativo visual para saber que tan lejos estamos de nuestro objetivo... como una barra de progreso... que tanto se esta acercando el precio desde que lo compranos hasta nuestro precio de TP..."*
  4. *"En el recuadro 'META DE GANANCIA NETA'... bajar el precio una linea por debajo.... ahora mismo se sale del recuadro"*
  5. *"En cada tarjeta de moneda... las opciones 'VER FICHAR Y ABRIR BINANCE' tambien bajalo a su propia linea... tambien se sale por la derecha"*
  6. *"En el cuadro de 'CAPITAL EN JUEGO'.. el monto no se ve completo.. ejemplo... $1.204,27... el numero 7 se muestra solo en una linea inferior"*
- **Soluciones Implementadas:**
  1. **Sincronización Dinámica Nube Web-Móvil (`SentinelAutoScanner.dart` + `api/orders.ts`):**
     - La app se conecta al endpoint serverless `https://micripto-lts.vercel.app/api/orders`.
     - Cero necesidad de recompilar la APK ante nuevas compras o ventas: la web publica y la app móvil actualiza sus órdenes vivas en memoria y almacenamiento local de inmediato.
  2. **Vigilancia Autónoma Binance Spot (Cero Clics):**
     - Escaneo continuo cada 25 segundos en primer plano directo contra Binance Spot REST API.
     - Disparo autónomo de la alarma militar agresiva al 100% en pantalla bloqueada en cuanto el precio de mercado toca o supera el TP de cualquiera de las órdenes.
     - Motor nativo Android `SentinelAlarmReceiver.kt` con bucle de despertar en Doze (`ACTION_SENTINEL_SCAN` vía `AlarmManager.setAlarmClock`).
  3. **Incorporación Oficial de las 6 Órdenes Spot (Dual RENDER):**
     - RENDER TP1 Defensivo: 56.88 RENDER @ $1.8100 ($102.95 USDT)
     - RENDER TP2 Expansivo: 56.88 RENDER @ $1.8600 ($105.79 USDT)
     - PENDLE: 72.10 PENDLE @ $2.1900 ($157.90 USDT)
     - SUI: 149.70 SUI @ $1.0650 ($159.43 USDT)
     - XRP: 261.00 XRP @ $1.3580 ($354.44 USDT)
     - ONDO: 1,091.20 ONDO @ $0.4880 ($532.51 USDT)
     - Capital total en juego: **$1,413.02 USDT** | Ganancia neta proyectada: **+$79.13 USDT limpios**.
  4. **4 Correcciones Visuales Brutalistas Tácticas:**
     - **Barra de Progreso Táctica hacia el TP:** Sustituida la línea divisoria negra por una barra de progreso que calcula `(livePrice - entryPrice) / (targetPrice - entryPrice) * 100%`. Posee pista brutalista, etiqueta de rango de compra a venta, porcentaje en tiempo real y color reactivo (Naranja, Oro caliente >=70% y Verde esmeralda al 100%).
     - **Meta de Ganancia Neta:** El monto pasa a una línea inferior independiente dentro de la franja naranja, protegido con `FittedBox` + `maxLines: 1` para eliminar desbordes.
     - **Acción "VER FICHA Y ABRIR BINANCE ➔":** Reubicada en una línea completa dedicada en la base de la tarjeta con botón brutalista centrado, eliminando el choque lateral con la fecha.
     - **Capital en Juego & Saldo Libre:** Protegidos con `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)` y `maxLines: 1`, impidiendo que dígitos sueltos salten a una segunda línea.
- **Despliegue de APK:**
  - Archivo generado: [`micripto_sentinel_v0.1.6_DynamicLiveSentinel.apk`](file:///C:/Richard/A/Aplicaciones%20Moviles/APKs/micripto_sentinel_v0.1.6_DynamicLiveSentinel.apk)
  - Ubicación central: `C:\Richard\A\Aplicaciones Moviles\APKs`

## [V.0.1.5] - 2026-10-18
### Rediseño Neo-Brutalista "Imán de Dinero" en Todas las Pantallas, Distribución en Grillas y Ocultamiento de Simulador
- **Mandato de Richard:**
  1. *"Correcto mate... me gusta mas esta interfaz... modifica todas las pantallas... asegurate de distribuir bien la informacion"*
  2. *"Mate... por ahora oculta la seccion de testeo de alarma (manten el codigo pero no lo muestres en la app)"*
- **Soluciones Implementadas:**
  1. **Sistema de Diseño DRY Neo-Brutalista (`app_colors.dart` & `main.dart`):**
     - Paleta unificada **Money Magnet**: Lienzo Solar Crema-Dorado (`#FFF8E7`), superficies en **Blanco Puro (`#FFFFFF`)**, **Amarillo Oro (`#FFD600`)**, **Naranja Fuego (`#FF5500`)** y bordes/sombras duras en **Negro Carbón (`#0A0A0A`)**.
     - Decoradores DRY `AppColors.brutalistBox` (bordes sólidos de `2.5px`/`3px` + sombra negra desplazada sin difuminado) y `AppColors.brutalistCell` (celdas internas de grilla).
  2. **Barra de Navegación Inferior Táctica (`main_navigation_page.dart`):**
     - Dock Neo-Brutalista dividido 50%/50% (`INICIO SPOT` y `AJUSTES & LOGS`) con bloque activo en Amarillo Oro y sombra dura de `4px`.
  3. **Pantalla Principal — Inicio Spot (`dashboard_page.dart`):**
     - Márgenes laterales de `22px` para respiración de sombras.
     - **Hero Card de Bóveda:** Bloque Amarillo Oro con 2 celdas blancas lado a lado (`SALDO LIBRE SPOT: $36.59` y `CAPITAL EN JUEGO: $1,204.27`) y franja inferior en Naranja Fuego (`META DE GANANCIA NETA: +$70.07 USDT LIMPIOS`).
     - **Tarjetas de las 4 Órdenes Vivas:** Cada orden (`SUI`, `XRP`, `ONDO`, `PENDLE`) organiza sus datos en una grilla de 3 celdas simétricas (`CANTIDAD`, `RETORNO TP`, `GANANCIA`).
     - **Tarjeta de Enlace Remoto Firebase FCM:** Rediseñada en estilo brutalista con botón Amarillo Oro para copiar el Token FCM.
     - **Ocultamiento Limpio del Simulador de Alarma:** Controlado por la bandera `_showTestAlarmSection = false`, manteniendo el 100% del código intacto y libre de advertencias de análisis.
  4. **Modal Flotante de Detalle de Orden (`order_detail_modal.dart`):**
     - Tarjeta blanca con sombra dura de `7px`, bloque Hero en Amarillo Oro + Naranja Fuego para el Precio Take Profit (`24sp`), grilla 2x2 de celdas brutalistas y botón directo a Binance Spot.
  5. **Pantalla de Ajustes & Telemetría (`settings_page.dart`):**
     - Selector de perfil de sonido con bloques brutalistas interactivos y check cuadrado `[✓]`, tarjeta de permisos de pantalla bloqueada, consola de auditoría en negro/oro, botones 50%/50% (`COPIAR LOG` / `BORRAR LOG`) y tarjeta de versión **V.0.1.5**.
- **Despliegue de APK:**
  - Archivo generado: [`micripto_sentinel_v0.1.5_FullBrutalistMoneyUI.apk`](file:///C:/Richard/A/Aplicaciones%20Moviles/APKs/micripto_sentinel_v0.1.5_FullBrutalistMoneyUI.apk)
  - Ubicación central: `C:\Richard\A\Aplicaciones Moviles\APKs`
  - Tamaño (`arm64-v8a` optimizado): `17.2 MB` (18,078,696 bytes)

## [V.0.1.4] - 2026-10-18
### Rediseño Neo-Brutalista "Imán de Dinero" en Formularios de Pantalla Bloqueada y Distribución Espacial Completa
- **Diagnóstico y Mandato de Richard:**
  1. Los formularios de pantalla bloqueada (`AlarmActivity`) se veían muy apretados de borde a borde y dejaban un espacio vacío importante en la parte inferior.
  2. Solicitud de aplicar estilo **Brutalista** con mejor distribución de datos y colores que **"llamen dinero"** (Blanco, Amarillo Oro y Naranja Fuego).
- **Soluciones Implementadas:**
  1. **Paleta Cromática "Money Magnet" (`#FFF8E7`, `#FFFFFF`, `#FFD600`, `#FF5500`, `#0A0A0A`):**
     - Lienzo solar crema-dorado (`#FFF8E7`) sincronizado con `AlarmTheme` (`styles.xml` y `values-night/styles.xml`) e iconos de barra de estado oscuros (`SYSTEM_UI_FLAG_LIGHT_STATUS_BAR`).
     - Bloques de superficie en **Blanco Puro (`#FFFFFF`)**, **Amarillo Oro (`#FFD600`)** y **Naranja Dinero (`#FF5500`)** con alto contraste tipográfico en negro carbón (`#0A0A0A`).
  2. **Sistema de Drawables Neo-Brutalistas con Sombra Dura Sólida (`<layer-list>`):**
     - Bordes negros sólidos de `2.5dp` a `3dp`, esquinas en ángulo recto (`0dp`) y sombras negras duras desplazadas (`4dp` a `6dp` sin difuminado) en `bg_card_tactical.xml`, `bg_card_action.xml`, `bg_status_badge.xml`, `bg_brutalist_orange.xml`, `bg_brutalist_yellow.xml` y `bg_brutalist_white.xml`.
     - Eliminado el uso de `setBackgroundColor()` en `AlarmActivity.kt` (que destruía los bordes del drawable) reemplazándolo por `setBackgroundResource(...)`.
  3. **Nueva Distribución Espacial y Grilla Interna (Cero Borde a Borde / Cero Vacío Inferior):**
     - Márgenes exteriores amplios (`24dp`) y `fitsSystemWindows="true"`.
     - Espaciadores elásticos (`<Space android:layout_weight="1" />`) que reparten uniformemente la altura en cualquier pantalla.
     - **Tarjeta 1 (Activo):** Cabecera con par + etiqueta de modo, divisor negro de `2.5dp` y grilla de 2 celdas lado a lado para **Precio** y **Capital / Posición**.
     - **Tarjeta 2 (Hero Orden Táctica):** Tarjeta Amarillo Oro con caja central en **Naranja Fuego (`#FF5500`)** para el Precio Objetivo en `32sp` Blanco Puro y cinta blanca de retorno esperado.
     - **Tarjeta 3 (Telemetría de Capital & Bóveda):** Ahora **siempre visible en los 3 modos** (`BUY_FILLED`, `TP_HIT`, `S_PLUS_ALPHA`) con 2 celdas superiores (Beneficio de Operación + Ganancia Acumulada `+$70.07 USDT`) y barra inferior de Liquidez Spot (`$36.59 USDT`).
     - **Consola Inferior de Botones:** Botón principal de ancho completo `🚀 ABRIR BINANCE DIRECTO` en Naranja Fuego y fila inferior dividida 50%/50% con `🔕 SILENCIAR` (Amarillo Oro) y `📊 VER PANEL` (Blanco Puro).
  4. **Sincronización de Versión en UI:** AppBar, Footer y Ajustes actualizados a **V.0.1.4** (`0.1.4+5`).
- **Despliegue de APK:**
  - Archivo generado: [`micripto_sentinel_v0.1.4_BrutalistMoneyLockForms.apk`](file:///C:/Richard/A/Aplicaciones%20Moviles/APKs/micripto_sentinel_v0.1.4_BrutalistMoneyLockForms.apk)
  - Ubicación central: `C:\Richard\A\Aplicaciones Moviles\APKs`
  - Tamaño (`arm64-v8a` optimizado): `17.4 MB` (18,210,432 bytes)

## [V.0.1.3] - 2026-10-17
### Arquitectura de Audio Centralizada (SentinelAudioManager), Canal V4 Limpio y Flujo de Permiso Overlay
- **Diagnóstico del Fallo de V.0.1.2:**
  1. En V.0.1.2 se intentó programar `setAlarmClock` con un `PendingIntent.getActivity` directo. En Android 10+ con pantalla bloqueada, el sistema operativo descarta silenciosamente los inicios de actividades directas desde alarmas en reposo (Doze/Lock) si la app no cuenta con el permiso especial de superposición (`SYSTEM_ALERT_WINDOW`). Como consecuencia, no se ejecutó el Receiver, no se adquirió el WakeLock y no sonó el audio ("pantalla negra y sin sonido").
- **Soluciones Implementadas:**
  1. **Motor Centralizado de Audio (`SentinelAudioManager.kt`):**
     - Singleton nativo que reproduce el Sonar Cuántico en bucle continuo sobre el canal de alarma del sistema (`USAGE_ALARM` al 100% de volumen) con vibración táctica.
     - Se dispara **inmediatamente** desde `SentinelAlarmReceiver.onReceive` antes de cualquier interacción de UI. El teléfono suena de inmediato sin depender de que la actividad se renderice.
     - Silenciable desde `AlarmActivity` o mediante el nuevo botón de acción rápida `🔕 SILENCIAR` en la notificación.
  2. **Restablecimiento de Disparo Confiable en `MainActivity.kt`:**
     - La alarma de 5s vuelve a utilizar `PendingIntent.getBroadcast` hacia `SentinelAlarmReceiver`, garantizando la ejecución del WakeLock de pantalla brillante y la reproducción de audio.
  3. **Canal de Notificación V4 Limpio (`sentinel_emergency_v4`):**
     - Nuevo canal con `IMPORTANCE_HIGH`, `VISIBILITY_PUBLIC` y `setBypassDnd(true)` para asegurar que ninguna configuración residual antigua de Android degrade la prioridad.
     - Acciones añadidas a la notificación: `🔕 SILENCIAR` y `🚀 VER ORDEN`.
  4. **Gestión Proactiva de Permiso de Superposición ("Aparecer Encima"):**
     - Módulo nativo para verificar `Settings.canDrawOverlays(this)` y solicitar `ACTION_MANAGE_OVERLAY_PERMISSION`.
     - Nueva tarjeta en la pestaña **Ajustes** que muestra el estado del permiso y ofrece un botón de 1 clic para activarlo en Android.
     - Verificación automática en el Dashboard: si el usuario pulsa `🔒 Bloqueo en 5s` y el permiso no está activo, un SnackBar le ofrece activarlo al instante.
  5. **Versión en UI:** Footer y Ajustes sincronizados a **V.0.1.3**.
- **Despliegue de APK:**
  - Archivo generado: [`micripto_sentinel_v0.1.3_DecoupledAudioAndOverlayPerms.apk`](file:///C:/Richard/A/Aplicaciones%20Moviles/APKs/micripto_sentinel_v0.1.3_DecoupledAudioAndOverlayPerms.apk)
  - Ubicación central: `C:\Richard\A\Aplicaciones Moviles\APKs`
  - Tamaño: `46.1 MB` (48,338,758 bytes)

## [V.0.1.2] - 2026-10-17
### Rediseño de Modales Centrados y Simétricos, Elusión de Clave en Bloqueo, Audio Continuo y Sincronización PENDLE
- **Diagnóstico y Feedback de Richard:**
  1. El modal de detalle de orden se expandía de extremo a extremo, apegado al borde inferior con desbordamiento de texto.
  2. En la prueba de alarma con pantalla apagada, tras 5s sonaba 1 sola vez y se encendía la pantalla pero mostrando el teclado para ingresar la clave/PIN en lugar del formulario directo.
- **Soluciones Implementadas:**
  1. **Rediseño del Modal de Detalle de Orden (`order_detail_modal.dart`):**
     - Migración de `showModalBottomSheet` a `showDialog` con diseño de tarjeta táctica flotante centrada (`maxWidth: 420px`).
     - Bordes simétricos con radio de 20px, botón de cierre 'X' y resplandor cian.
     - Filas de datos protegidas con `Expanded`, `maxLines: 2` y `TextOverflow.ellipsis` para erradicar cualquier desbordamiento.
  2. **Elusión Definitiva de Clave sobre Bloqueo (`AlarmActivity.kt`):**
     - Eliminación de `keyguardManager.requestDismissKeyguard()` (la cual era la causante de invocar la pantalla de ingreso de PIN sobre la actividad).
     - Activación estricta de `setShowWhenLocked(true)` y `setTurnScreenOn(true)` con flags de ventana para desplegar el formulario táctico DIRECTAMENTE sobre la pantalla bloqueada sin pedir contraseña previa.
  3. **Lanzamiento Directo de Alarma vía `setAlarmClock` (`MainActivity.kt`):**
     - Programación del `PendingIntent` apuntando directamente a `AlarmActivity` (PendingIntent.getActivity) en lugar de un broadcast intermediario, lo que otorga privilegios del sistema operativo para saltar cualquier restricción de inicio en segundo plano.
  4. **Blindaje de Audio Continuo:**
     - Agregado `setOnCompletionListener` a `MediaPlayer` para reiniciar inmediatamente la reproducción en caso de que el sistema operativo intente detener el loop.
  5. **Estética y Simetría Táctica Nativa (`activity_alarm.xml`):**
     - Creados drawables dedicados con esquinas redondeadas (`bg_card_tactical.xml`, `bg_card_action.xml`, `bg_status_badge.xml`).
     - Distribución equilibrada con márgenes laterales idénticos y jerarquía visual refinada.
  6. **Sincronización PENDLE (4 Órdenes Vivas):**
     - Tarjeta PENDLE ($2.1900 | 72.1 monedas) incorporada a `order_entity.dart`.
     - Métricas del Dashboard actualizadas: 4 Activas, $36.59 USDT líquidos, $1,204.27 USDT retorno esperado, +$70.07 USDT ganancia neta.
- **Despliegue de APK:**
  - Archivo generado: [`micripto_sentinel_v0.1.2_CenteredModalDirectAlarm.apk`](file:///C:/Richard/A/Aplicaciones%20Moviles/APKs/micripto_sentinel_v0.1.2_CenteredModalDirectAlarm.apk)
  - Ubicación central: `C:\Richard\A\Aplicaciones Moviles\APKs`
  - Tamaño: `46.1 MB` (48,322,082 bytes)

## [V.0.1.1] - 2026-10-17
### Corrección Crítica del Motor de Alarma: FullScreenIntent, AlarmClock y Modo Dual
- **Diagnóstico del Fallo de V.0.1.0:**
  1. En Android 10+ (API 29+), `SentinelAlarmReceiver` no podía invocar `startActivity` de fondo directamente debido a las restricciones de seguridad del sistema operativo. Se requería obligatoriamente un `NotificationChannel` de prioridad máxima con `setFullScreenIntent`.
  2. En Android 12+ (API 31+), `alarmManager.setExactAndAllowWhileIdle` requería permisos especiales que provocaban bloqueo silencioso.
  3. En Android 13+ (API 33+), no se estaba solicitando en tiempo de ejecución el permiso `POST_NOTIFICATIONS`.
  4. En `AlarmActivity.kt`, llamar a `setAudioAttributes` después de `MediaPlayer.create()` generaba `IllegalStateException`.
  5. En la interfaz, solo existía la prueba retardada de 5 segundos sin opción de disparo inmediato en mano.
- **Solución y Mejoras Implementadas:**
  1. **FullScreenIntent en `SentinelAlarmReceiver`:** Creación de canal de notificación con audio sonar y elevación garantizada de `AlarmActivity` sobre la pantalla de bloqueo.
  2. **Migración a `setAlarmClock`:** Programación de alarmas de máxima jerarquía de Android que traspasan el Doze Mode sin requerir permisos especiales.
  3. **Permiso Dinámico `POST_NOTIFICATIONS`:** Solicitado automáticamente al abrir la aplicación en Android 13/14+.
  4. **Blindaje de Audio en `AlarmActivity`:** AudioAttributes pre-configurados en `MediaPlayer.create()` y fallback automático al tono de alarma del sistema.
  5. **Controles Duales en Dashboard:** Cada uno de los 3 modos cuenta ahora con botón `⚡ Disparar Ahora` (prueba instantánea en pantalla) y `🔒 Bloqueo en 5s` (prueba de despertar con pantalla apagada).
  6. **Icono Institucional Cyberpunk:** Escudo táctico con sonar cuántico y velas criptográficas desplegado en todas las densidades de pantalla (`mipmap-mdpi` a `mipmap-xxxhdpi`).
  7. **Modal Táctico de Detalle de Orden (`order_detail_modal.dart`):** Al pulsar cualquier tarjeta en el Dashboard se despliega una ficha técnica con precio objetivo en tipografía de 28pt dorada, ganancia neta estimada en USDT y botón de enlace directo a Binance Spot.
  8. **Barra de Navegación Inferior con `SafeArea` (`main_navigation_page.dart`):** Navegación fluida entre *Inicio* y *Ajustes*, protegida contra superposición con la barra de gestos de Android.
  9. **Selector de Perfil de Sonido (`settings_page.dart`):** Soporte para alternar entre *"Sonar siempre"* (forzado táctico) y *"Sonar según configuración del teléfono"* (respeto a silencio/vibración para iglesias y reuniones).
  10. **Motor de Telemetría y Visor de Logs Nativos (`FileLogger.kt`):** Registro con marcas de tiempo en milisegundos de cada evento, alarma y wake-lock con visor en vivo, copia a portapapeles y purga.
- **Despliegue de APK:**
  - Archivo generado: [`micripto_sentinel_v0.1.1_FixAlarmModalIcon.apk`](file:///C:/Richard/A/Aplicaciones%20Moviles/APKs/micripto_sentinel_v0.1.1_FixAlarmModalIcon.apk)
  - Ubicación central: `C:\Richard\A\Aplicaciones Moviles\APKs`
  - Tamaño: `46.1 MB` (48,336,970 bytes)

## [V.0.1.0] - 2026-10-17
### Setup Inicial de la Arquitectura Híbrida Sentinel (Kotlin + Flutter)
- **Mandato de Richard:**
  - *"Quiero recibir informacion cuando se realize una compra en suelo de liquidez (para colocar la orden de venta), cuando se ejecute la orden de venta de TP... saber cuanto de dinero hemos ganado (por la transaccion de TP y en forma general)... ademas elige que alerta tiene la mayor probabilidad de hacernos ganar dinero y enviala tambien"*
  - *"Sabes ?... quiero que la app movil... despliegue un formulario con los datos que necesito ver y suene una alarma (busca un sonido ideal para nuestro sistema) aunque mi telefono este bloqueado"*
- **1. Arquitectura Híbrida Batallada (Richard & Kai):**
  - **Módulo Nativo Android (Kotlin):**
    - `AlarmActivity.kt`: Capacidad de despertar físico de pantalla con `setShowWhenLocked(true)`, `setTurnScreenOn(true)` y `KeyguardManager`.
    - Formulario visual nativo para pantalla bloqueada (`activity_alarm.xml`) con modo táctico militar de alto contraste.
    - Reproductor de audio nativo `MediaPlayer` en canal prioritario `AudioAttributes.USAGE_ALARM` con sonido "Sonar Cuántico Institucional".
    - Soporte para los 3 Modos Operativos de Alerta:
      1. `BUY_FILLED`: Alerta de compra ejecutada en suelo de liquidez indicando orden Take Profit a colocar en Binance.
      2. `TP_HIT`: Resumen de ganancia limpia de la transacción actual y ganancia histórica acumulada.
      3. `S_PLUS_ALPHA`: Alerta institucional de máxima probabilidad (Score >= 90).
  - **Módulo Flutter (Clean Architecture):**
    - Dashboard con las 3 órdenes vivas de Binance (SUI a $1.0650, XRP a $1.3580, ONDO a $0.4880).
    - Estado de Bóveda en vivo ($186.41 USDT libre / $1,046.37 USDT en juego).
    - Botón de prueba para verificar el despertar físico con pantalla bloqueada (5s delay).
- **2. Enlace Remoto Firebase Cloud Messaging (FCM):**
  - Incorporado `google-services.json` oficial del proyecto `micripto-sentinel`.
  - Configurados plugins Gradle `com.google.gms.google-services:4.4.2` y dependencias `firebase-bom:33.4.0` con `firebase-messaging-ktx`.
  - Desarrollado `SentinelFirebaseService.kt` (Servicio nativo Kotlin):
    - Recepción ultrarrápida de push data-only de alta prioridad (`priority: high`).
    - Despertador de CPU con `PowerManager.SCREEN_BRIGHT_WAKE_LOCK | ACQUIRE_CAUSES_WAKEUP`.
    - Canal de notificación crítico con sonido de Sonar Cuántico y `setFullScreenIntent` para eludir restricciones de Android 10+ sobre pantalla bloqueada.
    - Suscripción automática al tópico institucional `/topics/sentinel_alerts`.
  - Tarjeta en Dashboard de Flutter para monitorear enlace FCM y copiar el Token del dispositivo.
- **3. Sincronización y Versionado:**
  - Versión en `pubspec.yaml`: `0.1.0+1` (`V.0.1.0`)
  - Visibilidad de versión en UI según protocolo: Appbar y Footer institucional.
  - Verificación `flutter analyze`: **0 errores, 0 advertencias (Clean Build)**.
- **4. Despliegue de APK:**
  - Archivo generado: [`micripto_sentinel_v0.1.0_SetupInicial.apk`](file:///C:/Richard/A/Aplicaciones%20Moviles/APKs/micripto_sentinel_v0.1.0_SetupInicial.apk)
  - Ubicación central: `C:\Richard\A\Aplicaciones Moviles\APKs`
  - Tamaño: `43.4 MB` (45,558,854 bytes)

