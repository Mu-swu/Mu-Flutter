import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ItemSaveSection extends StatelessWidget {
  final double widthRatio;
  final double heightRatio;
  final VoidCallback onExit;
  final String itemName;

  const ItemSaveSection({
    required this.widthRatio,
    required this.heightRatio,
    required this.onExit,
    required this.itemName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final oneMonthLater = DateTime(now.year, now.month + 1, now.day);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$itemName 보관 시작',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 30 * widthRatio,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 24 * heightRatio),
          SizedBox(
            width: 266 * widthRatio,
            child: Text(
              '‘버릴까 말까 상자’ 보관 시작일을 기록해볼게요.\n한 달 뒤에 다시 확인할 수 있도록 알림을 보내드려요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF5C5C5C),
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 48 * heightRatio),
          _dateDisplay(label: '보관 시작일', date: now),
          SizedBox(height: 24 * heightRatio),
          _dateDisplay(label: '보관 확인일', date: oneMonthLater),
          SizedBox(height: 64 * heightRatio),
          GestureDetector(
            onTap: onExit,
            child: Container(
              width: 339 * widthRatio,
              height: 64 * heightRatio,
              decoration: ShapeDecoration(
                color: const Color(0xFF6C6C6C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(36),
                ),
              ),
              child: Center(
                child: Text(
                  '종료하기',
                  style: TextStyle(
                    color: const Color(0xFFF5F5F5),
                    fontSize: 18 * widthRatio,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateDisplay({required String label, required DateTime date}) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF5C5C5C),
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8 * heightRatio),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dateBox(year),
            SizedBox(width: 16 * widthRatio),
            _dateBox(month),
            SizedBox(width: 16 * widthRatio),
            _dateBox(day),
          ],
        ),
      ],
    );
  }

  Widget _dateBox(String text) {
    return Container(
      width: 65 * widthRatio,
      height: 54 * heightRatio,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF5C5C5C),
          fontSize: 24 * widthRatio,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}