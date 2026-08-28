# PiranhaTool Backend (Laravel 8)

This is the backend for the PiranhaTool (Vapi clone) loan management system.

## Setup

1. Copy `.env.example` to `.env` and configure your database connection:
   ```
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=piranhatool
   DB_USERNAME=root
   DB_PASSWORD=
   ```

2. Install PHP dependencies:
   ```
   composer install
   ```

3. Generate application key:
   ```
   php artisan key:generate
   ```

4. Run database migrations:
   ```
   php artisan migrate
   ```

5. Start the development server:
   ```
   php artisan serve
   ```
   Or configure a virtual host in XAMPP.

## API Endpoints

- `POST /api/register` - Register a new user
- `POST /api/login` - Login and receive Sanctum token
- `POST /api/logout` - logout (requires authentication)
- `GET /api/user` - get authenticated user (requires authentication)
- `GET /api/loans` - list user's loans
- `POST /api/loans` - create a new loan
- `GET /api/loans/{id}` - get a specific loan
- `PUT /api/loans/{id}` - update a loan
- `DELETE /api/loans/{id}` - delete a loan
- `GET /api/payments` - list all payments for user's loans
- `POST /api/payments` - record a payment

## Notes

- The API uses Laravel Sanctum for authentication. Send the token as a Bearer token in the Authorization header.
- The Flutter app expects the API to be available at `http://10.0.2.2:8000/api` when running in the Android emulator. Adjust the base URL in `lib/main.dart` if using a physical device or different port.