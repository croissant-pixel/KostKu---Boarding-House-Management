# kostku
A new Flutter project.
# KostKu---Boarding-House-Management
Aplikasi manajemen kost untuk pemilik dan penyewa
KostKu adalah aplikasi manajemen kost berbasis mobile yang memudahkan pemilik kost dalam mengelola properti, penyewa, dan keuangan secara terintegrasi. Dilengkapi dengan fitur GPS tracking, automatic payment generation, dan analytics dashboard.

<img width="377" height="831" alt="Screenshot 2026-01-08 171804" src="https://github.com/user-attachments/assets/3de7abbe-a50d-4973-bb97-499f9f98273b" />
<img width="375" height="830" alt="Screenshot 2026-01-08 171755" src="https://github.com/user-attachments/assets/b763d139-132f-4380-adf5-9499e164398d" />
<img width="383" height="831" alt="Screenshot 2026-01-08 171728" src="https://github.com/user-attachments/assets/3dbeb334-c6ca-41ee-bb00-0a26b6bc6d9a" />
<img width="375" height="837" alt="Screenshot 2026-01-08 171718" src="https://github.com/user-attachments/assets/9ff0708d-aac3-442b-8859-49c4f6b55f71" />
<img width="381" height="834" alt="Screenshot 2026-01-08 171559" src="https://github.com/user-attachments/assets/17492010-0b02-4070-8f97-c9afda9726a6" />
<img width="374" height="831" alt="Screenshot 2026-01-08 172435" src="https://github.com/user-attachments/assets/1e4bbb11-0a7a-4cdf-9ac4-bfc191bab76c" />
<img width="373" height="836" alt="Screenshot 2026-01-08 172426" src="https://github.com/user-attachments/assets/4d41be15-5f7b-4076-bb38-3456e1ad51c3" />
<img width="370" height="832" alt="Screenshot 2026-01-08 172118" src="https://github.com/user-attachments/assets/67c59c6c-190e-49cb-9b7d-61698ea9d9b0" />
<img width="375" height="830" alt="Screenshot 2026-01-08 172106" src="https://github.com/user-attachments/assets/30f6c81e-c2e6-4e6a-a175-590dbb472975" />
<img width="376" height="833" alt="Screenshot 2026-01-08 171946" src="https://github.com/user-attachments/assets/518a067e-a6ea-4a9c-9ee5-78be5abc422f" />
<img width="374" height="832" alt="Screenshot 2026-01-08 171932" src="https://github.com/user-attachments/assets/84bf545f-6aa9-4902-89a0-1365bc8efd7d" />
<img width="384" height="834" alt="Screenshot 2026-01-08 171905" src="https://github.com/user-attachments/assets/166d8f35-d11b-44ef-b411-be715a069829" />

Untuk Testing APK : https://drive.google.com/file/d/19zqtfd2h8XR2ckvt3daQv7xcbiJPcbek/view?usp=sharing

cara menjalankan

Flutter SDK (2.x or higher)
Dart SDK (2.x or higher)
Android Studio / VS Code
Android device/emulator (API level 21+)

Installation
Clone the repository

bash   git clone https://github.com/yourusername/kostku.git
   cd kostku

Install dependencies
bash   flutter pub get

Run the app
bash   flutter run
Build APK
bash# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# App Bundle (AAB) for Play Store
flutter build appbundle --release
Output location:
APK: build/app/outputs/flutter-apk/app-release.apk

Skema Database
CREATE TABLE rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT,
            type TEXT,
            price INTEGER,
            status TEXT,
            facilities TEXT,
            photoUrl TEXT,
            tenant_id INTEGER
          )
CREATE TABLE tenants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            email TEXT,
            room_id INTEGER,
            check_in_date TEXT,
            check_out_date TEXT,
            duration_month INTEGER DEFAULT 1,
            ktp_photo TEXT,
            profile_photo TEXT,
            emergency_contact TEXT,
            check_in_lat REAL,
            check_in_lng REAL,
            check_out_lat REAL,
            check_out_lng REAL,
            FOREIGN KEY (room_id) REFERENCES rooms(id)
          )
CREATE TABLE payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tenant_id INTEGER NOT NULL,
            month TEXT NOT NULL,
            amount INTEGER NOT NULL,
            paid_date TEXT,
            status TEXT NOT NULL,
            receipt_photo TEXT,
            notes TEXT,
            FOREIGN KEY (tenant_id) REFERENCES tenants(id)
          )
CREATE TABLE inspections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER,
            date TEXT,
            condition_notes TEXT,
            photo_url TEXT,
            FOREIGN KEY (room_id) REFERENCES rooms(id)
          )
CREATE TABLE monthly_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            month TEXT NOT NULL UNIQUE,
            occupancy_rate REAL,
            total_revenue INTEGER,
            payment_collection_rate REAL
          )
