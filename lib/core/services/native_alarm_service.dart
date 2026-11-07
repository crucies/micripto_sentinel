import 'package:flutter/services.dart';

class NativeAlarmService {
  static const MethodChannel _channel = MethodChannel('com.richard.micripto/sentinel_alarm');

  /// Disparar alarma nativa inmediata con despertar de pantalla y audio táctico
  static Future<bool> triggerImmediateAlarm({
    required String eventType,
    required String symbol,
    required String price,
    required String amount,
    required String targetPrice,
    required String projectedProfit,
    String totalProfit = '+\$41.56 USDT',
    String liquidCash = '\$345.84 USDT',
    String tp1Price = '',
    String tp2Price = '',
    String slPrice = '',
    String limitBuyPrice = '',
    double tradeAmount = 100.0,
    String buyPrice = '',
    String buyDate = '',
    String sellDate = '',
    String elapsedTime = '',
    String appVersion = 'V 0.2.5',
    String totalCoins = '',
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('triggerImmediateAlarm', {
        'eventType': eventType,
        'symbol': symbol,
        'price': price,
        'amount': amount,
        'targetPrice': targetPrice,
        'projectedProfit': projectedProfit,
        'totalProfit': totalProfit,
        'liquidCash': liquidCash,
        'tp1Price': tp1Price,
        'tp2Price': tp2Price,
        'slPrice': slPrice,
        'limitBuyPrice': limitBuyPrice,
        'tradeAmount': tradeAmount,
        'buyPrice': buyPrice,
        'buyDate': buyDate,
        'sellDate': sellDate,
        'elapsedTime': elapsedTime,
        'appVersion': appVersion,
        'totalCoins': totalCoins,
      });
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Programar alarma nativa con retardo para probar bloqueo de pantalla (ej. 5 segundos)
  static Future<bool> scheduleTestAlarm({
    int delaySeconds = 5,
    required String eventType,
    required String symbol,
    required String price,
    required String amount,
    required String targetPrice,
    required String projectedProfit,
    String totalProfit = '+\$41.56 USDT',
    String liquidCash = '\$345.84 USDT',
    String tp1Price = '',
    String tp2Price = '',
    String slPrice = '',
    String limitBuyPrice = '',
    double tradeAmount = 100.0,
    String buyPrice = '',
    String buyDate = '',
    String sellDate = '',
    String elapsedTime = '',
    String appVersion = 'V 0.2.5',
    String totalCoins = '',
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('scheduleTestAlarm', {
        'delaySeconds': delaySeconds,
        'data': {
          'eventType': eventType,
          'symbol': symbol,
          'price': price,
          'amount': amount,
          'targetPrice': targetPrice,
          'projectedProfit': projectedProfit,
          'totalProfit': totalProfit,
          'liquidCash': liquidCash,
          'tp1Price': tp1Price,
          'tp2Price': tp2Price,
          'slPrice': slPrice,
          'limitBuyPrice': limitBuyPrice,
          'tradeAmount': tradeAmount,
          'buyPrice': buyPrice,
          'buyDate': buyDate,
          'sellDate': sellDate,
          'elapsedTime': elapsedTime,
          'appVersion': appVersion,
        'totalCoins': totalCoins,
        },
      });
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Abrir la app de Binance o enlace web directo
  static Future<void> openBinance() async {
    try {
      await _channel.invokeMethod('openBinance');
    } catch (_) {}
  }

  /// Obtener Token de Firebase Cloud Messaging para registrar el dispositivo
  static Future<String?> getFcmToken() async {
    try {
      return await _channel.invokeMethod<String>('getFcmToken');
    } catch (_) {
      return null;
    }
  }

  /// Obtener todos los registros de telemetría nativos y de fondo
  static Future<String> getLogs() async {
    try {
      final res = await _channel.invokeMethod<String>('getLogs');
      return res ?? 'Sin registros';
    } catch (e) {
      return 'Error al obtener logs: $e';
    }
  }

  /// Borrar registros de telemetría
  static Future<bool> clearLogs() async {
    try {
      final res = await _channel.invokeMethod<bool>('clearLogs');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Obtener modo de sonido configurado ('ALWAYS' o 'DEVICE_SETTINGS')
  static Future<String> getSoundMode() async {
    try {
      final res = await _channel.invokeMethod<String>('getSoundMode');
      return res ?? 'ALWAYS';
    } catch (_) {
      return 'ALWAYS';
    }
  }

  /// Establecer modo de sonido ('ALWAYS' o 'DEVICE_SETTINGS')
  static Future<bool> setSoundMode(String mode) async {
    try {
      final res = await _channel.invokeMethod<bool>('setSoundMode', {'mode': mode});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Registrar evento desde Flutter
  static Future<void> logEvent(String message) async {
    try {
      await _channel.invokeMethod('logEvent', {'message': message});
    } catch (_) {}
  }

  /// Verificar si la app tiene permiso de 'Aparecer encima de otras apps' (Overlay)
  static Future<bool> checkOverlayPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abrir ajustes del sistema para conceder permiso de Overlay
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  /// Guardar órdenes dinámicas en SharedPreferences nativo
  static Future<bool> saveCachedOrders(String ordersJson) async {
    try {
      final res = await _channel.invokeMethod<bool>('saveCachedOrders', {'ordersJson': ordersJson});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Obtener órdenes dinámicas guardadas en SharedPreferences nativo
  static Future<String?> getCachedOrders() async {
    try {
      return await _channel.invokeMethod<String>('getCachedOrders');
    } catch (_) {
      return null;
    }
  }

  /// Iniciar escaneo autónomo nativo en segundo plano (Doze Mode) cada 60s
  static Future<bool> startNativeBackgroundScan() async {
    try {
      final res = await _channel.invokeMethod<bool>('startNativeBackgroundScan');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Detener escaneo autónomo nativo
  static Future<bool> stopNativeBackgroundScan() async {
    try {
      final res = await _channel.invokeMethod<bool>('stopNativeBackgroundScan');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Verificar si la app tiene desactivada la optimización de batería (Doze Mode Unrestricted)
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final res = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Solicitar al usuario desactivar la optimización de batería para vigilancia 24/7 en bloqueo
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Guardar órdenes archivadas en SharedPreferences nativo
  static Future<bool> saveArchivedOrders(String archivedOrdersJson) async {
    try {
      final res = await _channel.invokeMethod<bool>('saveArchivedOrders', {'archivedOrdersJson': archivedOrdersJson});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Obtener órdenes archivadas guardadas en SharedPreferences nativo
  static Future<String?> getArchivedOrders() async {
    try {
      return await _channel.invokeMethod<String>('getArchivedOrders');
    } catch (_) {
      return null;
    }
  }

  /// Obtener ajuste de cadena de texto persistido en SharedPreferences nativo
  static Future<String> getSetting(String key, {String defaultValue = ''}) async {
    try {
      final res = await _channel.invokeMethod<String>('getSetting', {
        'key': key,
        'defaultValue': defaultValue,
      });
      return res ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Guardar ajuste de cadena de texto persistido en SharedPreferences nativo
  static Future<bool> setSetting(String key, String value) async {
    try {
      final res = await _channel.invokeMethod<bool>('setSetting', {
        'key': key,
        'value': value,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Obtener ajuste booleano persistido en SharedPreferences nativo
  static Future<bool> getBoolSetting(String key, {bool defaultValue = false}) async {
    try {
      final res = await _channel.invokeMethod<bool>('getBoolSetting', {
        'key': key,
        'defaultValue': defaultValue,
      });
      return res ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Guardar ajuste booleano persistido en SharedPreferences nativo
  static Future<bool> setBoolSetting(String key, bool value) async {
    try {
      final res = await _channel.invokeMethod<bool>('setBoolSetting', {
        'key': key,
        'value': value,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Obtener ajuste double persistido en SharedPreferences nativo
  static Future<double> getDoubleSetting(String key, {double defaultValue = 100.0}) async {
    try {
      final res = await _channel.invokeMethod<double>('getDoubleSetting', {
        'key': key,
        'defaultValue': defaultValue,
      });
      return res ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Guardar ajuste double persistido en SharedPreferences nativo
  static Future<bool> setDoubleSetting(String key, double value) async {
    try {
      final res = await _channel.invokeMethod<bool>('setDoubleSetting', {
        'key': key,
        'value': value,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Verificar si el Servicio Nativo en Primer Plano 24/7 está corriendo activamente
  static Future<bool> isForegroundServiceRunning() async {
    try {
      final res = await _channel.invokeMethod<bool>('isForegroundServiceRunning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Verificar si la app tiene permiso de Alarmas Exactas (Android 12+)
  static Future<bool> checkExactAlarmPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkExactAlarmPermission');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Solicitar permiso de Alarmas Exactas en Ajustes del Sistema
  static Future<void> requestExactAlarmPermission() async {
    try {
      await _channel.invokeMethod('requestExactAlarmPermission');
    } catch (_) {}
  }
}
