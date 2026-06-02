import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/core/constants/app_image.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/providers/diary_provider.dart';
import 'package:yes_diary/providers/user_provider.dart';
import 'package:yes_diary/services/ad_service.dart';
import 'package:yes_diary/widgets/confirm_dialog.dart';
import 'package:yes_diary/widgets/diary_emotion_selector.dart';
import 'package:yes_diary/widgets/diary_header.dart';

class DiaryEmotionSelectScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final String content;
  final DiaryEntry? existingEntry;
  final bool showAdOnSave;

  const DiaryEmotionSelectScreen({
    super.key,
    required this.selectedDate,
    required this.content,
    this.existingEntry,
    this.showAdOnSave = true,
  });

  @override
  ConsumerState<DiaryEmotionSelectScreen> createState() =>
      _DiaryEmotionSelectScreenState();
}

class _DiaryEmotionSelectScreenState
    extends ConsumerState<DiaryEmotionSelectScreen> {
  static const int _virtualBase = 10000;

  static const int _cardMessageMaxLength = 20;

  String? _selectedEmotion;
  bool _isSaving = false;
  late final List<String> _emotionOrder;
  late final PageController _cardController;
  bool _syncingFromTap = false;
  final TextEditingController _cardMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emotionOrder = AppImages.emotionBlockImagePaths.keys.toList();
    _selectedEmotion =
        widget.existingEntry?.emotionName ?? _emotionOrder.first;
    _cardMessageController.text = widget.existingEntry?.cardMessage ?? '';
    _cardMessageController.addListener(() => setState(() {}));

    final initialIndex =
        _virtualBase + _emotionOrder.indexOf(_selectedEmotion!);

    _cardController = PageController(
      viewportFraction: 0.72,
      initialPage: initialIndex,
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    _cardMessageController.dispose();
    super.dispose();
  }

  String _emotionAt(int virtualIndex) {
    final idx = virtualIndex % _emotionOrder.length;
    return _emotionOrder[idx];
  }

  void _onCardPageChanged(int virtualIndex) {
    if (_syncingFromTap) return;
    final emotion = _emotionAt(virtualIndex);
    if (emotion == _selectedEmotion) return;
    setState(() {
      _selectedEmotion = emotion;
    });
  }

  void _onEmotionTapped(String emotion) {
    if (emotion == _selectedEmotion) return;
    setState(() {
      _selectedEmotion = emotion;
    });

    if (!_cardController.hasClients) return;
    final currentPage = _cardController.page?.round() ?? _virtualBase;
    final currentEmotionIndex = currentPage % _emotionOrder.length;
    final targetEmotionIndex = _emotionOrder.indexOf(emotion);
    final diff = targetEmotionIndex - currentEmotionIndex;
    final targetPage = currentPage + diff;

    _syncingFromTap = true;
    _cardController
        .animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _syncingFromTap = false);
  }

  Future<void> _handleCancel() async {
    final bool? shouldExit = await showExitConfirmDialog(context);
    if (shouldExit == true && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _saveDiary() async {
    if (_isSaving) return;

    final userData = ref.read(userProvider);
    final emotionName = _selectedEmotion;

    if (userData.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 ID를 불러올 수 없습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    if (emotionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('감정을 선택해주세요!')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final cardMessageText = _cardMessageController.text.trim();
    final cardMessage = cardMessageText.isEmpty ? null : cardMessageText;

    final diaryEntry = (widget.existingEntry ??
            DiaryEntry(
              date: widget.selectedDate,
              content: widget.content,
              emotionId: DiaryEntry.emotionNameToId(emotionName),
              cardMessage: cardMessage,
              userId: userData.userId!,
            ))
        .copyWith(
      date: widget.selectedDate,
      content: widget.content,
      emotionId: DiaryEntry.emotionNameToId(emotionName),
      cardMessage: cardMessage,
      userId: userData.userId!,
    );

    if (widget.existingEntry != null) {
      await ref.read(diaryProvider.notifier).updateDiary(diaryEntry);
    } else {
      await ref.read(diaryProvider.notifier).saveDiary(diaryEntry);
    }

    final localUserId = await SecureStorageService().getLocalUserId();
    final shouldShowAd = userData.userId == localUserId;

    if (!mounted) return;
    await showSaveConfirmDialog(context);

    if (!mounted) return;
    Navigator.of(context).pop(true);

    if (shouldShowAd && widget.showAdOnSave) {
      Future<void>.microtask(
        AdService.showDiarySavedInterstitialIfAvailable,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: DiaryHeader(
        selectedDate: widget.selectedDate,
        leftButtonText: '뒤로',
        rightButtonText: '저장',
        onLeftPressed: () => Navigator.of(context).pop(false),
        onRightPressed: _isSaving ? null : _saveDiary,
        rightButtonFontWeight: FontWeight.bold,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          color: const Color(0xFF1A1A1A),
          child: Column(
            children: [
              const SizedBox(height: 34),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Pretendard',
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    const TextSpan(text: '오늘의 감정요정: '),
                    if (_selectedEmotion != null)
                      TextSpan(
                        text: AppImages.emotionLabels[_selectedEmotion!] ?? '',
                        style: TextStyle(
                          color: AppImages.emotionColors[_selectedEmotion!],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 38),
              SizedBox(
                height: 286,
                child: PageView.builder(
                  controller: _cardController,
                  onPageChanged: _onCardPageChanged,
                  itemBuilder: (context, index) {
                    final emotion = _emotionAt(index);
                    final isCenter = emotion == _selectedEmotion;
                    return AnimatedScale(
                      scale: isCenter ? 1.0 : 0.86,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: AnimatedOpacity(
                        opacity: isCenter ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 220),
                        child: Center(
                          child: SizedBox(
                            height: 255,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Image.asset(
                                  AppImages.emotionCardImagePaths[emotion]!,
                                  fit: BoxFit.contain,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 24,
                                    left: 16,
                                    right: 16,
                                  ),
                                  child: Text(
                                    isCenter &&
                                            _cardMessageController.text
                                                .isNotEmpty
                                        ? _cardMessageController.text
                                        : (AppImages.emotionCardTexts[emotion] ??
                                            ''),
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Pretendard',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),
              DiaryEmotionSelector(
                selectedEmotion: _selectedEmotion,
                showQuestionText: false,
                imagePaths: AppImages.emotionBlockImagePaths,
                itemSpacing: 8,
                onEmotionSelected: _onEmotionTapped,
              ),
              const SizedBox(height: 29),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '카드 메세지를 작성해주세요.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Pretendard',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  height: 57,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C5C5C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cardMessageController,
                          maxLength: _cardMessageMaxLength,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              _cardMessageMaxLength,
                            ),
                          ],
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          cursorColor: Colors.white,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_cardMessageController.text.characters.length}/$_cardMessageMaxLength',
                        style: const TextStyle(
                          color: Color(0xFF838383),
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C5C5C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveDiary,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4646),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '일기 저장',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
