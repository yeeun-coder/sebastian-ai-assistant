import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/routes/app_routes.dart';
import 'package:sebastian_app/widgets/common/custom_icon.dart';
import 'package:sebastian_app/widgets/ai_controller.dart';

class CustomTopBar extends StatefulWidget {
  const CustomTopBar({super.key});

  @override
  State<CustomTopBar> createState() => _CustomTopBarState();
}

class _CustomTopBarState extends State<CustomTopBar> {
  final aiController = Get.find<AIController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                "나의 세바스찬",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.grey.withOpacity(0.5),
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 0,
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    icon: Icon(Icons.menu),

                    onSelected: (value) {
                      switch (value) {
                        case 'briefing':
                          Get.toNamed('/briefing');
                          break;

                        case 'dday':
                          Get.toNamed('/dday');
                          break;
                      }
                    },

                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'briefing',
                        child: Text('브리핑'),
                      ),

                      PopupMenuItem(
                        value: 'dday',
                        child: Text('디데이'),
                      ),
                    ],
                  ),

                  Transform.translate(
                    offset: Offset(-14, 0),
                    child: IconButton(
                      icon: Icon(Icons.notifications_none),
                      onPressed: () => Get.toNamed('/notifications'),
                    ),
                  ),
                ],
              ),
            ),

            // 우측
            Positioned(
              right: 2,
              child: Obx(() => GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.setting),
                child: CustomIcon(
                  size: 32,
                  child: Image.asset(aiController.image.value),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}