import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static DateTime? _lastShowAttemptAt;

  static String get _testInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  static Future<void> showDiarySavedInterstitialIfAvailable() async {
    final now = DateTime.now();
    final lastAttempt = _lastShowAttemptAt;
    if (lastAttempt != null &&
        now.difference(lastAttempt) < const Duration(seconds: 2)) {
      debugPrint('광고 미표시: 중복 호출 방지');
      return;
    }
    _lastShowAttemptAt = now;

    final adUnitId = _testInterstitialAdUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('광고 미표시: 지원하지 않는 플랫폼입니다.');
      return;
    }

    final completer = Completer<void>();

    try {
      debugPrint('일기 저장 광고 로드 시작: $adUnitId');
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('일기 저장 광고 로드 성공');
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('일기 저장 광고 닫힘');
                ad.dispose();
                if (!completer.isCompleted) completer.complete();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('일기 저장 광고 표시 실패: $error');
                ad.dispose();
                if (!completer.isCompleted) completer.complete();
              },
            );
            ad.show().catchError((_) {
              debugPrint('일기 저장 광고 show 호출 실패');
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            });
          },
          onAdFailedToLoad: (error) {
            debugPrint('일기 저장 광고 로드 실패: $error');
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
    } catch (error) {
      debugPrint('일기 저장 광고 예외: $error');
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }
}
