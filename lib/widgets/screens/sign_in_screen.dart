import 'package:flutter/material.dart';

import '../../app_config/service_locator.dart';
import '../../managers/user_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/snackbar_util.dart';

class SignInScreen extends StatefulWidget {
  static const ROUTE_PATH = '/sign-in';
  static const ROUTE_NAME = 'sign-in';

  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool isBusy = false;

  Future<void> onGoogleSignInPressed() async {
    setState(() => isBusy = true);
    final success = await locator<UserManager>().signInWithGoogle();
    if (!mounted) return;
    setState(() => isBusy = false);
    if (!success) {
      SnackBarUtil.showSnackBar(
        context,
        'Sign-in failed. Please try again.',
        Variant.ERROR,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month,
                      size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Krizot',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Shift scheduling & dispatch',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isBusy ? null : onGoogleSignInPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                          isBusy ? 'Signing in…' : 'Continue with Google'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
