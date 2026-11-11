import 'package:flutter/material.dart'; 

class CustomIcon extends StatelessWidget {
  final Widget child;
  final double size;

  const CustomIcon({
    super.key,
    required this.child,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 1,
          child: child,
        ),
      ),
    );
  }
}