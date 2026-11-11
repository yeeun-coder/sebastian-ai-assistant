import 'package:flutter/material.dart';

enum BriefingStatus {
  pending,
  completed,
  missed,
}

class BriefingItem {
  final String title;
  final String subTitle;
  final String time;
  final IconData icon;

  BriefingStatus status;

  BriefingItem({
    required this.title,
    required this.subTitle,
    required this.time,
    required this.icon,
    this.status = BriefingStatus.pending,
  });
}