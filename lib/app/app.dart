import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/zen/zen_screen.dart';
import '../screens/mood/mood_input_screen.dart';
import '../widgets/main_shell.dart';
import 'theme.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// RouterNotifier bridges Riverpod auth state to GoRouter's refreshListenable
class _RouterNotifier extends ChangeNotifier {
  AuthState _authState;

  _RouterNotifier(Ref ref)
      : _authState = ref.read(authProvider) {
    ref.listen(authProvider, (_, next) {
      _authState = next;
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoading = _authState.status == AuthStatus.initial ||
        _authState.status == AuthStatus.loading;
    if (isLoading) return null;

    final isAuthenticated = _authState.status == AuthStatus.authenticated;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isAuthenticated && !isAuthRoute) return '/login';
    if (isAuthenticated && isAuthRoute) return '/';
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                builder: (context, state) => const JournalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/zen',
                builder: (context, state) => const ZenScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/mood',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MoodInputScreen(),
      ),
    ],
  );
});

class MindEaseApp extends ConsumerWidget {
  const MindEaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MindEase',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
