# 🎬 CinemaOnline - Iranian Cinema Booking System

A modern web application for booking cinema tickets, built with Flask and SQL Server.

## ✨ Features

### 🎭 For Customers
- Browse available movies with search and genre filtering
- View movie details (duration, director, genre, rating)
- Book tickets with dynamic showtime selection
- Seat availability checking
- QR code ticket generation
- User-friendly booking confirmation

### 👨‍💼 For Staff
- Comprehensive dashboard with ticket statistics
- View all bookings with detailed information
- Export ticket data to CSV
- Real-time data refresh

### 🔐 Security & Authentication
- Secure user registration and login
- Password hashing with Werkzeug
- Session management
- Input validation and error handling
- Role-based access control

## 🚀 Recent Improvements

### Frontend Enhancements
- **Modern CSS Design**: Custom CSS with cinema-themed colors and responsive layout
- **Interactive Booking Modal**: Dynamic showtime selection with AJAX
- **Enhanced Forms**: Better validation, password visibility toggle, real-time feedback
- **Mobile Responsive**: Works well on all device sizes
- **Flash Messages**: User-friendly success/error notifications

### Backend Improvements
- **Dynamic Booking System**: Real showtime data instead of static values
- **Seat Availability**: Prevents double booking of seats
- **Better Error Handling**: Database connection error management
- **Enhanced Registration**: Comprehensive user data collection with validation
- **Improved Dashboard**: Rich ticket information with statistics

### User Experience
- **Search & Filter**: Find movies by title and genre
- **Detailed Confirmations**: Complete booking information display
- **Print Functionality**: Printable ticket format
- **Auto-refresh**: Dashboard updates automatically
- **Export Feature**: CSV export for staff reports

## 🛠️ Technology Stack

- **Backend**: Python Flask
- **Database**: Microsoft SQL Server with ODBC
- **Frontend**: HTML5, CSS3, JavaScript
- **Security**: Werkzeug password hashing
- **Styling**: Custom CSS with CSS Grid and Flexbox

## 📁 Project Structure

```
CinemaProject/
├── app.py                 # Main Flask application
├── static/
│   └── css/
│       └── style.css      # Modern styling
├── templates/
│   ├── index.html         # Movie listing with booking
│   ├── login.html         # User authentication
│   ├── register.html      # User registration
│   ├── dashboard.html     # Staff dashboard
│   └── success.html       # Booking confirmation
├── SQLQuery1_noerrors (1).sql  # Database schema
└── README.md              # This file
```

## 🎯 Key Improvements Made

1. **Visual Design**: Modern, cinema-themed interface with responsive design
2. **Functionality**: Dynamic booking with real showtime data and seat checking
3. **User Experience**: Better forms, validation, and feedback messages
4. **Staff Tools**: Enhanced dashboard with statistics and export capabilities
5. **Security**: Improved validation and error handling
6. **Mobile Support**: Responsive design for all devices

## 🔧 Setup Instructions

1. Ensure SQL Server is running with the cinema database
2. Install required Python packages: `pip install flask pyodbc werkzeug`
3. Update database connection string in `app.py` if needed
4. Run the application: `python app.py`
5. Access at `http://localhost:5000`

## 📊 Database Schema

The application uses a comprehensive database schema with:
- **Cinema & Hall Management**: Multiple cinemas with multiple halls
- **Movie Information**: Complete movie details with genres, cast, languages
- **Session Management**: Showtimes with pricing
- **User System**: Customers and staff with role-based access
- **Ticketing**: QR code tickets with seat reservations
- **Payment System**: Multiple payment methods support

## 🎓 University Project Notes

This project demonstrates:
- Full-stack web development with Flask
- Database design and integration
- User authentication and authorization
- Modern frontend development
- Responsive web design
- Real-world application architecture

Perfect for demonstrating web development skills in a university setting!