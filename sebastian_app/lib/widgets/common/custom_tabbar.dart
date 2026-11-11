import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({super.key});

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  int selectedIndex = 0;

  final tabs = [
    {"icon": Icons.home, "label": "홈", "route": "/home"},
    {"icon": Icons.calendar_today, "label": "일정", "route": "/schedule"},
    {"icon": Icons.check_box, "label": "루틴", "route": "/routine"},
    {"icon": Icons.menu_book, "label": "일기", "route": "/diary"},
    {"icon": Icons.person, "label": "설정", "route": "/users-setting"},
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;

    selectedIndex = tabs.indexWhere(
      (tab) => tab["route"] == currentRoute,
    );
    
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              Get.offAllNamed(tabs[index]["route"] as String);
            },
            
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 35,
                  width: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        tabs[index]["icon"] as IconData,
                        size: 25,
                        // color: isSelected ? Colors.white : Colors.black,
                        color: isSelected ? Colors.white : Color(0xFF49454F),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tabs[index]["label"] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Color(0xFF49454F),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}