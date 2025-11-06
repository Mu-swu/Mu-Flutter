import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mu/mission_start.dart';
import 'widgets/shortbutton.dart';
import 'package:mu/data/database.dart';

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
        statusBackgroundColor = const Color(0xFFC6DEFF);
        statusTextColor = const Color(0xFF1B73EC);
        break;
      case '보통':
        statusBackgroundColor = const Color(0xFFC0F1D0);
        statusTextColor = const Color(0xFF30AE65);
        break;
      case '혼잡':
        statusBackgroundColor = const Color(0xFFFFD7D7);
        statusTextColor = const Color(0xFFEC5353);
        break;
    }

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border:
            orderNumber != null
                ? Border.all(color: Color(0xFF7F91FF), width: 4.0)
                : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: 28,vertical: 28),
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
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontFamily: 'PretendardMedium',
                    fontSize: 14 * fontScale,
                  ),
                ),
              ),
              SizedBox(height: 8 * fontScale),
              Text(
                section,
                style: TextStyle(
                  color: const Color(0xFF8D93A1),
                  fontSize: 18 * fontScale,
                  fontFamily: 'PretendardMedium',
                ),
              ),
              SizedBox(height: 17 * fontScale),
              Text(
                time,
                style: TextStyle(
                  color: const Color(0xFF8D93A1),
                  fontSize: 32 * fontScale,
                  fontFamily: 'PretendardMedium',
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 42 * fontScale,
              height: 42 * fontScale,
              decoration: BoxDecoration(
                color:
                    orderNumber != null ? Color(0xFF7F91FF) : Color(0xFFDBDEE7),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child:
                  orderNumber != null
                      ? Text(
                        orderNumber.toString(),
                        style: TextStyle(
                          fontFamily: 'PretendardBold',
                          color: Colors.white,
                          fontSize: 20 * fontScale,
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

  Future<void>? _initializationFuture;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializePage();
  }

  Future<void> _initializePage() async {
    final db = AppDatabase.instance;
    _userType = await db.getUserType(1);

    if (_userType == null || _userType!.isEmpty) {
      _userType = '방치형';
    }
  }

  String _getTimeForStatus(String status, String? userType) {
    switch (userType) {
      case '감정형':
        switch (status) {
          case '혼잡':
            return '1시간 30분';
          case '보통':
            return '1시간';
          case '여유':
            return '45분';
          default:
            return '45분';
        }

      case '몰라형':
        switch (status) {
          case '혼잡':
            return '1시간';
          case '보통':
            return '40분';
          case '여유':
            return '20분';
          default:
            return '20분';
        }

      case '방치형':
      default:
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("오류가 발생했습니다: ${snapshot.error}"));
          }

          final List<Map<String, String>> cardData =
              widget.analysisResults.entries.map((entry) {
                final section = entry.key;
                final status = entry.value;
                return {
                  'status': status,
                  'section': section,
                  'time': _getTimeForStatus(status, _userType),
                };
              }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;

              // 기준 해상도(1280x800)에 대한 비율
              final widthRatio = screenW / 1280;
              final heightRatio = screenH / 800;
              final fontScale = (widthRatio + heightRatio) / 2.1;

              // 카드 크기
              final cardWidth = 310 * widthRatio;
              final cardHeight = 170 * heightRatio;

              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 20),
                      child: IconButton(
                        icon: SvgPicture.asset('assets/left.svg'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 150 * widthRatio,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 25 * heightRatio),
                            // 타이틀
                            Text(
                              '비움 스케줄링',
                              style: TextStyle(
                                fontSize: 32*widthRatio,
                                fontFamily: 'PretendardBold',
                                color: const Color(0xFF333333),
                              ),
                            ),
                            SizedBox(height: 10 * heightRatio),
                            Text(
                              '비우고 싶은 순서대로 다시 정렬해보세요.',
                              style: TextStyle(
                                fontSize: 20*widthRatio,
                                color: Color(0xFF5D5D5D),
                                fontFamily: 'PretendardRegular'
                              ),
                            ),

                            // 카드 영역
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: Wrap(
                                  spacing: 25 * widthRatio,
                                  runSpacing: 25 * heightRatio,
                                  alignment: WrapAlignment.start,
                                  children:
                                      cardData.map((c) {
                                        final sectionName = c['section']!;
                                        final int? order =
                                            _selectedOrder.contains(sectionName)
                                                ? _selectedOrder.indexOf(
                                                      sectionName,
                                                    ) +
                                                    1
                                                : null;
                                        return GestureDetector(
                                          onTap:
                                              () =>
                                                  _toggleSelection(sectionName),
                                          behavior: HitTestBehavior.opaque,
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
                            // 버튼
                            Row(
                              children: [
                                Flexible(
                                  child: ShortButton(
                                    text: "초기화",
                                    isYes: false,
                                    onPressed: () {
                                      setState(() {
                                        _selectedOrder.clear();
                                      });
                                    },
                                    height: 64,
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
                                            : () async {
                                              await AppDatabase.instance
                                                  .updateMissionOrder(
                                                    1,
                                                    _selectedOrder,
                                                  );

                                              await AppDatabase.instance
                                              .updateUserMissionIndex(1, 0);

                                              final firstMissionName =
                                                  _selectedOrder.first;
                                              final missionData = cardData
                                                  .firstWhere(
                                                    (data) =>
                                                        data['section'] ==
                                                        firstMissionName,
                                                  );

                                              if (!mounted) return;

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          MissionStartPage(
                                                          ),
                                                ),
                                              );
                                            },
                                    height: 64,
                                    fontSize: 18 * fontScale,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 80 * heightRatio),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
