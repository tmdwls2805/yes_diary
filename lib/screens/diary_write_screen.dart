// lib/screens/diary_write_screen.dart
import 'package:flutter/material.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/services/database_service.dart';
import 'package:yes_diary/core/services/storage/secure_storage_service.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG 사용을 위한 import
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위한 import
import 'package:flutter/services.dart'; // MaxLengthEnforcement를 위한 import 추가
import 'package:yes_diary/core/constants/app_image.dart'; // 추가

class DiaryWriteScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DiaryWriteScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _DiaryWriteScreenState createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final TextEditingController _contentController = TextEditingController();
  String? _selectedEmotion;
  String? _currentUserId;
  // String _emotionQuestionText = '오늘 해소할 감정은 무엇인가요?'; // 이 변수 제거

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    _currentUserId = await SecureStorageService().getUserId();
    setState(() {});
  }

  Future<void> _saveDiary() async {
    if (_currentUserId == null) {
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

    final newEntry = DiaryEntry(
      date: widget.selectedDate,
      content: _contentController.text,
      emotion: _selectedEmotion!,
      userId: _currentUserId!,
    );

    await DatabaseService.instance.diaryRepository.insertDiary(newEntry);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 24.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            elevation: 0,
            leading: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            title: Text(
              DateFormat('yyyy.MM.dd').format(widget.selectedDate),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: _saveDiary,
                child: const Text(
                  '저장',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                  children: AppImages.emotionFaceSvgPaths.entries.map((entry) {
                    final emotionName = entry.key;
                    final svgPath = entry.value;
                    // final koreanName = AppImages.emotionKoreanNames[emotionName]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0), // 4px 간격을 위해 각 아이템에 2px씩 적용
                      child: _buildEmotionOption(emotionName, svgPath), // 한글 이름 전달
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 28.0),
                  child: Text(
                    _selectedEmotion == null
                        ? '오늘 해소할 감정은 무엇인가요?' // 감정 미선택 시 기본 문장
                        : AppImages.emotionQuestionTexts[_selectedEmotion]!, // 선택된 감정에 따라 동적 문장 사용
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF363636),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Scrollbar(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        maxLength: 2000, // 2000자로 제한
                        maxLengthEnforcement: MaxLengthEnforcement.enforced, // 길이 제한 강제 적용
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: '오늘의 일기를 작성해주세요...',
                          hintStyle: TextStyle(color: Color(0xFF808080)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 42.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionOption(String emotionName, String svgPath) {
    final isSelected = _selectedEmotion == emotionName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmotion = emotionName;
        });
      },
      child: Transform.translate(
        offset: Offset(0, isSelected ? -8.0 : 0),
        child: Container(
          width: 52, // 48px SVG + 2px*2 테두리 = 52px
          height: 52, // 48px SVG + 2px*2 테두리 = 52px
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: const Color(0xFFFF0000), width: 2.0)
                : null,
          ),
          child: SvgPicture.asset(
            svgPath,
            width: 48, // SVG 크기 48px
            height: 48, // SVG 크기 48px
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}