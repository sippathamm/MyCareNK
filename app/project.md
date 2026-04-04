# MyCareNK Project Documentation

## 1. Application Overview
MyCareNK is a mobile health and wellness application engineered to provide users with accessible healthcare services, specifically concerning reproductive health. The application facilitates the request of free condoms and lubricants, tracks user monthly quotas, disseminates health-related knowledge, and features emergency contact capabilities. It incorporates a modern, user-centric interface tailored for the local community populace.

## 2. Technology Stack
- **Frontend Framework:** Flutter (Dart)
- **User Interface & Styling:** Material 3 Design, `google_fonts` (Prompt font family), `cupertino_icons`
- **Backend & Database:** Supabase (`supabase_flutter`)
- **Environment Management:** `flutter_dotenv` (.env files)
- **External Integration:** `url_launcher` (for emergency dialer and external web links)

## 3. Directory Structure
The application follows a modular, feature-based directory structure to separate concerns effectively between data layers and presentation layers.
```text
lib/
├── features/
│   ├── auth/                 # Authentication and user registration flows
│   │   ├── data/             # Services (e.g., recovery_service.dart)
│   │   └── presentation/
│   │       ├── pages/        # Login, Register, Forgot Password screens
│   │       └── widgets/      # Authentication specific widgets
│   ├── home/                 # Main dashboard functionality
│   │   └── presentation/
│   │       ├── pages/        # home_page.dart
│   │       └── widgets/      # Banners, Quota cards, Quick menus
│   ├── main/                 # Application host layout
│   │   └── presentation/
│   │       └── pages/        # main_page.dart (BottomNavigationBar host)
│   ├── history/              # Request history and status tracking
│   │   ├── data/             # Models (e.g., condom_request_model.dart)
│   │   └── presentation/
│   │       └── pages/        # Request history and detail screens
│   └── service/              # Core health service requests (Condom/Lubricant)
│       └── presentation/
│           ├── pages/        # Request forms, confirmation, success screens
│           └── widgets/      # Steppers and service-specific UI components
└── main.dart                 # Application entry point & initialization
```

## 4. Project Architecture and Modules

### 4.1 Authentication Module (`features/auth`)
This module manages user onboarding, authentication, and an encrypted password recovery system.
- **`login_page.dart`**: Implements the user login interface.
- **`register_page.dart` & `registration_success_page.dart`**: Handles the user registration workflow.
- **Password Recovery Flow:**
  - Includes `forgot_password_page.dart`, `forgot_password_recovery_code_page.dart`, and `forgot_password_reset_page.dart`.
  - Enables users to generate and utilize cryptographically secure recovery codes for password resets, replacing traditional email-based links.
- **`recovery_service.dart`**: A dedicated service class that communicates with Supabase to securely generate, store, and verify cryptographic recovery codes.

### 4.2 Main Navigation (`features/main`)
- **`main_page.dart`**: Serves as the root layout shell for the application, integrating a bottom navigation bar to transition between the Home, Services, and other top-level views.

### 4.3 Home Dashboard (`features/home`)
Functioning as the central hub for authenticated users.
- **`home_page.dart`**: The primary dashboard screen view.
- **Key Components:**
  - `monthly_free_card.dart`: Renders the user's remaining monthly allocation for free health supplies (condoms and lubricants), utilizing fluid animated progress bars.
  - `shortcut_menu.dart`: Provides rapid access navigation to essential application features.
  - `knowledge_section.dart`: Displays health articles and educational resources.
  - `campaign_banner.dart`: Presents promotional materials and health campaign banners.
  - `emergency_button.dart`: Offers immediate access to emergency contact numbers.

### 4.4 Services Module (`features/service`)
Manages the core business logic of requesting reproductive health supplies.
- **`condom_request_page.dart`**: The primary data entry form allowing users to select required quantities and sizes of condoms (49, 52, 54, 56 mm) alongside lubricants. It rigorously enforces maximum monthly quotas (e.g., 60 condoms, 30 lubricants). Users designate a pick-up facility (e.g., local health facilities) and schedule a specific date and time for collection.
- **`condom_request_confirm_page.dart`**: Presents an order summary and confirmation interface prior to committing data to the backend.
- **`condom_request_success_page.dart`**: A success confirmation screen detailing the request and subsequent instruction steps.
- **`service_navigator.dart` / `service_page.dart`**: Act as the navigation coordinators and entry points for the services module.

### 4.5 Request History Module (`features/history`)
Provides users with visibility into their past activity and current request statuses.
- **`request_history_page.dart`**: Lists all previous condom and lubricant requests with real-time status updates.
- **`request_history_detail_page.dart`**: Displays granular details of a specific request, including items, quantities, and timestamps.
- **Real-time Synchronization**: Utilizes Supabase Realtime to automatically update statuses and lists without manual refreshes.
- **Data Persistence**: Uses `CondomRequestModel` for mapping database records to UI components.

## 5. Database and Supabase Integration
The backend infrastructure leverages Supabase for Authentication, Database operations, and Remote Procedure Calls (RPCs).

### 5.1 Key Database Tables
1. **`user_monthly_quotas`**
   - **Purpose:** Monitors the usage limits allocated to each user.
   - **Schema Details:** `user_id`, `month`, `used_condoms`, `used_lubricants`.
   - **Mechanism:** The application queries this table to calculate residual quotas and executes `upsert` operations to revise usage statistics upon confirmation of a request.

2. **`condom_requests`**
   - **Purpose:** Archives the actual supply requests submitted by users.
   - **Schema Details:** Records parameters including item sizes, quantities, lubricant amounts, pickup location coordinates, pickup timestamp, and any optional user messages.

### 5.2 Custom RPCs (PostgreSQL Functions)
The authentication framework utilizes Custom RPCs to execute server-side logic securely:
- **`save_recovery_codes`**: Persists newly generated recovery codes to the database during user registration or key regeneration events.
- **`verify_recovery_code`**: Conducts pre-verification of a submitted recovery code without indiscriminately triggering a password reset. It returns statuses such as `success`, `rate_limited`, or `locked`.
- **`verify_recovery_code_and_reset_password`**: The culminating step in the recovery workflow; it validates the code and securely updates the user's secret credential in a single atomic transaction.

## 6. Technical Considerations for System Scalability
- **State Management Architecture:** The current implementation relies on native stateful widgets (`setState`) and StreamSubscriptions (`onAuthStateChange`). As the application scales, consideration should be given to migrating to a centralized state management architecture (e.g., BLoC, Riverpod, or Provider) to maintain code maintainability.
- **Animation Standards:** The application maintains a premium user experience utilizing `TweenAnimationBuilder` for quota visualizations. Ensure that any newly introduced data metrics conform to the established User Experience (UX) interaction patterns demonstrated in the `MonthlyFreeCard` and `CondomRequestPage` components.

## 7. Future Development Features
To further enhance the application's capabilities, the following features are proposed for the development roadmap:
- **User Profile Management**: Comprehensive settings for users to update personal information, securely regenerate recovery codes, and manage account preferences.
- **Push Notification System**: Integration of Firebase Cloud Messaging (FCM) or Supabase Notifications to alert users when a request is approved or ready for collection.
- **Administrative Portal Integration**: Synchronizing application request logic with a parallel web-based administrative dashboard for healthcare staff to process outgoing supplies efficiently.

## 8. Known Bugs and Current Issues
The following issues have been identified and require resolution in upcoming iterations:
- **Client-Side Quota Retrieval Vulnerability (`condom_request_page.dart`):** If the application fails to retrieve the user's monthly quota from the `user_monthly_quotas` table (e.g., due to network interference), it defaults to displaying zero usage. This implicitly permits users to request the maximum quota on the UI without realizing a network error occurred.
- **Lack of Backend Quota Enforcement:** While monthly quotas are restricted on the client-side User Interface (e.g., strictly restricting stepper maximum bounds), they must be rigorously secured by executing corresponding validation checks on the Supabase backend (e.g., via Row Level Security policies or secure insert RPCs) to prevent API manipulation.
- **Unverified Error Handling Coverage:** Some operations rely broadly on top-level `catch` clauses without distinguishing between network errors or application logic errors, temporarily displaying generic "An error occurred" dialogs. More specific exception handling routing should be implemented.

## 9. Changelog

### v0.9.3
#### Added
- Display real username dynamically from `user_profiles` table on the Home Page dashboard.
#### Fixed
- N/A
#### Changed
- Migrated user demographic information logging (gender, nationality, date of birth) from Supabase auth metadata to the `user_profiles` table during the registration process.

### v0.9.2
#### Added
- N/A
#### Fixed
- N/A
#### Changed
- Updated the application icon with the new brand design for both Android and iOS platforms.

### v0.9.1
#### Added
- N/A
#### Fixed
- Update condom request status logic to 'submitted' for better backend synchronization.
- Improve scrollability on the request success page to prevent overflow on smaller devices.
#### Changed
- N/A

### v0.9.0
#### Added
- Real-time data synchronization using Supabase Realtime for the request history module.
- "Pull-to-refresh" functionality for the dashboard and history pages.
#### Fixed
- N/A
#### Changed
- Enhanced date display across the app using localized Thai month names.
- Standardized data handling using `CondomRequestModel` for history and detail views.

### v0.8.0
#### Added
- Request History module with a comprehensive list of previous requests.
- Request History Detail page for granular order information.
- Project documentation and tracking (`project.md`).
#### Fixed
- N/A
#### Changed
- N/A

### v0.7.0
#### Added
- "Days until quota reset" display on the monthly free card.
#### Fixed
- N/A
#### Changed
- Dashboard enhancements specifically for better quota tracking visibility.
- Improved "hint text" and navigation logic (`rootNavigator`) for smoother UX interaction.

### v0.6.0
#### Added
- Complete Forgot Password flow with dedicated recovery pages.
- Recovery code generation and verification bridge via Supabase RPCs.
- Material prefix icons to authentication inputs for improved visual clarity.
#### Fixed
- N/A
#### Changed
- N/A

### v0.5.0
#### Added
- Automated generation and secure storage of recovery codes during registration.
#### Fixed
- N/A
#### Changed
- Full integration of Supabase Authentication and Database services.

### v0.4.0
#### Added
- Initial Login and Registration screens (UI layout).
#### Fixed
- N/A
#### Changed
- Re-organized application architecture into a unified navigation stack.

### v0.3.0
#### Added
- Condom Request workflow completion (confirmation and success states).
- Animated progress bars for quota visualization on the dashboard.
- Precision Stepper widgets for lubricant quantity control.
#### Fixed
- N/A
#### Changed
- N/A

### v0.2.0
#### Added
- Initial Services module and core Condom Request form.
- Core dashboard components: Banners, Shortcut Menus, and Emergency Button.
- Nested navigation architecture for the Service tab.
#### Fixed
- N/A
#### Changed
- N/A

### v0.1.0
#### Added
- Project initialization and environment configuration (Gradle, Java, Supabase Setup).
- Design system implementation (Google Fonts, Brand Colors, Material 3).
#### Fixed
- N/A
#### Changed
- N/A
