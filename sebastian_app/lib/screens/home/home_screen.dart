import 'package:flutter/material.dart';
import 'package:sebastian_app/widgets/common/custom_topbar.dart';
import 'package:sebastian_app/widgets/common/custom_tabbar.dart';
import 'package:sebastian_app/widgets/chat_test.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: [
            const CustomTopBar(),
            const SizedBox(height: 8),
            const CustomTabBar(),
            const SizedBox(height: 10),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFD9D9D9),
            ),
            const Expanded(
              child: TC(),
            ),
          ],
        ),
      ),
    );
  }
}
