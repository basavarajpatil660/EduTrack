import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Main auth listener will route appropriately
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) return true;
        return false;
      },
      child: Scaffold(
      body: Stack(
        children: [
          // Decorative Elements
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(64),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(128),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 96,
                    height: 96,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 40,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'EduTrack',
                    style: textTheme.headlineLarge?.copyWith(
                      color: colorScheme.primary,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Student & Teacher Portal',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outline,
                          width: 2,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'student@college.edu',
                              hintStyle: TextStyle(color: colorScheme.outline),
                              labelText: 'Email Address',
                              labelStyle: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password Field
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outline,
                          width: 2,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '••••••••',
                              hintStyle: TextStyle(color: colorScheme.outline),
                              labelText: 'Password',
                              labelStyle: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: colorScheme.primaryContainer.withOpacity(0.3),
                      minimumSize: const Size(double.infinity, 56), // full width
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'LOGIN',
                            style: textTheme.labelLarge?.copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 48),

                  Text(
                    'Contact admin if you forgot password',
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 16, color: colorScheme.outlineVariant),
                      const SizedBox(width: 8),
                      Text(
                        'SECURE PORTAL ACCESS',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
