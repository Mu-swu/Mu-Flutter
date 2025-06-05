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

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Widget _categoryOption(String name){
          final bool isSelected=(selectedCategory==name);
          return GestureDetector(
            onTap:(){
              setState((){
                selectedCategory=name;
              });
            },
            child:Container(
              padding:const EdgeInsets.symmetric(vertical:14, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected? Colors.blue.shade100:Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border:Border.all(
                  color:isSelected?Colors.blue:Colors.transparent,
                  width:1.5,
                ),
              ),
              child:Row(
                children: [
                  Text(
                    name,
                    style:TextStyle(
                      fontSize: 16,
                      color:isSelected?Colors.blue:Colors.black,
                      fontWeight: isSelected?FontWeight.bold:FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.check_circle,
                    size:20,
                    color:isSelected?Colors.blue:Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '음성 인식 확인',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (!showEditMode) ...[
                Text(
                  '"$itemName" 항목을\n"$selectedCategory" 카테고리로 저장할까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 28),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text("아니요"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm(selectedCategory);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text("네", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ] else ...[
                _categoryOption("식품"),
                const SizedBox(height: 12),
                _categoryOption("의류"),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => customCategory = value,
                  decoration: InputDecoration(
                    hintText: '새 카테고리 입력',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (customCategory.trim().isNotEmpty) {
                      Navigator.pop(context);
                      onAddCategory(customCategory.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  child: Text("추가하기", style: TextStyle(color: Colors.white)),
                ),
              ]
            ],
          ),
        );
      },
    ),
  );
}