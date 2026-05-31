import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/screens/main_screen.dart';
import 'package:yes_diary/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final profile = await SecureStorageService().getOnboardingProfile();
    if (!mounted) return;
    final hasProfile = (profile['nickname'] ?? '').isNotEmpty;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            hasProfile ? const MainScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icon/splash.svg'),
            const SizedBox(height: 28),
            const Text(
              '앗 네!의 일기',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
