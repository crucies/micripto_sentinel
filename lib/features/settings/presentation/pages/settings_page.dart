import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/native_alarm_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _soundMode = 'ALWAYS';
  String _logs = 'Cargando registros...';
  bool _isLoadingLogs = false;
  bool _hasOverlayPermission = false;
  bool _isIgnoringBattery = false;
  bool _hasExactAlarmPermission = true;
  bool _isForegroundRunning = false;
  int _testCountdown = 0;
  Timer? _testTimer;
  bool _soundSPlus = true;
  bool _soundS = false;
  bool _soundA = false;
  double _tradeAmount = 100.0;
  late TextEditingController _tradeAmountController;

  @override
  void initState() {
    super.initState();
    _tradeAmountController = TextEditingController(text: '100');
    _loadSettings();
    _refreshLogs();
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _tradeAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final mode = await NativeAlarmService.getSoundMode();
    final hasOverlay = await NativeAlarmService.checkOverlayPermission();
    final isIgnoring = await NativeAlarmService.isIgnoringBatteryOptimizations();
    final hasExact = await NativeAlarmService.checkExactAlarmPermission();
    final fgRunning = await NativeAlarmService.isForegroundServiceRunning();
    final sPlus = await NativeAlarmService.getBoolSetting('alarm_sound_s_plus', defaultValue: true);
    final s = await NativeAlarmService.getBoolSetting('alarm_sound_s', defaultValue: false);
    final a = await NativeAlarmService.getBoolSetting('alarm_sound_a', defaultValue: false);
    final amt = await NativeAlarmService.getDoubleSetting('default_trade_amount_usdt', defaultValue: 100.0);

    if (mounted) {
      setState(() {
        _soundMode = mode;
        _hasOverlayPermission = hasOverlay;
        _isIgnoringBattery = isIgnoring;
        _hasExactAlarmPermission = hasExact;
        _isForegroundRunning = fgRunning;
        _soundSPlus = sPlus;
        _soundS = s;
        _soundA = a;
        _tradeAmount = amt > 0 ? amt : 100.0;
        _tradeAmountController.text = _tradeAmount.toStringAsFixed(0);
      });
    }
  }

  void _startLockscreenTest() {
    setState(() => _testCountdown = 5);
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_testCountdown > 1) {
        setState(() => _testCountdown--);
      } else {
        timer.cancel();
        setState(() => _testCountdown = 0);
      }
    });

    NativeAlarmService.scheduleTestAlarm(
      delaySeconds: 5,
      eventType: 'TP_HIT',
      symbol: 'AAVE (TP1)',
      price: '\$152.4400',
      amount: '0.6220 AAVE (\$94.82 USDT)',
      targetPrice: '\$152.4400',
      projectedProfit: '+\$2.97 USDT (+3.23%)',
      totalProfit: '+\$31.91 USDT',
      liquidCash: '\$78.45 USDT',
      tp1Price: '\$152.4400',
      tp2Price: '\$156.1400',
      slPrice: '\$147.6700',
      limitBuyPrice: '\$147.6700',
      tradeAmount: 94.82,
      buyPrice: '\$147.6700',
      buyDate: '2026-10-22 07:36:24 BOT',
      sellDate: '2026-10-22 15:00:00 BOT',
      elapsedTime: '0d 7h 24m',
      appVersion: 'V 0.2.17',
      totalCoins: '0.6220',
    );
  }

  Future<void> _setSoundSignalQuality({bool? sPlus, bool? s, bool? a}) async {
    if (sPlus != null) {
      setState(() => _soundSPlus = sPlus);
      await NativeAlarmService.setBoolSetting('alarm_sound_s_plus', sPlus);
    }
    if (s != null) {
      setState(() => _soundS = s);
      await NativeAlarmService.setBoolSetting('alarm_sound_s', s);
    }
    if (a != null) {
      setState(() => _soundA = a);
      await NativeAlarmService.setBoolSetting('alarm_sound_a', a);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.ink,
        duration: Duration(seconds: 2),
        content: Text(
          '💾 Disparo de alarmas por calidad actualizado.',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Color(0xFF00E5FF),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTradeAmount(double amt) async {
    setState(() => _tradeAmount = amt);
    _tradeAmountController.text = amt.toStringAsFixed(0);
    await NativeAlarmService.setDoubleSetting('default_trade_amount_usdt', amt);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        content: Text(
          '💾 Monto por defecto actualizado: \$${amt.toStringAsFixed(0)} USDT',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Color(0xFF00E5FF),
          ),
        ),
      ),
    );
  }

  Future<void> _setSoundMode(String mode) async {
    await NativeAlarmService.setSoundMode(mode);
    if (mounted) {
      setState(() {
        _soundMode = mode;
      });
      final modeMsg = mode == 'ALWAYS'
          ? '🔊 Modo: Sonar Siempre (Fuerza volumen de alarma al 100%)'
          : (mode == 'TOTAL_SILENCE'
              ? '🛑 Modo: Silencio Total (Ninguna alarma suena ni despierta la pantalla)'
              : '🔕 Modo: Sonar según configuración del teléfono (Silencio en reuniones)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            modeMsg,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: AppColors.gold,
            ),
          ),
        ),
      );
    }
    _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _isLoadingLogs = true;
    });
    final logs = await NativeAlarmService.getLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    await NativeAlarmService.clearLogs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            '🗑️ Registros de telemetría borrados.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    _refreshLogs();
  }

  Future<void> _copyLogs() async {
    await Clipboard.setData(ClipboardData(text: _logs));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            '📋 ¡Log completo copiado al portapapeles! Pégalo en el chat de Kai.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              bottom: BorderSide(color: AppColors.ink, width: 3.0),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: AppColors.brutalistBox(
                      color: AppColors.gold,
                      borderWidth: 2.5,
                      shadowOffset: 3.0,
                    ),
                    child: const Text(
                      '⚙️ AJUSTES & TELEMETRÍA',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: AppColors.ink,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _refreshLogs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: AppColors.brutalistBox(
                        color: AppColors.surface,
                        borderWidth: 2.0,
                        shadowOffset: 3.0,
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.refresh, color: AppColors.ink, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'RECARGAR',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Simulador y Prueba Táctica de Despertador en Bloqueo (Richard & Kai)
            _buildLockscreenTestCard(),

            const SizedBox(height: 22),

            // 1. Selector Brutalista de Comportamiento del Sonido
            _buildSoundModeCard(),

            const SizedBox(height: 22),

            // 1B. Disparo de Alarmas Sonoras por Calidad de Señal
            _buildAlarmSignalQualityCard(),

            const SizedBox(height: 22),

            // 1C. Monto a Comprar por Defecto (Cálculo de Ganancia)
            _buildTradeAmountCard(),

            const SizedBox(height: 22),

            // 2. Estado de Permisos Críticos del Sistema (Despertar en Bloqueo)
            _buildPermissionsCard(),

            const SizedBox(height: 22),

            // 2B. Optimización de Batería (Doze Mode 24/7)
            _buildBatteryOptimizationCard(),

            const SizedBox(height: 22),

            // 2C. Permiso de Alarmas y Recordatorios Exactos (Android 12+)
            _buildExactAlarmCard(),

            const SizedBox(height: 22),

            // 2D. Servicio Nativo en Primer Plano 24/7 (Red & CPU Continua)
            _buildForegroundServiceCard(),

            const SizedBox(height: 22),

            // 3. Consola Brutalista de Telemetría y Logs del Sistema
            _buildLogViewerCard(),

            const SizedBox(height: 24),

            // 4. Tarjeta de Versión y Autoría según Protocolo (Sección Ajustes)
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundModeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: AppColors.surface,
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.ink,
            child: Row(
              children: const [
                Icon(Icons.volume_up, color: AppColors.gold, size: 16),
                SizedBox(width: 8),
                Text(
                  'PERFIL DE SONIDO TÁCTICO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Elige cómo debe reaccionar la alarma sonora ante las órdenes de Binance:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Opción 1: Sonar siempre
          _buildSoundOption(
            title: '🔊 SONAR SIEMPRE (MÁXIMA PRIORIDAD)',
            subtitle: 'Fuerza el volumen de la alarma al 100%, sonando incluso si el teléfono está en modo Silencio o No Molestar.',
            value: 'ALWAYS',
            activeBg: AppColors.gold,
          ),

          const SizedBox(height: 12),

          // Opción 2: Sonar según configuración del teléfono
          _buildSoundOption(
            title: '📳 SEGÚN CONFIGURACIÓN DEL TELÉFONO',
            subtitle: 'En iglesia o reunión con teléfono en silencio/vibración, respeta el perfil del sistema.',
            value: 'DEVICE_SETTINGS',
            activeBg: AppColors.orangeSoft,
          ),

          const SizedBox(height: 12),

          // Opción 3: Silencio Total
          _buildSoundOption(
            title: '🛑 SILENCIO TOTAL (NINGUNA ALARMA)',
            subtitle: 'Ninguna alarma suena ni despierta la pantalla. Para cuando estés sin fondos disponibles, en reuniones críticas o en la iglesia.',
            value: 'TOTAL_SILENCE',
            activeBg: const Color(0xFFFF8A80),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundOption({
    required String title,
    required String subtitle,
    required String value,
    required Color activeBg,
  }) {
    final isSelected = _soundMode == value;
    return GestureDetector(
      onTap: () => _setSoundMode(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? AppColors.brutalistBox(
                color: activeBg,
                borderWidth: 2.5,
                shadowOffset: 4.0,
              )
            : AppColors.brutalistCell(
                color: AppColors.surface,
                borderWidth: 2.0,
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: AppColors.brutalistCell(
                color: isSelected ? AppColors.ink : AppColors.surfaceLight,
                borderWidth: 2.0,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 15,
                        color: AppColors.gold,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: _hasOverlayPermission ? AppColors.surface : AppColors.orangeSoft,
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: AppColors.ink, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PERMISO PANTALLA',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: AppColors.brutalistCell(
                  color: _hasOverlayPermission ? AppColors.gold : AppColors.orange,
                  borderWidth: 2.0,
                ),
                child: Text(
                  _hasOverlayPermission ? 'ACTIVO' : 'REQUERIDO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _hasOverlayPermission ? AppColors.ink : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Container(
            height: 2.0,
            color: AppColors.ink,
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
          Text(
            _hasOverlayPermission
                ? '✅ El permiso de "Aparecer encima" está concedido. Sentinel tiene autorización total de Android para elevar el formulario Neo-Brutalista sobre el bloqueo.'
                : '⚠️ Para que Android permita encender la pantalla y mostrar el formulario sin pedir clave previa, es indispensable conceder el permiso "Aparecer encima de otras apps".',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (!_hasOverlayPermission) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await NativeAlarmService.requestOverlayPermission();
                await Future.delayed(const Duration(seconds: 1));
                _loadSettings();
              },
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: AppColors.brutalistBox(
                  color: AppColors.orange,
                  borderWidth: 2.5,
                  shadowOffset: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.settings, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'CONCEDER PERMISO EN ANDROID',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatteryOptimizationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: _isIgnoringBattery ? AppColors.surface : AppColors.orangeSoft,
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.battery_charging_full, color: AppColors.ink, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'BATERÍA Y RED 24/7',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: AppColors.brutalistCell(
                  color: _isIgnoringBattery ? AppColors.gold : AppColors.orange,
                  borderWidth: 2.0,
                ),
                child: Text(
                  _isIgnoringBattery ? 'SIN RESTRICCIÓN' : 'OPTIMIZADO ⚠️',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _isIgnoringBattery ? AppColors.ink : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Container(
            height: 2.0,
            color: AppColors.ink,
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
          Text(
            _isIgnoringBattery
                ? '✅ Optimización de batería desactivada. Android permite a Sentinel consultar Binance por internet y mantener la CPU activa para sonar 24/7 incluso con el teléfono bloqueado.'
                : '⚠️ Android suspende el acceso a internet cuando el teléfono entra en suspensión profunda (Doze Mode). Es indispensable seleccionar "Sin Restricciones / No Optimizar" para que la alarma suene en segundo plano.',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (!_isIgnoringBattery) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await NativeAlarmService.requestIgnoreBatteryOptimizations();
                await Future.delayed(const Duration(seconds: 1));
                _loadSettings();
              },
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: AppColors.brutalistBox(
                  color: AppColors.orange,
                  borderWidth: 2.5,
                  shadowOffset: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.bolt, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'PERMITIR EN SEGUNDO PLANO (SIN RESTRICCIONES)',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLockscreenTestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: _testCountdown > 0 ? AppColors.gold : const Color(0xFFE0F7FA),
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.ink,
            child: Row(
              children: const [
                Icon(Icons.alarm_on, color: AppColors.gold, size: 16),
                SizedBox(width: 8),
                Text(
                  'SIMULADOR DE DESPERTADOR EN BLOQUEO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Comprueba en persona que el Centinela enciende tu pantalla física y suena cuando el teléfono está bloqueado en tu bolsillo:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (_testCountdown > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: AppColors.brutalistBox(
                color: AppColors.orange,
                borderWidth: 2.5,
                shadowOffset: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '¡BLOQUEA TU TELÉFONO AHORA! ($_testCountdown s)',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _startLockscreenTest,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: AppColors.brutalistBox(
                  color: AppColors.ink,
                  borderWidth: 2.5,
                  shadowOffset: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock_clock, size: 18, color: AppColors.gold),
                    SizedBox(width: 8),
                    Text(
                      '🔒 PROBAR DESPERTADOR (5 SEGUNDOS)',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExactAlarmCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: _hasExactAlarmPermission ? AppColors.surface : AppColors.orangeSoft,
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_alarm, color: AppColors.ink, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ALARMAS EXACTAS (ANDROID 12+)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: AppColors.brutalistCell(
                  color: _hasExactAlarmPermission ? AppColors.gold : AppColors.orange,
                  borderWidth: 2.0,
                ),
                child: Text(
                  _hasExactAlarmPermission ? 'CONCEDIDO' : 'REQUERIDO ⚠️',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _hasExactAlarmPermission ? AppColors.ink : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Container(
            height: 2.0,
            color: AppColors.ink,
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
          Text(
            _hasExactAlarmPermission
                ? '✅ Autorización de alarmas exactas concedida. El AlarmManager de Android puede despertar el CPU al segundo exacto en Doze Mode.'
                : '⚠️ En Android 12+, el sistema retrasa las alarmas a menos que el usuario autorice "Alarmas y recordatorios exactos".',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (!_hasExactAlarmPermission) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await NativeAlarmService.requestExactAlarmPermission();
                await Future.delayed(const Duration(seconds: 1));
                _loadSettings();
              },
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: AppColors.brutalistBox(
                  color: AppColors.orange,
                  borderWidth: 2.5,
                  shadowOffset: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.alarm_add, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'PERMITIR ALARMAS EXACTAS EN AJUSTES',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForegroundServiceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: _isForegroundRunning ? const Color(0xFFE8F5E9) : AppColors.surface,
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.ink, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SERVICIO 24/7 EN PRIMER PLANO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: AppColors.brutalistCell(
                  color: _isForegroundRunning ? const Color(0xFF10B981) : AppColors.gold,
                  borderWidth: 2.0,
                ),
                child: Text(
                  _isForegroundRunning ? 'ACTIVO 24/7' : 'EN VIGILANCIA',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _isForegroundRunning ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          Container(
            height: 2.0,
            color: AppColors.ink,
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
          const Text(
            'El Servicio en Primer Plano mantiene viva la conexión a Binance incluso con la pantalla apagada, escaneando órdenes cada 20s y Radar S+ cada 2m.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              await NativeAlarmService.startNativeBackgroundScan();
              await Future.delayed(const Duration(milliseconds: 500));
              _loadSettings();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.ink,
                  content: Text(
                    '🛡️ Servicio en Primer Plano 24/7 reiniciado.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: AppColors.brutalistBox(
                color: AppColors.surface,
                borderWidth: 2.0,
                shadowOffset: 3.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.restart_alt, size: 16, color: AppColors.ink),
                  SizedBox(width: 8),
                  Text(
                    'REINICIAR SERVICIO NATIVO 24/7',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogViewerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: AppColors.surface,
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.terminal, color: AppColors.ink, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'AUDITORÍA & REGISTRO DE EVENTOS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              if (_isLoadingLogs)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.orange),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Registro en milisegundos de alarmas, WakeLocks, FullScreenIntent y FCM:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Consola de Logs con contraste brutalista
          Container(
            height: 210,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: AppColors.brutalistCell(
              color: AppColors.ink,
              borderWidth: 2.5,
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _logs,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.gold,
                  height: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botones de Acción del Log en Grilla 50% / 50%
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _copyLogs,
                  child: Container(
                    height: 44,
                    decoration: AppColors.brutalistBox(
                      color: AppColors.gold,
                      borderWidth: 2.0,
                      shadowOffset: 3.5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.copy, size: 15, color: AppColors.ink),
                        SizedBox(width: 6),
                        Text(
                          'COPIAR LOG',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _clearLogs,
                  child: Container(
                    height: 44,
                    decoration: AppColors.brutalistBox(
                      color: AppColors.orange,
                      borderWidth: 2.0,
                      shadowOffset: 3.5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.delete_outline, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'BORRAR LOG',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmSignalQualityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: AppColors.surface,
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.ink,
            child: Row(
              children: const [
                Icon(Icons.tune, color: Color(0xFF00E5FF), size: 16),
                SizedBox(width: 8),
                Text(
                  'DISPARO DE ALARMAS POR CALIDAD',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: Color(0xFF00E5FF),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Elige qué calidades de señal harán sonar el teléfono y despertarán la pantalla al detectarse en segundo plano (puedes combinar las que desees):',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Checkbox S+ (>=90%)
          _buildQualityCheckbox(
            label: '⭐ GRADO S+ (CONFLUENCIA >= 90%)',
            subtitle: 'Sonar Cuántico forzado. Barrida 2do toque + CHoCH + RSI div + Descuento 48h (92.3% WR).',
            color: const Color(0xFF00E5FF),
            isSelected: _soundSPlus,
            onChanged: (val) => _setSoundSignalQuality(sPlus: val),
          ),

          const SizedBox(height: 10),

          // Checkbox S (80-89%)
          _buildQualityCheckbox(
            label: '🟢 GRADO S (CONFLUENCIA 80-89%)',
            subtitle: 'Suelo institucional de alta probabilidad (cercanía <= 1.5% del suelo).',
            color: const Color(0xFF10B981),
            isSelected: _soundS,
            onChanged: (val) => _setSoundSignalQuality(s: val),
          ),

          const SizedBox(height: 10),

          // Checkbox A (70-79%)
          _buildQualityCheckbox(
            label: '🟡 GRADO A (CONFLUENCIA 70-79%)',
            subtitle: 'Entrada moderada en retroceso técnico hacia soporte fractal.',
            color: AppColors.gold,
            isSelected: _soundA,
            onChanged: (val) => _setSoundSignalQuality(a: val),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCheckbox({
    required String label,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.ink.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                border: Border.all(color: AppColors.ink, width: 2.0),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: AppColors.ink)
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: AppColors.surface,
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.ink,
            child: Row(
              children: const [
                Icon(Icons.attach_money, color: AppColors.gold, size: 16),
                SizedBox(width: 8),
                Text(
                  'MONTO DE COMPRA POR DEFECTO (USDT)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: AppColors.gold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Monto base para calcular automáticamente la ganancia esperada (TP1 +3% y TP2 +5.5%) en cada tarjeta del Radar de Señales:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.ink, width: 2.0),
                  ),
                  child: TextField(
                    controller: _tradeAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '\$ ',
                      suffixText: 'USDT',
                      prefixStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                      suffixStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    final p = double.tryParse(_tradeAmountController.text.trim());
                    if (p != null && p > 0) {
                      _saveTradeAmount(p);
                    }
                  },
                  child: Container(
                    height: 44,
                    decoration: AppColors.brutalistBox(
                      color: AppColors.gold,
                      borderWidth: 2.0,
                      shadowOffset: 2.0,
                    ),
                    child: const Center(
                      child: Text(
                        '💾 GUARDAR',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Chips rápidos de selección
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [50.0, 100.0, 200.0, 500.0].map((amt) {
              final isSel = _tradeAmount == amt;
              return GestureDetector(
                onTap: () => _saveTradeAmount(amt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.ink : Colors.white,
                    border: Border.all(color: AppColors.ink, width: 1.8),
                  ),
                  child: Text(
                    '\$${amt.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: isSel ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: AppColors.gold,
        borderWidth: 3.0,
        shadowOffset: 5.0,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: AppColors.ink,
            child: const Text(
              'MiCripto Sentinel • V.0.2.17',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Terminal Táctica Móvil de Vigilancia Binance Spot',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Alianza Richard & Kai — Protocolo Antigravity 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
