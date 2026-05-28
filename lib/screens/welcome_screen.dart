import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _buttonController;
  late AnimationController _glowController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Button animations controller
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Glow effect animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    // Text fade animation
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Button scale animation
    _buttonScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));
    
    // Button slide animation
    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutBack,
    ));
    
    // Glow animation
    _glowAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOutSine,
    ));
    
    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 1200), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onGetStartedPressed() {
    _buttonController.forward(from: 0.7);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isLargeScreen = size.width > 600;
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 52, 90),
      body: Stack(
        children: [
          // Animated background with subtle gradient movement
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      -0.5 + 0.5 * _glowController.value,
                      -0.3 + 0.3 * _glowController.value,
                    ),
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
          ),
          
          // Subtle grid pattern
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/grid_pattern.png'), // Add a subtle grid pattern asset
                fit: BoxFit.cover,
                opacity: 0.1,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.05),
                  BlendMode.overlay,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 600 : double.infinity,
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    
                    // Premium Logo Container
                    ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            width: isLargeScreen ? 280 : 220,
                            height: isLargeScreen ? 280 : 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.blueAccent.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                // Multi-layered glow effect
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.4 * _glowAnimation.value),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.3 * _glowAnimation.value),
                                  blurRadius: 80,
                                  spreadRadius: 30,
                                ),
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.2 * _glowAnimation.value),
                                  blurRadius: 100,
                                  spreadRadius: 40,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ring
                                Container(
                                  width: isLargeScreen ? 200 : 160,
                                  height: isLargeScreen ? 200 : 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                
                                // Middle ring
                                Container(
                                  width: isLargeScreen ? 150 : 120,
                                  height: isLargeScreen ? 150 : 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                
                                // Logo content
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.security_rounded,
                                      size: isLargeScreen ? 64 : 48,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'AUTO',
                                      style: GoogleFonts.poppins(
                                        fontSize: isLargeScreen ? 24 : 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    Text(
                                      'SURE',
                                      style: GoogleFonts.poppins(
                                        fontSize: isLargeScreen ? 24 : 18,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Animated Text Content
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'AUTO SURE',
                            style: GoogleFonts.poppins(
                              fontSize: isLargeScreen ? 42 : 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Premium Vehicle Protection',
                            style: GoogleFonts.poppins(
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 2,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(flex: 3),
                    
                    // Premium Glass Get Started Button
                    SlideTransition(
                      position: _buttonSlideAnimation,
                      child: ScaleTransition(
                        scale: _buttonScaleAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 100 : 40,
                          ),
                          child: Container(
                            height: isLargeScreen ? 70 : 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(35),
                              child: InkWell(
                                onTap: _onGetStartedPressed,
                                borderRadius: BorderRadius.circular(35),
                                hoverColor: Colors.white.withOpacity(0.1),
                                splashColor: Colors.white.withOpacity(0.2),
                                child: Stack(
                                  children: [
                                    // Animated shimmer effect
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(35),
                                        child: AnimatedBuilder(
                                          animation: _glowController,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(
                                                _glowController.value * 400 - 200,
                                                0,
                                              ),
                                              child: Container(
                                                width: 100,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.white.withOpacity(0.15),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    
                                    // Button content
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 30),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'GET STARTED',
                                              style: GoogleFonts.poppins(
                                                fontSize: isLargeScreen ? 16 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: 1.3,
                                              ),
                                            ),
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white.withOpacity(0.2),
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Footer text
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Text(
                        'Secure • Reliable • Trusted',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}