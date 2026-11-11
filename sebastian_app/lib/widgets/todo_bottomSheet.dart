import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart'; // 컨트롤러 임포트
import '../screens/home/todoDetail_screen.dart';

class TodoBottomsheet extends StatelessWidget {
  const TodoBottomsheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ScheduleController controller = Get.find<ScheduleController>();

    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.06,
      maxChildSize: 0.75,

      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // 핸들 바
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFF79747E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // TO-DO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60,vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TO-DO",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Obx(() {
                        final visibleTodos = controller.todos.where((todo) {
                          final dateTimeStr = todo['dueDate'];

                          if (dateTimeStr == null || dateTimeStr.isEmpty) return false;

                          final dateTime = DateTime.parse(dateTimeStr);
                          final leadDays = todo['scheduleLeadDays'] ?? 0;

                          return shouldShowTodo(dateTime, leadDays);
                        }).toList();

                        if (visibleTodos.isEmpty) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "할 일이 없습니다",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: visibleTodos.map((todo) {
                            return _buildTodoItem(context, todo);
                          }).toList(),
                        );
                      })
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: InkWell(
                    onTap: () {
                      Get.toNamed('/add-todo');
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF757575).withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(
                          color: const Color(0xFFD9D9D9),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "+ 할 일 추가",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Obx(() {
                  final showPreview = hasHiddenTodos(controller);

                  if (!showPreview) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: GestureDetector(
                      onTap: () {
                        Get.toNamed('/all-todos');
                      },
                      child: const Text(
                        "할 일 더보기",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodoItem(BuildContext context, Map<String, dynamic> todo) {
    final controller = Get.find<ScheduleController>();

    final id = todo['id'];
    final title = todo['title'];
    final isDone = todo['isDone'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                controller.toggleTodo(id, !isDone);
              },
              child: Icon(
                isDone ? Icons.check_box : Icons.check_box_outline_blank,
              ),
            ),
            const SizedBox(width: 12),

            GestureDetector(
              onTap: () {
                Get.to(
                  () => TodoDetailScreen(todo: todo),
                );
              },
              onLongPress: () {
                _showDeleteDialog(context, todo);
              },
              child: Text(
                title,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 할 일 표시 여부 판단 함수
  bool shouldShowTodo(DateTime dateTime, int leadDays) {
    // leadDays가 0(알림 없음)이면 등록 즉시 목록에 보여준다.
    if (leadDays <= 0) return true;
    
    final now = DateTime.now();
    // 알림 시작일
    final showStart = dateTime.subtract(Duration(days: leadDays));
    // 마감일 지나면 숨김
    if (now.isAfter(dateTime)) {
      return false;
    }
    // 시작일부터 마감일까지 표시
    return now.isAfter(showStart);
  }

  // 할 일 삭제 다이얼로그
  void _showDeleteDialog(BuildContext context, Map<String, dynamic> todo) {
    final controller = Get.find<ScheduleController>();

    Get.dialog(
      AlertDialog(
        title: const Text("할 일 삭제"),
        content: Text("'${todo['title']}' 할 일을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () {
              controller.deleteTodo(todo['id']);
              Get.back();
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("취소"),
          ),
        ],
      ),
    );
  }

  // 숨겨진 할 일이 있는지 판단하는 함수
  bool hasHiddenTodos(ScheduleController controller) {
    return controller.todos.any((todo) {
      final dateTimeStr = todo['dueDate'];
      if (dateTimeStr == null || dateTimeStr.isEmpty) return false;

      final dateTime = DateTime.parse(dateTimeStr);
      final leadDays = todo['scheduleLeadDays'] ?? 0;

      return !shouldShowTodo(dateTime, leadDays);
    });
  }
}