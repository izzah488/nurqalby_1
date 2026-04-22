import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title':    'Guidance for\nEvery Emotion',
      'subtitle': 'Whether you are happy, anxious, or seeking answers, let the Quran speak directly to your situation and heart.',
      'image':    'assets/images/welcome1.jpg',
    },
    {
      'title':    'Find Peace\nThrough Verses',
      'subtitle': 'Discover Quran verses that match your feelings and bring comfort to your soul.',
      'image':    'assets/images/welcome2.jpg',
    },
    {
      'title':    'Listen &\nReflect',
      'subtitle': 'Listen to beautiful recitations and let the words of Allah guide your heart.',
      'image':    'assets/images/welcome3.jpg',
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeInOut,
      );
    } else {
      _goToApp();
    }
  }

  void _goToApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // --- Page view ---
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _OnboardingPage(data: _pages[index]);
            },
          ),

          // --- Top badge ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3320).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFFFDD0).withOpacity(0.25), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded,
                            color: Color(0xFFB8D4BB), size: 14),
                        SizedBox(width: 6),
                        Text('QURAN GUIDE',
                            style: TextStyle(
                                color: Color(0xFFB8D4BB),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8)),
                      ],
                    ),
                  ),

                  // Skip button
                  if (_currentPage < _pages.length - 1)
                    GestureDetector(
                      onTap: _goToApp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFFFFDD0).withOpacity(0.2)),
                        ),
                        child: const Text('Skip',
                            style: TextStyle(
                                color: Color(0xFFFFFDD0), fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- Bottom content ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 52),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0F1E12).withOpacity(0.92),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Title
                  Text(
                    _pages[_currentPage]['title']!,
                    style: const TextStyle(
                      color:      Color(0xFFFFFDD0),
                      fontSize:   32,
                      fontWeight: FontWeight.w700,
                      height:     1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    _pages[_currentPage]['subtitle']!,
                    style: const TextStyle(
                      color:    Color(0xFFFFFDD0),
                      fontSize: 14,
                      height:   1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Dots + Button row
                  Row(
                    children: [

                      // Dots
                      Row(
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            width:  _currentPage == i ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? const Color(0xFF355E3B)
                                  : const Color(0xFFFFFDD0).withOpacity(0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Get Started / Next button
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          decoration: BoxDecoration(
                            color:        const Color(0xFF355E3B),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF355E3B).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _pages.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: const TextStyle(
                                    color:      Color(0xFFFFFDD0),
                                    fontSize:   15,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Color(0xFFFFFDD0), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────
// Single onboarding page
// ─────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final Map<String, String> data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          data['image']!,
          fit: BoxFit.cover,
        ),
        // Dark + green tinted overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F1E12).withOpacity(0.18),
                const Color(0xFF0F1E12).withOpacity(0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
