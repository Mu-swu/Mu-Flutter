import 'package:flutter/material.dart';
import 'package:mu/data/database.dart';

class DDayBanner extends StatelessWidget {
  final KeepBox item;
  final String space;

  const DDayBanner({Key? key, required this.item, required this.space})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 30.0),
          Image.asset('assets/mu.png', width: 50, height: 50),
          const SizedBox(width: 30.0),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MU',
                  style: TextStyle(
                    fontFamily: 'PretendardMedium',
                    fontSize: 16,
                    color: Color(0xFF5D5D5D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                Text(
                  '${space} 속 ${item.name}의 유예기간이 임박했어요!',
                  style: TextStyle(
                    fontFamily: 'PretendardMedium',
                    fontSize: 16,
                    color: Color(0xFF5D5D5D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  '버려야 할지, 아니면 마지막 기회를 줄지 지금 바로 확인하고 결정해보세요!',
                  style: TextStyle(
                    fontFamily: 'PretendardRegular',
                    fontSize: 14,
                    color: Color(0xFF8D93A1),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
