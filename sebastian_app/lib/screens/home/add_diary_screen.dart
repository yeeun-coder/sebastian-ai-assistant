import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/models/diary_entry.dart';
import 'package:sebastian_app/widgets/diary_controller.dart';

class AddDiaryScreen extends StatefulWidget {
  const AddDiaryScreen({
    super.key,
    required this.diaryDate,
    this.existing,
  });

  final String diaryDate;
  final DiaryEntry? existing;

  @override
  State<AddDiaryScreen> createState() => _AddDiaryScreenState();
}

class _AddDiaryScreenState extends State<AddDiaryScreen> {
  final controller = Get.find<DiaryController>();
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  String? selectedMood;

  DiaryEntry? get existing => widget.existing;
  String get diaryDate => widget.diaryDate;

  @override
  void initState() {
    super.initState();
    _prefillFromExisting();

    titleController.addListener(() => setState(() {}));
    contentController.addListener(() => setState(() {}));
  }

  void _prefillFromExisting() {
    final entry = existing;
    if (entry == null) return;

    titleController.text = entry.title ?? '';
    contentController.text = entry.content;
    final m = entry.mood ?? '';
    if (m == '좋음') {
      selectedMood = 'good';
    } else if (m == '보통') {
      selectedMood = 'neutral';
    } else if (m == '나쁨') {
      selectedMood = 'bad';
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  String get _moodLabel {
    switch (selectedMood) {
      case 'good': return '좋음';
      case 'neutral': return '보통';
      case 'bad': return '나쁨';
      default: return '';
    }
  }

  Future<void> _save() async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      Get.snackbar('알림', '일기 내용을 입력해 주세요');
      return;
    }

    final saved = await controller.saveDiary(
      diaryDate: diaryDate,
      content: content,
      title: titleController.text.trim(),
      mood: _moodLabel,
      existingId: existing?.id,
    );

    if (saved != null && mounted) {
      Get.back(result: true);
    }
  }

  String _formatDisplayDate(String ymd) {
    try {
      final parts = ymd.split('-');
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final wd = weekdays[dt.weekday - 1];
      return '${dt.year}년 ${dt.month}월 ${dt.day}일 ($wd)';
    } catch (_) {
      return ymd;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = existing != null;
    final titleLen = titleController.text.length;
    final contentLen = contentController.text.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(
              isEdit ? '일기 수정' : '일기 작성',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              '오늘의 순간을 기록해 보세요',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        // 💡 actions 내부의 북마크 버튼을 제거하여 타이틀이 중앙에 균형 있게 배치되도록 했습니다.
        actions: const [
          SizedBox(width: 48), // 좌측 leading(뒤로가기) 버튼과 대칭을 맞추기 위한 더미 공간
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 날짜 pill ──────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _formatDisplayDate(diaryDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 제목 카드 ──────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '제목',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: '제목을 입력하세요',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$titleLen/50',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 기분 카드 ──────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '기분은 어땠나요?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MoodChip(
                        emoji: '😊',
                        label: '좋음',
                        selected: selectedMood == 'good',
                        onTap: () => setState(() =>
                            selectedMood = selectedMood == 'good' ? null : 'good'),
                      ),
                      const SizedBox(width: 10),
                      _MoodChip(
                        emoji: '😐',
                        label: '보통',
                        selected: selectedMood == 'neutral',
                        onTap: () => setState(() =>
                            selectedMood = selectedMood == 'neutral' ? null : 'neutral'),
                      ),
                      const SizedBox(width: 10),
                      _MoodChip(
                        emoji: '😞',
                        label: '나쁨',
                        selected: selectedMood == 'bad',
                        onTap: () => setState(() =>
                            selectedMood = selectedMood == 'bad' ? null : 'bad'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 내용 카드 ──────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: contentController,
                    maxLength: 2000,
                    maxLines: 12,
                    minLines: 8,
                    decoration: InputDecoration(
                      hintText: '오늘 있었던 일을 자유롭게 적어보세요',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$contentLen/2000',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 저장 버튼 ──────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              label: const Text(
                '일기 저장하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text(emoji, style: const TextStyle(fontSize: 16)),
            Text(
              emoji,
              style: TextStyle(
                fontSize: 24,
                fontFamily: "Mona12Emoji",
                color: selected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}