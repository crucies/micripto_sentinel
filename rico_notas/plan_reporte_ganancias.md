# Plan de Implementación: Módulo de Reportes de Ganancias en App

## 1. Objetivo
Implementar una 4ta pestaña en la barra de navegación principal de la app (`REPORTES`) que muestre un reporte financiero y contable en tiempo real de las órdenes ejecutadas en Binance Spot, con el cálculo neto exacto:
$$\text{Monto Ganado} = \text{Total Venta Cobrado} - \text{Costo de Compra} - \text{Comisión Binance Spot}$$
y permitir filtrar dinámicamente por **Fecha** y por **Moneda**, calculando la sumatoria total en tiempo real según los filtros activos.

## 2. Columnas Exactas del Reporte (Diseño Compacto sin Scroll Horizontal Excesivo)
1. **Fecha:** Formato natural solicitado (`Mi 21 de Oct del 26`, `Ma 20 de Oct del 26`, etc.).
2. **Moneda:** Símbolo del activo (`OP`, `SUI`, `ONDO`, `RENDER`, etc.).
3. **Tipo de Señal:** Etiqueta distintiva (`S+`, `S`, etc.).
4. **Duración:** Tiempo transcurrido entre orden colocada y ejecutada (`N D N H N M`).
5. **Monto Ganado:** Valor neto exacto en USDT (`+NN.NNNN USDT`), con indicador visual verde brutalista.

## 3. Componentes a Crear y Modificar
1. **Entidad de Dominio / Helper de Cálculo:**
   - Asegurar que `OrderEntity` o el servicio de reportes calcule:
     - `netProfitUsdt = expectedReturnUsdt - costBasis - binanceFee` (donde `costBasis = entryPrice * amountCoins` y `binanceFee = (expectedReturnUsdt + costBasis) * 0.001` o comisión real 0.1% Spot).
     - Formato de fecha natural en español: `DateFormat('EEE dd \'de\' MMM \'del\' yy', 'es_ES')` o formateador limpio nativo.
     - Cálculo de duración en días, horas y minutos (`${d} D ${h} H ${m} M`).
2. **Nueva Pantalla (`lib/features/reports/presentation/pages/profit_reports_page.dart`):**
   - **Cabecera Brutalista:** Indicador de versión `V.0.2.10`, título `REPORTE DE GANANCIAS`.
   - **Card de Total Ganado Dinámico:** Caja grande brutalista dorada/verde que muestra la suma del `Monto Ganado` de todas las órdenes que cumplan los filtros actuales.
   - **Filtros Interactivos:**
     - Selector por Moneda: Chips horizontales (`TODAS`, `OP`, `SUI`, `ONDO`, `RENDER`, etc.).
     - Selector por Período: Chips (`TODAS`, `HOY`, `ESTA SEMANA`, `ESTE MES`) y selector de rango de fechas personalizado.
   - **Listado / Tabla de Órdenes:**
     - Cabecera de columnas clara: `FECHA` | `MONEDA` | `SEÑAL` | `DURACIÓN` | `GANANCIA NETA`.
     - Filas brutalistas estilizadas con datos alineados, tipografía monospace y espaciado optimizado para que no requiera scroll horizontal.
     - Estado vacío elegante si ningún registro coincide con los filtros.
3. **Barra de Navegación (`MainNavigationPage`):**
   - Actualizar a 4 pestañas:
     - Tab 0: `ÓRDENES` (Icono `Icons.candlestick_chart`)
     - Tab 1: `RADAR` (Icono `Icons.radar`)
     - Tab 2: `REPORTES` (Icono `Icons.bar_chart_rounded` o `Icons.analytics_outlined`)
     - Tab 3: `AJUSTES` (Icono `Icons.tune`)
   - Ajustar textos e iconos para que la barra se vea equilibrada, limpia y sin desbordes.
4. **Actualización de Versión y Bitácora:**
   - Incrementar a `V.0.2.10 (Build 21)` en `pubspec.yaml`, cabecera, ajustes y alarmas.
   - Documentar en `rico_notas/micripto_sentinel_versiones.md`.
5. **Verificación y Compilación:**
   - `flutter analyze` (0 errores).
   - Generación de APK `micripto_sentinel_v0.2.10_ReporteGanancias.apk`.
