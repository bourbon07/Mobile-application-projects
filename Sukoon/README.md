# ⚡ Sukoon - EV Charging Station Management

**Sukoon** is a premium, high-end mobile application designed for **EV Charging Station** management and guidance. Built with Flutter, it provides a luxury user experience with a marble-themed UI and sophisticated animations, specifically tailored for the Middle Eastern market with full Arabic support.

---

---


## ✨ Features

- **🌟 Elite UI Design**: Marble-textured backgrounds with gold (`kGold`) accents for a premium feel.
- **🔋 Real-time Station Monitoring**: Check bay availability in real-time via backend integration.
- **🛰️ Guidance System**: Dynamic guidance to assigned charging bays (Bays 1-10).
- **⏳ Session Management**: Start, monitor, and complete charging sessions with ease.
- **🕌 Amenities Integration**: A smart "Amenities Loop" that suggests nearby services (Masjid, Café, Restroom, etc.) while you wait.
- **🌍 Bilingual Interface**: Professional localization for **Arabic** and **English**.
- **🌒 Dynamic Theme**: Seamless switching between Light and Dark modes.
- **📢 Smart Notifications**: In-app notifications for session status and bay allocation.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Networking**: [HTTP](https://pub.dev/packages/http) (Node.js API Integration)
- **UI/UX**:
  - `google_fonts` (Cairo, Montserrat)
  - Custom Canvas Painting for background patterns.
  - Smooth page transitions and animations.
- **Architecture**: Modular State Machine for navigation and charging sessions.

---

## 📸 Screenshots

| Splash Screen | Home / Selection |
|:---:|:---:|
| ![Splash Page](ScreenShots/Splash%20page.png) | ![Home Page](ScreenShots/Home%20page.png) |

| Charging Guidance | Session Completion |
|:---:|:---:|
| ![Charge Page](ScreenShots/Charge%20page.jpg) | ![Finishing Page](ScreenShots/Finishing%20page.jpg) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.10.7)
- Backend API running on `http://192.168.100.2:3000` (configurable in `main.dart`)

### Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/bourbon07/Mobile-application-projects.git
   ```
2. **Navigate to the project directory**:
   ```bash
   cd Sukoon
   ```
3. **Install dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run the application**:
   ```bash
   flutter run
   ```

---

## 📁 Repository Structure
```text
lib/
└── main.dart       # Unified application logic and UI components
assets/
├── logo.jpeg       # Application branding
└── localization.json # Multilingual data
```

---

## 👨‍💻 Developed By

**Fawaz Allan**  
**Flutter & Mobile App Developer**  
*Expertise in Flutter, Dart, Riverpod, and API Integration.*

📧 [Gmail](mailto:fwzallan@gmail.com) | 💼 [LinkedIn](https://www.linkedin.com/in/fawaz-allan-188717247/)
