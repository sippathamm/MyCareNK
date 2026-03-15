import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result model for password recovery operations.
class RecoveryResult {
  final bool success;
  final String? error;
  final List<String>? newRecoveryCodes;
  final bool rateLimited;
  final bool locked;

  const RecoveryResult({
    required this.success,
    this.error,
    this.newRecoveryCodes,
    this.rateLimited = false,
    this.locked = false,
  });
}

/// Service for password recovery via recovery codes.
///
/// Handles:
/// - Recovery code generation (cryptographically secure)
/// - Saving codes during registration via `save_recovery_codes` RPC
/// - Pre-verifying codes via `verify_recovery_code` RPC
/// - Resetting passwords via `verify_recovery_code_and_reset_password` RPC
class RecoveryService {
  final SupabaseClient _client;

  RecoveryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Generate 6 cryptographically secure recovery codes.
  /// Each code is 6 uppercase hex characters (e.g. "A3F1B9").
  static List<String> generateRecoveryCodes() {
    const chars = 'ABCDEF0123456789';
    final rnd = Random.secure();
    return List.generate(6, (_) {
      return String.fromCharCodes(
        Iterable.generate(
          6,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
        ),
      );
    });
  }

  /// Save recovery codes to Supabase (called during registration).
  /// User must be authenticated.
  Future<void> saveRecoveryCodes(List<String> codes) async {
    await _client.rpc(
      'save_recovery_codes',
      params: {'secret_codes': codes},
    );
  }

  /// Pre-verify a recovery code without resetting the password.
  /// Used on the recovery code entry screen before navigating to the reset page.
  Future<RecoveryResult> verifyCode({
    required String username,
    required String recoveryCode,
  }) async {
    return _callRpc(
      'verify_recovery_code',
      params: {
        'p_username': username,
        'p_recovery_code': recoveryCode,
      },
    );
  }

  /// Verify a recovery code and reset the user's password.
  Future<RecoveryResult> resetPassword({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async {
    return _callRpc(
      'verify_recovery_code_and_reset_password',
      params: {
        'p_username': username,
        'p_recovery_code': recoveryCode,
        'p_new_password': newPassword,
      },
    );
  }

  /// Internal helper to call an RPC and parse the JSON result.
  /// Eliminates duplicate error handling across verifyCode/resetPassword.
  Future<RecoveryResult> _callRpc(
    String functionName, {
    required Map<String, dynamic> params,
  }) async {
    try {
      final response = await _client.rpc(functionName, params: params);
      final data = response as Map<String, dynamic>;

      if (data['success'] == true) {
        List<String>? codes;
        if (data['new_recovery_codes'] != null) {
          codes = (data['new_recovery_codes'] as List<dynamic>)
              .map((c) => c.toString())
              .toList();
        }
        return RecoveryResult(success: true, newRecoveryCodes: codes);
      }

      return RecoveryResult(
        success: false,
        error: data['error'] as String? ??
            'ชื่อผู้ใช้งานหรือรหัสกู้คืนไม่ถูกต้อง',
        rateLimited: data['rate_limited'] == true,
        locked: data['locked'] == true,
      );
    } on PostgrestException catch (e) {
      debugPrint('RecoveryService.$functionName PostgrestException: ${e.message}');
      return const RecoveryResult(
        success: false,
        error: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
      );
    } catch (e) {
      debugPrint('RecoveryService.$functionName error: $e');
      return const RecoveryResult(
        success: false,
        error: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
      );
    }
  }
}
