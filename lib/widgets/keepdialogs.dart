import 'package:flutter/material.dart';

Future<void> showVoiceConfirmDialog({
  required BuildContext context,
  required String itemName,
  required String initialCategory,
  required Function(String selectedCategory) onConfirm,
  required Function(String) onAddCategory,
}) async {
  String customCategory = '';
  bool showEditMode = false;
  String selectedCategory = initialCategory;

  final List<Map<String, dynamic>> categories = [
    {'name': '식품', 'isFilled': false},
    {'name': '의류', 'isFilled': true},
  ];

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Widget _categoryOption(String name) {
          final bool isSelected = (selectedCategory == name);
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = name;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 24,
                      color: isSelected ? Colors.blue : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: isSelected ? Colors.blue : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '음성 인식 확인',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (!showEditMode) ...[
                Text(
                  '"$itemName" 항목을\n"$selectedCategory" 카테고리로 저장할까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          showEditMode = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.black, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: Text(
                        "아니요",
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm(selectedCategory);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: Text(
                        "네",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var item in categories) ...[
                      _categoryOption(item['name']),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      onChanged: (value) => customCategory = value,
                      decoration: InputDecoration(
                        hintText: '새 카테고리 입력',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () {
                        if (customCategory.trim().isNotEmpty) {
                          Navigator.pop(context);
                          onAddCategory(customCategory.trim());
                        } else if (selectedCategory.isNotEmpty) {
                          Navigator.pop(context);
                          onConfirm(selectedCategory);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 18),
                      ),
                      child: Text(
                        "확인",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        );
      },
    ),
  );
}