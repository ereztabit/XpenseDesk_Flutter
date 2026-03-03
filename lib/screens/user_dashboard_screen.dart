import 'screen_imports.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await ref.read(userInfoProvider.notifier).loadFromSession();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userInfo = ref.watch(userInfoProvider);

    if (userInfo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
      return const SizedBox.shrink();
    }

    if (userInfo.roleId == 1) {
      // Manager landed here — redirect to manager dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: ConstrainedContent(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi ${userInfo.fullName}, you are a user.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (userInfo.termsConsentDate == null) ...
                      [
                        const SizedBox(height: 16),
                        const Text(
                          'Onboarding',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
