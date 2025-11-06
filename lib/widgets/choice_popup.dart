import 'package:flutter/material.dart';

import 'longbutton.dart';

class ChoicePopup extends StatelessWidget {
  final String message;
  final String imagePath;
  final VoidCallback onConfirm;

  const ChoicePopup({
    super.key,
    required this.message,
    required this.imagePath,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 543,
        height: 384,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 35),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5D5D5D),
                fontSize: 20,
                fontFamily: 'PretendardRegular',
                height: 1.7,
              ),
            ),

            Container(
              width: 389,
              height: 150,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 5.0,
                horizontal: 10,
              ),
              child: SizedBox(
                width: 389,
                height: 52,
                child: LongButton(
                  text: "알겠어요",
                  onPressed: onConfirm,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
