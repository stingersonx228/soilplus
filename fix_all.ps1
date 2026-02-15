powershell -ExecutionPolicy Bypass -File .\fix_all.ps1
flutter clean
flutter pub get
flutter run -d emulator-5554
