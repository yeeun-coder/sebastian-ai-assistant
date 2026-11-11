import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';

class DDayScreen extends StatefulWidget {
  const DDayScreen({super.key});

  @override
  State<DDayScreen> createState() => _DDayScreenState();
}

class _DDayScreenState extends State<DDayScreen> {
  final controller = Get.find<ScheduleController>();

  @override
  Widget build(BuildContext context) {
    final ddaySchedules = controller
        .allScheduleItemsFlat()
        .where((item) => item.createDday == true)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("D-Day"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: ddaySchedules.length,

        itemBuilder: (context, index) {
          final item = ddaySchedules[index];

          final targetDate =
              item.ddayBasis == 'end'
                  ? item.endDateTime ?? item.dateTime
                  : item.dateTime;

          final diff =
              targetDate.difference(DateTime.now()).inDays + 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFB3B3B3)),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "${targetDate.year}.${targetDate.month.toString().padLeft(2, '0')}.${targetDate.day.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                Text(
                  "D-$diff",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}