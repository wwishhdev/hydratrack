import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hydratrack/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:hydratrack/models/settings_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<DateTime, int> _weeklyConsumption = {};
  late int _dailyGoal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final settingsModel = Provider.of<SettingsModel>(context, listen: false);
    _dailyGoal = settingsModel.dailyGoal;

    final storageService = Provider.of<StorageService>(context, listen: false);
    _weeklyConsumption = await storageService.getWeeklyConsumption();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('statistics').tr(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'weekly_summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ).tr(),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 300,
              child: _buildBarChart(),
            ),
            const SizedBox(height: 24.0),
            _buildStatsSummary(),
            const SizedBox(height: 16.0),
            _buildTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (_weeklyConsumption.isEmpty) {
      return Center(
        child: Text('no_data').tr(),
      );
    }

    final List<DateTime> dates = _weeklyConsumption.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (_dailyGoal * 1.2).toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueAccent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = dates[groupIndex];
              final amount = _weeklyConsumption[date] ?? 0;
              final percent = (amount / _dailyGoal * 100).toStringAsFixed(0);
              return BarTooltipItem(
                '${DateFormat.E().format(date)}\n$amount ml\n$percent%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < dates.length) {
                  final date = dates[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat.E().format(date)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 500 == 0) {
                  return Text('${value.toInt()} ml');
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 500,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dates.length, (index) {
          final date = dates[index];
          final amount = _weeklyConsumption[date]!;
          final percentage = amount / _dailyGoal;
          Color barColor;

          if (percentage >= 1) {
            barColor = Colors.green;
          } else if (percentage >= 0.7) {
            barColor = Colors.orange;
          } else {
            barColor = Colors.red;
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: amount.toDouble(),
                color: barColor,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatsSummary() {
    if (_weeklyConsumption.isEmpty) {
      return Container();
    }

    int totalConsumption = 0;
    int daysAboveGoal = 0;
    int bestDay = 0;
    DateTime? bestDayDate;

    _weeklyConsumption.forEach((date, amount) {
      totalConsumption += amount;
      if (amount >= _dailyGoal) {
        daysAboveGoal++;
      }
      if (amount > bestDay) {
        bestDay = amount;
        bestDayDate = date;
      }
    });

    final dailyAverage = totalConsumption ~/ _weeklyConsumption.length;
    final achievementRate = (daysAboveGoal / _weeklyConsumption.length * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'summary',
              style: Theme.of(context).textTheme.titleLarge,
            ).tr(),
            const SizedBox(height: 16.0),
            _buildStatRow(
              Icons.timeline,
              'daily_average',
              '$dailyAverage ml',
            ),
            const Divider(),
            _buildStatRow(
              Icons.check_circle_outline,
              'days_goal_achieved',
              '$daysAboveGoal / ${_weeklyConsumption.length} ($achievementRate%)',
            ),
            const Divider(),
            _buildStatRow(
              Icons.emoji_events,
              'best_day',
              bestDayDate != null
                  ? '${DateFormat.EEEE().format(bestDayDate!)} - $bestDay ml'
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String labelKey, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              labelKey,
              style: Theme.of(context).textTheme.titleSmall,
            ).tr(),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'hydration_tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ).tr(),
              ],
            ),
            const SizedBox(height: 16.0),
            Text('tip_1').tr(),
            const SizedBox(height: 8.0),
            Text('tip_2').tr(),
            const SizedBox(height: 8.0),
            Text('tip_3').tr(),
          ],
        ),
      ),
    );
  }
}