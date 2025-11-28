import 'package:flutter/material.dart';
import 'shortbutton.dart';

Future<void> CategoryEditPopup({
  required BuildContext context,
  required String initialCategoryName,
  required Function(String newCategoryName) onSave,
  required Function() onDelete,
}) async {
  TextEditingController _categoryNameController = TextEditingController(text: initialCategoryName);

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          padding: const EdgeInsets.only(top: 16.0),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      '카테고리 이름 변경',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        onSave(_categoryNameController.text);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '완료',
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이름',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _categoryNameController,
                      decoration: InputDecoration(
                        hintText: '카테고리 이름을 입력하세요',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                child: ShortButton(
                  text: "저장",

                  isYes: true,

                  onPressed: () {
                    onDelete();
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
}