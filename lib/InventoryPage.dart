import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'widgets/longbutton.dart';

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

  const CategoryBox({
    super.key,
    required this.categoryName,
    required this.imagePath,
    required this.isSelected,
    required this.onSelect,
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
            onTap: _toggleActions,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('수정하기',
                  style: TextStyle(fontFamily: 'PretendardRegular', fontSize: 14)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          InkWell(
            onTap: _toggleActions,
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
    {'category': '식품', 'title': '딸기잼', 'date': '2025.05.26 ~ 2025.08.26'},
    {'category': '식품', 'title': '피마산 치즈', 'date': '2025.05.14 ~ 2025.05.21'},
    {'category': '식품', 'title': '샐러드', 'date': '2025.05.26'},
    {'category': '식품', 'title': '냉동피자', 'date': '2025. 05. 26 ~ 2025. 08. 26'},
    {'category': '식품', 'title': '딸기잼', 'date': '2025. 05. 26 ~ 2025. 08. 26'},
    {'category': '식품', 'title': '피마산 치즈', 'date': '2025.05.14 ~ 2025.05.21'},
    {'category': '식품', 'title': '샐러드', 'date': '2025.05.26'},
    {'category': '식품', 'title': '냉동피자', 'date': '2025. 05. 26 ~ 2025. 08. 26'},
  ];

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
                                    return Container(
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
                  padding: const EdgeInsets.all(30),
                  child: LongButton(
                    text: '물품 추가하러 가기',
                    onPressed: () {},
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
