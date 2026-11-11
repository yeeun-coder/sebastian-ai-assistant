import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/common/custom_icon.dart';
import 'package:sebastian_app/widgets/ai_controller.dart';

class AISettingScreen extends StatefulWidget {
  const AISettingScreen({super.key});

  @override
  State<AISettingScreen> createState() => _AISettingScreenState();
}

final aiGroupList = [
  {
    "title": "비서봇",
    "message": "안녕하세요. 무엇을 도와드릴까요?",
    "items": [
      {"id": "sebastian1", "personaType": "basic", "name": "비서봇", "image": "assets/images/logo.png", "message": "안녕하세요. 무엇을 도와드릴까요?"}
    ]
  },
  {
    "title": "엄마봇",
    "message": "왜? 뭐 필요해?",
    "items": [
      {"id": "mother1", "personaType": "mother", "name": "엄마봇", "image": "assets/images/mother1.png", "message": "왜? 뭐 필요해?"}
    ]
  },
  {
    "title": "신하봇",
    "message": "전하 아니되옵니다!",
    "items": [
      {"id": "minister1", "personaType": "minister", "name": "신하봇", "image": "assets/images/minister1.png", "message": ""},
      {"id": "minister2", "personaType": "minister", "name": "신하봇", "image": "assets/images/minister2.png", "message": ""},
    ]
  },
  {
    "title": "교관봇",
    "message": "도움이 필요하십니깎?!",
    "items": [
      {"id": "teacher1", "personaType": "teacher", "name": "교관봇", "image": "assets/images/teacher1.png", "message": ""},
      {"id": "teacher2", "personaType": "teacher", "name": "교관봇", "image": "assets/images/teacher2.png", "message": ""},
    ]
  },
  {
    "title": "신사봇",
    "message": "무엇을 도와드릴까요?",
    "items": [
      {"id": "sage1", "personaType": "sage", "name": "신사봇", "image": "assets/images/sage1.png", "message": ""},
      {"id": "sage2", "personaType": "sage", "name": "신사봇", "image": "assets/images/sage2.png", "message": ""},
      {"id": "sage3", "personaType": "sage", "name": "신사봇", "image": "assets/images/sage3.png", "message": ""},
    ]
  },
];

class _AISettingScreenState extends State<AISettingScreen> {
  final aiController = Get.find<AIController>();

  void selectAI(String id, String name, String image, String message, String personaType) {
    aiController.selectAI(id, name, image, message, personaType);
  }

  String selectedName = "비서봇";
  String selectedImage = "assets/images/logo.png";
  String selectedMessage = "안녕하세요. 무엇을 도와드릴까요?";
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI 설정'),
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: aiGroupList.map((group) {
                return buildAISection(
                  group["title"] as String,
                  group["message"] as String,
                  group["items"] as List<Map>,
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
  Widget buildAISection(String name, String message, List<Map> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 설명
          Row(
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Text(message, style: const TextStyle(color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 10),

          // 아이콘 리스트 (가로)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final ai = items[index];

                return GestureDetector(
                  onTap: () {
                    selectAI(ai["id"], ai["name"], ai["image"], ai["message"], ai["personaType"]);
                    Get.back();
                  },
                  child: Column(
                    children: [
                      CustomIcon(
                        size: 70,
                        child: Image.asset(ai["image"]),
                      ),
                      const SizedBox(height: 5),

                      Obx(() {
                        return aiController.id.value == ai["id"]
                            ? const Icon(Icons.check, color: Colors.black, size: 20)
                            : const SizedBox();
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}