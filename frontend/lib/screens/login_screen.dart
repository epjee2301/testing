import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;

      // Membaca AuthProvider tanpa me-rebuild UI secara langsung
      final authProvider = context.read<AuthProvider>();
      
      // Mengeksekusi request login ke API Laravel
      final success = await authProvider.login(email, password);

      // Cek apakah widget masih terpasang (mounted) sebelum menggunakan context setelah proses await
      if (!mounted) return;

      if (success) {
        // Ambil role yang tersimpan dari backend dan arahkan ke rute yang sesuai
        final role = authProvider.role;
        
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'hrd') {
          Navigator.pushReplacementNamed(context, '/hrd');
        } else if (role == 'karyawan') {
          Navigator.pushReplacementNamed(context, '/employee');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role pengguna tidak valid atau tidak dikenali.')),
          );
        }
      } else {
        // Tampilkan pesan error (seperti kredensial salah) melalui SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'LookIn Presensi',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Consumer mendengarkan perubahan nilai isLoading pada AuthProvider
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return ElevatedButton(
                      // Nonaktifkan tombol jika sedang loading
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Login', style: TextStyle(fontSize: 18)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}