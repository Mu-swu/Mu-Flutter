import 'package:flutter/material.dart';
import 'mission_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Timer Mission',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(),       // 기존 홈을 사용
        '/mission': (context) => MissionStepPage(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Mu'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/mission'); // 미션 화면 이동
              },
              child: const Text('미션 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
