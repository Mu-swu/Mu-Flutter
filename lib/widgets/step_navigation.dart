import 'package:flutter/material.dart';

class StepNavigation extends StatelessWidget {
  final int currentIndex;
  final int totalSteps;
  final Function(int) onStepSelected;

  const StepNavigation({
    Key? key,
    required this.currentIndex,
    required this.totalSteps,
    required this.onStepSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(totalSteps, (index) {
        bool isSelected = index == currentIndex;

        return GestureDetector(
          onTap: () => onStepSelected(index),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 100,
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'STEP ${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}