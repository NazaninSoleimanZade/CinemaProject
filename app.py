from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import pyodbc
import uuid
import os
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, timedelta

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'university_project_key_change_in_production')

# --- CONFIGURATION ---
conn_str = (
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=DESKTOP-E5GIR84;" 
    "Database=cinema;"
    "Trusted_Connection=yes;"
)

def get_db_connection():
    """Get database connection with better error handling"""
    try:
        conn = pyodbc.connect(conn_str)
        return conn
    except pyodbc.Error as e:
        print(f"Database connection error (pyodbc): {e}")
        return None
    except Exception as e:
        print(f"Database connection error (general): {e}")
        return None

def check_seat_availability(cinema_id, hall_number, show_date, start_time, row_no, seat_no):
    """Check if a seat is available for booking"""
    conn = get_db_connection()
    if not conn:
        print("Cannot check seat availability - no database connection")
        return False
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT COUNT(*) FROM Ticket 
            WHERE CinemaID = ? AND HallNumber = ? AND ShowDate = ? 
            AND StartTime = ? AND RowNo = ? AND SeatNo = ?
            AND TicketStatus IN ('Reserved', 'Paid')
        """, (cinema_id, hall_number, show_date, start_time, row_no, seat_no))
        
        count = cursor.fetchone()[0]
        conn.close()
        return count == 0
    except Exception as e:
        print(f"Error checking seat availability: {e}")
        conn.close()
        return False

@app.route('/')
def index():
    search_query = request.args.get('search', '')
    genre_filter = request.args.get('genre', '')
    
    conn = get_db_connection()
    if not conn:
        flash('Database connection error. Please try again later.', 'error')
        return render_template('index.html', movies=[], genres=[])
    
    cursor = conn.cursor()
    
    # Get all genres for filter dropdown
    cursor.execute("SELECT DISTINCT Genre FROM MovieGenre ORDER BY Genre")
    genres = [row[0] for row in cursor.fetchall()]
    
    # Build dynamic query based on filters
    sql = """
        SELECT M.FilmID, M.Title, M.AgeRating, M.DurationMin, M.Director,
               STRING_AGG(G.Genre, ', ') AS Genre
        FROM Movie M
        LEFT JOIN MovieGenre G ON M.FilmID = G.FilmID
    """
    
    conditions = []
    params = []
    
    if search_query:
        conditions.append("M.Title LIKE ?")
        params.append('%' + search_query + '%')
    
    if genre_filter:
        conditions.append("EXISTS (SELECT 1 FROM MovieGenre MG WHERE MG.FilmID = M.FilmID AND MG.Genre = ?)")
        params.append(genre_filter)
    
    if conditions:
        sql += " WHERE " + " AND ".join(conditions)
    
    sql += " GROUP BY M.FilmID, M.Title, M.AgeRating, M.DurationMin, M.Director ORDER BY M.Title"
    
    cursor.execute(sql, params)
    movies = cursor.fetchall()
    conn.close()
    
    return render_template('index.html', movies=movies, genres=genres, 
                         current_search=search_query, current_genre=genre_filter)

@app.route('/login_page')
def login_page():
    return render_template('login.html')

@app.route('/register_page')
def register_page():
    return render_template('register.html')

@app.route('/register', methods=['POST'])
def register():
    username = request.form.get('username', '').strip()
    password = request.form.get('password', '')
    confirm_password = request.form.get('confirm_password', '')
    role = request.form.get('role', 'Customer')
    email = request.form.get('email', '').strip()
    first_name = request.form.get('first_name', '').strip()
    last_name = request.form.get('last_name', '').strip()
    
    # Basic validation
    if not username or not password or not first_name or not last_name:
        flash('Please fill in all required fields.', 'error')
        return redirect(url_for('register_page'))
    
    if password != confirm_password:
        flash('Passwords do not match.', 'error')
        return redirect(url_for('register_page'))
    
    if len(password) < 6:
        flash('Password must be at least 6 characters long.', 'error')
        return redirect(url_for('register_page'))
    
    conn = get_db_connection()
    if not conn:
        flash('Database connection error. Please try again later.', 'error')
        return redirect(url_for('register_page'))
    
    try:
        cursor = conn.cursor()
        
        # Check if username already exists
        cursor.execute("SELECT Username FROM [User] WHERE Username = ?", (username,))
        if cursor.fetchone():
            flash('Username already exists. Please choose a different one.', 'error')
            conn.close()
            return redirect(url_for('register_page'))
        
        # Check if email already exists (if provided)
        if email:
            cursor.execute("SELECT Username FROM [User] WHERE Email = ?", (email,))
            if cursor.fetchone():
                flash('Email already registered. Please use a different email.', 'error')
                conn.close()
                return redirect(url_for('register_page'))
        
        # Insert new user
        hashed_pw = generate_password_hash(password)
        cursor.execute("""
            INSERT INTO [User] (Username, Password, Role, Email, FirstName, LastName) 
            VALUES (?, ?, ?, ?, ?, ?)
        """, (username, hashed_pw, role, email or None, first_name, last_name))
        conn.commit()
        conn.close()
        
        flash('Registration successful! Please log in.', 'success')
        return redirect(url_for('login_page'))
        
    except pyodbc.IntegrityError as e:
        conn.close()
        print(f"Registration integrity error: {e}")
        flash('Username or email already exists. Please try different values.', 'error')
        return redirect(url_for('register_page'))
    except pyodbc.Error as e:
        conn.close()
        print(f"Registration database error: {e}")
        flash('Database error occurred. Please try again later.', 'error')
        return redirect(url_for('register_page'))
    except Exception as e:
        conn.close()
        print(f"Registration unexpected error: {e}")
        flash('Registration failed. Please try again.', 'error')
        return redirect(url_for('register_page'))

@app.route('/login', methods=['POST'])
def login():
    username = request.form.get('username', '').strip()
    password = request.form.get('password', '')
    
    if not username or not password:
        flash('Please enter both username and password.', 'error')
        return redirect(url_for('login_page'))
    
    conn = get_db_connection()
    if not conn:
        flash('Database connection error. Please try again later.', 'error')
        return redirect(url_for('login_page'))
    
    cursor = conn.cursor()
    cursor.execute("SELECT Password, Role, FirstName FROM [User] WHERE Username = ?", (username,))
    user = cursor.fetchone()
    conn.close()

    if user and check_password_hash(user[0], password):
        session['username'] = username
        session['role'] = user[1]
        session['first_name'] = user[2]
        flash(f'Welcome back, {user[2]}!', 'success')
        return redirect(url_for('index'))
    else:
        flash('Invalid username or password.', 'error')
        return redirect(url_for('login_page'))

@app.route('/get_showtimes/<int:film_id>')
def get_showtimes(film_id):
    """API endpoint to get available showtimes for a movie"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    cursor = conn.cursor()
    cursor.execute("""
        SELECT S.CinemaID, C.CinemaName, S.HallNumber, S.ShowDate, S.StartTime, S.Price
        FROM [Session] S
        JOIN Cinema C ON S.CinemaID = C.CinemaID
        WHERE S.FilmID = ? AND S.ShowDate >= CAST(GETDATE() AS DATE)
        ORDER BY S.ShowDate, S.StartTime
    """, (film_id,))
    
    showtimes = []
    for row in cursor.fetchall():
        showtimes.append({
            'cinema_id': row[0],
            'cinema_name': row[1],
            'hall_number': row[2],
            'show_date': row[3].strftime('%Y-%m-%d'),
            'start_time': str(row[4]),
            'price': float(row[5])
        })
    
    conn.close()
    return jsonify(showtimes)

@app.route('/book', methods=['POST'])
def book_ticket():
    if 'username' not in session:
        flash('Please log in to book tickets.', 'error')
        return redirect(url_for('login_page'))
    
    # Debug: Print all form data
    print("Form data received:", dict(request.form))
    
    # Get form data
    movie_title = request.form.get('movie_title', 'Selected Movie')
    cinema_id = request.form.get('cinema_id', type=int)
    hall_number = request.form.get('hall_number', type=int)
    show_date = request.form.get('show_date')
    start_time = request.form.get('start_time')
    row_no = request.form.get('row_no', type=int)
    seat_no = request.form.get('seat_no', type=int)
    
    # Debug: Print parsed values
    print(f"Parsed values - Cinema: {cinema_id}, Hall: {hall_number}, Date: {show_date}, Time: {start_time}, Row: {row_no}, Seat: {seat_no}")
    
    # Validate required fields
    if not all([cinema_id, hall_number, show_date, start_time, row_no, seat_no]):
        missing_fields = []
        if not cinema_id: missing_fields.append('cinema_id')
        if not hall_number: missing_fields.append('hall_number')
        if not show_date: missing_fields.append('show_date')
        if not start_time: missing_fields.append('start_time')
        if not row_no: missing_fields.append('row_no')
        if not seat_no: missing_fields.append('seat_no')
        
        print(f"Missing fields: {missing_fields}")
        flash(f'Please fill in all booking details. Missing: {", ".join(missing_fields)}', 'error')
        return redirect(url_for('index'))
    
    conn = get_db_connection()
    if not conn:
        flash('Database connection error. Please try again later.', 'error')
        return redirect(url_for('index'))
    
    try:
        # Check seat availability
        if not check_seat_availability(cinema_id, hall_number, show_date, start_time, row_no, seat_no):
            flash('Sorry, this seat is already taken. Please select another seat.', 'error')
            conn.close()
            return redirect(url_for('index'))
        
        # Generate unique QR code
        ticket_qr = str(uuid.uuid4())[:80]
        
        cursor = conn.cursor()
        
        # Insert ticket
        cursor.execute("""
            INSERT INTO Ticket (QRCode, Username, CinemaID, HallNumber, ShowDate, StartTime, RowNo, SeatNo, TicketStatus)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Reserved')
        """, (ticket_qr, session['username'], cinema_id, hall_number, show_date, start_time, row_no, seat_no))
        conn.commit()
        
        # Get cinema and session details for confirmation
        cursor.execute("""
            SELECT C.CinemaName, S.Price
            FROM Cinema C
            JOIN [Session] S ON C.CinemaID = S.CinemaID
            WHERE S.CinemaID = ? AND S.HallNumber = ? AND S.ShowDate = ? AND S.StartTime = ?
        """, (cinema_id, hall_number, show_date, start_time))
        
        session_info = cursor.fetchone()
        cinema_name = session_info[0] if session_info else 'Unknown Cinema'
        price = session_info[1] if session_info else 0
        
        conn.close()
        
        flash('Ticket booked successfully!', 'success')
        return render_template('success.html', 
                             qr=ticket_qr, 
                             seat=f"Row {row_no}, Seat {seat_no}",
                             username=session['username'], 
                             movie=movie_title,
                             cinema=cinema_name,
                             hall=hall_number,
                             show_date=show_date,
                             start_time=start_time,
                             price=price)
    
    except pyodbc.IntegrityError as e:
        conn.close()
        print(f"Booking integrity error: {e}")
        flash('This seat is already booked. Please select another seat.', 'error')
        return redirect(url_for('index'))
    except pyodbc.Error as e:
        conn.close()
        print(f"Booking database error: {e}")
        flash('Database error occurred. Please try again later.', 'error')
        return redirect(url_for('index'))
    except Exception as e:
        conn.close()
        print(f"Booking unexpected error: {e}")
        flash('Booking failed. Please try again.', 'error')
        return redirect(url_for('index'))

@app.route('/dashboard')
def dashboard():
    if session.get('role') != 'Staff':
        flash('Access denied. Staff access required.', 'error')
        return redirect(url_for('index'))
    
    conn = get_db_connection()
    if not conn:
        flash('Database connection error.', 'error')
        return redirect(url_for('index'))
    
    cursor = conn.cursor()
    cursor.execute("""
        SELECT T.QRCode, T.Username, U.FirstName, U.LastName, T.RowNo, T.SeatNo, 
               T.TicketStatus, T.BuyDate, M.Title, C.CinemaName, T.ShowDate, T.StartTime
        FROM Ticket T
        JOIN [User] U ON T.Username = U.Username
        JOIN [Session] S ON T.CinemaID = S.CinemaID AND T.HallNumber = S.HallNumber 
                         AND T.ShowDate = S.ShowDate AND T.StartTime = S.StartTime
        JOIN Movie M ON S.FilmID = M.FilmID
        JOIN Cinema C ON T.CinemaID = C.CinemaID
        ORDER BY T.BuyDate DESC
    """)
    tickets = cursor.fetchall()
    
    # Get summary statistics
    cursor.execute("""
        SELECT 
            COUNT(*) as total_tickets,
            SUM(CASE WHEN TicketStatus = 'Paid' THEN 1 ELSE 0 END) as paid_tickets,
            SUM(CASE WHEN TicketStatus = 'Reserved' THEN 1 ELSE 0 END) as reserved_tickets
        FROM Ticket
    """)
    stats = cursor.fetchone()
    
    conn.close()
    return render_template('dashboard.html', tickets=tickets, stats=stats)

@app.route('/logout')
def logout():
    session.clear()
    flash('You have been logged out successfully.', 'info')
    return redirect(url_for('index'))

@app.route('/debug/db-test')
def debug_db_test():
    """Debug route to test database connection"""
    if not app.debug:
        return "Debug mode only", 403
    
    conn = get_db_connection()
    if not conn:
        return "Database connection failed"
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM [User]")
        user_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM Movie")
        movie_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM Cinema")
        cinema_count = cursor.fetchone()[0]
        
        conn.close()
        
        return f"""
        Database Connection: SUCCESS<br>
        Users: {user_count}<br>
        Movies: {movie_count}<br>
        Cinemas: {cinema_count}<br>
        """
    except Exception as e:
        conn.close()
        return f"Database query failed: {e}"

if __name__ == '__main__':
    app.run(debug=True)