import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart'; // Import Lottie
import 'dart:async'; // Add this import for Timer

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    // Add a listener to the animation controller to start delay when animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Add a 2-second delay before navigation
        Timer(const Duration(seconds: 2), () {
          _checkAuthAndNavigate();
        });
      }
    });

    _animationController.forward();
  }

  // Check for JWT token and navigate accordingly
  void _checkAuthAndNavigate() async {
    var box = Hive.box('authBox');
    var token = box.get('jwtToken');
    if (token != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E1E1E), // Darker gray
                Color(0xFF121212), // Very dark gray
                Color(0xFF0A0A0A), // Almost black
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(
                    flex: 2,
                  ),
                  // App logo with animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + 0.1 * _animationController.value,
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                  spreadRadius: 2 * _animationController.value,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App name with animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      "CloseCart",
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.yellow, // Yellow text
                        fontWeight: FontWeight.bold,
                        fontSize: 40,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            offset: const Offset(2, 2),
                            blurRadius: 5,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tagline with animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      "Shop smart, shop close",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  Spacer(
                    flex: 1,
                  ),
                  // Lottie animation replacing the logo
                  Lottie.asset(
                    'assets/images/splash_animation.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
