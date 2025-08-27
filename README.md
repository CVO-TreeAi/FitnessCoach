# FitnessCoach - iOS App

A comprehensive iOS fitness coaching application built with SwiftUI, Core Data, CloudKit, and HealthKit integration. This app transforms professional Excel-based fitness coaching templates into a modern, full-featured mobile platform for coaches and clients.

## 🏗️ Architecture Overview

**Technology Stack:**
- **UI Framework:** SwiftUI with UIKit for complex components
- **Architecture:** MVVM + Coordinator Pattern
- **Data Layer:** Core Data + CloudKit for real-time sync
- **Authentication:** Sign in with Apple + Custom Auth
- **Health Integration:** HealthKit + ResearchKit
- **Cloud Storage:** CloudKit for data sync between coach/client
- **Platform Support:** iOS 16+, watchOS 9+, iPadOS 16+

## 🎯 Core Features

### ✅ Completed Features

#### Authentication & User Management
- Sign in with Apple integration
- Role-based access control (Coach/Client)
- CloudKit user sync and profile management
- Secure biometric authentication for sensitive data

#### Progress Tracking System
- **Weight Tracking:** Historical weight data with interactive charts
- **Body Measurements:** Comprehensive body measurement logging
- **Progress Photos:** Visual transformation tracking with tips
- **Health Metrics:** Integration with Apple Health for heart rate, blood pressure
- **Charts & Analytics:** Beautiful Swift Charts integration with trend analysis

#### Core Data Model
- **Coach/Client Relationships:** Many-to-one relationships with proper data modeling
- **Progress Entries:** Comprehensive tracking of weight, measurements, vitals
- **Program Management:** Training programs with week-by-week structure
- **Nutrition System:** Complete macro tracking with meal planning
- **Supplement Tracking:** Medication/supplement logging (replacing PED tracker from Excel)

#### UI & Design System
- **Themed Components:** Consistent design system with light/dark mode
- **Fitness Theme:** Athletic color palette with rounded fonts
- **Responsive Design:** Adaptive layouts for iPhone/iPad
- **Accessibility:** VoiceOver support and Dynamic Type

#### Data Integration
- **Excel Template Conversion:** Complete migration from Master Template Excel system
- **Food Database:** 50+ foods from Excel "Food Cheat Sheet" with macro data
- **Program Templates:** Structured workout templates based on Excel training weeks
- **Sample Data Seeding:** Automatic population of realistic test data

### 🚧 In Development

#### Workout System
- Exercise library with video tutorials
- Workout tracking with rest timers
- Set/rep logging with RPE (Rate of Perceived Exertion)
- Progress photos for exercises

#### Nutrition Features
- Barcode scanning for food entries
- Meal planning with drag-and-drop
- Macro calculator with goal adjustments
- Smart grocery list generation

#### Coach-Client Features
- In-app messaging between coach and client
- Program assignment and customization
- Progress report generation
- Client dashboard for coaches

### 🔮 Planned Features

#### Apple Ecosystem Integration
- **Apple Watch:** Workout tracking, heart rate monitoring, quick logging
- **Handoff:** Seamless continuation between iPhone/iPad/Mac
- **Shortcuts:** Siri shortcuts for quick data entry
- **Widgets:** Home Screen widgets for progress tracking

#### Advanced Features
- AI-powered form analysis using Core ML and camera
- Smart macro adjustments based on progress data
- Advanced analytics and progress predictions
- Custom branding for coaches (white-label options)

## 📱 App Flow

### Client Experience
```
Login/Onboarding → Progress Dashboard → Daily Tasks
├── Today's Workout
├── Meal Plan & Logging
├── Progress Check-in
└── Coach Communication
```

### Coach Experience
```
Coach Dashboard → Client Management → Program Design
├── Client Overview & Progress
├── Workout Programming
├── Nutrition Planning
└── Business Analytics
```

## 🛠️ Development Setup

### Prerequisites
- **Xcode 15.0+**
- **iOS 16.0+ Deployment Target**
- **Apple Developer Account** (for CloudKit, HealthKit, Sign in with Apple)
- **Swift 5.9+**

### Project Setup

1. **Clone and Open Project:**
   ```bash
   cd /Users/ain/FitnessCoach
   open Package.swift
   ```

2. **Configure CloudKit:**
   - Set up CloudKit container in Apple Developer Console
   - Configure CloudKit schema for Core Data entities
   - Update CloudKit container identifier in code

3. **Configure Capabilities:**
   - Enable CloudKit capability
   - Enable HealthKit capability
   - Enable Sign in with Apple
   - Add background modes for workout tracking

4. **Set Up Data Seeding:**
   ```swift
   // In FitnessCoachApp.swift onAppear
   DataSeeder.shared.seedInitialData()
   ```

### Key Configuration Files

#### Info.plist Permissions
- **HealthKit:** NSHealthShareUsageDescription, NSHealthUpdateUsageDescription
- **Camera:** NSCameraUsageDescription (for progress photos)
- **Location:** NSLocationWhenInUseUsageDescription (for gym check-ins)
- **Motion:** NSMotionUsageDescription (for Apple Watch integration)

#### Core Data Configuration
- **CloudKit Integration:** NSPersistentCloudKitContainer
- **Background Sync:** Remote change notifications enabled
- **Conflict Resolution:** NSMergeByPropertyObjectTrumpMergePolicy

## 📊 Excel Template Migration

The app successfully migrates all major components from the Excel Master Template:

| Excel Sheet | iOS Feature | Implementation |
|-------------|-------------|----------------|
| **Terms & Conditions** | Legal Onboarding | SwiftUI legal acceptance flow |
| **Questionnaire** | Client Intake | Multi-step form with validation |
| **Journal** | Progress Notes | Rich text editor with photos |
| **STATS** | Progress Dashboard | Interactive charts with HealthKit sync |
| **Training Week 1-14** | Workout Programs | Dynamic workout system with templates |
| **PED Tracker** | Supplement Manager | Renamed to Supplement tracking for compliance |
| **Food Cheat Sheet** | Food Database | Searchable database with 50+ foods |
| **Macro Schedule** | Nutrition Planner | Drag-drop meal builder with macro tracking |
| **Meal Plan** | Daily Nutrition | Meal logging with smart suggestions |
| **Grocery List** | Shopping Lists | Auto-generated from meal plans |

## 🎨 Design System

### Color Palette (Fitness Theme)
- **Primary:** Energy Orange (`#FF4500`)
- **Secondary:** Athletic Blue (`#0099CC`)
- **Success:** Bright Green (`#33CC33`)
- **Background:** System backgrounds with dark mode support

### Typography
- **Design:** SF Rounded for athletic feel
- **Scale:** Large Title → Caption with proper weight hierarchy
- **Accessibility:** Dynamic Type support throughout

### Components
- **ThemedButton:** 5 styles (Primary, Secondary, Outline, Destructive, Ghost)
- **ThemedCard:** Consistent cards with shadows and corner radius
- **ThemedStatCard:** Progress metrics with trend indicators

## 🔐 Security & Privacy

### Data Protection
- **End-to-End Encryption:** CloudKit handles encryption at rest
- **Biometric Authentication:** Face ID/Touch ID for sensitive health data
- **HIPAA Considerations:** Designed with healthcare privacy in mind
- **Granular Permissions:** Users control what health data is shared

### Privacy Features
- **Data Export:** Users can export all their data
- **Account Deletion:** Complete data removal option
- **Transparent Privacy Policy:** Clear explanation of data usage

## 📈 Performance Optimizations

### Core Data
- **Batch Processing:** Efficient handling of large datasets
- **Lazy Loading:** Relationships loaded on demand
- **Background Context:** Heavy operations on background threads

### UI Performance  
- **LazyVGrid/LazyVStack:** Efficient list rendering
- **Image Compression:** Progress photos optimized for storage
- **AsyncImage:** Efficient image loading with placeholders

### CloudKit Sync
- **Incremental Sync:** Only changed data synchronized
- **Offline First:** App works without internet connection
- **Conflict Resolution:** Automatic handling of sync conflicts

## 🧪 Testing Strategy

### Unit Tests
- Core Data operations
- Business logic in ViewModels
- Data validation and transformations

### Integration Tests
- HealthKit integration
- CloudKit sync functionality
- Authentication flow

### UI Tests
- Critical user workflows
- Accessibility compliance
- Cross-device compatibility

## 🚀 Deployment

### App Store Requirements
- **iOS 16.0+ minimum target**
- **App Privacy Report:** Detailed privacy questionnaire
- **App Review Guidelines:** Health & Fitness category compliance
- **Metadata:** Screenshots, descriptions, keywords optimized for ASO

### Distribution Strategy
1. **TestFlight Beta:** Internal testing, coach beta, client beta
2. **App Store Release:** Phased rollout with feature flags
3. **Coach Onboarding:** Dedicated onboarding for fitness professionals
4. **Enterprise Options:** White-label solutions for gym chains

## 📧 Support & Documentation

### For Developers
- **API Documentation:** In-code documentation with examples
- **Architecture Decision Records:** Key architectural choices documented
- **Setup Guides:** Step-by-step development environment setup

### For Users
- **In-App Help:** Contextual help throughout the app
- **Video Tutorials:** For complex features like program creation
- **Coach Certification:** Training materials for fitness professionals

---

## 🎉 Getting Started

1. **Open Xcode Project:** Open `Package.swift` in Xcode
2. **Configure Apple Services:** Set up CloudKit, HealthKit, Sign in with Apple
3. **Run Data Seeding:** Use `DataSeeder.shared.seedInitialData()`
4. **Test on Device:** HealthKit requires physical device for testing
5. **Explore Features:** Try the progress tracking, authentication, and data sync

This project represents a complete transformation of Excel-based fitness coaching into a modern, scalable iOS application that leverages the full Apple ecosystem for an exceptional user experience.

---

**Built with ❤️ for the fitness coaching community**