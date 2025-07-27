import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diary_entity.dart';
import '../../widgets/diary_header.dart';
import '../../widgets/diary_emotion_selector.dart';
import '../../widgets/diary_content_field.dart';
import '../../core/di/injection_container.dart';

class DiaryWriteView extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final DiaryEntity? existingEntry;
  final DiaryEntity? existingDiary;

  const DiaryWriteView({
    Key? key,
    required this.selectedDate,
    this.existingEntry,
    this.existingDiary,
  }) : super(key: key);

  @override
  ConsumerState<DiaryWriteView> createState() => _DiaryWriteViewState();
}

class _DiaryWriteViewState extends ConsumerState<DiaryWriteView> {
  final TextEditingController _contentController = TextEditingController();
  String? _selectedEmotion;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final existingData = widget.existingEntry ?? widget.existingDiary;
    if (existingData != null) {
      _contentController.text = existingData.content;
      _selectedEmotion = existingData.emotion;
    }
  }

  Future<void> _saveDiary() async {
    try {
      final userState = ref.read(userViewModelProvider);
      
      if (userState.user?.userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 ID를 불러올 수 없습니다. 다시 시도해 주세요.')),
        );
        return;
      }

      if (_selectedEmotion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('감정을 선택해주세요!')),
        );
        return;
      }

      final diaryEntity = DiaryEntity(
        date: widget.selectedDate,
        content: _contentController.text,
        emotion: _selectedEmotion!,
        userId: userState.user!.userId,
      );

      final diaryViewModel = ref.read(diaryViewModelProvider.notifier);

      final existingData = widget.existingEntry ?? widget.existingDiary;
      if (existingData != null) {
        await diaryViewModel.updateDiary(diaryEntity);
        print('일기 수정 완료: ${diaryEntity.date}');
      } else {
        await diaryViewModel.createDiary(diaryEntity);
        print('일기 생성 완료: ${diaryEntity.date}');
      }

      // 저장 완료 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일기가 저장되었습니다.'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      print('일기 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diaryState = ref.watch(diaryViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: DiaryHeader(
        selectedDate: widget.selectedDate,
        leftButtonText: '취소',
        rightButtonText: '저장',
        onRightPressed: _saveDiary,
      ),
      body: diaryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                DiaryEmotionSelector(
                  selectedEmotion: _selectedEmotion,
                  onEmotionSelected: (emotion) {
                    setState(() {
                      _selectedEmotion = emotion;
                    });
                  },
                ),
                Expanded(
                  child: DiaryContentField(
                    controller: _contentController,
                  ),
                ),
              ],
            ),
    );
  }
}