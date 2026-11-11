import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sebastian_app/widgets/user_controller.dart';
import 'package:sebastian_app/widgets/common/custom_button.dart';
import 'package:sebastian_app/services/user_service.dart';
import 'package:sebastian_app/widgets/profile_avatar.dart';

class UserEditScreen extends StatefulWidget {
  const UserEditScreen({super.key});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final userController = Get.find<UserController>();
  final userService = UserService();
  late TextEditingController nameController;
  String gender = "";
  String? profileImageUrl;
  File? selectedImage;
  XFile? pickedImage;
  bool _isLoading = true;
  bool _isSaving = false;

  int? selectedYear;
  int? selectedMonth;
  int? selectedDay;

  int? get calculatedAge {
    if (selectedYear == null || selectedMonth == null || selectedDay == null) {
      return null;
    }
    final today = DateTime.now();
    final birthday = DateTime(selectedYear!, selectedMonth!, selectedDay!);
    int age = today.year - birthday.year;
    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age;
  }

  int get maxDaysInMonth {
    if (selectedYear == null || selectedMonth == null) return 31;
    return DateTime(selectedYear!, selectedMonth! + 1, 0).day;
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: userController.name.value);
    gender = userController.gender.value;
    profileImageUrl = userController.profileImage.value;
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await userService.getProfile();
    if (!mounted) return;

    if (data != null) {
      nameController.text = data['nickname'] ?? userController.name.value;
      gender = data['gender'] ?? userController.gender.value;
      profileImageUrl = data['profileImage'] as String?;

      final birthdayStr = data['birthday'] as String?;
      if (birthdayStr != null) {
        try {
          final parts = birthdayStr.split('-');
          if (parts.length == 3) {
            selectedYear = int.parse(parts[0]);
            selectedMonth = int.parse(parts[1]);
            selectedDay = int.parse(parts[2]);
          }
        } catch (_) {}
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        pickedImage = picked;
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final age = calculatedAge;
      final birthday = selectedYear != null && selectedMonth != null && selectedDay != null
          ? '$selectedYear-${selectedMonth!.toString().padLeft(2, '0')}-${selectedDay!.toString().padLeft(2, '0')}'
          : null;

      final profile = await userService.updateProfile({
        'nickname': nameController.text,
        'age': age,
        'gender': gender,
        if (birthday != null) 'birthday': birthday,
      });

      if (profile == null) {
        Get.snackbar('오류', '저장 실패');
        return;
      }

      Map<String, dynamic> latest = profile;
      if (pickedImage != null) {
        final upload = await userService.uploadProfileImage(pickedImage!);
        if (upload.data == null) {
          Get.snackbar('오류', upload.error ?? '프로필 사진 업로드에 실패했습니다');
          return;
        }
        latest = upload.data!;
      }

      userController.setUser(
        latest['nickname'] ?? nameController.text,
        age ?? latest['age'] ?? 0,  // ← 계산된 나이 우선 적용
        latest['gender'] ?? gender,
      );
      userController.setProfileImage(latest['profileImage'] as String?);

      Get.back(result: true);
      Get.snackbar('성공', '프로필 업데이트 완료');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget customBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _buildBirthdayRow() {
    final currentYear = DateTime.now().year;
    final years = List.generate(currentYear - 1949, (i) => currentYear - i);
    final months = List.generate(12, (i) => i + 1);
    final days = List.generate(maxDaysInMonth, (i) => i + 1);

    if (selectedDay != null && selectedDay! > maxDaysInMonth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => selectedDay = null);
      });
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: customBox(
            child: DropdownButton<int>(
              value: selectedYear,
              isExpanded: true,
              underline: const SizedBox(),
              hint: const Text('년'),
              items: years.map((y) {
                return DropdownMenuItem(value: y, child: Text('$y'));
              }).toList(),
              onChanged: (value) => setState(() {
                selectedYear = value;
                selectedDay = null;
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: customBox(
            child: DropdownButton<int>(
              value: selectedMonth,
              isExpanded: true,
              underline: const SizedBox(),
              hint: const Text('월'),
              items: months.map((m) {
                return DropdownMenuItem(value: m, child: Text('$m월'));
              }).toList(),
              onChanged: (value) => setState(() {
                selectedMonth = value;
                selectedDay = null;
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: customBox(
            child: DropdownButton<int>(
              value: selectedDay,
              isExpanded: true,
              underline: const SizedBox(),
              hint: const Text('일'),
              items: days.map((d) {
                return DropdownMenuItem(value: d, child: Text('$d일'));
              }).toList(),
              onChanged: (value) => setState(() => selectedDay = value),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfileAvatar(
                    size: 100,
                    imageUrl: profileImageUrl,
                    localFile: selectedImage,
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text('프로필 사진 변경'),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('이름', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  customBox(
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '이름 입력',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('생일', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      if (calculatedAge != null)
                        Text(
                          '(만 $calculatedAge세)',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildBirthdayRow(),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('성별', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  customBox(
                    child: DropdownButton<String>(
                      value: gender.isEmpty ? null : gender,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('성별 선택'),
                      items: ['남', '여'].map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (value) => setState(() => gender = value!),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomButton(
                      label: _isSaving ? '저장 중...' : '저장하기',
                      variant: CustomButtonVariant.darkLong,
                      expandWidth: true,
                      height: 45,
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (nameController.text.isEmpty) {
                                Get.snackbar('오류', '이름을 입력하세요');
                                return;
                              }
                              if (selectedYear == null ||
                                  selectedMonth == null ||
                                  selectedDay == null) {
                                Get.snackbar('오류', '생일을 입력하세요');
                                return;
                              }
                              if (gender.isEmpty) {
                                Get.snackbar('오류', '성별을 선택하세요');
                                return;
                              }
                              saveProfile();
                            },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}