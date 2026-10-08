# 📱 GOKULAM Traders App — Flutter Trading Application

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/shreyas026/GOKULAM_TRADERS_APP/actions/workflows/ci.yml/badge.svg)](https://github.com/shreyas026/GOKULAM_TRADERS_APP/actions)
[![Stars](https://img.shields.io/github/stars/shreyas026/GOKULAM_TRADERS_APP?style=social)](https://github.com/shreyas026/GOKULAM_TRADERS_APP/stargazers)
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4+-blue.svg)](https://dart.dev)
[![Django](https://img.shields.io/badge/Django-5.0+-green.svg)](https://djangoproject.com)
[![Railway](https://img.shields.io/badge/Deployed_on-Railway-purple.svg)](https://railway.app)

**A comprehensive trading management application built with Flutter (mobile) and Django (backend). Features real-time portfolio tracking, trade execution, analytics, and multi-user support.**

---

## 🎯 Features

- 📊 **Portfolio Dashboard** — Real-time holdings, P&L, allocation charts
- 💹 **Trade Execution** — Buy/sell orders with multiple order types
- 📈 **Advanced Analytics** — Performance metrics, risk analysis, reports
- 🔔 **Real-time Alerts** — Price alerts, news notifications, order updates
- 👥 **Multi-user Support** — Teams, roles, permissions
- 🔐 **Secure Authentication** — JWT, OAuth2, biometric login
- 🌙 **Dark/Light Theme** — System-aware theming
- 📱 **Offline Support** — Local caching, sync on reconnect

---

## 🏗️ Architecture

`
┌─────────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Flutter App       │────▶│   Django REST    │────▶│   PostgreSQL    │
│   (Mobile/Web)      │     │   API (Backend)  │     │   (Database)    │
└─────────────────────┘     └──────────────────┘     └─────────────────┘
         │                           │                         │
         ▼                           ▼                         ▼
┌─────────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Riverpod State     │     │  Celery + Redis  │     │  Railway/Cloud  │
│  Management         │     │  (Async Tasks)   │     │  (Deployment)   │
└─────────────────────┘     └──────────────────┘     └─────────────────┘
`

### Tech Stack
| Layer | Technology |
|-------|------------|
| **Mobile** | Flutter 3.22, Dart 3.4, Riverpod, GoRouter |
| **Backend** | Django 5.0, Django REST Framework, Celery |
| **Database** | PostgreSQL (via Railway) |
| **Auth** | JWT (SimpleJWT), OAuth2 (Google/GitHub) |
| **Real-time** | Django Channels, WebSockets |
| **Charts** | fl_chart, syncfusion_flutter_charts |
| **CI/CD** | GitHub Actions, Railway |
| **Testing** | flutter_test, pytest |

---

## 📁 Project Structure

`
GOKULAM_TRADERS_APP/
├── gokulam_app/              # Flutter Application
│   ├── lib/
│   │   ├── core/            # Constants, theme, utils
│   │   ├── data/            # Models, repositories, datasources
│   │   ├── domain/          # Entities, use cases, repositories
│   │   ├── presentation/    # Pages, widgets, providers
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── test/
├── gokulam_backend/          # Django Backend
│   ├── apps/
│   │   ├── accounts/        # User management
│   │   ├── portfolio/       # Holdings, positions
│   │   ├── trading/         # Orders, executions
│   │   ├── analytics/       # Reports, metrics
│   │   └── notifications/   # Alerts, real-time
│   ├── config/              # Settings, celery, channels
│   ├── manage.py
│   └── requirements.txt
├── railway.toml              # Railway deployment config
├── build_apk*.sh/bat/ps1     # Build scripts
├── .github/workflows/        # CI/CD
└── README.md
`

---

## ⚙️ Quick Start

### Prerequisites
- Flutter 3.22+
- Python 3.11+
- PostgreSQL (local or Railway)

### 1. Clone Repository
`ash
git clone https://github.com/shreyas026/GOKULAM_TRADERS_APP.git
cd GOKULAM_TRADERS_APP
`

### 2. Backend Setup
`ash
cd gokulam_backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Environment variables
cp .env.example .env
# Edit .env with your config

# Database
python manage.py migrate
python manage.py createsuperuser

# Run server
python manage.py runserver
`

### 3. Frontend Setup
`ash
cd gokulam_app
flutter pub get

# Run
flutter run -d chrome  # Web
flutter run -d android # Android
flutter run -d ios     # iOS (macOS only)
`

### 4. Build APK
`ash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
`

---

## 🚀 Deployment

### Backend (Railway)
`ash
# Connect repo to Railway
# Set environment variables
# Deploy automatically
`

### Frontend (Web)
`ash
flutter build web --release
# Deploy build/web to Vercel/Netlify/Firebase
`

### Mobile Stores
- **Android**: Upload pp-release.aab to Play Console
- **iOS**: Archive in Xcode → App Store Connect

---

## 🧪 Testing & Quality

`ash
# Backend
cd gokulam_backend
pytest --cov=apps --cov-report=html
ruff check .
mypy .

# Frontend
cd gokulam_app
flutter analyze
flutter test --coverage
`

---

## 📱 Screenshots
*(Add screenshots here)*

---

## 🤝 Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License
MIT License — see [LICENSE](LICENSE)

---

## 🙏 Acknowledgments
- [Flutter](https://flutter.dev) for the amazing framework
- [Django](https://djangoproject.com) for the robust backend
- [Railway](https://railway.app) for seamless deployment
- [Riverpod](https://riverpod.dev) for state management
