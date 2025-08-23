# Swivo iOS App

## Overview

Swivo is an iOS app that helps small groups quickly reach consensus by swiping through category-specific options (like restaurants, movies, etc.). Users join a "swiping session," like or dislike each option, and the first option liked by a predetermined number of participants ends the session as the match.

## Requirements

- Xcode 15.0 or later
- iOS 17.0+ target
- Swift 5.9+
- SwiftUI
- [Supabase Swift SDK](https://github.com/supabase-community/supabase-swift)

## Project Structure

The app follows a feature-based organization:

```
Swivo/
├── Features/         # Feature-oriented SwiftUI modules
│   ├── Landing/      # Open / Closed sessions list
│   ├── StartSession/ # Session creation flow
│   ├── JoinSession/  # Session joining flow
│   ├── SwipeDeck/    # Card swiping interface
│   ├── Results/      # Match results display
│   └── Settings/     # User profile & settings
├── Models/           # Shared data models
├── Networking/       # Supabase client & API calls
├── Services/         # Push notifications, persistence
├── Extensions/       # Swift helpers & modifiers
└── Resources/        # Assets & localization
```

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/[your-username]/Swivo.git
   cd Swivo/app
   ```

2. **Install Dependencies**
   - Open the Xcode project
   - Install Swift Package dependencies

3. **Configure Environment**
   - Create a `Config.xcconfig` file based on the template
   - Add your Supabase URL and API Key

4. **Run the Project**
   - Select a simulator or connected device
   - Build and run the project

## Key Features

- **Anonymous Authentication**: Users automatically get an anonymous account
- **Session Management**: Create or join swiping sessions with unique invite codes
- **Swipe Interface**: Tinder-style card swiping for options
- **Real-time Matching**: Get instant notifications when a match occurs
- **Offline Support**: Queue actions locally when offline

## Backend

The app uses [Supabase](https://supabase.com/) for backend services. See the `/backend/supabase` directory for backend implementation details.
