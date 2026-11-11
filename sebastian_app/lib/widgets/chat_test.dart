import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:sebastian_app/services/chat_service.dart';
import 'package:sebastian_app/widgets/common/custom_icon.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';
import 'package:sebastian_app/widgets/routine_controller.dart';
import 'package:sebastian_app/widgets/ai_controller.dart';
import 'package:sebastian_app/widgets/overdue_chat_controller.dart';
import 'package:sebastian_app/widgets/briefing_controller.dart';

const String _kUserId = 'user1';
const String _kAssistantId = 'assistant';

/// 홈 화면 채팅: 로컬 Nest `GET/POST /chat/messages` + [ChatService].
class TC extends StatefulWidget {
  const TC({super.key});

  @override
  State<TC> createState() => _TCState();
}

class _TCState extends State<TC> {
  final _chatController = InMemoryChatController();
  final _chatService = ChatService();
  final _inputController = TextEditingController();

  late final ScheduleController scheduleController;
  late final RoutineController routineController;
  late final AIController aiController;
  late final OverdueChatController overdueController;

  bool _loading = true;
  String? _error;
  bool _sending = false;
  Worker? _overdueWorker;
  Worker? _personaWorker;

  @override
  void dispose() {
    _overdueWorker?.dispose();
    _personaWorker?.dispose();
    _chatController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    scheduleController = Get.find<ScheduleController>();
    routineController = Get.find<RoutineController>();
    aiController = Get.find<AIController>();
    overdueController = Get.find<OverdueChatController>();

    _overdueWorker = ever<String?>(overdueController.pendingBotText, (text) {
      if (text == null || text.isEmpty) return;
      _insertLocalBotMessage(text);
      overdueController.consumeBotText();
    });

    // 페르소나 변경 시 서버 히스토리가 삭제되므로 인메모리 채팅도 초기화 후 재로드
    _personaWorker = ever<int>(aiController.chatHistoryVersion, (_) {
      _loadHistory();
    });

    _loadHistory().then((_) async {
      final pending = overdueController.pendingBotText.value;
      if (pending != null && pending.isNotEmpty) {
        _insertLocalBotMessage(pending);
        overdueController.consumeBotText();
      }
      await overdueController.checkOverdue();
    });
  }

  void _insertLocalBotMessage(String text) {
    final id = 'local_overdue_${DateTime.now().microsecondsSinceEpoch}';
    _chatController.insert(TextMessage(
      id: id,
      authorId: _kAssistantId,
      createdAt: DateTime.now().toUtc(),
      text: text,
    ));
  }

  void _insertLocalUserMessage(String text) {
    final id = 'local_user_${DateTime.now().microsecondsSinceEpoch}';
    _chatController.insert(TextMessage(
      id: id,
      authorId: _kUserId,
      createdAt: DateTime.now().toUtc(),
      text: text,
    ));
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _chatService.fetchMessages();

      // 새로추가 
      List<Message> messages = rows.map((row) => _mapToTextMessage(row) as Message).toList();
      await _chatController.set(messages);

      // for (final row in rows) {
      //   await _chatController.insertMessage(_mapToTextMessage(row));
      // }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  TextMessage _mapToTextMessage(Map<String, dynamic> m) {
    final raw = m['createdAt'];
    DateTime created;
    if (raw is String) {
      created = DateTime.parse(raw);
    } else {
      created = DateTime.now().toUtc();
    }
    if (!created.isUtc) {
      created = created.toUtc();
    }
    final role = m['senderRole'] as String? ?? 'user';
    return TextMessage(
      id: 'm_${m['id']}',
      authorId: role == 'user' ? _kUserId : _kAssistantId,
      createdAt: created,
      text: m['message'] as String? ?? '',
    );
  }

  void _onMessageSend(String text) {
    _handleOutgoing(text);
  }

  Future<void> _handleOutgoing(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (overdueController.pendingReschedule != null) {
      final handled =
          await overdueController.tryHandleCompletionShortcut(trimmed);
      if (handled) {
        _insertLocalUserMessage(trimmed);
        _insertLocalBotMessage('완료 처리했어요.');
        await scheduleController.loadSchedulesFromDB();
        await scheduleController.syncScheduleNotifications();
        return;
      }
    }

    await _sendToServer(trimmed);
  }

  Future<void> _sendToServer(String text) async {
    if (_sending) return;
    setState(() => _sending = true);
    final pending = overdueController.pendingReschedule;
    final contextHint = overdueController.buildContextHint();
    try {
      final data = await _chatService.sendMessage(
        text,
        contextHint: contextHint,
      );
      final um = data['userMessage'];
      final am = data['assistantMessage'];
      final schedule = data['schedule'];
      final todo = data['todo'];
      final routine = data['routine'];
      final routines = data['routines'];

      if (um is Map) {
        // await _chatController.insertMessage(
        //   _mapToTextMessage(Map<String, dynamic>.from(um)),
        // );
        await _chatController.insert(
          _mapToTextMessage(Map<String, dynamic>.from(um)),
        );
      }
      if (am is Map) {
        // await _chatController.insertMessage(
        //   _mapToTextMessage(Map<String, dynamic>.from(am)),
        // );
        await _chatController.insert(
          _mapToTextMessage(Map<String, dynamic>.from(am)),
        );
      }
      final updated = data['updated'] == true;
      if (schedule is Map && mounted) {
        final title = schedule['title']?.toString() ?? '일정';
        final returnedId = (schedule['id'] is num)
            ? (schedule['id'] as num).toInt()
            : int.tryParse(schedule['id']?.toString() ?? '');
        if (pending != null &&
            returnedId != null &&
            returnedId == pending.scheduleId) {
          overdueController.clearReschedule();
        }
        await scheduleController.loadSchedulesFromDB();
        await scheduleController.syncScheduleNotifications();
        if (Get.isRegistered<BriefingController>()) {
          await Get.find<BriefingController>().loadTodayBriefing(); // 홈 브리핑 stale 상태 갱신
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated
                  ? '"$title" 일정 시간을 반영했습니다.'
                  : '"$title" 일정이 등록되었습니다.',
            ),
          ),
        );
      }
      if (todo is Map && mounted) {
        final title = todo['title']?.toString() ?? '할 일';
        await scheduleController.fetchTodos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated
                  ? '"$title" 할 일 정보를 반영했습니다.'
                  : '"$title" 할 일이 등록되었습니다.',
            ),
          ),
        );
      }
      if (routines is List && routines.isNotEmpty && mounted) {
        await routineController.fetch();
        final first = routines.first;
        final cat = first is Map
            ? (first['category']?.toString() ?? '루틴')
            : '루틴';
        final n = routines.length;
        final msg = n > 1
            ? '"$cat" 폴더에 습관 $n개가 등록되었습니다.'
            : '"${first is Map ? (first['title']?.toString() ?? '루틴') : '루틴'}" 루틴이 등록되었습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } else if (routine is Map && mounted) {
        final title = routine['title']?.toString() ?? '루틴';
        await routineController.fetch();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$title" 루틴이 등록되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadHistory,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: Chat(
              chatController: _chatController,
              currentUserId: _kUserId,
              onMessageSend: _onMessageSend,

              resolveUser: (UserID id) async {
                if (id == _kUserId) {
                  return User(id: id, name: '나');
                }
                return User(id: id, name: aiController.name.value);
              },
  
              builders: Builders(
                textMessageBuilder: (context, message, index) {
                  final isMe = message.authorId == _kUserId;

                  if (isMe) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message.text,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child:Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => CustomIcon(
                          child: Image.asset(
                            aiController.image.value,
                            width: 24,
                          ),
                        )),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(() => Text(
                                aiController.name.value,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey
                                ),
                              )),
                              const SizedBox(height: 4),

                              Container(
                                // 글씨 제한
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(message.text),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },

                composerBuilder: (context) => const SizedBox.shrink(),
              ),
            ),
          ),

          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              20, 0, 20,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Stack(
              children: [
                TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 5,

                  decoration: InputDecoration(
                    hintText: "안녕하세요. 무엇을 도와드릴까요?",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),

                    contentPadding: const EdgeInsets.fromLTRB(16, 14, 50, 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                  ),
                ),

                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        final text = _inputController.text.trim();
                        if (text.isEmpty) return;
                        _onMessageSend(text);
                        _inputController.clear();
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
