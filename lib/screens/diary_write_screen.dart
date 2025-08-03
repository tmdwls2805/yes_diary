import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/providers/diary_provider.dart';
import 'package:yes_diary/providers/user_provider.dart';
import 'package:yes_diary/widgets/diary_header.dart';
import 'package:yes_diary/widgets/diary_emotion_selector.dart';
import 'package:yes_diary/widgets/diary_content_field.dart';
import 'package:yes_diary/widgets/confirm_dialog.dart';

class DiaryWriteScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final DiaryEntry? existingEntry;

  const DiaryWriteScreen({Key? key, required this.selectedDate, this.existingEntry}) : super(key: key);

  @override
  ConsumerState<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends ConsumerState<DiaryWriteScreen> {
  final TextEditingController _contentController = TextEditingController();
  String? _selectedEmotion;

  String _initialContent = '';
  String? _initialEmotion;

  bool get _isModified =>
      _contentController.text != _initialContent ||
      _selectedEmotion != _initialEmotion;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _loadExistingData() {
    if (widget.existingEntry != null) {
      _contentController.text = widget.existingEntry!.content;
      _selectedEmotion = widget.existingEntry!.emotion;
    }
    _initialContent = _contentController.text;
    _initialEmotion = _selectedEmotion;
  }

  void _handleCancel() async {
    if (!_isModified) {
      Navigator.of(context).pop();
      return;
    }

    final bool? shouldPop = await showExitConfirmDialog(context);
    if (shouldPop == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveDiary() async {
    final userData = ref.read(userProvider);
    
    if (userData.userId == null) {
      print('User ID is null. Cannot save diary.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 ID를 불러올 수 없습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    if (_selectedEmotion == null) {
      print('Emotion is not selected.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('감정을 선택해주세요!')),
      );
      return;
    }

    final diaryEntry = DiaryEntry(
      date: widget.selectedDate,
      content: _contentController.text,
      emotion: _selectedEmotion!,
      userId: userData.userId!,
    );

    if (widget.existingEntry != null) {
      await ref.read(diaryProvider.notifier).updateDiary(diaryEntry);
    } else {
      await ref.read(diaryProvider.notifier).saveDiary(diaryEntry);
    }

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onTextChanged);
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isModified,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final bool? shouldPop = await showExitConfirmDialog(context);
        if (shouldPop == true && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: DiaryHeader(
          selectedDate: widget.selectedDate,
          leftButtonText: '취소',
          rightButtonText: '저장',
          onLeftPressed: _handleCancel, 
          onRightPressed: _saveDiary,
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            color: const Color(0xFF1A1A1A),
            width: double.infinity,
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                DiaryEmotionSelector(
                  selectedEmotion: _selectedEmotion,
                  onEmotionSelected: (emotion) {
                    setState(() {
                      _selectedEmotion = emotion;
                    });
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DiaryContentField(
                      controller: _contentController,
                      isReadOnly: false,
                    ),
                  ),
                ),
                const SizedBox(height: 42.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}