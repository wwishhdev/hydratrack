import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:hydratrack/models/consumption_model.dart';
import 'package:hydratrack/models/settings_model.dart';
import 'package:hydratrack/screens/history_screen.dart';
import 'package:hydratrack/screens/settings_screen.dart';
import 'package:hydratrack/services/storage_service.dart';
import 'package:hydratrack/widgets/progress_indicator.dart';
import 'package:flutter/services.dart';

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
        title: const Text('HydraTrack'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            tooltip: 'history'.tr(),
          ),
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        DateFormat.yMMMMd(context.locale.languageCode).format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: WaterProgressIndicator(
                          progress: goalProgress,
                          consumedAmount: _consumedToday,
                          dailyGoal: settings.dailyGoal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('+250 ml'),
                          onPressed: () => _addWater(250),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('+500 ml'),
                          onPressed: () => _addWater(500),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'today',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ).tr(),
                      const Expanded(child: SizedBox()),
                      Text(
                        '${_todayConsumptions.length} ${'records'.tr()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _todayConsumptions.isEmpty
                    ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_records',
                          style: TextStyle(color: Colors.grey[600]),
                        ).tr(),
                      ],
                    ),
                  ),
                )
                    : Column(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todayConsumptions.length > 5 ? 5 : _todayConsumptions.length,
                      itemBuilder: (context, index) {
                        final consumption = _todayConsumptions[index];
                        final time = DateFormat.Hm().format(consumption.timestamp);
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 8.0),
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
                            subtitle: Text(time),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteConsumption(index),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_todayConsumptions.length > 5)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.history),
                          label: Text('view_more').tr(),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HistoryScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomAmountDialog() async {
    TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('enter_amount').tr(),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'amount_ml'.tr(),
                suffixText: 'ml',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Permitir solo números enteros
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              // Agregar validación para limitar el valor máximo
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_amount'.tr();
                }

                int? amount = int.tryParse(value);
                if (amount == null) {
                  return 'enter_valid_number'.tr();
                }

                if (amount <= 0) {
                  return 'amount_must_be_positive'.tr();
                }

                if (amount > 5000) {
                  return 'amount_too_large'.tr();
                }

                return null;
              },
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel').tr(),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  int? amount = int.tryParse(controller.text);
                  if (amount != null && amount > 0 && amount <= 5000) {
                    _addWater(amount);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text('add').tr(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteConsumption(int index) async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('confirm_delete').tr(),
            content: Text('delete_consumption_confirmation').tr(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel').tr(),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text('delete').tr(),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Eliminar el consumo
    final consumptionToRemove = _todayConsumptions[index];
    final storage = Provider.of<StorageService>(context, listen: false);

    // Crear nueva lista sin el elemento eliminado
    final updatedConsumptions = List<Consumption>.from(_todayConsumptions)
      ..removeAt(index);

    // Actualizar el almacenamiento
    final today = DateTime.now();

    // Si usamos la API indirecta a través de StorageService
    await storage.deleteAndReplaceConsumptions(today, updatedConsumptions);

    // Actualizar la UI
    await _loadTodayData();

    // Mostrar confirmación
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('consumption_deleted').tr(),
        action: SnackBarAction(
          label: 'undo'.tr(),
          onPressed: () async {
            // Restaurar el consumo eliminado
            await storage.saveConsumption(consumptionToRemove);
            await _loadTodayData();
          },
        ),
      ),
    );
  }
}