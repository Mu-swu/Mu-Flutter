import 'package:flutter/material.dart';

enum UserType { bang, gam, mol }

class UserThemeManager {
  static UserType currentUserType = UserType.mol; // 기본값은 '방치형'으로 설정

  static void setUserType(UserType type) {
    currentUserType = type;
  }

  static String get retestImage {
    switch (currentUserType) {
      case UserType.bang:
        return 'assets/home/retest_bang.png';
      case UserType.gam:
        return 'assets/home/retest_gam.png';
      case UserType.mol:
        return 'assets/home/retest_mol.png';
    }
  }

  static String get tagLabel {
    switch (currentUserType) {
      case UserType.bang:
        return '#정리보단 숨기기';
      case UserType.gam:
        return '#추억에 미련가득';
      case UserType.mol:
        return '#어떻게 시작할까';
    }
  }

  static String get userTitle {
    switch (currentUserType) {
      case UserType.bang:
        return '방치형 비움이';
      case UserType.gam:
        return '감정형 비움이';
      case UserType.mol:
        return '몰라형 비움이';
    }
  }

  static String get momImage {
    switch (currentUserType) {
      case UserType.bang:
        return 'assets/home/mom_bang.png';
      case UserType.gam:
        return 'assets/home/mom_gam.png';
      case UserType.mol:
        return 'assets/home/mom_mol.png';
    }
  }

  static Color get momBackgroundColor {
    switch (currentUserType) {
      case UserType.bang:
        return const Color(0xFFFBF4FF);
      case UserType.gam:
        return const Color(0xFFFFF6EF);
      case UserType.mol:
        return const Color(0xFFF3FBF0);
    }
  }

  static String get statusImage {
    switch (currentUserType) {
      case UserType.bang:
        return 'assets/home/refr.png';
      case UserType.gam:
        return 'assets/home/closet.png';
      case UserType.mol:
        return 'assets/home/drawer.png';
    }
  }

  static Color get keepboxGradientStartColor {
    switch (currentUserType) {
      case UserType.bang:
        return const Color(0xFFF2D7FF); // 방치형 시작 색상
      case UserType.gam:
        return const Color(0xFFFEE1C7); // 감정형 시작 색상
      case UserType.mol:
        return const Color(0xFFD7F2C2); // 몰라형 시작 색상
    }
  }
}