import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sebastian_app/widgets/briefing_controller.dart';
import 'package:sebastian_app/widgets/user_controller.dart';
import 'package:sebastian_app/widgets/weather_controller.dart';
import 'package:sebastian_app/screens/home/briefingFinal_screen.dart';

class BriefingScreen extends StatefulWidget {
  const BriefingScreen({super.key});

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen> {
  final controller = Get.put(BriefingController());
  final userController = Get.find<UserController>();
  final weatherController = Get.put(WeatherController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          _buildTodayBriefing(),
          BriefingFinalScreen(),
        ],
      )
    );
  }

  Widget _buildTodayBriefing() {
    final now = DateTime.now();
    final formattedDate = DateFormat('M월 d일 EEEE', 'ko_KR').format(now);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [

              const SizedBox(height: 30),

              // 로고
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

              // 제목
              const Text(
                "오늘 일정 브리핑",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 6),

              Obx(() => Text(
                "좋은 하루입니다. ${userController.name.value.isEmpty ? '사용자' : userController.name.value}님!",
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold
                ),
              )),

              const SizedBox(height: 20),

              // 카드
              Expanded(
                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 20,
                  ),

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

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Obx(() => Row(
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            "|",
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Icon(
                            weatherController.weatherIcon(),
                            size: 16,
                            color: Color(0xFF757575),
                          ),

                          const SizedBox(width: 5),

                          Text(
                            weatherController.weatherText(),
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(width: 5),

                          Text(
                            "${weatherController.temperature.value}°",
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )),

                      const SizedBox(height: 4),

                      Obx(() => Text(
                        weatherController.briefingText.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      )),

                      const SizedBox(height: 10),

                      Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),

                      const SizedBox(height: 10),

                      // 일정 목록
                      Expanded(
                        child: Obx(() {
                          final now = DateTime.now();

                          final visibleItems = controller.todayItems.where((item) {

                            if (item.time == "하루 종일") {
                              return true;
                            }

                            try {
                              final isPm = item.time.contains("오후");

                              final timePart = item.time
                                  .replaceAll("오전 ", "")
                                  .replaceAll("오후 ", "");

                              final parts = timePart.split(":");

                              int hour = int.parse(parts[0]);
                              int minute = int.parse(parts[1]);

                              if (isPm && hour != 12) hour += 12;
                              if (!isPm && hour == 12) hour = 0;

                              final target = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                hour,
                                minute,
                              );

                              // 1분 지나면 숨김
                              return now.isBefore(
                                target.add(const Duration(minutes: 1)),
                              );

                            } catch (_) {
                              return true;
                            }
                          }).toList();

                          return ListView.separated(
                            itemCount: visibleItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              final item = visibleItems[index];

                              return Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      item.icon,
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [

                                        Row(
                                          children: [
                                            Text(
                                              item.time,
                                              style: const TextStyle(fontSize: 16),
                                            ),

                                            const SizedBox(width: 8),

                                            const Text(
                                              "|",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            // Expanded(
                                            //   child: Text(
                                            //     item.title,
                                            //     style: const TextStyle(fontSize: 16),
                                            //   ),
                                            // ),
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          item.subTitle,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }),
                      ),

                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swipe_left,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "결과 보기",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 버튼
              SizedBox(
                width: 85,
                height: 46,

                child: ElevatedButton(
                  onPressed: () {
                    final fromLogin = Get.arguments?['fromLogin'] == true;

                    if (fromLogin) {
                      // 로그인 직후라면 홈으로 이동
                      Get.offAllNamed('/home');
                    } else {
                      // 메뉴에서 들어왔다면 이전 화면으로 돌아가기
                      Get.back();
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                  ),

                  child: const Text(
                    "확인",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}