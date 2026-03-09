import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../../signal_engine/provider/account_provider.dart';
import '../provider/setting_provider.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _balanceController = TextEditingController();
  final _riskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load saved values
    final settings = ref.read(accountProvider);
    _balanceController.text = settings.balance.toString();
    _riskController.text = settings.riskPercent.toString();
  }

  @override
  Widget build(BuildContext context) {
    final settingAsync = ref.watch(settingsProvider);
    return settingAsync.when(
      data: (settings) {
        //final notifier = ref.read(settingsProvider.notifier);
        return Scaffold(
          appBar: AppBar(
              title: Text(AppStrings.text('account', settings.languageCode))),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _balanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText:
                          "${AppStrings.text('account', settings.languageCode)} ${AppStrings.text('balance', settings.languageCode)} (\$)"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _riskController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Risk % per trade"),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    final balance =
                        double.tryParse(_balanceController.text) ?? 10000;
                    final risk = double.tryParse(_riskController.text) ?? 1;
                    ref.read(accountProvider.notifier).update(balance, risk);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settings saved!")),
                    );
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text("Error loading settings: $error")),
      ),
    );
  }
}
