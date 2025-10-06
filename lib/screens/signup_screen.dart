import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _formController;
  AnimationController? _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Animation<double>? _glowAnimation;

  final _nameFocusNode = FocusNode();
  final _surnameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isNameFocused = false;
  bool _isSurnameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isLoading = false;
  bool _isHovering = false;
  bool _isAdmin = false;
  bool _termsAccepted = false;

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
      begin: 0.8,
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
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutBack,
    ));

    _masterController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
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

    // Focus node listeners
    _nameFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isNameFocused = _nameFocusNode.hasFocus;
        });
      }
    });
    
    _surnameFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSurnameFocused = _surnameFocusNode.hasFocus;
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
    _nameFocusNode.dispose();
    _surnameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleAdmin() {
    setState(() {
      _isAdmin = !_isAdmin;
    });
  }

  void _toggleTerms() {
    setState(() {
      _termsAccepted = !_termsAccepted;
    });
  }

Future<void> _handleSignup() async {
  if (!mounted) return;
  
  // Validation
  if (_nameController.text.isEmpty || 
      _surnameController.text.isEmpty || 
      _emailController.text.isEmpty || 
      _passwordController.text.isEmpty) {
    _showErrorDialog('Please fill in all fields');
    return;
  }

  setState(() => _isLoading = true);

  try {
    print('🚀 STEP 1: Starting Firebase Auth signup...');
    
    // Create user with Firebase Authentication
    final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    print('✅ STEP 1 COMPLETE: User created in Auth - UID: ${userCredential.user!.uid}');
    print('📧 User email: ${userCredential.user!.email}');

    // Save user data to Realtime Database
    print('🚀 STEP 2: Saving to Realtime Database...');
    
    final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${userCredential.user!.uid}');
    
    final userData = {
      'firstName': _nameController.text.trim(),
      'lastName': _surnameController.text.trim(),
      'email': _emailController.text.trim(),
      'isAdmin': _isAdmin,
      'createdAt': ServerValue.timestamp,
    };

    print('📝 User data to save: $userData');
    print('🔗 Database path: users/${userCredential.user!.uid}');

    // Test database connection first
    try {
      await userRef.set(userData);
      print('✅ STEP 2 COMPLETE: User data saved to Realtime Database!');
      print('🎉 SIGNUP SUCCESSFUL!');
    } catch (dbError) {
      print('❌ DATABASE ERROR: $dbError');
      print('🔧 Database error details: ${dbError.toString()}');
      
      // If database fails, delete the auth user to keep things clean
      await userCredential.user!.delete();
      print('🗑️ Deleted auth user due to database failure');
      
      _showErrorDialog('Database error: Unable to save user profile. Please try again.');
      setState(() => _isLoading = false);
      return;
    }

  } on FirebaseAuthException catch (e) {
    print('❌ AUTH ERROR: ${e.code} - ${e.message}');
    String errorMessage = 'An error occurred during signup';
    
    if (e.code == 'email-already-in-use') {
      errorMessage = 'This email is already registered. Please use a different email.';
    } else if (e.code == 'weak-password') {
      errorMessage = 'Password is too weak. Please use a stronger password.';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'Invalid email address. Please check your email.';
    } else if (e.code == 'operation-not-allowed') {
      errorMessage = 'Email/password accounts are not enabled. Please contact support.';
    } else if (e.code == 'network-request-failed') {
      errorMessage = 'Network error. Please check your internet connection.';
    }
    
    _showErrorDialog(errorMessage);
    setState(() => _isLoading = false);
  } catch (e) {
    print('❌ UNEXPECTED ERROR: $e');
    print('🔧 Error type: ${e.runtimeType}');
    _showErrorDialog('An unexpected error occurred: ${e.toString()}');
    setState(() => _isLoading = false);
  }
}  

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          'Signup Error',
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
                        
                        // Header Section
                        SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              Text(
                                "Create Account",
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
                                "Join Autosure for premium protection",
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
                        
                        // Premium Glass Signup Form
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
                                    // Header with Role Toggle
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Sign Up",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        
                                        // Premium Role Toggle
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                "User",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: _isAdmin ? Colors.white54 : Colors.white,
                                                  fontWeight: _isAdmin ? FontWeight.w400 : FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              AnimatedContainer(
                                                duration: const Duration(milliseconds: 300),
                                                width: 40,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  gradient: _isAdmin 
                                                      ? LinearGradient(
                                                          colors: [
                                                            Colors.purpleAccent,
                                                            Colors.purple,
                                                          ],
                                                        )
                                                      : LinearGradient(
                                                          colors: [
                                                            Colors.grey.shade600,
                                                            Colors.grey.shade400,
                                                          ],
                                                        ),
                                                ),
                                                child: Switch(
                                                  value: _isAdmin,
                                                  onChanged: (value) => _toggleAdmin(),
                                                  activeColor: Colors.transparent,
                                                  inactiveThumbColor: Colors.transparent,
                                                  activeTrackColor: Colors.transparent,
                                                  inactiveTrackColor: Colors.transparent,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Admin",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: _isAdmin ? Colors.white : Colors.white54,
                                                  fontWeight: _isAdmin ? FontWeight.w600 : FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 30),
                                    
                                    // Name and Surname in Row for larger screens
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        if (constraints.maxWidth > 400) {
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: _buildPremiumTextField(
                                                  controller: _nameController,
                                                  focusNode: _nameFocusNode,
                                                  isFocused: _isNameFocused,
                                                  hintText: "First Name",
                                                  prefixIcon: Icons.person_rounded,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Expanded(
                                                child: _buildPremiumTextField(
                                                  controller: _surnameController,
                                                  focusNode: _surnameFocusNode,
                                                  isFocused: _isSurnameFocused,
                                                  hintText: "Last Name",
                                                  prefixIcon: Icons.person_outline_rounded,
                                                ),
                                              ),
                                            ],
                                          );
                                        } else {
                                          return Column(
                                            children: [
                                              _buildPremiumTextField(
                                                controller: _nameController,
                                                focusNode: _nameFocusNode,
                                                isFocused: _isNameFocused,
                                                hintText: "First Name",
                                                prefixIcon: Icons.person_rounded,
                                              ),
                                              const SizedBox(height: 20),
                                              _buildPremiumTextField(
                                                controller: _surnameController,
                                                focusNode: _surnameFocusNode,
                                                isFocused: _isSurnameFocused,
                                                hintText: "Last Name",
                                                prefixIcon: Icons.person_outline_rounded,
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
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
                                    
                                    const SizedBox(height: 25),
                                    
                                    // Terms and Conditions
                                    GestureDetector(
                                      onTap: _toggleTerms,
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: _termsAccepted 
                                                  ? Colors.blueAccent.withOpacity(0.8)
                                                  : Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _termsAccepted 
                                                    ? Colors.blueAccent
                                                    : Colors.white.withOpacity(0.3),
                                              ),
                                            ),
                                            child: _termsAccepted
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: "I agree to the ",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: "Terms & Conditions",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.blueAccent.shade200,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 30),
                                    
                                    // Sign Up Button
                                    _isLoading
                                        ? _buildLoadingIndicator()
                                        : _buildPremiumSignUpButton(),
                                    
                                    const SizedBox(height: 25),
                                    
                                    // Already have account
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Already have an account? ",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "Sign In",
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

  Widget _buildPremiumSignUpButton() {
    if (_glowController == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade600,
              Colors.green.shade400,
              Colors.greenAccent.shade400,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _handleSignup,
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
                "CREATE ACCOUNT",
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
                Colors.green.shade600,
                Colors.green.shade400,
                Colors.greenAccent.shade400,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.5 * (_glowAnimation?.value ?? 0.8)),
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
            onPressed: _handleSignup,
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
                  "CREATE ACCOUNT",
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent.shade400),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            "Creating Account...",
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