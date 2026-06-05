# Suraksha - AI-Powered Women Safety Ecosystem

Suraksha is a futuristic, production-ready women's safety platform built with Flutter, Node.js, and MongoDB. It integrates AI-driven assistance, real-time emergency systems, and sensor-based detection to provide a comprehensive safety net.

## 🚀 Features

- **Advanced SOS System**: One-tap emergency trigger with real-time location sharing via Socket.IO.
- **AI Safety Assistant**: Gemini-powered POSH legal advisor and safety intelligence.
- **Safety Pulse Radar**: Futuristic visualization of nearby safe zones and activity.
- **Sensor-based Detection**: Automated SOS triggers for impacts and screams.
- **Cyber Crime Module**: Integrated reporting for financial fraud, stalking, and harassment.
- **Medical Health Vault**: Digital emergency medical ID and QR code access.
- **Safety Intelligence Map**: Dark-themed map with safe/risk zone indicators.

## 🛠 Tech Stack

- **Frontend**: Flutter (Material 3, Clean Architecture, Riverpod, GoRouter, Socket.IO Client).
- **Backend**: Node.js, Express.js, Socket.IO, JWT Auth, Mongoose.
- **Database**: MongoDB Atlas.
- **AI**: Google Gemini API.
- **Media**: Cloudinary for evidence storage.

## 📂 Project Structure

### Flutter (lib/)
- `core/`: Network, theme, and common utils.
- `features/`: Modular features (Auth, SOS, Maps, Cybercrime, AI).
- `widgets/`: Reusable futuristic UI components.

### Backend (backend/)
- `controllers/`: Business logic.
- `models/`: MongoDB schemas (User, SOS, CyberReport).
- `sockets/`: Real-time communication logic.
- `routes/`: API endpoints.

## 🏁 Getting Started

### Prerequisites
- Flutter SDK
- Node.js & npm
- MongoDB Atlas account (or local MongoDB)
- Google Gemini API Key
- Google Maps API Key

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/suraksha.git
   ```

2. **Backend Setup**:
   ```bash
   cd backend
   npm install
   # Create a .env file with your variables (MONGO_URI, JWT_SECRET, etc.)
   node src/server.js
   ```

3. **Frontend Setup**:
   ```bash
   cd ..
   flutter pub get
   # Configure ApiConstants.baseUrl in lib/constants/api_constants.dart
   flutter run
   ```

## 🔒 Security
- JWT-based stateless authentication.
- Encrypted storage for sensitive tokens.
- Secure evidence uploading to Cloudinary.
- Helmet & Rate-limiting on the backend.

## 📜 License
This project is licensed under the MIT License.
