# ⚽ Football Training App

The Football Training App is a role-based mobile application built with Flutter and Firebase, designed to streamline the management of football teams, training sessions, attendance tracking, and reporting. It includes three main roles:

- **🧑‍💼 Receptionist** – Can add, edit, or delete Coaches, Players, and Teams, assign Coaches to Teams, and upload Coach profile images using **Cloudinary**.  
- **🧑‍🏫 Coach** – Can view their assigned teams and players, start a training session (restricted to a 2-hour window), mark attendance with optional notes per player, and save session details.  
- **👨‍💻 Admin** – Has access to dashboard stats (total players, coaches, teams), can view full attendance history, and generate downloadable **PDF reports**.

---

## 📁 App Structure
'''
lib/
├── config/            # Firebase setup
├── views/             # Role-based screens (admin/, coach/, receptionist/, etc.)
├── widgets/           # Shared UI components
├── main.dart          # App entry point
'''
---

## 🛠 Tech Stack

- **Flutter + Dart**
- **Firebase Firestore** – Real-time cloud database
- **Cloudinary** – Media uploads (coach pictures)
- **PDF Generation** – For exporting reports

---

## 📊 UML Overview

### ✅ Use Case Diagram (Text)

- **Receptionist**
  - Manage Coaches (Add/Edit/Delete)
  - Manage Players (Add/Edit/Delete)
  - Manage Teams (Add/Edit/Delete)
  - Assign Coaches to Teams
  - Upload Coach Images

- **Coach**
  - View Assigned Teams
  - View Players in a Team
  - Start Training Session (≤ 2 hours)
  - Mark Attendance
  - Add Notes
  - Save Sessions

- **Admin**
  - View Total Stats (Players, Teams, Coaches)
  - View Attendance History
  - Export PDF Reports

---

### ✅ Class Diagram (Simplified)


---

### ✅ Sequence Diagram – “Coach Marks Attendance”

1. Coach opens assigned team  
2. System loads players  
3. Coach taps “Start Session”  
4. System validates 2-hour time window  
5. Coach marks attendance for each player  
6. Coach adds optional notes  
7. Coach taps “Save Session”  
8. Session and attendance are stored in Firestore  

---


🚀 To get started:  
1. `git clone https://github.com/yourusername/footballTraining.git`  
2. `cd footballTraining`  
3. `flutter pub get`  
4. `flutter run`  

🧠 Notes: Role-based logic is enforced via Firebase, coach photos are stored on Cloudinary, and session data is structured in Firestore collections (`users`, `players`, `teams`, `training_sessions`). PDF reports summarize attendance and player participation.  

📄 License: This project is intended for educational and training use.
