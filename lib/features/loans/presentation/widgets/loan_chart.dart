import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LoanChart extends StatelessWidget {
  final int activeCount;
  final int overdueCount;

  const LoanChart({
    super.key,
    required this.activeCount,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      width: 80,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: activeCount.toDouble(),
              color: Colors.green,
              title: '',
              radius: 18,
            ),
            PieChartSectionData(
              value: overdueCount.toDouble(),
              color: Colors.red,
              title: '',
              radius: 18,
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 18,
        ),
      ),
    );
  }
}
