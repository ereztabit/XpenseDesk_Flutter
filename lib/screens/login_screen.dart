import 'package:flutter/material.dart';
import '../widgets/header/login_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/login/login_card.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          const LoginHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTheme.cardMaxWidth,
                  ),
                  child: const LoginCard(),
                ),
              ),
            ),
          ),
          const AppFooter(showTermsLink: true),
        ],
      ),
    );
  }
}
