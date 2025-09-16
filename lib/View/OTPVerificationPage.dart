import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ResetPasswordPage.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;

  const OTPVerificationPage({super.key, required this.email});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
        (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      _showMessage('Please enter the complete 6-digit code', Colors.orange);
      return;
    }

    setState(() => _loading = true);

    try {
      // Verify OTP and get session
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: _otp,
        type: OtpType.recovery,
      );

      if (mounted && response.session != null) {
        _showMessage(
          'Code verified! You can now reset your password.',
          Colors.green,
        );

        // Wait a moment for the success message to be visible
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate to reset password page (without token since user is already authenticated)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
          );
        }
      } else {
        _showMessage('Verification failed. Please try again.', Colors.red);
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Invalid or expired code';
        if (e.message.toLowerCase().contains('expired')) {
          errorMessage = 'Code has expired. Please request a new one.';
        } else if (e.message.toLowerCase().contains('invalid')) {
          errorMessage = 'Invalid code. Please check and try again.';
        }
        _showMessage(errorMessage, Colors.red);
        _clearOTP(); // Clear the entered OTP
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Verification failed: ${e.toString()}', Colors.red);
        _clearOTP();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearOTP() {
    for (var controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes[0].canRequestFocus) {
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _resending = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(widget.email);

      if (mounted) {
        _showMessage('New code sent to your email', Colors.green);
        _clearOTP(); // Clear current OTP input
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error resending code: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.orange
                  ? Icons.warning
                  : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-verify when all 6 digits are entered
        if (_otp.length == 6) {
          _verifyOTP();
        }
      }
    }
  }

  void _onKeyDown(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Verify Email"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              Icon(Icons.mail_outline, size: 80, color: Colors.blue),
              const SizedBox(height: 24),

              Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text.rich(
                TextSpan(
                  text: 'We sent a 6-digit verification code to\n',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyDown(event, index),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor:
                          isDark
                              ? Colors.grey[900]?.withOpacity(0.3)
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                              isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onChanged(value, index),
                        enabled: !_loading, // Disable input during verification
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Verify Button
              ElevatedButton(
                onPressed: (_loading || _otp.length != 6) ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: Colors.blue.withOpacity(0.6),
                ),
                child:
                _loading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Text(
                  'Verify Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: _resending ? null : _resendOTP,
                    child:
                    _resending
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    )
                        : const Text(
                      'Resend',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Help text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                  isDark
                      ? Colors.blue.shade900.withOpacity(0.2)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.blue.shade800 : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Check your spam folder if you don\'t see the email. The code expires in 10 minutes.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          isDark
                              ? Colors.blue.shade300
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}