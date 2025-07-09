# 🎉 MemeVerse — The Ultimate Tech Meme Experience

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Reddit API](https://img.shields.io/badge/Reddit_API-FF4500?style=for-the-badge&logo=reddit&logoColor=white)
![Material Design](https://img.shields.io/badge/Material_Design_3-757575?style=for-the-badge&logo=material-design&logoColor=white)
![License](https://img.shields.io/github/license/shourya13x/MemeVerse?style=for-the-badge)
![Stars](https://img.shields.io/github/stars/shourya13x/MemeVerse?style=for-the-badge)

**The most advanced meme app for tech enthusiasts!**  
_Experience stunning Material 3 design, smart category navigation, infinite scrolling, and seamless cross-platform performance._

[🚀 Live Demo](https://shourya13x.github.io/MemeVerse/) • [📦 Download APK](https://github.com/shourya13x/MemeVerse/releases/latest) • [🐛 Report Issues](https://github.com/shourya13x/MemeVerse/issues)

</div>

---

## ✨ What's New in v2.0

### 🎯 **Smart Category System**
- **5 Curated Categories**: Home, Trending, Marvel, DC, Anime
- **25+ Popular Subreddits** with real-time metrics
- **Category Statistics Dashboard** with engagement insights
- **Smart Content Deduplication** across categories

### 🎨 **Enhanced UI/UX**
- **Material 3 Design** with Arc browser-inspired theming
- **Dynamic Color Schemes** (Default, Blue, Green, Orange)
- **Smooth Category Navigation** with intuitive drawer
- **Advanced Loading States** and error recovery

### 🔧 **Technical Improvements**
- **Mouse Tracker Exception Fix** for seamless web experience
- **Enhanced Error Handling** with graceful degradation
- **Performance Optimizations** with efficient caching
- **Cross-Platform Compatibility** (Web, Android, iOS)

---

## 🌟 Key Features

### 🎭 **Multi-Category Experience**
- **Home**: Mixed content from all categories
- **Trending**: Viral and hot memes
- **Marvel**: MCU and superhero content
- **DC**: DC Comics and movies
- **Anime**: Anime and manga memes

### 🔐 **Authentication & Security**
- **Google Sign-In** via Firebase Auth
- **Secure User Sessions** with automatic token refresh
- **Privacy-First Design** with minimal data collection

### ⭐ **Personalization**
- **Favorites System** with persistent storage
- **Theme Customization** (Light/Dark + Color themes)
- **Category Preferences** with smart recommendations
- **Personal Statistics** and engagement tracking

### 🚀 **Performance & Reliability**
- **Infinite Scrolling** with smart pagination
- **Content Caching** for offline viewing
- **Error Recovery** with retry mechanisms
- **Memory Optimization** for smooth performance

### 📱 **Cross-Platform Excellence**
- **Web**: Optimized for desktop and mobile browsers
- **Android**: Native performance with Material Design
- **iOS**: Smooth animations and native feel
- **Responsive Design** that adapts to any screen

---

## 📱 Screenshots

<div align="center">

| iOS Experience | Android Experience | Web Experience |
|:---:|:-------:|:---:|
| ![iOS Screenshot](screenshots/ios.png) | ![Android Screenshot](screenshots/android.jpg) | ![Web Screenshot](screenshots/ios2.png) |

*Beautiful Material 3 design across all platforms*

</div>

---

## 🚀 Quick Start

### Prerequisites
- **Flutter 3.7+** and **Dart SDK**
- **Firebase Project** (for authentication)
- **Reddit API Access** (for content)

### Installation

```bash
# Clone the repository
git clone https://github.com/shourya13x/MemeVerse.git
cd MemeVerse

# Install dependencies
flutter pub get

# Configure Firebase (optional for development)
# Add your firebase_options.dart file

# Run the app
flutter run
```

### Build Commands

```bash
# Web Build
flutter build web

# Android APK
flutter build apk

# iOS (requires macOS)
flutter build ios
```

---

## 🏗️ Architecture & Tech Stack

### **Frontend Framework**
- **Flutter 3.7+** with **Dart**
- **Material Design 3** for modern UI
- **Responsive Design** for all screen sizes

### **Backend Services**
- **Firebase Authentication** for secure login
- **Reddit API** (OAuth2) for content fetching
- **Shared Preferences** for local storage

### **Key Dependencies**
```yaml
firebase_core: ^3.14.0      # Firebase integration
firebase_auth: ^5.6.0       # Authentication
cached_network_image: ^3.4.1 # Image caching
palette_generator: ^0.3.3+7  # Dynamic theming
share_plus: ^7.2.1          # Social sharing
http: ^1.4.0                # API requests
```

### **Project Structure**
```
lib/
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Business logic
├── widgets/         # Reusable components
└── utils/           # Utilities and constants
```

---

## 🎯 Category System

### **Home Category** 🏠
- **Subreddits**: memes, funny, dankmemes, wholesomememes
- **Content**: Mixed memes from all categories
- **Focus**: General entertainment and humor

### **Trending Category** 🔥
- **Subreddits**: dankmemes, pewdiepiesubmissions, okbuddyretard
- **Content**: Viral and trending memes
- **Focus**: Hot and popular content

### **Marvel Category** 🦸‍♂️
- **Subreddits**: marvelmemes, thanosdidnothingwrong, raimimemes
- **Content**: MCU and superhero memes
- **Focus**: Marvel Cinematic Universe

### **DC Category** 🦇
- **Subreddits**: dcmemes, batman, superman, wonderwoman
- **Content**: DC Comics and movies
- **Focus**: DC Universe content

### **Anime Category** 🎌
- **Subreddits**: animemes, goodanimemes, manga, naruto
- **Content**: Anime and manga memes
- **Focus**: Japanese animation and comics

---

## 🔧 Recent Fixes & Improvements

### **Mouse Tracker Exception Fix** ✅
- Resolved Flutter web pointer event conflicts
- Enhanced error handling for cross-platform compatibility
- Improved gesture detection and user interaction

### **Performance Optimizations** ⚡
- Efficient content caching and deduplication
- Optimized image loading with lazy loading
- Memory management improvements

### **UI/UX Enhancements** 🎨
- Material 3 design implementation
- Dynamic theming with multiple color schemes
- Smooth animations and transitions

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### **Development Setup**
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test thoroughly
4. Commit your changes: `git commit -m 'Add amazing feature'`
5. Push to the branch: `git push origin feature/amazing-feature`
6. Open a Pull Request

### **Guidelines**
- Follow Flutter best practices and conventions
- Add tests for new features
- Update documentation as needed
- Ensure cross-platform compatibility

### **Areas for Contribution**
- 🐛 Bug fixes and improvements
- 🎨 UI/UX enhancements
- 📱 New platform support
- 🔧 Performance optimizations
- 📚 Documentation improvements

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Reddit API** for providing amazing content
- **Firebase** for secure authentication
- **Flutter Team** for the incredible framework
- **Material Design Team** for beautiful design guidelines
- **Open Source Community** for inspiration and support

---

<div align="center">

**Made with ❤️ by [Shourya Gupta](https://github.com/shourya13x)**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/shouryagupta13/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/shourya13x)
[![Twitter](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/shourya13x)

**⭐ Star this repository if you found it helpful!**

</div>
