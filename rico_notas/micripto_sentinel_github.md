# 🚀 Registro de Despacho GitHub — MiCripto Sentinel

## Estado de Sincronización Remota
- **Repositorio Remoto:** `https://github.com/crucies/micripto_sentinel.git`
- **Rama:** `master`
- **Rango de Sincronización:** `V.0.1.6 ➔ V.0.1.8`
- **Versión Despachada Actual:** `V.0.1.8` (`0.1.8+9`)
- **Fecha de Despacho:** 2026-10-20
- **Anfitrión / Autores:** Richard Coronado & Kai (Protocolo Antigravity)

---

## 📦 Resumen Consolidado de Cambios Acumulados (`V.0.1.6 ➔ V.0.1.8`)

### 1. Motor Cuantitativo `Smart Engine 2.2 (S+ >= 90%, 92.3% WR)` On-Device (`V.0.1.7` – `V.0.1.8`):
- **Escáner Autónomo 1H en Flutter (`lib/core/services/smc_s_plus_scanner.dart`) y Kotlin Nativo (`SentinelAlarmReceiver.kt`):**
  - Consulta directa cada **3 minutos** a `api.binance.com/api/v3/klines?interval=1h&limit=100` para los 10 activos institucionales (`RENDER`, `SUI`, `NEAR`, `PENDLE`, `XRP`, `ONDO`, `TAO`, `FET`, `ETH`, `BTC`), operando incluso en Doze Mode con pantalla bloqueada y sin depender de cron jobs externos en Vercel.
- **Paridad Matemática 100% Web-Móvil (`smcEngine.ts` == `SmcSPlusScanner.dart` == `SentinelAlarmReceiver.kt`):**
  - Detección fractal `lookback = 4`, descarte inmediato (`break`) si un Swing Low `1H` ya fue barrido en horas previas (evitando falsos positivos en pisos gastados como `TAO`), filtro de descuento $\ge 3.5\%$, confirmación `CHoCH` envolvente (`close > prevHigh`) y divergencia/sobreventa `RSI(14)`.
- **Nueva Pestaña Central `RADAR S+` (`lib/features/radar/presentation/pages/radar_s_plus_page.dart`):**
  - Jerarquía cromática institucional estricta: **$\ge 90\%$ (`GRADO S+`) en Celeste/Turquesa (`#00E5FF`)**, **$80\%–89\%$ (`GRADO S`) en Verde Esmeralda (`#10B981`)**, y **$70\%–79\%$ (`GRADO A`) en Ámbar/Oro (`#FFD600`)**.
  - Ficha completa de ejecución **OCO en Binance** (`Suelo 1H`, `TP1 +3.0%`, `TP2 +5.5%`, `OCO SL Trigger -2.8%`, `OCO SL Limit -2.95%`) y botón de prueba física de bloqueo en 5s por moneda.

### 2. Sincronización de Saldo Libre Spot (`$0.91 USDT`) y Edición Táctil Directa (`V.0.1.8`):
- **Sincronización Nube + Local:** El recuadro `SALDO LIBRE SPOT` refleja `$0.91 USDT` por defecto, se sincroniza con `metrics.liquidCashUsdt` desde `https://micripto-lts.vercel.app/api/orders` y permite edición manual instantánea con 1 toque sobre la tarjeta en el Dashboard.
- **7 Órdenes Vivas en Binance Spot:** `SUI TP2 ($1.0540)`, `SUI TP1 ($1.0280)`, `RENDER TP2 ($1.8600)`, `PENDLE ($2.1900)`, `SUI Lote 1 ($1.0650)`, `XRP ($1.3580)` y `ONDO ($0.4880)`.

---

## 📜 Historial de Despachos Previos

### Despacho `V.0.1.6` (2026-10-18)
- **Sincronización Dinámica en la Nube con MiCripto LTS (`SentinelAutoScanner.dart`):** Descarga automática de órdenes vivas desde `https://micripto-lts.vercel.app/api/orders` y escaneo continuo cada 25s en primer plano / 60s en segundo plano (`AlarmManager.setAlarmClock`).
- **Mejoras Visuales Neo-Brutalistas:** Barra de progreso táctica hacia el TP en cada tarjeta, protección `FittedBox` en montos de bóveda y estética **Money Magnet** (`#FFF8E7`, `#FFFFFF`, `#FFD600`, `#FF5500`, `#0A0A0A`).
