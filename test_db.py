#!/usr/bin/env python3
"""
Test script to verify database connection and basic functionality
"""
import pyodbc
from werkzeug.security import generate_password_hash

# Database connection string
conn_str = (
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=DESKTOP-E5GIR84;" 
    "Database=cinema;"
    "Trusted_Connection=yes;"
)

def test_connection():
    """Test basic database connection"""
    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        # Test basic queries
        cursor.execute("SELECT COUNT(*) FROM [User]")
        user_count = cursor.fetchone()[0]
        print(f"✅ Users in database: {user_count}")
        
        cursor.execute("SELECT COUNT(*) FROM Movie")
        movie_count = cursor.fetchone()[0]
        print(f"✅ Movies in database: {movie_count}")
        
        cursor.execute("SELECT COUNT(*) FROM Cinema")
        cinema_count = cursor.fetchone()[0]
        print(f"✅ Cinemas in database: {cinema_count}")
        
        cursor.execute("SELECT COUNT(*) FROM [Session]")
        session_count = cursor.fetchone()[0]
        print(f"✅ Sessions in database: {session_count}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def test_user_creation():
    """Test user creation functionality"""
    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        # Test user creation
        test_username = "test_user_123"
        test_password = generate_password_hash("testpass123")
        
        # Clean up any existing test user
        cursor.execute("DELETE FROM [User] WHERE Username = ?", (test_username,))
        
        # Insert test user
        cursor.execute("""
            INSERT INTO [User] (Username, Password, Role, FirstName, LastName) 
            VALUES (?, ?, ?, ?, ?)
        """, (test_username, test_password, 'Customer', 'Test', 'User'))
        
        conn.commit()
        print(f"✅ Test user created successfully")
        
        # Clean up
        cursor.execute("DELETE FROM [User] WHERE Username = ?", (test_username,))
        conn.commit()
        print(f"✅ Test user cleaned up")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ User creation test failed: {e}")
        return False

if __name__ == "__main__":
    print("🔍 Testing CinemaProject Database Connection...")
    print("=" * 50)
    
    if test_connection():
        print("\n🔍 Testing User Creation...")
        test_user_creation()
    
    print("\n" + "=" * 50)
    print("✅ Database tests completed!")