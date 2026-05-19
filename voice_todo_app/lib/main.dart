import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/todo_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';

// Conditional import: web gets no-op stubs, native gets real foreground service.
import 'services/foreground_service_stub.dart'
    if (dart.library.io) 'services/foreground_task_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ReminderService().initialize();

  initForegroundCommunicationPort();
  initForegroundTask();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TippidiApp());
}

class TippidiApp extends StatelessWidget {
  const TippidiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoProvider(),
      child: MaterialApp(
        title: 'Tippidi',
        theme: AppTheme.darkTheme(),
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}

/// Listens to Supabase auth state and routes between AuthScreen / HomeScreen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      final provider = context.read<TodoProvider>();
      if (data.session != null) {
        provider.initialize();
      } else {
        provider.reset();
      }
    });
    if (supabase.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TodoProvider>().initialize();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<TodoProvider>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (provider.voiceService.isAlwaysListening) {
        startForegroundListening();
      }
    } else if (state == AppLifecycleState.resumed) {
      stopForegroundListening();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, _) {
        if (supabase.auth.currentSession == null) {
          return const AuthScreen();
        }
        if (!provider.isInitialized) {
          return const _SplashScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF8B7FFF), AppTheme.primaryColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tippidi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Loading your tasks…',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
