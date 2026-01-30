import 'package:flutter/material.dart';
import 'package:app_wallet/services/biometric_service.dart';
import 'package:app_wallet/widgets/pin_input_dialog.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricLoginEnabled = false;
  bool _biometricTransactionEnabled = false;
  bool _pinEnabled = false;
  String _biometricType = 'Biometric';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() => _isLoading = true);

    final available = await BiometricService.isBiometricAvailable();
    final loginEnabled = await BiometricService.isBiometricEnabledForLogin();
    final transactionEnabled =
        await BiometricService.isBiometricEnabledForTransactions();
    final pinSet = await BiometricService.isPinSet();
    final biometricType = await BiometricService.getBiometricTypeName();

    setState(() {
      _biometricAvailable = available;
      _biometricLoginEnabled = loginEnabled;
      _biometricTransactionEnabled = transactionEnabled;
      _pinEnabled = pinSet;
      _biometricType = biometricType;
      _isLoading = false;
    });
  }

  // ============================================
  // BIOMETRIC LOGIN TOGGLE
  // ============================================
  Future<void> _toggleBiometricLogin(bool value) async {
    if (value) {
      // Enable biometric login
      final authenticated = await BiometricService.authenticateWithBiometric(
        reason: 'Authenticate to enable $_biometricType for login',
      );

      if (authenticated) {
        final success = await BiometricService.enableBiometricLogin();

        if (success) {
          setState(() => _biometricLoginEnabled = true);
          _showSuccessMessage('$_biometricType login enabled');
        } else {
          _showErrorMessage('Failed to enable $_biometricType login');
        }
      } else {
        _showErrorMessage('Authentication failed');
      }
    } else {
      // Disable biometric login
      final success = await BiometricService.disableBiometricLogin();

      if (success) {
        setState(() => _biometricLoginEnabled = false);
        _showSuccessMessage('$_biometricType login disabled');
      } else {
        _showErrorMessage('Failed to disable $_biometricType login');
      }
    }
  }

  // ============================================
  // BIOMETRIC TRANSACTION TOGGLE
  // ============================================
  Future<void> _toggleBiometricTransaction(bool value) async {
    if (value) {
      // Enable biometric for transactions
      final authenticated = await BiometricService.authenticateWithBiometric(
        reason: 'Authenticate to enable $_biometricType for transactions',
      );

      if (authenticated) {
        final success = await BiometricService.enableBiometricForTransactions();

        if (success) {
          setState(() => _biometricTransactionEnabled = true);
          _showSuccessMessage('$_biometricType for transactions enabled');
        } else {
          _showErrorMessage(
            'Failed to enable $_biometricType for transactions',
          );
        }
      } else {
        _showErrorMessage('Authentication failed');
      }
    } else {
      // Disable biometric for transactions
      final success = await BiometricService.disableBiometricForTransactions();

      if (success) {
        setState(() => _biometricTransactionEnabled = false);
        _showSuccessMessage('$_biometricType for transactions disabled');
      } else {
        _showErrorMessage('Failed to disable $_biometricType for transactions');
      }
    }
  }

  // ============================================
  // PIN SETUP
  // ============================================
  Future<void> _setupPin() async {
    // First PIN entry
    final pin1 = await PinInputDialog.show(
      context: context,
      title: 'Set Up PIN',
      subtitle: 'Enter a 4-digit PIN',
      isSetup: true,
    );

    if (pin1 == null || pin1.length != 4) return;

    // Confirm PIN entry
    final pin2 = await PinInputDialog.show(
      context: context,
      title: 'Confirm PIN',
      subtitle: 'Re-enter your PIN to confirm',
      isSetup: true,
    );

    if (pin2 == null || pin2.length != 4) return;

    // Check if PINs match
    if (pin1 != pin2) {
      _showErrorMessage('PINs do not match. Please try again.');
      return;
    }

    // Save PIN
    final success = await BiometricService.setPin(pin1);

    if (success) {
      setState(() => _pinEnabled = true);
      _showSuccessMessage('PIN set successfully');
    } else {
      _showErrorMessage('Failed to set PIN');
    }
  }

  // ============================================
  // CHANGE PIN
  // ============================================
  Future<void> _changePin() async {
    // Verify old PIN
    final oldPin = await PinInputDialog.show(
      context: context,
      title: 'Enter Current PIN',
      subtitle: 'Enter your current PIN',
    );

    if (oldPin == null || oldPin.length != 4) return;

    final isValid = await BiometricService.verifyPin(oldPin);

    if (!isValid) {
      _showErrorMessage('Incorrect PIN');
      return;
    }

    // Enter new PIN
    final newPin1 = await PinInputDialog.show(
      context: context,
      title: 'Enter New PIN',
      subtitle: 'Enter your new 4-digit PIN',
      isSetup: true,
    );

    if (newPin1 == null || newPin1.length != 4) return;

    // Confirm new PIN
    final newPin2 = await PinInputDialog.show(
      context: context,
      title: 'Confirm New PIN',
      subtitle: 'Re-enter your new PIN',
      isSetup: true,
    );

    if (newPin2 == null || newPin2.length != 4) return;

    // Check if new PINs match
    if (newPin1 != newPin2) {
      _showErrorMessage('PINs do not match');
      return;
    }

    // Change PIN
    final success = await BiometricService.changePin(oldPin, newPin1);

    if (success) {
      _showSuccessMessage('PIN changed successfully');
    } else {
      _showErrorMessage('Failed to change PIN');
    }
  }

  // ============================================
  // REMOVE PIN
  // ============================================
  Future<void> _removePin() async {
    // Verify PIN before removal
    final pin = await PinInputDialog.show(
      context: context,
      title: 'Remove PIN',
      subtitle: 'Enter your current PIN to remove it',
    );

    if (pin == null || pin.length != 4) return;

    final isValid = await BiometricService.verifyPin(pin);

    if (!isValid) {
      _showErrorMessage('Incorrect PIN');
      return;
    }

    // Confirm removal
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Remove PIN?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove your PIN? This will disable PIN authentication for transactions.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Remove PIN
    final success = await BiometricService.removePin();

    if (success) {
      setState(() => _pinEnabled = false);
      _showSuccessMessage('PIN removed successfully');
    } else {
      _showErrorMessage('Failed to remove PIN');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF080814),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Security Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Security Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purpleAccent.withValues(alpha: 0.2),
                    Colors.purpleAccent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.purpleAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Secure Your Wallet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add an extra layer of security to your transactions',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Biometric Authentication Section
            if (_biometricAvailable) ...[
              _buildSectionTitle('Biometric Authentication'),
              const SizedBox(height: 16),
              _buildBiometricCard(),
              const SizedBox(height: 32),
            ] else ...[
              _buildUnavailableCard(
                icon: Icons.fingerprint_outlined,
                title: 'Biometric Not Available',
                subtitle:
                    'Your device does not support biometric authentication',
              ),
              const SizedBox(height: 32),
            ],

            // PIN Section
            _buildSectionTitle('PIN Security'),
            const SizedBox(height: 16),
            _buildPinCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBiometricCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Biometric Login Toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fingerprint, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_biometricType Login',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use $_biometricType to login',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _biometricLoginEnabled,
                onChanged: _toggleBiometricLogin,
                activeColor: Colors.green,
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white24),

          // Biometric Transaction Toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_outline, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_biometricType for Transactions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verify all transactions with $_biometricType',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _biometricTransactionEnabled,
                onChanged: _toggleBiometricTransaction,
                activeColor: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // PIN Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pinEnabled
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pin_outlined,
                  color: _pinEnabled ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pinEnabled ? 'PIN Enabled' : 'PIN Disabled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pinEnabled
                          ? 'Your transactions are secured with PIN'
                          : 'Set up a PIN for transaction security',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _pinEnabled
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _pinEnabled ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _pinEnabled ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // PIN Action Buttons
          if (!_pinEnabled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _setupPin,
                icon: const Icon(Icons.add),
                label: const Text('Set Up PIN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _changePin,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _removePin,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildUnavailableCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
