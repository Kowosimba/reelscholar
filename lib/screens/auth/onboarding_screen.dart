import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reelscholar/core/constants/app_colors.dart';

class _OnboardSlide {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final List<_Feature> features;

  const _OnboardSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.features,
  });
}

class _Feature {
  final String emoji;
  final String text;
  const _Feature(this.emoji, this.text);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _page = PageController();
  int _current = 0;
  late AnimationController _btnCtrl;

  static const _slides = [
    _OnboardSlide(
      title: 'Learn through\nshort-form video',
      subtitle:
          'Watch and create educational reels curated for your degree programme',
      icon: Icons.play_circle_fill_rounded,
      gradient: AppColors.onboardGradient1,
      features: [
        _Feature('🎥', 'Engaging educational content'),
        _Feature('🔍', 'Discover new topics daily'),
        _Feature('🎓', 'Learning made entertaining'),
      ],
    ),
    _OnboardSlide(
      title: 'Talk to your\nAI Tutor',
      subtitle:
          'Get real-time voice or text support from a subject-specialist AI, anytime',
      icon: Icons.smart_toy_rounded,
      gradient: AppColors.onboardGradient2,
      features: [
        _Feature('🤖', '24/7 AI Tutor support'),
        _Feature('🎙️', 'Voice & text conversations'),
        _Feature('📚', 'Flashcards & concept maps'),
      ],
    ),
    _OnboardSlide(
      title: 'Engage &\nLevel Up',
      subtitle:
          'Earn XP, unlock badges, climb leaderboards, and build your daily learning streak',
      icon: Icons.auto_awesome_rounded,
      gradient: AppColors.onboardGradient3,
      features: [
        _Feature('⚡', 'Earn XP for every action'),
        _Feature('🏆', 'Compete on leaderboards'),
        _Feature('🔥', 'Build your learning streak'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _setOverlayStyle(0);
  }

  void _setOverlayStyle(int index) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _page.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _skip() => Navigator.pushReplacementNamed(context, '/login');

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_current];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(gradient: slide.gradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar: Skip ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.65),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // ── PageView ───────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _slides.length,
                  onPageChanged: (i) {
                    setState(() => _current = i);
                    _setOverlayStyle(i);
                  },
                  itemBuilder: (_, i) => _SlideContent(slide: _slides[i]),
                ),
              ),

              // ── Dots + button ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _current ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _current
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary CTA button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _current == _slides.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (_current < _slides.length - 1) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Already have account
                    GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Already have an account? Sign in',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  final _OnboardSlide slide;
  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with glass effect
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(slide.icon, size: 54, color: Colors.white),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 14),

          // Subtitle
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.55,
            ),
          ),

          const SizedBox(height: 36),

          // Feature bullets
          ...slide.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(f.emoji, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      f.text,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
