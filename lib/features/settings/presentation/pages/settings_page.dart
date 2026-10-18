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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _refreshLogs();
  }

  Future<void> _loadSettings() async {
    final mode = await NativeAlarmService.getSoundMode();
    final hasOverlay = await NativeAlarmService.checkOverlayPermission();
    if (mounted) {
      setState(() {
        _soundMode = mode;
        _hasOverlayPermission = hasOverlay;
      });
    }
  }

  Future<void> _setSoundMode(String mode) async {
    await NativeAlarmService.setSoundMode(mode);
    if (mounted) {
      setState(() {
        _soundMode = mode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            mode == 'ALWAYS'
                ? '🔊 Modo: Sonar Siempre (Fuerza volumen de alarma al 100%)'
                : '🔕 Modo: Sonar según configuración del teléfono (Silencio en reuniones)',
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
            // 1. Selector Brutalista de Comportamiento del Sonido
            _buildSoundModeCard(),

            const SizedBox(height: 22),

            // 2. Estado de Permisos Críticos del Sistema (Despertar en Bloqueo)
            _buildPermissionsCard(),

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
            title: '🔕 SEGÚN CONFIGURACIÓN DEL TELÉFONO',
            subtitle: 'En iglesia, reunión o cine con teléfono en silencio, SOLO enciende la pantalla y muestra el formulario sin sonar.',
            value: 'DEVICE_SETTINGS',
            activeBg: AppColors.orangeSoft,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.security, color: AppColors.ink, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'PERMISOS DE PANTALLA BLOQUEADA',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
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
              'MiCripto Sentinel — V.0.1.6',
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
