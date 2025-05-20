import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:hydratrack/models/consumption_model.dart';
import 'package:hydratrack/models/settings_model.dart';
import 'package:hydratrack/screens/history_screen.dart';
import 'package:hydratrack/screens/settings_screen.dart';
import 'package:hydratrack/services/storage_service.dart';
import 'package:hydratrack/widgets/progress_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _consumedToday = 0;
  List<Consumption> _todayConsumptions = [];

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final today = DateTime.now();

    _todayConsumptions = await storage.getConsumptionsByDate(today);
    _consumedToday = _todayConsumptions.fold(0, (sum, item) => sum + item.amount);

    if (mounted) setState(() {});
  }

  Future<void> _addWater(int amount) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final consumption = Consumption(
      amount: amount,
      timestamp: DateTime.now(),
    );

    await storage.saveConsumption(consumption);
    await _loadTodayData();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    final goalProgress = _consumedToday / settings.dailyGoal;

    return Scaffold(
      appBar: AppBar(
        title: Text('HydraTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadTodayData());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayData,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: WaterProgressIndicator(
                      progress: goalProgress,
                      consumedAmount: _consumedToday,
                      dailyGoal: settings.dailyGoal,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text('+250 ml'),
                            onPressed: () => _addWater(250),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text('+500 ml'),
                            onPressed: () => _addWater(500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle),
                      label: Text('custom_amount').tr(),
                      onPressed: () => _showCustomAmountDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _todayConsumptions.length,
                          itemBuilder: (context, index) {
                            final consumption = _todayConsumptions[index];
                            final time = DateFormat.Hm().format(consumption.timestamp);
                            return ListTile(
                              leading: const Icon(Icons.water_drop),
                              title: Text('${consumption.amount} ml'),
                              subtitle: Text(time),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteConsumption(index),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
        },
        tooltip: 'history'.tr(),
        child: const Icon(Icons.history),
      ),
    );
  }

  Future<void> _showCustomAmountDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('enter_amount').tr(),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'amount_ml'.tr(),
              suffixText: 'ml',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel').tr(),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  int? amount = int.tryParse(controller.text);
                  if (amount != null && amount > 0) {
                    _addWater(amount);
                  }
                }
                Navigator.pop(context);
              },
              child: Text('add').tr(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteConsumption(int index) async {
    // Esta función eliminaría un consumo del historial
    // Implementación pendiente
  }
}