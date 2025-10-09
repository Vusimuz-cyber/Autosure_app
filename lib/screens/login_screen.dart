import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';
import 'auto_sure_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _formController;
  AnimationController? _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Animation<double>? _glowAnimation;

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isLoading = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8, // Changed from 0.5 to match signup
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2), // Changed from 0.3 to match signup
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutBack,
    ));

    _masterController.forward();
    Future.delayed(const Duration(milliseconds: 400), () { // Reduced delay to match signup
      _formController.forward();
    });

    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          _glowController = AnimationController(
            vsync: this,
            duration: const Duration(seconds: 2),
          )..repeat(reverse: true);
          
          _glowAnimation = Tween<double>(
            begin: 0.6,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: _glowController!,
            curve: Curves.easeInOutSine,
          ));
        });
      }
    });

    _emailFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isEmailFocused = _emailFocusNode.hasFocus;
        });
      }
    });
    
    _passwordFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isPasswordFocused = _passwordFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    _formController.dispose();
    _glowController?.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!mounted) return;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Firebase Auth login
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("No user found");

      // Step 2: Get user details from Realtime Database
      final userRef = FirebaseDatabase.instance.ref("users/${user.uid}");
      final snapshot = await userRef.get();

      String username = "User";
      bool isAdmin = false;

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        username = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
        isAdmin = data['isAdmin'] == true || data['role'] == "admin";
      }

      // Step 3: Debugging print (optional)
      print("✅ Login successful → ${isAdmin ? 'Admin' : 'Normal User'}");
      print("👤 Username: $username");

      // Step 4: Stop loading before navigation
      if (mounted) setState(() => _isLoading = false);

      // Step 5: Redirect based on role
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isAdmin
              ? const AdminDashboard()
              : HomeScreen(username: username.isEmpty ? "User" : username),
        ),
        (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') message = 'No account found with this email.';
      else if (e.code == 'wrong-password') message = 'Incorrect password.';
      else if (e.code == 'invalid-email') message = 'Invalid email format.';
      else if (e.code == 'too-many-requests') message = 'Too many failed attempts. Try later.';

      _showErrorDialog(message);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Unexpected error: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          'Login Error',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 52, 90),
      body: Stack(
        children: [
          // Static background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.8,
                colors: [
                  Color.fromARGB(255, 16, 52, 90),
                  Color.fromARGB(255, 8, 26, 45),
                  Color.fromARGB(255, 4, 15, 26),
                ],
                stops: [0.1, 0.6, 1.0],
              ),
            ),
          ),
          
          // Animated Background
          if (_glowController != null) _buildAnimatedBackground(),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Header Section - Matches signup structure
                        SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // Logo with Premium Animation
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const AutoSureLogo(
                                  size: 100,
                                  animated: true,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Welcome Back",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: const Offset(2, 2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Sign in to your Autosure account",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Premium Glass Login Form
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: MouseRegion(
                              onEnter: (_) {
                                if (mounted) {
                                  setState(() => _isHovering = true);
                                }
                              },
                              onExit: (_) {
                                if (mounted) {
                                  setState(() => _isHovering = false);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(_isHovering ? 0.18 : 0.15),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(_isHovering ? 0.3 : 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    ),
                                    if (_isHovering)
                                      BoxShadow(
                                        color: Colors.blueAccent.withOpacity(0.2),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                  ],
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.12),
                                      Colors.white.withOpacity(0.05),
                                      Colors.white.withOpacity(0.02),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header - Matches signup style
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Log In",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 30),
                                    
                                    // Email Field
                                    _buildPremiumTextField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      isFocused: _isEmailFocused,
                                      hintText: "Email address",
                                      prefixIcon: Icons.email_rounded,
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Password Field
                                    _buildPremiumTextField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      isFocused: _isPasswordFocused,
                                      hintText: "Password",
                                      prefixIcon: Icons.lock_rounded,
                                      isPassword: true,
                                    ),
                                    
                                    const SizedBox(height: 15),
                                    
                                    // Forgot Password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        onTap: _handleForgotPassword,
                                        child: Text(
                                          "Forgot Password?",
                                          style: GoogleFonts.poppins(
                                            color: Colors.blueAccent.shade200,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 30),
                                    
                                    // Login Button
                                    _isLoading
                                        ? _buildLoadingIndicator()
                                        : _buildPremiumLoginButton(),
                                    
                                    const SizedBox(height: 25),
                                    
                                    // Divider with "OR" text
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white.withOpacity(0.3),
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 15),
                                          child: Text(
                                            "OR",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white54,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white.withOpacity(0.3),
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 25),
                                    
                                    // Sign Up Button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context, animation, secondaryAnimation) => const SignupScreen(),
                                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                  const begin = Offset(1.0, 0.0);
                                                  const end = Offset.zero;
                                                  const curve = Curves.easeInOutQuart;
                                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                                  return SlideTransition(position: animation.drive(tween), child: child);
                                                },
                                                transitionDuration: const Duration(milliseconds: 800),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            "Sign Up",
                                            style: GoogleFonts.poppins(
                                              color: Colors.blueAccent.shade200,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleForgotPassword() {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Please enter your email to reset password.');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'We will send a password reset link to ${_emailController.text.trim()}',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim()).then((_) {
                _showErrorDialog('Password reset email sent. Please check your inbox.');
              }).catchError((error) {
                _showErrorDialog('Failed to send reset email: ${error.toString()}');
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Send',
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFocused
              ? [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                ]
              : [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
        border: Border.all(
          color: isFocused ? Colors.blueAccent.withOpacity(0.6) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 16,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            prefixIcon,
            color: isFocused ? Colors.blueAccent.shade200 : Colors.white54,
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPremiumLoginButton() {
    if (_glowController == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueAccent.shade400,
              Colors.lightBlue.shade400,
              Colors.blueAccent.shade200,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "LOG IN",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _glowController!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blueAccent.shade400,
                Colors.lightBlue.shade400,
                Colors.blueAccent.shade200,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.5 * (_glowAnimation?.value ?? 0.8)),
                blurRadius: 20,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "LOG IN",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent.shade400),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            "Authenticating...",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    if (_glowController == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _glowController!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.5, _glowController!.value - 0.5),
              radius: 1.8,
              colors: [
                const Color.fromARGB(255, 16, 52, 90).withOpacity(0.9),
                const Color.fromARGB(255, 8, 26, 45),
                const Color.fromARGB(255, 4, 15, 26),
              ],
              stops: const [0.1, 0.6, 1.0],
            ),
          ),
        );
      },
    );
  }
}