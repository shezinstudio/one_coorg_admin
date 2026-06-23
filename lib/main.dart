import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://wacayfyuuugawcwzsqcn.supabase.co',
    // publishableKey: 'sb_publishable_WDyUGVPutJMulZevxZ-T2A_PCbF9ulZ',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhY2F5Znl1dXVnYXdjd3pzcWNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyNjg5MDMsImV4cCI6MjA5Njg0NDkwM30.kgoi97hUSazLORehFjDFafRbjCLnRt5Blro2WF84sHo',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(const CoorgAdminApp());
}

final supabase = Supabase.instance.client;

class CoorgAdminApp extends StatelessWidget {
  const CoorgAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One  Coorg Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: supabase.auth.currentSession != null
          ? const DashboardScreen()
          : const LoginScreen(),
    );
  }
}
