import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ItemListSection.dart';
import 'category_edit_popup.dart';

class ItemSaveSection extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final double widthRatio;
  final double heightRatio;
  final VoidCallback onExit;
  final String itemName;
  final String? itemCategory;

  final Function(String itemName, String newEndDate) onDateChanged;
  final Function(String oldName, String newName) onCategoryUpdated;
  final Function(String categoryName) onCategoryDeleted;

  const ItemSaveSection({
    required this.categories,
    required this.widthRatio,
    required this.heightRatio,
    required this.onExit,
    required this.itemName,
    required this.itemCategory,
    required this.onDateChanged,
    required this.onCategoryUpdated,
    required this.onCategoryDeleted,
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
      initialEntryMode: DatePickerEntryMode.calendarOnly,

      // ⬇️ 캘린더 테마 및 여백 적용 부분 ⬇️
      builder: (BuildContext context, Widget? child) {
        return Padding(
          padding: const EdgeInsets.all(30.0), // 👈 전체 여백 20 적용
          child: Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                // 배경색 (전체 다이얼로그 배경)
                surface: const Color(0xFFFAFBFF),
                // 선택된 날짜 배경색
                primary: const Color(0xFF463EC6),
              ),
              // 오늘 날짜 테두리/배경색 등을 위한 설정
              datePickerTheme: DatePickerThemeData(
                // 오늘 날짜 배경색 (DatePickerDialog의 Calendar Day 부분)
                todayBackgroundColor: MaterialStateProperty.all(const Color(0xFFD7D7FA)),
              ),
              // TextButton의 색상 (예: OK, CANCEL 버튼)
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF463EC6), // 버튼 텍스트 색상
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
      // ⬆️ 캘린더 테마 및 여백 적용 부분 ⬆️
    );


    if (picked != null && picked != initialDate) {
      onSelected(picked);

      final DateFormat formatter = DateFormat("yyyy.MM.dd");
      final String newEndDateString = formatter.format(picked);
      widget.onDateChanged(widget.itemName, newEndDateString);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.widthRatio;
    final h = widget.heightRatio;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 960 * w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ───── 왼쪽: 세부 수정 영역 ─────
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
                      '오늘 날짜',
                      style: TextStyle(
                        fontSize: 14 * w,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8 * h),
                    _infoBox(_formatDate(todayDate)),
                    SizedBox(height: 12 * h),

                    Text(
                      '리마인드 날짜',
                      style: TextStyle(
                        fontSize: 14 * w,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8 * h),

                    GestureDetector(
                      onTap:
                          () => _pickDate(
                            initialDate: oneWeekLaterDate,
                            onSelected:
                                (picked) =>
                                    setState(() => oneWeekLaterDate = picked),
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
                              child: Icon(
                                Icons.calendar_today,
                                size: 20 * w,
                                color: Colors.grey,
                              ),
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

            // ───── 오른쪽: 아이템 리스트 영역 ─────
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40 * w),
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
                        onItemTapped: (String categoryName) {
                          CategoryEditPopup(
                            context: context,
                            initialCategoryName: categoryName,
                            onSave: (String newCategoryName) {
                              widget.onCategoryUpdated(
                                categoryName,
                                newCategoryName,
                              );
                            },
                            onDelete: () {
                              widget.onCategoryDeleted(categoryName);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            style: TextStyle(fontSize: 16 * w, color: Colors.black),
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
        style: TextStyle(fontSize: 16 * w, color: Colors.black),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 ${date.day.toString().padLeft(2, '0')}일';
  }
}
