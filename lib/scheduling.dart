import 'package:flutter/material.dart';
import 'package:mu/mission_start.dart';
import 'widgets/shortbutton.dart';

// ===== ScheduleCard =====
class ScheduleCard extends StatelessWidget {
  final String status;
  final String section;
  final String time;
  final double cardWidth;
  final double cardHeight;
  final double fontScale;
  final int? orderNumber;

  const ScheduleCard({
    super.key,
    required this.status,
    required this.section,
    required this.time,
    required this.cardWidth,
    required this.cardHeight,
    required this.fontScale,
    this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    Color statusBackgroundColor = Colors.transparent;
    Color statusTextColor = Colors.black;

    switch (status) {
      case '여유':
        statusBackgroundColor = const Color(0xFFC6E9C6);
        statusTextColor = const Color(0xFF63BB63);
        break;
      case '보통':
        statusBackgroundColor = const Color(0xFFE9F0FC);
        statusTextColor = const Color(0xFF678FF1);
        break;
      case '혼잡':
        statusBackgroundColor = const Color(0xFFF9C0C0);
        statusTextColor = const Color(0xFFF16767);
        break;
    }

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20 * fontScale),
        border:
            orderNumber != null
                ? Border.all(color: Colors.indigo[600]!, width: 2.0)
                : null,
      ),
      padding: EdgeInsets.all(24 * fontScale),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * fontScale,
                  vertical: 4 * fontScale,
                ),
                decoration: BoxDecoration(
                  color: statusBackgroundColor,
                  borderRadius: BorderRadius.circular(8 * fontScale),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * fontScale,
                  ),
                ),
              ),
              SizedBox(height: 10 * fontScale),
              Text(
                section,
                style: TextStyle(
                  color: const Color(0xFF8D93A1),
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8 * fontScale),
              Text(
                time,
                style: TextStyle(
                  color: const Color(0xFF8D93A1),
                  fontSize: 32 * fontScale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 28 * fontScale,
              height: 28 * fontScale,
              decoration: BoxDecoration(
                color:
                    orderNumber != null ? Colors.indigo[600] : Colors.grey[400],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child:
                  orderNumber != null
                      ? Text(
                        orderNumber.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== EmptyingSchedulePage =====
class EmptyingSchedulePage extends StatefulWidget {
  final Map<String, String> analysisResults;

  const EmptyingSchedulePage({super.key, required this.analysisResults});

  @override
  _EmptyingSchedulePageState createState() => _EmptyingSchedulePageState();
}

class _EmptyingSchedulePageState extends State<EmptyingSchedulePage> {
  // 카드 데이터 리스트
  List<String> _selectedOrder = [];

  String _getTimeForStatus(String status) {
    switch (status) {
      case '혼잡':
        return '1시간';
      case '보통':
        return '45분';
      case '여유':
        return '30분';
      default:
        return '30분';
    }
  }

  Duration _parseDuration(String timeString) {
    if (timeString.contains('시간')) {
      final hours = int.tryParse(timeString.replaceAll('시간', '').trim()) ?? 0;
      return Duration(hours: hours);
    } else if (timeString.contains('분')) {
      final minutes = int.tryParse(timeString.replaceAll('분', '').trim()) ?? 0;
      return Duration(minutes: minutes);
    }
    return const Duration(minutes: 30);
  }

  void _toggleSelection(String section) {
    setState(() {
      if (_selectedOrder.contains(section)) {
        _selectedOrder.remove(section);
      } else {
        _selectedOrder.add(section);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> cardData =
        widget.analysisResults.entries.map((entry) {
          final section = entry.key;
          final status = entry.value;
          return {
            'status': status,
            'section': section,
            'time': _getTimeForStatus(status),
          };
        }).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          final screenH = constraints.maxHeight;

          // 기준 해상도(1280x800)에 대한 비율
          final widthRatio = screenW / 1280;
          final heightRatio = screenH / 800;
          final fontScale = (widthRatio + heightRatio) / 2;

          // 카드 크기
          final cardWidth = 298 * widthRatio;
          final cardHeight = 180 * heightRatio;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 150 * widthRatio,
                vertical: 20 * heightRatio,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 뒤로가기 버튼
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: const Color(0xFF8D93A1),
                        size: 24 * fontScale,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(height: 20 * heightRatio),

                  // 타이틀
                  Text(
                    '비움 스케줄링',
                    style: TextStyle(
                      fontSize: 28 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 10 * heightRatio),
                  Text(
                    '비우고 싶은 순서대로 다시 정렬해보세요.',
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 40 * heightRatio),

                  // 카드 영역
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: 40 * widthRatio,
                        runSpacing: 40 * heightRatio,
                        alignment: WrapAlignment.start,
                        children:
                            cardData.map((c) {
                              final sectionName = c['section']!;
                              final int? order =
                                  _selectedOrder.contains(sectionName)
                                      ? _selectedOrder.indexOf(sectionName) + 1
                                      : null;
                              return GestureDetector(
                                onTap: () => _toggleSelection(sectionName),
                                child: ScheduleCard(
                                  status: c['status']!,
                                  section: sectionName,
                                  time: c['time']!,
                                  cardWidth: cardWidth,
                                  cardHeight: cardHeight,
                                  fontScale: fontScale,
                                  orderNumber: order,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 40 * heightRatio),

                  // 버튼
                  Row(
                    children: [
                      Expanded(
                        child: ShortButton(
                          text: "초기화",
                          isYes: false,
                          onPressed: () {
                            setState(() {
                              _selectedOrder.clear();
                            });
                          },
                          height: 60 * heightRatio,
                          fontSize: 18 * fontScale,
                        ),
                      ),
                      SizedBox(width: 20 * widthRatio),
                      Expanded(
                        child: ShortButton(
                          text: "미션 시작",
                          isYes: _selectedOrder.isNotEmpty,
                          onPressed:
                              _selectedOrder.isEmpty
                                  ? null
                                  : () {
                                    final firstMissionName =
                                        _selectedOrder.first;
                                    final missionData = cardData.firstWhere(
                                      (data) =>
                                          data['section'] == firstMissionName,
                                    );
                                    final timeString = missionData['time']!;
                                    final missionDuration = _parseDuration(
                                      timeString,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => MissionStartPage(
                                              missionOrder: _selectedOrder,
                                              missionTime: missionDuration,
                                            ),
                                      ),
                                    );
                                  },
                          height: 60 * heightRatio,
                          fontSize: 18 * fontScale,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40 * heightRatio),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
