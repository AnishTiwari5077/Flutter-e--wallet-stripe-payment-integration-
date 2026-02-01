import 'package:flutter/material.dart';
import 'package:app_wallet/services/biometric_service.dart';
import 'package:app_wallet/widgets/pin_input_dialog.dart';

class TransactionAuthHelper {
  static Future<bool> authenticate(BuildContext context) async {
    try {
      final biometricEnabled =
          await BiometricService.isBiometricEnabledForTransactions();
      final pinEnabled = await BiometricService.isPinSet();
      if (!biometricEnabled && !pinEnabled) {
        return true;
      }
      if (biometricEnabled) {
        final biometricSuccess =
            await BiometricService.authenticateWithBiometric(
              reason: 'Authenticate to confirm transaction',
            );

        if (biometricSuccess) {
          return true;
        }
        if (!pinEnabled) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication failed'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return false;
        }
        if (context.mounted) {
          final usePinInstead = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text(
                'Use PIN Instead?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Biometric authentication failed. Would you like to use PIN instead?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                  ),
                  child: const Text('Use PIN'),
                ),
              ],
            ),
          );

          if (usePinInstead != true) {
            return false;
          }
        }
      }
      if (pinEnabled) {
        if (!context.mounted) return false;

        final pin = await PinInputDialog.show(
          context: context,
          title: 'Confirm Transaction',
          subtitle: 'Enter your PIN to confirm',
        );
        if (pin == null) {
          return false;
        }

        final isValid = await BiometricService.verifyPin(pin);

        if (!isValid) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect PIN'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return false;
        }

        return true;
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  static Future<void> showAuthRequiredDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Security Required',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: const Text(
          'Please set up biometric authentication or PIN in Security Settings to secure your transactions.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
            ),
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }
}
