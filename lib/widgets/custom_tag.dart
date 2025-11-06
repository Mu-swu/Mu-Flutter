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

  factory CustomTag({Key? key, required String label, required TagType type}) {
    switch (type) {
      case TagType.bang:
        return CustomTag._internal(
          key: key,
          label: label,
          background: const Color(0xFFF2D7FF),
          textColor: const Color(0xFFE444C4),
        );
      case TagType.gam:
        return CustomTag._internal(
          key: key,
          label: label,
          background: const Color(0xFFFEE1C7),
          textColor: const Color(0xFFDD5C24),
        );
      case TagType.mol:
        return CustomTag._internal(
          key: key,
          label: label,
          background: const Color(0xFFD7F2C2),
          textColor: const Color(0xFF568417),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontFamily: 'PretendardMedium',
        ),
      ),
    );
  }
}
