import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mu/mission_start.dart';
import 'package:mu/widgets/longbutton.dart';
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
  final bool isCompleted;

  const ScheduleCard({
    super.key,
    required this.status,
    required this.section,
    required this.time,
    required this.cardWidth,
    required this.cardHeight,
    required this.fontScale,
    this.orderNumber,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = orderNumber != null;

    Color statusBackgroundColor;
    Color statusTextColor;
    Color contentTextColor;
    Color timeTextColor;
    Color circleColor;
    Widget circleChild;
    Border? border;
    Color cardBackgroundColor = const Color(0xFFF5F5F5);

    Color originalStatusBackgroundColor;
    Color originalStatusTextColor;
    switch (status) {
      case '여유':
        originalStatusBackgroundColor = const Color(0xFFC6DEFF);
        originalStatusTextColor = const Color(0xFF1B73EC);
        break;
      case '보통':
        originalStatusBackgroundColor = const Color(0xFFC0F1D0);
        originalStatusTextColor = const Color(0xFF30AE65);
        break;
      case '혼잡':
      default:
        originalStatusBackgroundColor = const Color(0xFFFFD7D7);
        originalStatusTextColor = const Color(0xFFEC5353);
        break;
    }

    if (isCompleted) {
      statusBackgroundColor = const Color(0xFFDBDEE7);
      statusTextColor = const Color(0xFFB0B8C1);
      contentTextColor = const Color(0xFF8D93A1);
      timeTextColor = const Color(0xFF8D93A1);
      circleColor = const Color(0xFFDBDEE7);
      border = null;
      cardBackgroundColor = const Color(0xFFF5F5F5);
      circleChild = Image.asset(
        'assets/mission/done.png',
        width: 42,
        height: 42,
      );
    } else if (isSelected) {
      statusBackgroundColor = originalStatusBackgroundColor;
      statusTextColor = originalStatusTextColor;
      contentTextColor = const Color(0xFF5D5D5D);
      timeTextColor = const Color(0xFF333333);
      circleColor = const Color(0xFF7F91FF);
      border = Border.all(color: Color(0xFF7F91FF), width: 4.0);
      circleChild = Text(
        orderNumber.toString(),
        style: TextStyle(
          fontFamily: 'PretendardBold',
          color: Colors.white,
          fontSize: 20 * fontScale,
        ),
      );
    } else {
      statusBackgroundColor = originalStatusBackgroundColor;
      statusTextColor = originalStatusTextColor;
      contentTextColor = const Color(0xFF5D5D5D);
      timeTextColor = const Color(0xFF333333);
      circleColor = const Color(0xFFDBDEE7);
      border = null;
      circleChild = Image.asset(
        'assets/mission/undone.png',
        width: 42,
        height: 42,
      );
    }

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * fontScale * 0.8,
                  vertical: 4 * fontScale * 0.8,
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
              SizedBox(height: 8 * fontScale * 0.6),
              Text(
                section,
                style: TextStyle(
                  color: contentTextColor,
                  fontSize: 18 * fontScale,
                  fontFamily: 'PretendardMedium',
                ),
              ),
              SizedBox(height: 17 * fontScale * 0.6),
              Text(
                time,
                style: TextStyle(
                  color: contentTextColor,
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: circleChild,
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
  List<String> _selectedOrder = [];
  Future<void>? _initializationFuture;
  String? _userType;

  List<String> _completedMissionNames = [];
  List<String> _orderedMissionNames = [];
  int _currentMissionIndex = 0;

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

    _currentMissionIndex = await db.getUserMissionIndex(1);
    final orderedMissions = await db.getOrderedMissions(1);
    _orderedMissionNames = orderedMissions.map((s) => s.name).toList();

    if (_currentMissionIndex > 0 &&
        _currentMissionIndex <= _orderedMissionNames.length) {
      _completedMissionNames = _orderedMissionNames.sublist(
        0,
        _currentMissionIndex,
      );
    }
  }

  String _getTimeForStatus(String status, String? userType) {
    switch (userType) {
      case '감정형':
        switch (status) {
          case '혼잡':
            return '30분';
          case '보통':
            return '20분';
          case '여유':
            return '10분';
          default:
            return '10분';
        }
      case '몰라형':
        switch (status) {
          case '혼잡':
            return '30분';
          case '보통':
            return '15분';
          case '여유':
            return '10분';
          default:
            return '10분';
        }
      case '방치형':
      default:
        switch (status) {
          case '혼잡':
            return '30분';
          case '보통':
            return '15분';
          case '여유':
            return '5분';
          default:
            return '5분';
        }
    }
  }

  void _toggleSelection(String section) {
    if (_completedMissionNames.contains(section)) {
      return;
    }
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
          widget.analysisResults.entries.where((entry) {
            final sectionName = entry.key;
            final status = entry.value;
            final bool isCompleted = _completedMissionNames.contains(sectionName);
            final bool isAnalyzed = (status == '혼잡' || status == '보통' || status == '여유');

            return isCompleted || isAnalyzed;

          }).map((entry) {
            final section = entry.key;
            final status = entry.value;
                return {
                  'status': status,
                  'section': section,
                  'time': _getTimeForStatus(status, _userType),
                };
              }).toList();

          final allMissionNames = widget.analysisResults.keys.toList();
          final availableMissionNames =
              allMissionNames
                  .where((name) => !_completedMissionNames.contains(name))
                  .toList();

          final bool showResetButton = availableMissionNames.isEmpty;

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;

              final widthRatio = screenW / 1280;
              final heightRatio = screenH / 800;
              final fontScale = (widthRatio + heightRatio) / 2.1;

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
                            Text(
                              '비움 스케줄링',
                              style: TextStyle(
                                fontSize: 32 * widthRatio,
                                fontFamily: 'PretendardBold',
                                color: const Color(0xFF333333),
                              ),
                            ),
                            SizedBox(height: 10 * heightRatio),
                            Text(
                              '비우고 싶은 순서대로 다시 정렬해보세요.',
                              style: TextStyle(
                                fontSize: 20 * widthRatio,
                                color: Color(0xFF5D5D5D),
                                fontFamily: 'PretendardRegular',
                              ),
                            ),
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
                                        final bool isCompleted =
                                            _completedMissionNames.contains(
                                              sectionName,
                                            );

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
                                            isCompleted: isCompleted,
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                            if (showResetButton)
                              LongButton(
                                text: '재촬영하기',
                                onPressed: () async {
                                  await AppDatabase.instance
                                      .updateUserMissionIndex(1, 0);

                                  await AppDatabase.instance.updateMissionOrder(
                                    1,
                                    [],
                                  );

                                  setState(() {
                                    _selectedOrder.clear();
                                    _completedMissionNames.clear();
                                    _currentMissionIndex = 0;
                                  });
                                },
                              )
                            else
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
                                                final List<String>
                                                finalMissionOrderNames = [
                                                  ..._completedMissionNames,
                                                  ..._selectedOrder,
                                                ];


                                                await AppDatabase.instance
                                                    .updateMissionOrder(
                                                      1,
                                                  finalMissionOrderNames,
                                                    );

                                                await AppDatabase.instance
                                                    .updateUserMissionIndex(
                                                      1,
                                                      _completedMissionNames
                                                          .length,
                                                    );

                                                if (!mounted) return;

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            MissionStartPage(),
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
