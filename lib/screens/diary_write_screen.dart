import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/providers/diary_provider.dart';
import 'package:yes_diary/providers/user_provider.dart';
import 'package:yes_diary/widgets/diary_header.dart';
import 'package:yes_diary/widgets/diary_emotion_selector.dart';
import 'package:yes_diary/widgets/diary_content_field.dart';

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

  // 초기 상태를 저장하여 변경 여부를 감지하기 위한 변수
  String _initialContent = '';
  String? _initialEmotion;

  // 내용이나 감정이 변경되었는지 확인하는 getter
  bool get _isModified =>
      _contentController.text != _initialContent ||
      _selectedEmotion != _initialEmotion;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    // 텍스트 컨트롤러에 리스너를 추가하여 텍스트 변경 감지
    _contentController.addListener(_onTextChanged);
  }

  // 텍스트가 변경될 때마다 setState를 호출하여 화면을 갱신하는 함수
  void _onTextChanged() {
    setState(() {
      // PopScope가 _isModified 값을 다시 확인하도록 화면을 갱신
    });
  }

  void _loadExistingData() {
    if (widget.existingEntry != null) {
      _contentController.text = widget.existingEntry!.content;
      _selectedEmotion = widget.existingEntry!.emotion;
    }
    // 위젯이 로드될 때의 초기값을 저장
    _initialContent = _contentController.text;
    _initialEmotion = _selectedEmotion;
  }

  // 뒤로가기 또는 취소 시 표시될 다이얼로그
  Future<bool?> _showExitConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            '😳 혹시,, 너 사축이야??',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '글쓰기를 취소하시면 글을 저장되지 않습니다.\n작성하신 글은 본인만 확인 가능하며 이후 수정 가능합니다.\n정말 취소하시겠습니까?',
            style: TextStyle(color: Colors.white70),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.zero,
          actions: <Widget>[
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.of(context).pop(true), // 네
                      child: const Text('네'),
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[700]),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => Navigator.of(context).pop(false), // 아니요
                      child: const Text('아니요'),
                    ),
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  // 취소 버튼을 눌렀을 때의 동작을 처리하는 함수
  void _handleCancel() async {
    // 내용이 변경되지 않았으면 그냥 뒤로가기
    if (!_isModified) {
      Navigator.of(context).pop();
      return;
    }

    // 변경 내용이 있으면 다이얼로그를 띄움
    final bool? shouldPop = await _showExitConfirmDialog();
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
    // 위젯이 종료될 때 리스너를 제거하여 메모리 누수를 방지
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
        final bool? shouldPop = await _showExitConfirmDialog();
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
