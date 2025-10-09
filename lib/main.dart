import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart'; // Keep this import
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Use FirebaseOptions for initialization - THIS IS CORRECT
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
      if (!kIsWeb) {
       FirebaseDatabase.instance.setPersistenceEnabled(true);
       FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000);
    }
    
    runApp(const AutosureApp());
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    runApp(const ErrorApp(error: 'Firebase initialization failed'));
  }
}

class AutosureApp extends StatelessWidget {
  const AutosureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoSure Insurance',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 16, 52, 90),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  'Initialization Error',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (mounted) {
          setState(() {
            _user = user;
            _error = null;
          });
        }
      });

      // Add timeout for initial load
      await Future.any([
        Future.delayed(const Duration(seconds: 10)),
        FirebaseAuth.instance.authStateChanges().first,
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Authentication error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();
    
    if (_error != null) return _buildErrorScreen(_error!);

    // If no user logged in → Welcome screen
    if (_user == null) return const WelcomeScreen();

    // If user logged in → check admin or normal user in Realtime DB
    return FutureBuilder<UserData>(
      future: _getUserData(_user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          return _buildErrorScreen('Failed to load user data: ${snapshot.error}');
        }

        final userData = snapshot.data ?? UserData(name: 'User', isAdmin: false);

        if (userData.isAdmin) {
          return const AdminDashboard();
        } else {
          return HomeScreen(username: userData.name);
        }
      },
    );
  }

  /// 🔹 Get user data (name and type) in single call
  Future<UserData> _getUserData(String uid) async {
    try {
      final ref = FirebaseDatabase.instance.ref('users/$uid');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final first = data['firstName']?.toString() ?? '';
        final last = data['lastName']?.toString() ?? '';
        final name = '$first $last'.trim();
        final isAdmin = data['isAdmin'] == true;
        
        return UserData(name: name.isEmpty ? 'User' : name, isAdmin: isAdmin);
      }
      return UserData(name: 'User', isAdmin: false);
    } catch (e) {
      print('Error fetching user data: $e');
      throw e;
    }
  }

  /// 🔹 Loading screen design
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 52, 90),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'AutoSure',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Security in Motion',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 52, 90),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkAuthState,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserData {
  final String name;
  final bool isAdmin;

  UserData({required this.name, required this.isAdmin});
}