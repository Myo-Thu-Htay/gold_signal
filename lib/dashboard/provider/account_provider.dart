import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>(
  (ref) => AccountNotifier(),
);

class AccountState {
  final double balance;
  final double riskPercent;

  const AccountState({required this.balance, required this.riskPercent});

  AccountState copyWith({double? balance, double? riskPercent}) {
    return AccountState(
      balance: balance ?? this.balance,
      riskPercent: riskPercent ?? this.riskPercent,
    );
  }
}

class AccountNotifier extends StateNotifier<AccountState> {
  AccountNotifier() : super(const AccountState(balance: 10000, riskPercent: 1)) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bal = prefs.getDouble('account_balance') ?? 10000;
    final risk = prefs.getDouble('account_risk') ?? 1;
    state = AccountState(balance: bal, riskPercent: risk);
  }

  Future<void> update(double pnl) async {
    final prefs = await SharedPreferences.getInstance();
    final newBalance = state.balance + pnl;
    await prefs.setDouble('account_balance', newBalance);
    state = AccountState(balance: newBalance, riskPercent: state.riskPercent);
  }

  Future<void> updateBalanceAndRisk(double balance, double risk) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('account_balance', balance);
    await prefs.setDouble('account_risk', risk);
    state = AccountState(balance: balance, riskPercent: risk);
  }
}

