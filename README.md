# PiranhaTool Loan Management System

This project consists of two parts:
1. A Flutter mobile application (Android/iOS) located in the root directory.
2. A Laravel 8 backend API located in the `backend` directory.

## Flutter App

The Flutter app is located in the root of this directory (`lib/main.dart`). It provides:
- User authentication (register/login/logout) via Laravel Sanctum
- CRUD operations for loans
- Ability to record payments against loans
- Simple UI for managing loans and payments

To run the Flutter app:
1. Ensure Flutter is installed and configured.
2. Run `flutter pub get` to get dependencies.
3. Run `flutter run` to start the app on an emulator or device.

**Note**: The app expects the Laravel backend to be running at `http://10.0.2.2:8000/api` when using the Android emulator. If you are using a physical device or iOS simulator, you may need to change the base URL in `lib/config.dart`.

## Laravel Backend

The Laravel backend is located in the `backend` directory. It provides:
- User registration and authentication (Laravel Sanctum)
- API endpoints for loans and payments
- CORS support for the Flutter app

### Setup Instructions

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Copy the example environment file and configure it:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` to set your database connection (MySQL recommended):
   ```
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=your_database_name
   DB_USERNAME=your_username
   DB_PASSWORD=your_password
   ```

3. Install PHP dependencies. Due to potential SSL issues with Composer on Windows, you may need to disable SSL verification temporarily:
   ```bash
   set COMPOSER_SSL_VERIFY_PEER=false
   composer install --ignore-platform-reqs --no-scripts
   ```
   If the above fails, you may need to manually resolve the SSL issue or use a different Composer configuration.

4. Generate the application key:
   ```bash
   php artisan key:generate
   ```

5. Run the database migrations:
   ```bash
   php artisan migrate
   ```

6. Start the development server:
   ```bash
   php artisan serve
   ```
   This will start the server at `http://127.0.0.1:8000`.

### API Endpoints

- `POST /api/register` - Register a new user
- `POST /api/login` - Login and receive a Sanctum token
- `POST /api/logout` - Logout (requires authentication)
- `GET /api/user` - Get the authenticated user (requires authentication)
- `GET /api/loans` - List all loans for the authenticated user
- `POST /api/loans` - Create a new loan
- `GET /api/loans/{id}` - Get a specific loan
- `PUT /api/loans/{id}` - Update a loan
- `DELETE /api/loans/{id}` - Delete a loan
- `GET /api/payments` - List all payments for the user's loans
- `POST /api/payments` - Record a payment

## Notes

- The Flutter app uses a simple state management approach with `setState`. For a production app, consider using a state management solution like Provider, Bloc, or Riverpod.
- The Laravel API uses Sanctum for token-based authentication. Ensure that your frontend sends the token in the `Authorization: Bearer <token>` header.
- CORS is configured via the `fruitcake/laravel-cors` package. The default configuration allows all origins; you may want to restrict this in production.

## Troubleshooting

If you encounter SSL issues with Composer, try:
- Updating your CA certificates
- Using `--no-plugins --no-scripts` flags
- Setting environment variable `SSL_CERT_FILE` to point to your CA bundle (e.g., from Git Bash)

If you have any questions, please refer to the Laravel and Flutter documentation.