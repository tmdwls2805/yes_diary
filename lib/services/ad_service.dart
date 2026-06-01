import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
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
    final adUnitId = _testInterstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    final completer = Completer<void>();

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!completer.isCompleted) completer.complete();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                if (!completer.isCompleted) completer.complete();
              },
            );
            ad.show().catchError((_) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            });
          },
          onAdFailedToLoad: (error) {
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }
}
