# Moku: Goal Tracker

Moku is a native iOS app for setting meaningful goals, building habits, and keeping track of progress over time.

[Download Moku on the App Store](https://apps.apple.com/us/app/moku-goal-tracker/id6767920722)

## Features

- Create one-time or recurring goals
- Track simple completion or measurable numeric progress
- Build streaks with daily, weekly, monthly, or yearly goals
- Set target dates and local notification reminders
- Organize goals with reusable tags
- Search, sort, and filter goals
- Review and manage progress history
- Keep goal data in sync through private iCloud storage

Moku does not require an account and does not include third-party analytics, advertising, or tracking.

## Built With

- Swift and SwiftUI
- SwiftData with CloudKit sync
- UserNotifications for goal reminders
- Swift Testing

The project targets iOS 26.4 or later.

## Running the Project

1. Clone the repository.
2. Open `GoalTracker.xcodeproj` in Xcode.
3. Select the `GoalTracker` scheme and an iOS simulator or device.
4. Build and run the app.

The app uses the iCloud container configured for the production project. Update the signing team, bundle identifier, and iCloud capability if you want to run it with your own developer account.

## Support and Privacy

- [Support](docs/support.md)
- [Privacy Policy](docs/privacy.md)
