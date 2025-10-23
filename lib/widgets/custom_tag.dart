import 'package:flutter/material.dart';

enum TagType { bang, gam, mol }

class CustomTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const CustomTag._internal({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
  });

  /// 유형(TagType)에 따라 색상 자동 지정
  factory CustomTag({
    Key? key,
    required String label,
    required TagType type,
  }) {
    switch (type) {
      case TagType.bang:
        return CustomTag._internal(
          key: key,
          label: label,
          background: const Color(0xFFF2D7FF), // 방치형 배경
          textColor: const Color(0xFFE443C3), // 방치형 텍스트
        );
      case TagType.gam:
        return CustomTag._internal(
          key: key,
          label: label,
          background: const Color(0xFFFEE1C7), // 감정형 배경
          textColor: const Color(0xFFDD5B23), // 감정형 텍스트
        );
      case TagType.mol:
        return CustomTag._internal(
          key: key,
          label: label,
          background: const Color(0xFFD7F2C2), // 몰라형 배경
          textColor: const Color(0xFF568316), // 몰라형 텍스트
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
