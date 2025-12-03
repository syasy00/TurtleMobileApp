# TurtleMobileApp 🐢📱

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-74.7%25-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev)

> A Flutter-based mobile application for sea turtle conservation management. Features push notifications, data tracking, and real-time updates for marine conservationists and researchers.

## 📋 Overview

TurtleMobileApp is a comprehensive mobile solution designed to support sea turtle conservation efforts. The application enables conservationists to manage turtle data, receive important notifications, track nesting activities, and collaborate with other team members in real-time.

### Key Features

- 🔔 **Push Notifications**: Real-time alerts for critical turtle nesting events
- 📊 **Data Management**: Track and record turtle sightings and nest locations
- 🗺️ **Location Tracking**: GPS integration for accurate nest mapping
- 📸 **Photo Documentation**: Capture and store images of turtles and nests
- 👥 **Team Collaboration**: Share data with conservation team members
- 📱 **Offline Support**: Work in remote locations without internet
- 📈 **Statistics Dashboard**: View conservation metrics and trends
- 🌙 **Dark Mode**: Comfortable viewing during night patrols

## 🛠️ Technologies Used

### Mobile Framework
- **Framework**: Flutter 3.x
- **Language**: Dart (74.7%)
- **Architecture**: Clean Architecture / MVVM
- **State Management**: Provider / Bloc

### Additional Technologies
- **C++** (11.1%): Native platform code
- **CMake** (8.9%): Build system
- **Python** (1.4%): Backend scripts
- **Ruby** (1.3%): iOS tooling
- **Swift** (1.3%): iOS native code

### Features & Integrations
- **Firebase**: Cloud storage, authentication, push notifications
- **Google Maps**: Location services and mapping
- **Local Storage**: SQLite / Hive for offline data
- **Camera Integration**: Native camera access
- **Background Services**: Location tracking while app is closed

## 📦 Installation

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 2.17 or higher
- Android Studio / Xcode
- Git

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/syasy00/TurtleMobileApp.git
   cd TurtleMobileApp
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Download configuration files:
     - `google-services.json` for Android → `android/app/`
     - `GoogleService-Info.plist` for iOS → `ios/Runner/`

4. **Set up notification services**
   - Configure Firebase Cloud Messaging (FCM)
   - Add necessary permissions in AndroidManifest.xml and Info.plist

5. **Run the application**
   
   For Android:
   ```bash
   flutter run
   ```
   
   For iOS:
   ```bash
   flutter run -d ios
   ```

6. **Build for release**
   
   Android:
   ```bash
   flutter build apk --release
   ```
   
   iOS:
   ```bash
   flutter build ios --release
   ```

## 🎯 Usage

### For Conservationists

1. **Registration & Login**
   - Create account or sign in
   - Set up your conservation organization profile
   - Enable notification permissions

2. **Recording Turtle Sightings**
   - Tap the "Add Sighting" button
   - Enter turtle species and characteristics
   - Capture photos
   - Mark GPS location
   - Submit to database

3. **Nest Management**
   - Log new nest discoveries
   - Track incubation progress
   - Set hatching date estimates
   - Receive notifications for monitoring tasks

4. **Receiving Notifications**
   - Get alerts for:
     - New turtle sightings nearby
     - Nest monitoring reminders
     - Critical events (storms, predators)
     - Team member updates

5. **View Statistics**
   - Check total turtles recorded
   - View nest success rates
   - Analyze seasonal patterns
   - Export reports for research

## 🏗️ Project Structure

```
TurtleMobileApp/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   ├── screens/               # UI screens
│   │   ├── home_screen.dart
│   │   ├── sighting_form.dart
│   │   ├── nest_details.dart
│   │   └── stats_dashboard.dart
│   ├── services/              # Business logic
│   │   ├── firebase_service.dart
│   │   ├── notification_service.dart
│   │   ├── location_service.dart
│   │   └── database_service.dart
│   ├── widgets/               # Reusable widgets
│   ├── providers/             # State management
│   └── utils/                 # Helper functions
├── android/                   # Android platform code
├── ios/                       # iOS platform code
├── assets/                    # Images and resources
├── test/                      # Unit tests
└── pubspec.yaml              # Dependencies
```

## 📱 Screenshots

*Coming soon: Screenshots of the app in action*

## 🔔 Notification Features

The app includes a robust notification system:

- **Scheduled Notifications**: Reminders for nest checks
- **Location-based Alerts**: Notifications when near monitored areas
- **Team Notifications**: Updates from other conservationists
- **Emergency Alerts**: Critical situations requiring immediate attention
- **Daily Summaries**: End-of-day activity reports

## 🌍 Conservation Impact

This application aims to:
- Improve data collection accuracy
- Reduce response time to critical events
- Enhance collaboration among conservation teams
- Provide data-driven insights for research
- Support long-term turtle population monitoring
- Facilitate better resource allocation

## 🧪 Testing

Run tests using:
```bash
flutter test
```

For integration tests:
```bash
flutter test integration_test
```

## 🚀 Deployment

### Android (Google Play Store)
1. Build signed APK/AAB
2. Create app listing in Play Console
3. Upload build and submit for review

### iOS (App Store)
1. Build iOS archive in Xcode
2. Upload to App Store Connect
3. Complete app metadata
4. Submit for review

## 🤝 Contributing

This is an academic project focused on mobile development and wildlife conservation. Contributions and suggestions are welcome!

## 📄 License

This project is part of academic coursework at Universiti Utara Malaysia (UUM).

## 👨‍💻 Author

**Syasya** - [@syasy00](https://github.com/syasy00)

## 🙏 Acknowledgments

- Marine conservation organizations for project requirements
- Universiti Utara Malaysia (UUM)
- Flutter and Dart communities
- Firebase documentation and support
- Conservation biologists for domain expertise

## 📧 Contact

For questions about mobile conservation technology or collaboration opportunities, feel free to reach out!

## 🐛 Known Issues

- iOS background location tracking requires additional permissions
- Offline sync may take time with large datasets
- Camera quality depends on device hardware

## 🔮 Future Enhancements

- [ ] Machine learning for species identification
- [ ] Multi-language support
- [ ] Apple Watch companion app
- [ ] Advanced data analytics dashboard
- [ ] Integration with research databases
- [ ] AR features for nest visualization

---

⭐ If you support sea turtle conservation and mobile development, please star this project!
