import 'package:flutter/material.dart';
import 'ItemListSection.dart';

class ItemSaveSection extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final double widthRatio;
  final double heightRatio;
  final VoidCallback onExit;
  final String itemName;
  final String? itemCategory;

  const ItemSaveSection({
    required this.categories,
    required this.widthRatio,
    required this.heightRatio,
    required this.onExit,
    required this.itemName,
    required this.itemCategory,
    super.key,
  });

  @override
  State<ItemSaveSection> createState() => _ItemSaveSectionState();
}

class _ItemSaveSectionState extends State<ItemSaveSection> {
  late DateTime todayDate;
  late DateTime oneWeekLaterDate;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    todayDate = DateTime.now();
    oneWeekLaterDate = todayDate.add(const Duration(days: 7));
    _selectedCategory = widget.itemCategory;
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required Function(DateTime) onSelected,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko'),
    );

    if (picked != null && picked != initialDate) {
      onSelected(picked);
    }
  }
  @override
  Widget build(BuildContext context) {
    final w = widget.widthRatio;
    final h = widget.heightRatio;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 960 * w,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ───────── 왼쪽: 세부 수정 영역 ─────────
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40 * w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 48 * h),
                    Text(
                      '세부 수정',
                      style: TextStyle(
                        fontSize: 18 * w,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 24 * h),

                    _labelTextField('이름', widget.itemName),
                    SizedBox(height: 16 * h),

                    Text(
                      '날짜',
                      style: TextStyle(
                        fontSize: 14 * w,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8 * h),

                    _infoBox(_formatDate(todayDate)),
                    SizedBox(height: 12 * h),

                    GestureDetector(
                      onTap: () => _pickDate(
                        initialDate: oneWeekLaterDate,
                        onSelected: (picked) => setState(() => oneWeekLaterDate = picked),
                      ),
                      child: Container(
                        height: 48 * h,
                        padding: EdgeInsets.symmetric(horizontal: 16 * w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(oneWeekLaterDate),
                              style: TextStyle(
                                fontSize: 16 * w,
                                color: Colors.black,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.calendar_today, size: 20 * w, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 10 * w),

            // ───────── 오른쪽: 아이템 리스트 영역 ─────────
        // ───────── 오른쪽: 아이템 리스트 영역 ─────────
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40 * w), // 왼쪽과 동일한 패딩
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 48 * h),
                Text(
                  '카테고리',
                  style: TextStyle(
                    fontSize: 18 * w,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                Expanded(
                  child: ItemListSection(
                    categories: widget.categories,
                    onAddPressed: (category) {
                      print('$category 추가');
                    },
                    onItemTapped: (category) {
                      print('$category 이미지 탭됨');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    ));
  }
  Widget _labelTextField(String label, String value) {
    final w = widget.widthRatio;
    final h = widget.heightRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14 * w,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8 * h),
        Container(
          height: 48 * h,
          padding: EdgeInsets.symmetric(horizontal: 16 * w),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16 * w,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(String text) {
    final w = widget.widthRatio;
    final h = widget.heightRatio;

    return Container(
      height: 48 * h,
      padding: EdgeInsets.symmetric(horizontal: 16 * w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16 * w,
          color: Colors.black,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 ${date.day.toString().padLeft(2, '0')}일';
  }
}