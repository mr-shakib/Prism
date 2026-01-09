# Prism - Social Media App

<div align="center">
  <img src="assets/images/logo.png" alt="Prism Logo" width="120" height="120" />
  
  <p><strong>A modern, feature-rich social media application built with Flutter</strong></p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue.svg)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Powered-orange.svg)](https://firebase.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

---

## 📱 About Prism

Prism is a comprehensive social media platform that enables users to connect, share moments, and engage with a vibrant community. Built with Flutter and Firebase, it offers a seamless cross-platform experience with real-time updates and modern UI/UX.

### ✨ Key Features

- **User Authentication**
  - Email/Password registration and login
  - Biometric authentication (fingerprint/face ID)
  - Secure session management
  
- **Social Interaction**
  - Create and share posts
  - Like and comment on posts
  - Follow/unfollow users
  - Real-time updates
  
- **User Profiles**
  - Customizable profile pages
  - Bio and profile picture
  - Follower/following counts
  - User activity feed
  
- **Privacy & Security**
  - Block/unblock users
  - Content reporting
  - Privacy settings
  - Secure data storage

- **Modern UI/UX**
  - Clean, intuitive interface
  - Dark/Light theme support
  - Smooth animations
  - Responsive design

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.24.0 or higher
  ```bash
  flutter --version
  ```
- **Dart SDK**: Version 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control
- **Firebase Account** for backend services

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/Prism.git
   cd Prism
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   
   a. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   
   b. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
   
   c. Configure Firebase for your project:
   ```bash
   flutterfire configure
   ```
   
   d. Enable Authentication and Firestore in Firebase Console

4. **Configure environment variables**
   
   Copy the example environment file:
   ```bash
   cp .env.example .env.dev
   ```
   
   Update `.env.dev` with your configuration

5. **Run the app**
   ```bash
   # For development
   flutter run --dart-define=ENVIRONMENT=dev
   
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   ```

## 📂 Project Structure

```
lib/
├── core/                      # Core functionality
│   ├── config/               # App configuration
│   ├── constants/            # Constants and enums
│   ├── errors/              # Error handling
│   ├── network/             # Network utilities
│   └── utils/               # Helper utilities
│
├── features/                 # Feature modules
│   ├── authentication/      # Auth feature
│   │   ├── data/           # Data layer
│   │   ├── domain/         # Business logic
│   │   └── presentation/   # UI layer
│   ├── posts/              # Posts feature
│   ├── profile/            # Profile feature
│   └── social/             # Social features
│
├── shared/                   # Shared resources
│   ├── widgets/            # Reusable widgets
│   ├── theme/              # Theme configuration
│   └── services/           # Shared services
│
├── routes/                   # Navigation
└── main.dart                # Entry point
```

See [PROFESSIONAL_UPGRADE_GUIDE.md](PROFESSIONAL_UPGRADE_GUIDE.md) for detailed architecture information.

## 🏗️ Architecture

Prism follows **Clean Architecture** principles with the **BLoC** pattern for state management:

- **Presentation Layer**: UI components and state management
- **Domain Layer**: Business logic and use cases
- **Data Layer**: Data sources and repositories

This architecture ensures:
- ✅ Separation of concerns
- ✅ Testability
- ✅ Maintainability
- ✅ Scalability

## 🔒 Security

Security is our top priority. We implement:

- Secure storage for sensitive data
- Firebase App Check for API protection
- Firestore security rules
- Input validation and sanitization
- Rate limiting

**⚠️ Important**: Never commit sensitive files like API keys or Firebase configuration. See [SECURITY_CHECKLIST.md](SECURITY_CHECKLIST.md) for details.

## 🧪 Testing

### Run Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

### Test Structure
- **Unit Tests**: Test business logic
- **Widget Tests**: Test UI components
- **Integration Tests**: Test user flows

Target coverage: **80%+**

## 📦 Build & Release

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS

```bash
# Build IPA
flutter build ipa --release
```

### Configuration Files

- Android: `android/app/build.gradle`
- iOS: `ios/Runner/Info.plist`

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code of conduct
- Development workflow
- Coding standards
- Pull request process

## 📄 Documentation

- [Professional Upgrade Guide](PROFESSIONAL_UPGRADE_GUIDE.md) - Comprehensive guide to make the app production-ready
- [Security Checklist](SECURITY_CHECKLIST.md) - Security best practices and checklist
- [Contributing Guide](CONTRIBUTING.md) - How to contribute to the project
- [API Documentation](docs/API.md) - API reference (if applicable)

## 🛠️ Tech Stack

- **Framework**: Flutter 3.24+
- **Language**: Dart 3.0+
- **Backend**: Firebase
  - Authentication
  - Firestore Database
  - Cloud Storage
  - Cloud Functions
- **State Management**: BLoC
- **Dependency Injection**: get_it
- **Navigation**: go_router

### Key Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  get_it: ^7.6.0
  # See pubspec.yaml for full list
```

## 📱 Screenshots

| Home Feed | Profile | Messages |
|-----------|---------|----------|
| ![Home](screenshots/home.png) | ![Profile](screenshots/profile.png) | ![Messages](screenshots/messages.png) |

## 📈 Roadmap

### Version 1.0 (Current)
- [x] User authentication
- [x] Post creation and viewing
- [x] User profiles
- [x] Follow system
- [x] Comments

### Version 1.1 (In Progress)
- [ ] Real-time messaging
- [ ] Push notifications
- [ ] Story feature
- [ ] Enhanced search

### Version 2.0 (Planned)
- [ ] Voice/Video calls
- [ ] Live streaming
- [ ] Group chats
- [ ] Advanced analytics

See [PROFESSIONAL_UPGRADE_GUIDE.md](PROFESSIONAL_UPGRADE_GUIDE.md) for detailed feature roadmap.

## 🐛 Known Issues

- Firebase reCAPTCHA may require additional setup for some environments
- iOS build requires proper provisioning profiles

See [Issues](https://github.com/yourusername/Prism/issues) for the full list.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors & Contributors

- **Your Name** - *Initial work* - [@yourusername](https://github.com/yourusername)

See also the list of [contributors](https://github.com/yourusername/Prism/contributors) who participated in this project.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for backend services
- All contributors and testers

## 📞 Contact & Support

- **Email**: support@prismapp.com
- **Website**: https://prismapp.com
- **Discord**: [Join our community](https://discord.gg/yourserver)
- **Twitter**: [@PrismApp](https://twitter.com/prismapp)

## 📊 Project Status

🟢 **Active Development** - We're actively working on new features and improvements!

---

<div align="center">
  <p>Made with ❤️ using Flutter</p>
  <p>© 2026 Prism. All rights reserved.</p>
</div> 
