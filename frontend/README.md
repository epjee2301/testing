# LookIn Presensi Mobile

Flutter mobile client for HRD and employee accounts. Admins use the Laravel web panel.

## Features by role

- **Admin (Laravel web):** attendance, calendar/history, leave/permission/sick/overtime requests, approvals, employee activity/reports, HRD/employee account management, and profile.
- **HRD (Flutter mobile):** live attendance/request overview and reports, attendance, requests, and profile.
- **Karyawan (Flutter mobile):** attendance, personal calendar/history and work duration, requests, and profile.
- The mobile API only accepts HRD and karyawan roles. Admin authentication is handled by Laravel web sessions.

## Run locally

Start Laravel in a separate terminal from the project root:

```powershell
cd C:\Users\ASUS\LookIn-app\backend
php artisan migrate
php artisan db:seed
php artisan serve --host 0.0.0.0 --port 8000
```

Open the admin panel in a computer browser at `http://127.0.0.1:8000/admin/login`.
In VS Code, open the `frontend` folder, select an Android/iOS device, and press **F5** for HRD or karyawan. Alternatively:

```powershell
cd C:\Users\ASUS\LookIn-app\frontend
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

Android Emulator uses `http://10.0.2.2:8000/api`. For a physical phone, set the API base URL to the computer's LAN IP:

```powershell
flutter run -d DEVICE_ID --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
```

Replace the example IP with the computer's actual Wi-Fi IPv4 address. The phone and computer must be on the same network, and Laravel must remain running.
The same `API_BASE_URL` setting can be used for iOS simulators/devices. Local HTTP is enabled for local-network development; use HTTPS for deployed environments.

Local development accounts created by the Laravel seeder:

| Role | Email | Password |
|---|---|---|
| Admin | `admin@lookin.com` | `password123` |
| HRD | `hrd@lookin.com` | `password123` |
| Karyawan | `karyawan@lookin.com` | `password123` |

The admin account logs in at the Laravel web panel. HRD and karyawan accounts log in in the mobile app. These are local development credentials; change them before deployment.

## Validate

```powershell
flutter analyze
flutter test
flutter build apk --debug
```
