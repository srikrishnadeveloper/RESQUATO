# Security Setup Guide

This document explains how to securely configure API keys and other sensitive information for the ResQAuto Flutter app.

## Required Environment Variables

### 1. Google Gemini API Key
- **Variable:** `GOOGLE_API_KEY`
- **Purpose:** Used for the chatbot functionality
- **How to get:** Visit [Google AI Studio](https://aistudio.google.com/) to create an API key

### 2. Supabase Configuration
- **Variables:** 
  - `SUPABASE_URL`: Your Supabase project URL
  - `SUPABASE_ANON_KEY`: Your Supabase anonymous key
- **Purpose:** Database connectivity and authentication
- **How to get:** Visit your [Supabase Dashboard](https://app.supabase.com/) project settings

## Setup Instructions

### Option 1: Using Flutter Command Line (Recommended for Development)

Run your Flutter app with environment variables:

```bash
flutter run --dart-define=GOOGLE_API_KEY=your_actual_api_key_here --dart-define=SUPABASE_URL=your_supabase_url --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Option 2: Using VS Code Launch Configuration

Create a `.vscode/launch.json` file in your project root:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Flutter",
            "request": "launch",
            "type": "dart",
            "toolArgs": [
                "--dart-define=GOOGLE_API_KEY=your_actual_api_key_here",
                "--dart-define=SUPABASE_URL=your_supabase_url",
                "--dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key"
            ]
        }
    ]
}
```

### Option 3: Using Environment Configuration File (Advanced)

For production builds, consider using a secure configuration management solution or CI/CD environment variables.

## Security Best Practices

1. **Never commit API keys to version control**
2. **Use different API keys for development and production**
3. **Regularly rotate your API keys**
4. **Restrict API key permissions to minimum required scope**
5. **Monitor API key usage for unusual activity**

## Files Modified for Security

The following files were updated to remove hardcoded secrets:

1. `lib/screens/chatbot_page.dart` - Removed Google API key
2. `lib/main.dart` - Removed Supabase URL and anonymous key

## Troubleshooting

If the app fails to start with configuration errors:

1. Verify all environment variables are set correctly
2. Check that API keys are valid and active
3. Ensure Supabase project is accessible
4. Review the console output for specific error messages

## Contact

If you need help obtaining API keys or setting up the environment, contact your development team or system administrator.
