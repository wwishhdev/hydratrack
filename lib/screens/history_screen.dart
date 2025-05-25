import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hydratrack/models/consumption_model.dart';
import 'package:hydratrack/services/storage_service.dart';
import 'package:hydratrack/screens/statistics_screen.dart';
import 'package:provider/provider.dart';
import 'package:hydratrack/models/settings_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<DateTime> _dates = [];
  final Map<DateTime, List<Consumption>> _consumptionsMap = {};
  final Map<DateTime, int> _totalConsumptionMap = {};
  late int _dailyGoal;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    final settingsModel = Provider.of<SettingsModel>(context, listen: false);
    _dailyGoal = settingsModel.dailyGoal;

    // Generar las últimas 7 fechas
    _dates.clear();
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      _dates.add(date);
    }

    // Cargar los consumos de cada día
    final storage = context.read<StorageService>();
    _consumptionsMap.clear();
    _totalConsumptionMap.clear();

    for (final date in _dates) {
      final consumptions = await storage.getConsumptionsByDate(date);
      _consumptionsMap[date] = consumptions;

      final totalConsumption = consumptions.fold(0, (sum, item) => sum + item.amount);
      _totalConsumptionMap[date] = totalConsumption;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('history').tr(),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
            tooltip: 'statistics'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'last_7_days',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ).tr(),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    itemBuilder: (context, index) {
                      final date = _dates[index];
                      final isSelected = _areSameDay(_selectedDate, date);
                      final totalAmount = _totalConsumptionMap[date] ?? 0;
                      final percentComplete = _dailyGoal > 0 ? (totalAmount / _dailyGoal) * 100 : 0;
                      final formattedDate = DateFormat.MMMd(context.locale.languageCode).format(date);
                      final isToday = _areSameDay(date, DateTime.now());

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isToday
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '$totalAmount ml',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                '${percentComplete.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: isSelected
                                      ? Colors.white70
                                      : Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildDayDetail(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetail() {
    final consumptions = _consumptionsMap[_selectedDate] ?? [];
    if (consumptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'no_records',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ).tr(),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            DateFormat.yMMMMd(context.locale.languageCode).format(_selectedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: consumptions.length,
            itemBuilder: (context, index) {
              final consumption = consumptions[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Icon(
                      Icons.water_drop,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text(
                    '${consumption.amount} ml',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(DateFormat.Hm().format(consumption.timestamp)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _areSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}