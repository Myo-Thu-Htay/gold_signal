class AppStrings {
  static final Map<String, Map<String, String>> _localized = {
    'en': {
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'language': 'Language',
      'notifications': 'Notifications',
      'dashboard': 'Dashboard',
      'balance': 'Balance',
      'account': 'Account',
      'profit': 'Profit',
      'equity': 'Equity',
      'trade': 'Trade',
      'tradeHistory': 'Trade History',
      'portfolio': 'Portfolio',
      'tradingStats': 'Trading Stats',
      'winRate': 'Win Rate',
      'trades': 'Trades',
      'accountSettings': 'Account Settings',
    },
    'my': {
      'settings': 'ဆက်တင်များ',
      'darkMode': 'အမှောင်မုဒ်',
      'lightMode': 'အလင်းမုဒ်',
      'language': 'ဘာသာစကား',
      'notifications': 'အသိပေးချက်များ',
      'dashboard': 'ဒက်ရှ်ဘုတ်',
      'balance': 'လက်ကျန်',
      'profit': 'အမြတ်',
      'equity': 'အရင်းအနှီး',
      'trade': 'ကုန်သွယ်မှု',
      'tradeHistory': 'ကုန်သွယ်မှုမှတ်တမ်း',
      'account': 'အကောင့်',
      'portfolio': 'Portfolio',
      'winRate': 'အနိုင်ရနှုန်း',
      'tradingStats': 'ကုန်သွယ်မှုဆိုင်ရာအချက်အလက်များ',
      'trades': 'ကုန်သွယ်မှုများ',
      'accountSettings': 'အကောင့်ဆက်တင်များ',
    },
  };

  static String text(String key, String languageCode) {
    if (languageCode == 'my') {
      return _localized['my']?[key] ?? key;
    } else {
      return _localized['en']?[key] ?? key;
    }
  }
}
