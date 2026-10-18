# 🧭 Manual de Reconstrucción (Prompt Kai) — MiCripto Sentinel

## 1. Identidad y Propósito
**MiCripto Sentinel** es la terminal centinela móvil complementaria de **MiCripto LTS**.
Su misión es monitorear permanentemente el estado de las órdenes en Binance Spot y despertar físicamente el teléfono celular de Richard (incluso con pantalla bloqueada y en reposo profundo Doze Mode) ante 3 eventos críticos:
1. **Compra en suelo de liquidez ejecutada (`BUY_FILLED`):** Despliega el formulario táctico indicando el precio exacto de Take Profit a plantar en Binance.
2. **Take Profit alcanzado (`TP_HIT`):** Notifica la ganancia limpia en USDT de la operación actual y el total acumulado en la cartera.
3. **Alerta Alfa Grado S+ (`S_PLUS_ALPHA`):** Señal de máxima probabilidad institucional (Score >= 90) para colocar compras de francotirador.

## 2. Pila Tecnológica
- **Framework UI:** Flutter 3.41+ (Dart 3.11+) con Clean Architecture.
- **Motor Nativo Android:** Kotlin con `AlarmActivity.kt`, `WakeLock` (`ACQUIRE_CAUSES_WAKEUP`), `KeyguardManager` y `MediaPlayer` (`USAGE_ALARM`).
- **Enlace Remoto en la Nube:** Firebase Cloud Messaging (FCM) con `SentinelFirebaseService.kt`, push prioritario (`priority: high`), auto-suscripción al tópico `/topics/sentinel_alerts` y `setFullScreenIntent`.
- **Layout Nativo:** `activity_alarm.xml` para despliegue instantáneo sobre Keyguard.
- **Canal de Comunicación:** `MethodChannel('com.richard.micripto/sentinel_alarm')`.

## 3. Comandos de Compilación y Verificación
- Verificación estática: `flutter analyze`
- Compilación de Release: `flutter build apk --release`
- Destino de Entrega: `C:\Richard\A\Aplicaciones Moviles\APKs\micripto_sentinel_V.X.Y.Z_[tag].apk`
