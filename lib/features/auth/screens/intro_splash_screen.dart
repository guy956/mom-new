import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/features/home/screens/main_screen.dart';

/// MOMIT Premium Intro Splash - Warm & Inviting Design
/// Beautiful entrance with soft pink/cream palette - NOT dark/black
class IntroSplashScreen extends StatefulWidget {
  final String userName;
  const IntroSplashScreen({super.key, required this.userName});

  @override
  State<IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<IntroSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _rippleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotateY;
  late Animation<double> _logoFade;
  late Animation<double> _ringExpand;
  late Animation<double> _glowPulse;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _shimmerProgress;
  late Animation<double> _rippleAnimation;

  final List<_FloatingParticle> _particles = [];
  final _rand = Random.secure();

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _setupAnimations();
    _startSequence();
  }

  void _generateParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(_FloatingParticle(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        size: _rand.nextDouble() * 5 + 2,
        speed: _rand.nextDouble() * 0.2 + 0.05,
        opacity: _rand.nextDouble() * 0.4 + 0.1,
        twinkleOffset: _rand.nextDouble() * 2 * pi,
        type: i % 4 == 0 ? 1 : 0, // 1 = heart, 0 = dot
        driftX: (_rand.nextDouble() - 0.5) * 0.2,
      ));
    }
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200),
    );

    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _textController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    );

    _particleController = AnimationController(
      vsync: this, duration: const Duration(seconds: 16),
    )..repeat();

    _rippleController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Logo: Elegant bounce-in
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.92).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.04).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ]).animate(_mainController);

    _logoRotateY = Tween<double>(begin: -0.4, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );

    _ringExpand = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.65, curve: Curves.easeOutCubic)),
    );

    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)),
    );

    _shimmerProgress = Tween<double>(begin: 0.0, end: 1.0).animate(_shimmerController);

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  void _startSequence() {
    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });

    Future.delayed(const Duration(milliseconds: 4200), () {
      if (!mounted) return;
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionDuration: const Duration(milliseconds: 1000),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        ),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Warm, inviting gradient background - NO dark/black
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFDF5F6),  // Soft blush top
                  Color(0xFFF7EDEF),  // Rose breath
                  Color(0xFFF5F0ED),  // Warm cream
                  Color(0xFFFFFFFF),  // Pure white bottom
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Soft radial glow from center
          AnimatedBuilder(
            animation: Listenable.merge([_mainController, _pulseController]),
            builder: (_, __) => Opacity(
              opacity: _logoFade.value * 0.6,
              child: Center(
                child: Container(
                  width: size.width * (0.8 + _glowPulse.value * 0.1),
                  height: size.width * (0.8 + _glowPulse.value * 0.1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15 * _glowPulse.value),
                        AppColors.primaryLight.withValues(alpha: 0.08),
                        AppColors.secondary.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Soft ripple waves
          AnimatedBuilder(
            animation: _rippleController,
            builder: (_, __) {
              return Center(
                child: Opacity(
                  opacity: (1.0 - _rippleAnimation.value) * 0.12 * _logoFade.value,
                  child: Container(
                    width: 160 + _rippleAnimation.value * size.width * 0.5,
                    height: 160 + _rippleAnimation.value * size.width * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: (1.0 - _rippleAnimation.value) * 0.25),
                        width: 1.5 * (1.0 - _rippleAnimation.value),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating particles - warm pink/cream dots
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              painter: _WarmParticlePainter(
                particles: _particles,
                progress: _particleController.value,
                pulseValue: _pulseController.value,
              ),
              size: Size.infinite,
            ),
          ),

          // Expanding rings - soft pink
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_mainController, _pulseController]),
              builder: (_, __) {
                return Opacity(
                  opacity: _logoFade.value * 0.2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: List.generate(4, (i) {
                      final baseScale = 1.3 + i * 0.45;
                      final scale = _ringExpand.value * baseScale * (1.0 + _glowPulse.value * 0.03);
                      final alpha = (0.2 - i * 0.04).clamp(0.02, 0.2);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: alpha),
                              width: 1.5 - i * 0.3,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),

          // Main 3D Logo
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_mainController, _pulseController, _shimmerController]),
              builder: (_, __) {
                return Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_logoRotateY.value),
                      child: _buildLogo(),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Text Section
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _textController,
              builder: (_, __) => FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(36, 0, 36, 90),
                    child: Column(
                      children: [
                        // Shimmer text MOMIT - warm colors
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (_, __) => ShaderMask(
                            shaderCallback: (bounds) {
                              final shimmerX = _shimmerProgress.value * 2.5 - 0.75;
                              return LinearGradient(
                                begin: Alignment(shimmerX - 0.4, 0),
                                end: Alignment(shimmerX + 0.4, 0),
                                colors: const [
                                  Color(0xFFD4A1AC),
                                  Color(0xFFBE8A93),
                                  Color(0xFFD4A1AC),
                                  Color(0xFFBE8A93),
                                  Color(0xFFD4A1AC),
                                ],
                                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              'MOMIT',
                              style: TextStyle(
                                fontFamily: 'Heebo',
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Greeting - clear readable dark text on light bg
                        Text(
                          '\u05d4\u05d9\u05d9 ${widget.userName}',
                          style: const TextStyle(
                            fontFamily: 'Heebo',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF45393C), // Dark readable on light bg
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Slogan pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.15),
                                AppColors.secondary.withValues(alpha: 0.08),
                              ],
                            ),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            '\u05db\u05d9 \u05e8\u05e7 \u05d0\u05de\u05d0 \u05de\u05d1\u05d9\u05e0\u05d4 \u05d0\u05de\u05d0',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7A6E70), // Readable hint on light bg
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildLoadingBar(),
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

  Widget _buildLogo() {
    return Container(
      width: 155,
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A1AC), Color(0xFFC4939C), Color(0xFFBE8A93)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // Outer glow - warm pink
          BoxShadow(
            color: AppColors.primary.withValues(alpha: _glowPulse.value * 0.35),
            blurRadius: 40 + _glowPulse.value * 20,
            spreadRadius: 2,
          ),
          // Soft warm shadow
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: _glowPulse.value * 0.2),
            blurRadius: 60 + _glowPulse.value * 15,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner shine highlight
          Positioned(
            top: 14, left: 14,
            child: Container(
              width: 60, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Heart icon
          Icon(
            Icons.favorite_rounded,
            color: Colors.white.withValues(alpha: 0.95),
            size: 75,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBar() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (_, __) {
        final progress = _mainController.value.clamp(0.0, 1.0);
        return Column(
          children: [
            Container(
              width: 140,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4A1AC), Color(0xFFC4939C), Color(0xFFBE8A93)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 11,
                color: AppColors.textHint.withValues(alpha: 0.6),
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FloatingParticle {
  double x, y, size, speed, opacity, twinkleOffset, driftX;
  int type;
  _FloatingParticle({
    required this.x, required this.y, required this.size,
    required this.speed, required this.opacity, required this.twinkleOffset,
    required this.type, required this.driftX,
  });
}

class _WarmParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;
  final double pulseValue;

  _WarmParticlePainter({required this.particles, required this.progress, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFD4A1AC), // Primary pink
      const Color(0xFFE8C8CE), // Light pink
      const Color(0xFFC4939C), // Rose
      const Color(0xFFCCBBB4), // Warm nude
    ];

    for (final p in particles) {
      final y = ((p.y + progress * p.speed) % 1.0) * size.height;
      final x = p.x * size.width + sin(progress * 2 * pi + p.twinkleOffset) * 15 + p.driftX * progress * size.width;
      final twinkle = (sin(progress * 4 * pi + p.twinkleOffset) + 1) / 2;
      final alpha = p.opacity * (0.3 + twinkle * 0.7) * (0.5 + pulseValue * 0.5);

      final colorIndex = (p.twinkleOffset * 10).toInt() % colors.length;
      final color = colors[colorIndex];

      if (p.type == 1) {
        // Bigger soft glow
        final paint = Paint()
          ..color = color.withValues(alpha: alpha * 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 1.2);
        canvas.drawCircle(Offset(x, y), p.size * 1.5, paint);
      } else {
        // Dot particle
        final paint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.5);
        canvas.drawCircle(Offset(x, y), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
