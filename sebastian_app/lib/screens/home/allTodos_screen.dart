import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';
import 'package:sebastian_app/screens/home/addTodo_screen.dart';

class AllTodosScreen extends StatelessWidget {
  const AllTodosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScheduleController controller = Get.find<ScheduleController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("전체 할 일"),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.todos.isEmpty) {
          return const Center(
            child: Text(
              "할 일이 없습니다",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // 날짜 빠른 순으로 정렬
        final sortedTodos = [...controller.todos];
        sortedTodos.sort((a, b) {
          final aDate = DateTime.parse(a['dueDate']);
          final bDate = DateTime.parse(b['dueDate']);
          return aDate.compareTo(bDate);
        });

        return ListView.builder(
          itemCount: sortedTodos.length,
          itemBuilder: (context, index) {
            final todo = sortedTodos[index];
            return _buildTodoItem(context, todo);
          },
        );
      }),
    );
  }

  Widget _buildTodoItem(BuildContext context, Map<String, dynamic> todo) {
    final controller = Get.find<ScheduleController>();

    final id = todo['id'];
    final title = todo['title'];
    final isDone = todo['isDone'];
    final dateTime = DateTime.parse(todo['dueDate']);

    final dateText =
        "${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}";
    final timeText =
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () {
        Get.to(() => AddTodoScreen(todo: todo));
      },
      onLongPress: () {
        _showDeleteDialog(context, todo);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$dateText  $timeText",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> todo) {
    final controller = Get.find<ScheduleController>();

    Get.dialog(
      AlertDialog(
        title: const Text("할 일 삭제"),
        content: Text("'${todo['title']}' 할 일을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              controller.deleteTodo(todo['id']);
              Get.back();
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}