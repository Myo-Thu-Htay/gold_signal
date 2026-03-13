Gold Signal 📈

A Flutter-based trading assistant app designed to analyze Gold (XAUUSD) price movements and manage trades with real-time data.

The app helps traders monitor price action, calculate trade risk/reward, and manage open positions efficiently.

---

✨ Features

- 📊 Live Gold Price Tracking
- 📉 Support / Resistance Analysis
- 🚀 Breakout & Retest Detection (coming soon)
- 💧 Liquidity Sweep Detection (coming soon)
- 📐 Risk / Reward Calculation
- 🎯 Automatic TP / SL Monitoring
- 💼 Portfolio & Trade Management
- 🔔 Trade Notification System

---

🛠 Built With

- Flutter – Cross-platform UI framework
- Dart – Application logic
- Riverpod – State management
- WebSocket API – Live market data
- Binance API – Price feed source

---

📱 Screens

- Dashboard – Market overview and signals
- Account – Trading statistics
- Add Trade – Manual trade entry
- Portfolio – Active trade tracking
- Settings – App configuration

---

⚙️ Installation

1️⃣ Clone the repository

git clone https://github.com/Myo-Thu-Htay/gold_signal.git

2️⃣ Navigate to project

cd gold_signal

3️⃣ Install dependencies

flutter pub get

4️⃣ Run the app

flutter run

---

🚀 Build Release

flutter build appbundle --release

or

flutter build apk --release

---

🔒 Security Notes

- API keys are not stored inside the app
- Market data is retrieved through a secure backend server
- Release builds use code obfuscation

---

📊 Trading Strategy Logic

The app detects trading opportunities using:

- Support & Resistance Zones
- Breakout Confirmation
- Liquidity Sweep
- Retest Entry
- Risk/Reward calculation

Example trade setup:

- Entry: Breakout Retest
- Risk/Reward: 1:2
- Stop Loss: Structure Low
- Take Profit: Next Resistance

---

📌 Disclaimer

This app is a trading assistant tool and does not provide financial advice.
Trading involves risk. Always trade responsibly.

---

👨‍💻 Author

Developed by Myo Thu Htay

---

⭐ Support

If you find this project useful, please consider giving it a star on GitHub.
