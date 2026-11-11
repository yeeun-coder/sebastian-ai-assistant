import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/screens/home/addTodo_screen.dart';

class TodoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> todo;

  const TodoDetailScreen({
    super.key,
    required this.todo,
  });

  String formatDate(DateTime dt) {
    return
        "${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}";
  }

  String formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');

    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return "$period $displayHour:$minute";
  }

  @override
  Widget build(BuildContext context) {

    final dueDate =
        DateTime.parse(todo['dueDate']);

    final isDone = todo['isDone'];

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "할 일 상세",
          style: TextStyle(color: Colors.black),
        ),

        iconTheme:
            const IconThemeData(color: Colors.black),

        actions: [
          IconButton(
            onPressed: () {
              Get.to(
                () => AddTodoScreen(todo: todo),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              todo['title'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: Column(
                children: [

                  _buildInfoRow(
                    Icons.calendar_today,
                    "날짜",
                    formatDate(dueDate),
                  ),

                  const SizedBox(height: 18),

                  _buildInfoRow(
                    Icons.access_time,
                    "시간",
                    formatTime(dueDate),
                  ),

                  const SizedBox(height: 18),

                  _buildInfoRow(
                    Icons.notifications_none,
                    "상태",
                    isDone ? "완료" : "진행 중",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [

        Icon(icon, size: 20),

        const SizedBox(width: 12),

        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),

        const Spacer(),

        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}