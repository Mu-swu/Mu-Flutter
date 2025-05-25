import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/ItemListSection.dart';
import 'widgets/ItemSaveSection.dart';

class keepbox extends StatefulWidget {
  const keepbox({super.key});

  @override
  State<keepbox> createState() => _keepboxState();
}

class _keepboxState extends State<keepbox> {
  List<Map<String, String>> foodItems = [];
  bool isSaving = false;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        foodItems.add({
          'name': '딸기잼',
          'date': '3월 29일',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final widthRatio = screenWidth / 1280;
    final heightRatio = screenHeight / 832;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 1280 * widthRatio,
          height: 832 * heightRatio,
          padding: EdgeInsets.all(32 * widthRatio),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF333333), width: 0.5),
            borderRadius: BorderRadius.circular(10 * widthRatio),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // 좌측 안내 영역
              Container(
                width: 640 * widthRatio,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '못 버린 물건이 있나요?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30 * widthRatio,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 40 * heightRatio),
                    Image.asset(
                      'assets/box.jpg',
                      width: 224 * 1.3 * widthRatio,
                      height: 226 * 1.3 * heightRatio,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 40 * heightRatio),
                    _infoBox(
                      text:
                      '애매한 건 딱 10초 고민하고, ‘버릴까 말까 상자’에 넣어.\n미련과 혼란은 그 상자 안에 다 넣고, 냉장고 안은 깔끔하게.',
                      widthRatio: widthRatio,
                      heightRatio: heightRatio,
                    ),
                    SizedBox(height: 24 * heightRatio),
                    _infoBox(
                      text:
                      '‘버릴까 말까’ 하고 말하면서 식재료 이름을 말해.\n자동으로 분류하고 ‘버릴까 말까 상자’에 저장해줄게.',
                      widthRatio: widthRatio,
                      heightRatio: heightRatio,
                    ),
                  ],
                ),
              ),

              SizedBox(width: 32 * widthRatio),

              // 우측 콘텐츠
              Expanded(
                child: isSaving
                    ? ItemSaveSection(
                  widthRatio: widthRatio,
                  heightRatio: heightRatio,
                  itemName: foodItems[selectedIndex!]['name']!,
                  onExit: () {
                    setState(() {
                      isSaving = false;
                    });
                  },
                )
                    : ItemListSection(
                  title: '식품',
                  items: foodItems,
                  onAddPressed: () {
                    setState(() {
                      foodItems.add({'name': '새 식품', 'date': '오늘'});
                    });
                  },
                  onItemTapped: (index) {
                    final now = DateTime.now();
                    final formattedDate = DateFormat('MM월 dd일').format(now);
                    setState(() {
                      foodItems[index]['date'] = formattedDate;
                      selectedIndex = index;
                      isSaving = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox({
    required String text,
    required double widthRatio,
    required double heightRatio,
  }) {
    return Container(
      width: 500 * widthRatio,
      height: 120 * heightRatio,
      padding: EdgeInsets.all(16 * widthRatio),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10 * widthRatio),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16 * widthRatio,
            color: Color(0xFF5C5C5C),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}