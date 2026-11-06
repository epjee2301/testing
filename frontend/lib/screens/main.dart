import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Sesuaikan path import Anda
import 'login_screen.dart';
import 'hrd_dashboard.dart';
import 'employee_dashboard.dart';
import '../providers/auth_provider.dart';

void main() {
  runApp(const LookInApp());
}

class LookInApp extends StatelessWidget {
  const LookInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'LookIn Presensi',
        debugShowCheckedModeBanner: false,
        // Gunakan AuthWrapper sebagai penentu halaman awal
        home: const AuthWrapper(),
        // Rute manual tetap dipertahankan untuk navigasi dari halaman login
        routes: {
          '/login': (context) => const LoginScreen(),
          '/hrd': (context) => const HrdDashboard(),
          '/employee': (context) => EmployeeDashboard(),
        },
      ),
    );
  }
}

// Widget khusus untuk mengecek sesi (token) saat aplikasi pertama kali dibuka
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _authCheckFuture;

  @override
  void initState() {
    super.initState();
    // Eksekusi fungsi pengecekan token HANYA SEKALI saat aplikasi dimulai
    _authCheckFuture = context.read<AuthProvider>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authCheckFuture,
      builder: (context, snapshot) {
        // 1. Tampilkan loading screen saat sedang membaca memori internal perangkat
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
        }

        // 2. Gunakan Consumer agar otomatis pindah ke Login jika user melakukan Logout nantinya
        return Consumer<AuthProvider>(
          builder: (context, auth, child) {
            if (auth.isAuthenticated) {
              final isMobile =
                  !kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS);

              if (auth.role == 'admin') {
                return const RoleAccessScreen(
                  message: 'Admin menggunakan web Laravel. Silakan buka alamat backend melalui browser komputer.',
                );
              }
              if (auth.role == 'hrd' || auth.role == 'karyawan') {
                if (!isMobile) {
                  return const RoleAccessScreen(
                    message: 'Akun HRD dan karyawan digunakan melalui aplikasi mobile.',
                  );
                }
                return auth.role == 'hrd'
                    ? const HrdDashboard()
                    : const EmployeeDashboard();
              }
              return const RoleAccessScreen(
                message: 'Role akun tidak dikenali. Hubungi administrator.',
              );
            }

            // Jika token kosong (belum login / sudah logout), kembali ke form login
            return const LoginScreen();
          },
        );
      },
    );
  }
}

class RoleAccessScreen extends StatelessWidget {
  const RoleAccessScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.devices_other, size: 56),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
