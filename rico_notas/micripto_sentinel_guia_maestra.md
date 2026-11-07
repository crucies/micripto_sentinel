# 🧭 MANIFIESTO Y GUÍA MAESTRA — ALIANZA RICHARD & KAI
**Proyecto:** MiCripto Sentinel  
**Entorno Operativo:** Binance Spot Trading & Centinela Autónomo  
**Protocolo:** Antigravity Senior Engineering  

---

## 🎯 PROPÓSITO FUNDAMENTAL Y CREDO OPERATIVO

> ### *"Nuestro objetivo es ganar dinero para satisfacer plenamente nuestras necesidades.*  
> *Abrir posiciones en Binance de compra/venta de criptomonedas con las que incrementemos nuestro capital de manera continua y segura.*  
> *Nuestro dinero no debe estar estancado por mucho tiempo en la transacción.*  
> *Compramos barato y vendemos a un mejor precio.*  
> *Nuestro compromiso Boy Scout hace que dejemos nuestro sistema mejor de como lo encontramos.*  
> ***+++ Siempre mejoramos nuestro proceso +++"***  
> — **Richard & Kai**

---

## 🏛️ LOS 5 PILARES NO NEGOCIABLES

### 1. 💰 Rentabilidad y Seguridad Continua del Capital
- Cada operación en Binance Spot tiene un propósito único: **generar liquidez real y hacer crecer el patrimonio** para satisfacer nuestras metas y bienestar.
- No operamos por apostar ni por emoción; operamos por confluencia matemática estricta y preservación de capital.
- Riesgo estrictamente acotado: Entrada calculada ($500 USDT estándar) con órdenes OCO y gestión defensiva.

### 2. ⚡ Política Cero-Estancamiento (Flujo de Capital Ágil)
- **El dinero estancado es dinero muerto:** Nuestro capital debe rotar de forma dinámica y eficiente.
- Evitamos activos en rangos muertos o tendencias bajistas prolongadas.
- Priorizamos movimientos rápidos hacia **Take Profit 1 (+3.0%)** y **Take Profit 2 (+5.5%)** en plazos cortos.
- Si un activo pierde su impulso o rompe estructura, el sistema lo descarta antes de comprometer liquidez.

### 3. 📉 Comprar Barato, Vender Más Caro (Smart Money Concepts)
- **Nunca perseguimos velas verdes ni compramos en euforia:**
  - Compramos en el **suelo institucional**, tras una barrida de liquidez (sweep) y confirmación de absorción (mechas $\ge 35\%$ y RSI divergente).
  - Compramos con descuento real en 48 horas ($\ge 3.5\%$).
- **Vendemos escalonadamente en resistencia:**
  - 50% de la posición en **TP1 (+3.0%)** para asegurar ganancias y recuperar capital libre.
  - 50% restante en **TP2 (+5.5%)** para maximizar el retorno de la corrida.

### 4. 🛡️ Validación Adversarial Implacable (Red Team)
- Antes de disparar una señal o arriesgar $500 USDT, la configuración debe sobrevivir al ataque del **Adversary Inquisitor**:
  - ¿Es una trampa de liquidez (*bull trap*)?
  - ¿Bitcoin está mostrando debilidad que arrastrará al activo?
  - ¿Hay muros de venta pesados antes del TP1?
- Si el Inquisidor encuentra riesgos críticos, la moneda queda **vetada**. Solo las monedas **Aprobadas S+** tienen derecho a sonar en nuestra alarma.

### 5. 🧹 Regla del Boy Scout & Evolución Perpetua
- **"Deja el sistema mejor de como lo encontraste":**
  - Cada intervención en el código, en la UI o en los modelos cuantitativos debe mejorar la arquitectura, limpiar deuda técnica y reforzar la robustez.
- **+++ Siempre mejoramos nuestro proceso +++:**
  - Aprendemos de cada ciclo de mercado.
  - Documentamos cada lección en `rico_notas/`.
  - La tecnología evoluciona, y nuestro Centinela evoluciona con ella para ser cada día más rápido, preciso e infalible.

---

## 🚨 PROTOCOLO Y ESPECIFICACIÓN DE ALARMAS MILITARES (RICHARD & KAI)

> **Regla de Operación:** Las órdenes que se abren en Binance Spot se copian o registran manualmente en la app móvil en sus tarjetas correspondientes. La app y el Centinela en segundo plano vigilan el precio de Binance Spot segundo a segundo 24/7 (incluso con el teléfono bloqueado y en Doze Mode).

Nuestras alarmas militares están diseñadas con un solo fin: **hacernos ganar dinero, proteger el capital y actuar con velocidad quirúrgica**. Deben sonar obligatoriamente en tres (3) escenarios:

### ⚡ Escenario 1: ORDEN DE COMPRA LÍMITE EJECUTADA EN BINANCE (`BUY_FILLED`)
- **Condición de Disparo:** Cuando el precio en vivo de Binance toca o cae por debajo del precio límite de la tarjeta (`curPrice <= targetPrice`).
- **Propósito Táctico Inmediato:** Avisar de inmediato a Richard que las monedas ya están en cartera para **entrar a Binance y colocar los respectivos Take Profit (TP1 y TP2)**.
- **Comportamiento en Pantalla:**
  1. Despierta físicamente la pantalla del teléfono con brillo máximo y audio militar forzado al 100%.
  2. Muestra el **Formulario de Compra de Richard**:
     - Moneda adquirida y precio exacto de compra ejecutado (ej. OP @ $0.1281).
     - Cantidad total de monedas en cartera (ej. 1,327.08 OP).
     - **Calcula de inmediato y presenta los dos valores listos para copiar en Binance**:
       - **TP1 Defensivo (+3.0%):** Venta del 50% de las monedas para asegurar ganancia y devolver liquidez a la Bóveda.
       - **TP2 Expansivo (+5.5%):** Venta del 50% restante para exprimir el rebote institucional hacia resistencia.
     - Botón táctico de acceso directo: **[ABRIR PAR EN BINANCE SPOT]**.

### 🎯 Escenario 2: ORDEN DE VENTA TAKE PROFIT EJECUTADA EN BINANCE (`TP_HIT`)
- **Condición de Disparo:** Cuando el precio en vivo de Binance sube y toca la meta fijada en la tarjeta (`curPrice >= targetPrice`).
- **Propósito Táctico Inmediato:** Avisar que **se cobró la ganancia en dólares reales**, actualizar el saldo libre disponible en USDT en la Bóveda, archivar la orden en el Historial y **habilitar el capital para buscar la siguiente entrada según las señales**.
- **Comportamiento en Pantalla:**
  1. Despierta físicamente la pantalla del teléfono con brillo máximo y sonido marcial.
  2. Muestra el **Formulario de Venta de Richard**:
     - Ganancia neta cobrada en la transacción (ej. +$17.57 USDT en ONDO, +$2.34 USDT en OP TP1).
     - Ganancia acumulada histórica total en el bolsillo.
     - Monto exacto de **Saldo Líquido Libre en USDT** disponible para reinversión inmediata.
     - Botón de archivo inmediato: **[ARCHIVAR EN HISTORIAL]**.

### 📡 Escenario 3: OPORTUNIDAD CUANTITATIVA IDENTIFICADA (`S_PLUS_ALPHA`)
- **Condición de Disparo:** Cuando una criptomoneda cumple estrictamente con los requisitos cuantitativos del Smart Engine 2.2 y el filtro del Reporte Adversarial, según el nivel de calidad que elijamos en la pantalla de **Ajustes**:
  - **Calidad S+ (Confluencia $\ge 90\%$):** Confluencia ultra-estricta con barrida de liquidez, rechazo de mecha $\ge 35\%$, RSI divergente y aprobación adversarial unánime. Ideal para entradas fuertes de $500 USDT.
  - **Calidad S (Confluencia $80-89\%$):** Rebote en zona de acumulación con buen ratio beneficio/riesgo.
  - **Calidad A (Confluencia $70-79\%$):** Configuración técnica preliminar apta para seguimiento táctico.
- **Propósito Táctico Inmediato:** Avisar a Richard que el mercado ha dejado un activo en suelo con alta probabilidad matemática para **abrir una orden de compra límite barata**.
- **Comportamiento en Pantalla:**
  1. Despierta la pantalla con sonido dedicado y título: **OPORTUNIDAD DETECTADA**.
  2. Presenta el Suelo Institucional 1H, el descuento de 48h, los niveles calculados de entrada y salida (TP1, TP2, Stop Loss OCO) y la disponibilidad líquida en USDT para ejecutar la orden en Binance.

---

## 📋 PROTOCOLO DIARIO DE SESIONES (1h Post-Apertura Bursátil)
- **10:30 BOT:** Auditoría Sesión Americana (Wall Street & ETFs Spot de Bitcoin).
- **22:00 BOT:** Auditoría Sesión Asiática (Tokio, Hong Kong & Singapur).
- **Vigilancia 24/7:** El Centinela custodia Binance Spot con alarma militar en segundo plano, protegiendo nuestro sueño, nuestro capital y nuestro tiempo.

---
*Este documento es el faro rector de cada decisión técnica, arquitectónica y operativa entre Richard y Kai.*
