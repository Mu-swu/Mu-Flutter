import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'widgets/longbutton.dart';
import 'widgets/shortbutton.dart';
import 'package:intl/intl.dart';
import 'widgets/category_edit_popup.dart';
import 'keepbox.dart';


// ───────────── ItemEditPopup 정의 ─────────────

// 날짜 포맷팅 유틸리티 함수
String _formatDate(DateTime date) {
  return DateFormat("yyyy년 M월 d일").format(date);
}

// 캘린더 피커 함수 (요청하신 커스텀 테마 적용)
Future<void> _pickDate({
  required BuildContext context,
  required DateTime initialDate,
  required Function(DateTime) onSelected,
  required DateTime firstDate,
}) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate, // 시작 날짜는 오늘 이전이 될 수 없도록 설정
    lastDate: DateTime(2100),
    locale: const Locale('ko', 'KR'), // locale 설정
    initialEntryMode: DatePickerEntryMode.calendarOnly,

    // ⬇️ 캘린더 테마 및 여백 적용 부분 ⬇️
    builder: (BuildContext context, Widget? child) {
      return Padding(
        padding: const EdgeInsets.all(30.0), // 👈 전체 여백 30 적용
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
              // 오늘 날짜 배경색
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

  if (picked != null) {
    onSelected(picked);
  }
}


Future<void> ItemEditPopup({
  required BuildContext context,
  required String initialName,
  required DateTime initialStartDate,
  required DateTime initialEndDate,
  required Function(String newName, DateTime newEndDate) onSave,
  required Function() onDelete,
}) async {
  // 상태 관리를 위해 showDialog 내부에서 State<T>를 모방하는 변수 선언
  String itemName = initialName;
  DateTime startDate = initialStartDate;
  DateTime endDate = initialEndDate;
  TextEditingController nameController = TextEditingController(text: initialName);

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) {
      // 팝업 내부의 상태를 관리하기 위해 StatefulBuilder 사용
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            alignment: Alignment.center,
            child: Container(
              width: 543, // 적절한 고정 너비 설정 (화면 중앙에 팝업을 띄우기 위함)
              padding: const EdgeInsets.only(top: 32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 헤더 (취소/물품 수정/완료)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            '취소',
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                        ),
                        const Text(
                          '물품 수정',
                          style: TextStyle(fontSize: 18, fontFamily: 'PretendardBold'),
                        ),
                        GestureDetector(
                          onTap: () {
                            onDelete();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '삭제',
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. 입력 필드 (이름, 날짜)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이름 입력 필드
                        _buildLabel('이름'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: '물품 이름을 입력하세요',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                          onChanged: (value) => itemName = value,
                        ),
                        const SizedBox(height: 24),

                        // 날짜 입력 필드
                        _buildLabel('날짜'),
                        const SizedBox(height: 8),
                        _buildDateBox(
                          context,
                          date: startDate,
                          canEdit: false,
                          onTap: () {},
                        ),
                        const SizedBox(height: 16),

                        // 날짜 입력 필드 (리마인드/종료일)
                        _buildDateBox(
                          context,
                          date: endDate,
                          canEdit: true,
                          onTap: () async {
                            await _pickDate(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate, // 납부일 이후만 선택 가능하도록 제한
                              onSelected: (picked) {
                                setState(() {
                                  endDate = picked;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),

                  // 3. 저장 버튼
                  Padding(
                    padding: const EdgeInsets.only(left: 50.0, right:50.0, bottom: 24.0),
                    child: ShortButton(
                      text: "저장",
                      isYes: true, // 삭제는 보통 'No' 스타일 버튼

                      onPressed: () {
                        onSave(nameController.text, endDate);
                        Navigator.pop(context);
                      },
                      width: double.infinity,
                      height: 56,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
// ───────────── CategoryDeleteConfirmPopup 정의 ─────────────
Future<void> CategoryDeleteConfirmPopup({
  required BuildContext context,
  required String categoryName,
  required VoidCallback onConfirmDelete,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        // 🌟 요청하신 가로 543px 너비와 중앙 정렬 팝업 스타일 적용
        child: Container(
          width: 543,
          constraints: const BoxConstraints(maxWidth: 543),
          padding: const EdgeInsets.all(32.0), // 내부 패딩
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 제목
              const Text(
                '정말로 삭제하시겠습니까?',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'PretendardBold',
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 2. 설명 텍스트
              const Text(
                '삭제 시 카테고리 속에 들어있던\n모든 물품이 삭제돼요!',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'PretendardRegular',
                  color: Color(0xFF5D5D5D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 3. 버튼 영역 (아니요/네)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 아니요 (취소 버튼)
                  ShortButton(
                    text: '아니요',
                    onPressed: () => Navigator.pop(context),
                    width: 120,
                    height: 56,
                    fontSize: 18,
                    isYes: false, // 회색 버튼 스타일
                  ),
                  const SizedBox(width: 16),
                  // 네 (확인 버튼)
                  ShortButton(
                    text: '네',
                    onPressed: () {
                      onConfirmDelete();
                      Navigator.pop(context);
                    },
                    width: 120,
                    height: 56,
                    fontSize: 18,
                    isYes: true, // 보라색 버튼 스타일
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
// 팝업 내부 위젯 빌더 함수 (정적)
Widget _buildLabel(String label) {
  return Text(
    label,
    style: const TextStyle(fontSize: 16, fontFamily: 'PretendardRegular'),
  );
}

Widget _buildDateBox(
    BuildContext context, {
      required DateTime date,
      required bool canEdit,
      required VoidCallback onTap,
    }) {
  return GestureDetector(
    onTap: canEdit ? onTap : null,
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: canEdit ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: canEdit ? Border.all(color: Colors.grey.shade300) : null,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDate(date),
            style: TextStyle(
              fontSize: 16,
              color: canEdit ? Colors.black : Colors.black54,
            ),
          ),
          if (canEdit)
            const Icon(
              Icons.calendar_today,
              size: 20,
              color: Colors.grey,
            ),
          if (!canEdit)
            const SizedBox.shrink(), // 납부일은 아이콘 숨김
        ],
      ),
    ),
  );
}

// ───────────── ItemCard ─────────────
class ItemCard extends StatelessWidget {
  final String title;
  final String dateRange;

  const ItemCard({
    super.key,
    required this.title,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final dates = dateRange.split(' ~ ').map((e) => e.trim()).toList();
    final startDate = dates.isNotEmpty ? dates[0] : '';
    final endDate = dates.length > 1 ? dates[1] : startDate;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'PretendardBold',
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            startDate,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'PretendardRegular',
              color: Colors.grey,
            ),
          ),
          if (dates.length > 1)
            Text(
              '~ $endDate',
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'PretendardRegular',
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────── CategoryBox ─────────────
class CategoryBox extends StatefulWidget {
  final String categoryName;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryBox({
    super.key,
    required this.categoryName,
    required this.imagePath,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,   // 추가
    required this.onDelete, // 추가
  });

  @override
  State<CategoryBox> createState() => _CategoryBoxState();
}

class _CategoryBoxState extends State<CategoryBox> {
  bool _showActions = false;
  final double boxSize = 164;

  void _toggleActions() {
    setState(() {
      _showActions = !_showActions;
    });
  }

  Widget _buildActionsMenu() {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              _toggleActions();
              widget.onEdit(); // 🌟 수정하기 콜백 호출
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('수정하기',
                  style: TextStyle(fontFamily: 'PretendardRegular', fontSize: 14)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          InkWell(
            onTap: () {
              _toggleActions();
              widget.onDelete(); // 🌟 삭제하기 콜백 호출
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('삭제하기',
                  style: TextStyle(fontFamily: 'PretendardRegular', fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSelect,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: boxSize,
            height: boxSize,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF4C40F7)
                      : const Color(0xFFE0E0E0),
                  width: widget.isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    widget.imagePath,
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Text('Icon', style: TextStyle(fontSize: 10)),
                        ),
                      );
                    },
                  ),
                  Text(
                    widget.categoryName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'PretendardBold',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF5D5D5D)),
              onPressed: _toggleActions,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          if (_showActions)
            Positioned(
              top: 40,
              right: 15,
              child: _buildActionsMenu(),
            ),
        ],
      ),
    );
  }
}

// ───────────── InventoryPage ─────────────
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final bool _isInitialized = true;
  final bool _isLoading = false;
  int _selectedCategoryIndex = 0;

  final List<String> _categories = ['식품', '학용품', '잡동사니', '악세서리', '기타'];
  final List<Map<String, String>> _items = [
    {'category': '식품', 'title': '딸기잼', 'date': '2025.11.26 ~ 2025.12.26'},
    {'category': '식품', 'title': '피마산 치즈', 'date': '2025.11.14 ~ 2025.12.21'},
    {'category': '식품', 'title': '샐러드', 'date': '2025.11.26 ~ 2025.11.29'},
    {'category': '식품', 'title': '냉동피자', 'date': '2025.11. 26 ~ 2025.12. 26'},
    {'category': '식품', 'title': '딸기잼', 'date': '2025. 11. 26 ~ 2025.12. 26'},
    {'category': '식품', 'title': '피마산 치즈', 'date': '2025.11.14 ~ 2025.12.21'},
    {'category': '식품', 'title': '냉동피자', 'date': '2025.11.26 ~ 2025.12.26'},
  ];

  // 카테고리 수정 핸들러
  void _handleCategoryEdit(String oldName, int index) {
    // CategoryEditPopup 함수가 외부에서 정의되어 있어야 합니다.
    CategoryEditPopup(
      context: context,
      initialCategoryName: oldName,
      onSave: (newName) {
        if (newName != oldName) {
          // TODO: 실제 DB 및 상태 업데이트 로직 구현
          setState(() {
            _categories[index] = newName;
            print('카테고리 수정: $oldName -> $newName');
          });
        }
      },
      // CategoryEditPopup 내부에 이미 onDelete 콜백이 존재하므로,
      // 이 콜백은 CategoryDeleteConfirmPopup을 띄우는 역할을 합니다.
      onDelete: () {
        // CategoryEditPopup에서 삭제 버튼을 누르면 이 함수가 호출되고,
        // 여기서 확인 팝업을 띄웁니다.
        _handleCategoryDeleteConfirm(oldName, index);
      },
    );
  }

// 카테고리 삭제 확인 팝업 핸들러
  void _handleCategoryDeleteConfirm(String categoryName, int index) {
    CategoryDeleteConfirmPopup(
      context: context,
      categoryName: categoryName,
      onConfirmDelete: () {
        // 🌟 최종 삭제 실행 🌟
        // TODO: 실제 DB 및 상태 업데이트 로직 구현 (해당 카테고리 및 물품 모두 삭제)
        setState(() {
          _categories.removeAt(index);
          _items.removeWhere((item) => item['category'] == categoryName);
          if (_selectedCategoryIndex >= _categories.length && _categories.isNotEmpty) {
            _selectedCategoryIndex = _categories.length - 1;
          } else if (_categories.isEmpty) {
            _selectedCategoryIndex = 0;
          }
          print('카테고리 최종 삭제됨: $categoryName');
        });
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double maxContentWidth = 1000;
    final double contentWidth = min(screenWidth, maxContentWidth);

    const double categoryRatio = 367 / (367 + 576);
    const double itemRatio = 541 / (367 + 576);
    const double horizontalPadding = 30.0;

    final double effectiveContentWidth = contentWidth - (horizontalPadding * 2);
    final double categoryWidth = effectiveContentWidth * categoryRatio;
    final double itemWidth = effectiveContentWidth * itemRatio;

    return Scaffold(
      backgroundColor: Colors.white,
      body: !_isInitialized
          ? Container(color: Colors.white)
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Center(
          child: Container(
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 뒤로가기 ───
                Padding(
                  padding: const EdgeInsets.only(
                      top: 20, left: 0, right: 20, bottom: 10),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: SvgPicture.asset(
                      'assets/left.svg',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.arrow_back_ios),
                    ),
                  ),
                ),

                // ─── 제목 ───
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text('버릴까말까 상자',
                          style: TextStyle(
                              fontSize: 32,
                              fontFamily: 'PretendardBold',
                              color: Colors.black)),
                      SizedBox(height: 8),
                      Text('메모를 눌러서 보관된 물품을 수정 및 삭제할 수 있어요.',
                          style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'PretendardRegular',
                              color: Color(0xFF5D5D5D))),
                      SizedBox(height: 30),
                    ],
                  ),
                ),

                // ─── 본문 ───
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── 카테고리 ───
                        SizedBox(
                          width: categoryWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('카테고리',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'PretendardMedium',
                                      color: Colors.black)),
                              const SizedBox(height: 15),
                              Expanded(
                                child: GridView.builder(
                                  padding: EdgeInsets.zero,
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 20,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: _categories.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == _categories.length) {
                                      return SizedBox(
                                        width: 140,
                                        height: 140,
                                        child: Container(
                                          margin: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F5),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: const Color(0xFFE0E0E0)),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFD7DCFA),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.add,
                                                  color: Colors.white, size: 28),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final categoryName = _categories[index];
                                    return CategoryBox(
                                      categoryName: _categories[index],
                                      imagePath: 'assets/home/categorybox.png',
                                      isSelected:
                                      _selectedCategoryIndex == index,
                                      onSelect: () {
                                        setState(() {
                                          _selectedCategoryIndex = index;
                                        });
                                      },
                                      onEdit: () => _handleCategoryEdit(categoryName, index),
                                      onDelete: () => _handleCategoryDeleteConfirm(categoryName, index),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 30),

                        // ─── 물품 ───
                        SizedBox(
                          width: itemWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('보관된 물품',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'PretendardMedium',
                                      color: Colors.black)),
                              const SizedBox(height: 15),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCD7FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 80, vertical: 30),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                  const AlwaysScrollableScrollPhysics(),
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 24,
                                    mainAxisSpacing: 24,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: _items.length,
                                  itemBuilder: (context, index) {
                                    final item = _items[index];
                                    // 🌟 이 부분을 수정하여 GestureDetector로 감싸고 팝업을 호출합니다. 🌟
                                    return GestureDetector(
                                      onTap: () {
                                        // 임시 데이터 파싱
                                        final dates = item['date']!.split(' ~ ');
                                        final startDate = DateFormat("yyyy.MM.dd").parse(dates[0].trim());
                                        // 종료일이 없는 경우 시작일로 대체
                                        final endDate = dates.length > 1 ? DateFormat("yyyy.MM.dd").parse(dates[1].trim()) : startDate;

                                        ItemEditPopup(
                                          context: context,
                                          initialName: item['title']!,
                                          initialStartDate: startDate,
                                          initialEndDate: endDate,
                                          onSave: (newName, newEndDate) {
                                            // TODO: 여기에 실제 물품 수정 로직 (DB 업데이트 및 _items 리스트 업데이트) 구현
                                            print('물품 저장: $newName, 새로운 종료일: $newEndDate');
                                          },
                                          onDelete: () {
                                            // TODO: 여기에 실제 물품 삭제 로직 (DB 삭제 및 _items 리스트 업데이트) 구현
                                            print('물품 삭제: ${item['title']}');
                                          },
                                        );
                                      },
                                      child: Container(
                                        // ... (기존 Container decoration 및 ItemCard)
                                        decoration: BoxDecoration(
                                          color: index == 0
                                              ? const Color(0xFFFFF3F3)
                                              : const Color(0xFFF3F5FF),
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ItemCard(
                                          title: item['title']!,
                                          dateRange: item['date']!,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── 하단 버튼 ───
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: LongButton(
                    text: '물품 추가하러 가기',
                    onPressed: () {Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const keepbox(),
                      ),
                    );},
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
