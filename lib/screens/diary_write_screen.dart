import 'package:flutter/material.dart';
import 'package:yes_diary/models/diary_entry.dart';
import 'package:yes_diary/screens/diary_emotion_select_screen.dart';
import 'package:yes_diary/widgets/diary_header.dart';
import 'package:yes_diary/widgets/diary_content_field.dart';
import 'package:yes_diary/widgets/confirm_dialog.dart';

class DiaryWriteScreen extends StatefulWidget {
  final DateTime selectedDate;
  final DiaryEntry? existingEntry;
  final bool showAdOnSave;

  const DiaryWriteScreen({
    super.key,
    required this.selectedDate,
    this.existingEntry,
    this.showAdOnSave = true,
  });

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final TextEditingController _contentController = TextEditingController();

  String _initialContent = '';

  bool get _isModified => _contentController.text != _initialContent;

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
    }
    _initialContent = _contentController.text;
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

  Future<void> _openEmotionSelect() async {
    FocusScope.of(context).unfocus();

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DiaryEmotionSelectScreen(
          selectedDate: widget.selectedDate,
          content: _contentController.text,
          existingEntry: widget.existingEntry,
          showAdOnSave: widget.showAdOnSave,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
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
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: DiaryHeader(
          selectedDate: widget.selectedDate,
          leftButtonText: '뒤로',
          onLeftPressed: _handleCancel,
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              color: const Color(0xFF1A1A1A),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Text(
                        '오늘의 감정을 작성해주세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Pretendard',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DiaryContentField(
                        controller: _contentController,
                        isReadOnly: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openEmotionSelect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4646),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '작성 완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
