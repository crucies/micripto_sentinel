# 🧭 Manual de Reconstrucción (Prompt Kai) — MiCripto Sentinel

## 1. Identidad y Propósito
**MiCripto Sentinel (V.0.1.8)** es la terminal centinela móvil nativa complementaria de **MiCripto LTS**.
Su misión es monitorear autónomamente (24/7, incluso en Doze Mode con pantalla bloqueada) las órdenes vivas en Binance Spot y el radar institucional **Smart Engine 2.2 (`1H`)**, despertando físicamente el teléfono de Richard con alarma militar y formulario Neo-Brutalista sobre el bloqueo ante 3 eventos:
1. **Compra en suelo de liquidez ejecutada (`BUY_FILLED`):** Indica el precio exacto de Take Profit a plantar en Binance.
2. **Take Profit alcanzado (`TP_HIT`):** Notifica la ganancia limpia en USDT de la operación y el acumulado en bóveda.
3. **Alerta Institucional Grado S+ (`S_PLUS_ALPHA`, Score >= 90%):** Detectada en tiempo real por el motor cuántico `1H` (92.3% Win Rate) con plan completo de compra y protección OCO.

## 2. Arquitectura y Pila Tecnológica
- **Framework UI:** Flutter 3.41+ (Dart 3.11+) con estética **Neo-Brutalista "Money Magnet"** (`#FFF8E7`, `#FFFFFF`, `#FFD600`, `#FF5500`, `#0A0A0A`) y jerarquía cromática oficial para el Radar (`#00E5FF` Celeste para $\ge 90\%$ S+, `#10B981` Esmeralda para $80-89\%$ S, `#FFD600` Oro para $70-79\%$ A).
- **3 Pestañas Tácticas (`main_navigation_page.dart`):**
  1. `INICIO SPOT`: Bóveda (Saldo Libre Spot editable con 1 toque + sincronizado con nube, Capital en Juego y Meta de Ganancia Neta) y tarjetas de órdenes vivas con barra de progreso hacia el TP.
  2. `RADAR S+`: Escáner autónomo `Smart Engine 2.2` en temporalidad `1H` para los 10 activos institucionales con paridad matemática 100% idéntica a `smcEngine.ts` de la Web.
  3. `AJUSTES`: Selector de perfil de sonido (`ALWAYS` vs `DEVICE_SETTINGS`), verificación de permiso de superposición y consola de telemetría en vivo.
- **Motor Nativo Android (Kotlin):**
  - `AlarmActivity.kt` + `activity_alarm.xml`: Despertar físico sobre pantalla bloqueada (`setShowWhenLocked`, `setTurnScreenOn`, `SCREEN_BRIGHT_WAKE_LOCK`).
  - `SentinelAlarmReceiver.kt`: Bucle perpetuo con `AlarmManager.setAlarmClock` cada 60s que verifica precios de Take Profit y cada 3 ciclos (~3 min) ejecuta `scanSmartEngineSPlus1H()` en segundo plano.
  - `SentinelAudioManager.kt`: Singleton de audio en `USAGE_ALARM` con bucle garantizado y vibración táctica.

## 3. Comandos de Compilación y Despliegue
- Verificación estática: `flutter analyze`
- Compilación optimizada: `flutter build apk --release --split-per-abi`
- Repositorio Remoto: `https://github.com/crucies/micripto_sentinel.git`
- Destino local de APKs: `C:\Richard\A\Aplicaciones Moviles\APKs\micripto_sentinel_vX.Y.Z_[tag].apk`
