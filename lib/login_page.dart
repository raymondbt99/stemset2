import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Ganti dengan nama project dan path file dashboard Anda yang sebenarnya
import 'package:stemset/pages/user_dashboard_page.dart';
// import 'admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Mendengarkan perubahan status login secara real-time
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        _handlePostLogin(session.user);
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // Pastikan URL callback ini sudah terdaftar di dashboard Supabase Anda
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePostLogin(User user) async {
    try {
      // Ambil data role dari tabel profiles
      final response =
          await supabase
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

      // Jika profil belum terbuat (menunggu trigger database)
      if (response == null) {
        print("Menunggu profil dibuat oleh trigger...");
        await Future.delayed(const Duration(seconds: 2));
        return _handlePostLogin(user);
      }

      final String role = response['role'];

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Navigasi Berdasarkan Role
      if (role == 'admin') {
        // Navigasi ke Dashboard Admin
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
        print("User adalah Admin");
      } else {
        // Navigasi ke Dashboard User
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserDashboard()),
        );
      }
    } catch (e) {
      print("Error mengambil role: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau Icon Aplikasi
              const Icon(Icons.inventory_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'STEMSET',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'Asset Management System',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 60),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login_rounded),
                      label: const Text(
                        'Login dengan Akun Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _signInWithGoogle,
                    ),
                  ),
              const SizedBox(height: 20),
              const Text(
                "Gunakan email organisasi Stella Maris",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
