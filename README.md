# RESQUATO 🚗⛽

A comprehensive Flutter mobile application that provides on-demand vehicle services including fuel delivery, roadside assistance, and vehicle service booking. RESQUATO connects users with service providers to solve vehicle-related problems efficiently.

## 🌟 Features

### Core Services
- **🛞 Fuel Delivery**: Order fuel to be delivered directly to your location
- **🔧 Road Service**: Request roadside assistance for vehicle breakdowns
- **📅 Book Service**: Schedule vehicle maintenance and repair services
- **🤖 AI Chatbot**: Get instant help and guidance for vehicle-related issues
- **📊 Status Tracking**: Real-time tracking of all your service requests

### Key Capabilities
- **📍 GPS Location Integration**: Automatic location detection and address fetching
- **👤 User Authentication**: Secure login and registration system
- **💾 Real-time Data**: Live status updates using Supabase real-time subscriptions
- **📱 Cross-platform**: Built with Flutter for iOS and Android
- **🔒 Secure Backend**: Powered by Supabase for reliable data management

## 🏗️ Architecture

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: StatefulWidget with setState
- **Navigation**: Bottom Navigation Bar with multiple pages
- **UI/UX**: Material Design with custom styling

### Backend & Services
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Custom username/password system
- **Real-time Updates**: Supabase real-time subscriptions
- **AI Integration**: Google Gemini API for chatbot functionality
- **Location Services**: Geolocator and Geocoding packages

### Data Tables
- `user_credentials`: User login information
- `fuel_requests`: Fuel delivery orders
- `road_service_requests`: Roadside assistance requests
- `book_service_requests`: Vehicle service bookings
- `status_updates`: Real-time status tracking

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.7.2)
- Dart SDK
- Android Studio / Xcode for device testing
- Supabase account
- Google API key for Gemini AI

### Environment Setup
1. **Supabase Configuration**:
   ```bash
   export SUPABASE_URL="your_supabase_url"
   export SUPABASE_ANON_KEY="your_supabase_anon_key"
   ```

2. **Google AI API**:
   ```bash
   export GOOGLE_API_KEY="your_google_api_key"
   ```

### Installation
```bash
# Clone the repository
git clone <repository_url>
cd my_flutter_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Database Setup
Create the following tables in your Supabase database:

```sql
-- User credentials table
CREATE TABLE user_credentials (
  id SERIAL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Fuel requests table
CREATE TABLE fuel_requests (
  id SERIAL PRIMARY KEY,
  username TEXT NOT NULL,
  location_text TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  fuel_type TEXT,
  fuel_quantity DOUBLE PRECISION,
  payment_amount DOUBLE PRECISION,
  custom_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Road service requests table
CREATE TABLE road_service_requests (
  id SERIAL PRIMARY KEY,
  username TEXT NOT NULL,
  location_text TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  vehicle_type TEXT,
  problem_category TEXT,
  custom_message TEXT,
  phone_number TEXT,
  alternate_number TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Book service requests table
CREATE TABLE book_service_requests (
  id SERIAL PRIMARY KEY,
  username TEXT NOT NULL,
  location_text TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  vehicle_type TEXT,
  preferred_date TIMESTAMP,
  preferred_time_slot TEXT,
  custom_message TEXT,
  phone_number TEXT,
  alternate_number TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Status updates table
CREATE TABLE status_updates (
  id SERIAL PRIMARY KEY,
  username TEXT NOT NULL,
  service_type TEXT,
  status TEXT,
  message TEXT,
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## 📱 App Structure

```
lib/
├── main.dart                    # App entry point and navigation
└── screens/
    ├── login_page.dart         # User authentication
    ├── registration_page.dart  # New user registration
    ├── fuel_delivery_page.dart # Fuel ordering interface
    ├── road_service_page.dart  # Roadside assistance
    ├── book_service_page.dart  # Service scheduling
    ├── chatbot_page.dart       # AI-powered support
    └── status_page.dart        # Request tracking
```

## 🔧 Key Dependencies

```yaml
dependencies:
  flutter: sdk
  supabase_flutter: ^2.5.3    # Backend and real-time data
  geolocator: ^14.0.0         # GPS location services
  geocoding: ^3.0.0           # Address resolution
  permission_handler: ^12.0.0  # Device permissions
  http: ^1.4.0                # API communication
  intl: ^0.18.0               # Date formatting
```

## 🛡️ Security Considerations

⚠️ **Important Security Notes**:
- Passwords are currently stored in plain text (development only)
- Environment variables should be used for API keys
- Implement proper authentication for production
- Add input validation and sanitization
- Use HTTPS for all communications

## 🚧 Development Status

This is a development version of RESQUATO with the following limitations:
- Plain text password storage (needs encryption)
- Missing production-grade error handling
- Limited user input validation
- Basic UI design (can be enhanced)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request



## 📞 Support

For technical support or feature requests, use the in-app chatbot or contact the development team through the EMAIL: srikrishnawebdeveloper@gmail.com 
