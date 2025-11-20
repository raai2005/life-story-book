# Life Story Book

A Flutter application that helps users create, enhance, and preserve their life stories using AI-powered text enhancement.

## Features

### ✨ Core Functionality

- **AI-Powered Story Enhancement** - Transform your raw memories into engaging, well-written narratives using OpenRouter AI
- **Multi-Modal Input** - Write, attach images, or use voice input (voice coming soon)
- **Chapter Management** - Create, edit, and organize your life story in chapters
- **Version History** - All edits are tracked and preserved in Firebase
- **User Authentication** - Secure Firebase Authentication with email/password
- **Session Management** - 30-day session persistence with automatic login

### 🎨 User Interface

- **Splash Screen** - Animated logo with StaggeredDotsWave loader
- **Dark Theme** - Modern UI with custom color scheme (#1A1A2E background, #6C63FF purple accent)
- **Dashboard** - View all your chapters with word count and statistics
- **Profile Screen** - User settings and logout functionality

### 🔐 Authentication & Security

- Firebase Authentication (email/password)
- Session persistence with SharedPreferences
- User-specific chapter storage
- Environment variable configuration for API keys

## Tech Stack

### Frontend

- **Flutter** 3.10.0+
- **Dart** SDK 3.10.0+
- Material Design with custom dark theme

### Backend & Services

- **Firebase Core** 3.0.0 - App initialization
- **Firebase Auth** 5.0.0 - User authentication
- **Cloud Firestore** 5.0.0 - Chapter storage and version history
- **OpenRouter API** - AI text enhancement (LLaMA 3.1 8B Instruct)

### Packages

- `flutter_dotenv: ^5.1.0` - Environment variable management
- `http: ^1.1.0` - API requests
- `shared_preferences: ^2.2.2` - Local session storage
- `loading_animation_widget: ^1.2.1` - Splash screen animations

## Project Structure

```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── screens/
│   ├── splash_screen.dart    # Initial loading screen
│   ├── login_screen.dart     # Email/password authentication
│   ├── signup_screen.dart    # User registration
│   ├── home_screen.dart      # Welcome screen for new users
│   ├── dashboard_screen.dart # Chapter list and management
│   ├── new_chapter_screen.dart # Create/edit chapters with AI
│   └── profile_screen.dart   # User settings and logout
├── services/
│   └── ai_service.dart       # OpenRouter AI integration
└── utils/
    └── session_manager.dart  # Session persistence logic
```

## Setup Instructions

### Prerequisites

- Flutter SDK 3.10.0 or higher
- Firebase project configured
- OpenRouter API key

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/raai2005/life-story-book.git
cd lifestorybook
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Firebase Setup**

- Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
- Enable Authentication (Email/Password)
- Enable Cloud Firestore
- Run FlutterFire CLI to configure:

```bash
flutterfire configure
```

4. **Environment Variables**

- Copy `.env.example` to `.env`
- Add your OpenRouter API key:

```env
OPENROUTER_API_KEY=your_api_key_here
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1/chat/completions
OPENROUTER_MODEL=meta-llama/llama-3.1-8b-instruct
```

5. **Run the app**

```bash
flutter run
```

## Firebase Data Structure

### Chapters Collection

```javascript
chapters/
  {chapterId}/
    - userId: string
    - title: string (AI-suggested)
    - rawText: string (original user input)
    - enhancedText: string (AI-enhanced version)
    - attachments: array (image paths/URLs)
    - createdAt: timestamp
    - updatedAt: timestamp
    - wordCount: number
    - editHistory/ (subcollection)
        {editId}/
          - rawText: string
          - enhancedText: string
          - attachments: array
          - editedAt: timestamp
```

## User Flow

### New User Journey

1. Splash Screen (3 seconds)
2. Login Screen
3. Sign Up (if new user)
4. Home Screen with input box
5. Write story → AI Enhance → Save to Dashboard

### Returning User Journey

1. Splash Screen
2. Auto-login (if session valid < 30 days) OR Login Screen
3. Dashboard with all chapters
4. Tap chapter to edit or create new

## AI Enhancement

The app uses OpenRouter API to enhance user stories:

- **Model**: LLaMA 3.1 8B Instruct (configurable)
- **Process**: Preserves authentic voice while improving engagement
- **Features**: Better narrative flow, vivid descriptions, emotional resonance
- **Privacy**: Raw text always saved alongside enhanced version

## Validation Rules

### Authentication

- **Email**: Valid email format required
- **Password**: Minimum 5 characters, must include 1 number, 1 letter, 1 symbol
- **Username**: Minimum 8 characters

## Known Limitations & TODOs

- [ ] Image picker integration (placeholder currently)
- [ ] Speech-to-text for voice input
- [ ] Load chapters from Firestore on dashboard
- [ ] Search functionality
- [ ] AI-generated chapter titles (currently uses placeholder)
- [ ] Export stories as PDF/Book
- [ ] Share chapters with family/friends

## Development

### Running Tests

```bash
flutter test
```

### Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue on GitHub.

---

**Made with ❤️ using Flutter and AI**
