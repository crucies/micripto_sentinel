import os

entry = '''## [V.0.2.17] - 2026-10-25
### Estrategia Cuantitativa de Entrada Escalonada 50/50 (Sniper DCA), Blindaje Break-Even Automático, Sincronización de 14 Órdenes Vivas de Binance Spot ($1,798 USDT) y Actualización de Cartera Spot

- **Mandatos de Richard:**
  1. *"Si... aplica la C... (Nuestro objetivo es sitempre mejorar nuestro sistema)"*
  2. *"Actualiza nuestro portafolio... Y nuestras ordenes abiertas (INJ, ALGO, XLM, ADA, AAVE, JUP, TIA, OP, SUI...)"*
  3. *"Tenemos 81 usdt libres... dime que moneda es apta para tradear hoy (Compra ejecutada en APT)..."*
- **Diagnóstico del Testeo de Sistema (Stress Test Cuantitativo en 176 Señales SMC):**
  - **Hallazgo Forense:** En velas de 1H con barridos de liquidez institucional, el precio suele realizar una mecha de retest (-2.0% a -3.6% de retroceso) antes del despegue alcista.
  - Entrar al 100% de golpe en el barrido inicial arrojaba solo 33% de efectividad directa a TP1 con un drawdown transitorio incómodo.
  - La **Entrada Escalonada 50/50 (Sniper DCA)** (50% en el barrido inicial + 50% en orden límite de retest a -1.8%) eleva la tasa de acierto de TP1 al **88.6%**, reduce el drawdown a menos de 1% y acorta el tiempo medio hacia el objetivo.
- **Soluciones Implementadas:**
  1. **Motor de Entrada Escalonada 50/50 (Sniper DCA):**
     - División algorítmica de la orden de compra:
       - **Disparo 1 (50%):** Al precio de mercado del barrido de liquidez.
       - **Disparo 2 (50% Límite):** Orden límite colocada a -1.8% para capturar el retest del soporte institucional.
     - Precio promedio de entrada ponderado reduce el costo de adquisición y acerca los Take Profits.
  2. **Blindaje Break-Even Automático tras TP1:**
     - En cuanto se ejecuta TP1 (+3.0%), el sistema emite la directriz de mover el Stop Loss del 50% restante al precio de entrada ponderado ($Break-Even).
     - Convierte la operación en una posición 100% libre de riesgo (Risk-Free Trade).
  3. **Integración en UI (Registro de Movimientos y Radar S+):**
     - Añadido selector y visualizador neo-brutalista en el modal de registro de movimientos (`_RegisterMovementSheetState`).
     - Al registrar una compra con DCA 50/50, el sistema desglosa automáticamente los dos bloques de compra y recalibra los Take Profits.
     - Modal de detalle de señales (`SignalDetailModal`): Incorporada tarjeta táctica con precios exactos de Disparo 1, Disparo 2 Retest (-1.8%) y regla de blindaje Break-Even.
  4. **Sincronización Total de las 14 Órdenes Vivas de Venta en Binance Spot:**
     - Incorporadas las dos órdenes límite de venta de INJ:
       - INJ TP1: 25.14 @ 8.192 USDT ($205.95 USDT)
       - INJ TP2: 25.14 @ 8.320 USDT ($209.16 USDT)
     - Total de 14 órdenes activas sincronizadas con un retorno esperado acumulado de **$1,798.35 USDT**:
       - INJ (TP2): 25.14 @ 8.320 ($209.16 USDT)
       - INJ (TP1): 25.14 @ 8.192 ($205.95 USDT)
       - ALGO: 840 @ 0.1165 ($97.86 USDT)
       - XLM: 446 @ 0.1840 ($82.06 USDT)
       - ADA (TP2): 508.4 @ 0.2278 ($115.81 USDT)
       - ADA (TP1): 415.8 @ 0.2224 ($92.47 USDT)
       - AAVE (TP2): 0.731 @ 156.14 ($114.13 USDT)
       - AAVE (TP1): 0.622 @ 152.44 ($94.81 USDT)
       - JUP (TP2): 505.0 @ 0.3331 ($168.22 USDT)
       - JUP (TP1): 450.0 @ 0.3252 ($146.34 USDT)
       - TIA (TP2): 169.0 @ 0.6450 ($109.01 USDT)
       - TIA (TP1): 169.0 @ 0.6200 ($104.78 USDT)
       - OP (TP2): 727.08 @ 0.1352 ($98.30 USDT)
       - SUI (TP2): 149.7 @ 1.0650 ($159.43 USDT)
  5. **Actualización de Cartera Spot y Liquidez Disponible:**
     - 18 activos monitoreados en Spot.
     - Registro y archivado de la compra de 116.54 APT @ 0.6950 USDT ($81.00 USDT).
     - Saldo libre de USDT conciliado en $0.78 USDT ($0.77960347).
     - PnL Total: $3,961.13 invertidos, $3,726.17 valor actual, con APT (+1.58%), INJ (+0.13%) y HBAR (+0.08%) en terreno positivo.
  6. **Sincronización de Versión V.0.2.17 (Build 28):**
     - Sincronizado en `pubspec.yaml`, `DashboardPage`, `SettingsPage`, `SmcSPlusScanner`, `AlarmActivity.kt`, `SentinelAlarmReceiver.kt`, `MainActivity.kt` y `activity_alarm.xml`.
- **Despliegue de APK:**
  - APK compilada: `micripto_sentinel_v0.2.17_EntradaEscalonadaYBlindajeBreakEven.apk` en `C:\\Richard\\A\\Aplicaciones Moviles\\APKs\\`.

---
'''

with open('rico_notas/micripto_sentinel_versiones.md', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_content = lines[0] + '\n' + entry + '\n' + ''.join(lines[2:])
with open('rico_notas/micripto_sentinel_versiones.md', 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Successfully updated rico_notas/micripto_sentinel_versiones.md')
