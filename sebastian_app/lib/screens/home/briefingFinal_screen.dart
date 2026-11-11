import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/briefing_controller.dart';

class BriefingFinalScreen extends StatelessWidget {
  BriefingFinalScreen({super.key});

  final controller = Get.find<BriefingController>();

  @override
  Widget build(BuildContext context) {

    final completedCount = controller.completedItems.length;
    final expiredCount = controller.expiredItems.length;

    final total = completedCount + expiredCount;

    final percent =
        total == 0
            ? 0
            : ((completedCount / total) * 100).round();


    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Column(
                  children: [
                    Image.asset(
                      "assets/images/logo1.png", 
                      width: 83,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                const Text(
                  "오늘 브리핑 결과",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Column(
                    children: [

                      // 메인 카드
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),

                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // 완료
                                const Row(
                                  children: [
                                    Text(
                                      "😃",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontFamily: "Mona12Emoji",
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "완료한 일정",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Obx(() => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: controller.completedItems.isEmpty
                                      ? [
                                          const Text(
                                            "완료한 일정이 없습니다.",
                                            style: TextStyle(color: Colors.grey),
                                          )
                                        ]
                                      : controller.completedItems
                                          .map(
                                            (item) => Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    item.icon,
                                                    size: 18,
                                                  ),

                                                  const SizedBox(width: 8),

                                                  Expanded(
                                                    child: Text(item.title),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                )),

                                const SizedBox(height: 60),

                                Divider(
                                  color: Colors.grey.shade300,
                                ),

                                const SizedBox(height: 20),

                                // 지나간 일정
                                const Row(
                                  children: [
                                    Text(
                                      "😢",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontFamily: "Mona12Emoji",
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "지나간 일정",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Obx(() => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: controller.expiredItems.isEmpty
                                      ? [
                                          const Text(
                                            "지나간 일정이 없습니다.",
                                            style: TextStyle(color: Colors.grey),
                                          )
                                        ]
                                      : controller.expiredItems
                                          .map(
                                            (item) => Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    item.icon,
                                                    size: 18,
                                                  ),

                                                  const SizedBox(width: 8),

                                                  Expanded(
                                                    child: Text(item.title),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 통계 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),

                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Column(
                          children: [

                            Text(
                              "완료율 $percent%",
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "완료 $completedCount건 · 지나감 $expiredCount건",
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              "오늘도 수고하셨습니다.",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}