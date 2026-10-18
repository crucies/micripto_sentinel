# 🛠️ Bitácora de Problemas y Soluciones — MiCripto Sentinel

## Problema 1: Restricciones de Doze Mode y Bloqueo de Pantalla en Android
- **Síntoma:** Los plugins convencionales de Flutter en segundo plano no pueden encender físicamente la pantalla apagada ni saltarse la pantalla de bloqueo cuando el teléfono está suspendido.
- **Solución Definitiva:** Se implementó una actividad nativa en Kotlin (`AlarmActivity.kt`) que utiliza `setShowWhenLocked(true)`, `setTurnScreenOn(true)`, `PowerManager.ACQUIRE_CAUSES_WAKEUP` y `KeyguardManager.requestDismissKeyguard()`. Esta combinación enciende físicamente el panel y dibuja el formulario táctico directamente sobre el lockscreen.

## Problema 3: Fallo en Pruebas Locales (Sin Sonido ni Formulario en V.0.1.0)
- **Síntoma:** Al presionar los botones de prueba en V.0.1.0, tras 5 segundos no sonaba la alarma ni aparecía el formulario en pantalla.
- **Causas Raíz Identificadas:**
  1. `SentinelAlarmReceiver` no creaba un canal de notificación ni utilizaba `setFullScreenIntent`, por lo que el sistema Android bloqueaba en silencio el inicio de `AlarmActivity` desde segundo plano.
  2. `alarmManager.setExactAndAllowWhileIdle` en Android 12+ requería permisos de alarmas exactas no otorgados, provocando fallo silencioso.
  3. `AlarmActivity` ejecutaba `setAudioAttributes` tras inicializar `MediaPlayer.create()`, disparando `IllegalStateException`.
  4. En Android 13/14 no se solicitaba el permiso en tiempo de ejecución `POST_NOTIFICATIONS`.
  5. La UI solo ofrecía prueba retardada de 5s sin opción de prueba inmediata en mano.
- **Solución Definitiva (V.0.1.1):**
  1. Se migró `SentinelAlarmReceiver` para enviar una notificación `PRIORITY_MAX` con `setFullScreenIntent` y `WakeLock` agresivo.
  2. Se migró la programación de alarmas a `setAlarmClock`, la API de máxima jerarquía de Android que traspasa Doze Mode sin permisos especiales.
  3. Se incorporó solicitud automática en tiempo de ejecución de `POST_NOTIFICATIONS`.
  4. Se blindó la reproducción de audio con atributos pre-configurados y fallback a la alarma oficial del sistema.
  5. Se implementó el sistema de auditoría nativo `FileLogger.kt` con visor en la pantalla de Ajustes para diagnosticar cualquier evento con milisegundos de precisión.


