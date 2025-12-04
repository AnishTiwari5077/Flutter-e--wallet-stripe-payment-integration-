import pymysql

# Database connection
connection = pymysql.connect(
    host='localhost',
    user='root',
    password='Aaa123@@@',  # Change to your MySQL password
    cursorclass=pymysql.cursors.DictCursor
)

try:
    with connection.cursor() as cursor:
        # Create database
        print("Creating database...")
        cursor.execute("CREATE DATABASE IF NOT EXISTS ewallet")
        cursor.execute("USE ewallet")
        
        # Drop existing tables
        print("Dropping existing tables if any...")
        cursor.execute("DROP TABLE IF EXISTS transactions")
        cursor.execute("DROP TABLE IF EXISTS users")
        
        # Create users table
        print("Creating users table...")
        cursor.execute("""
            CREATE TABLE users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                phone VARCHAR(20) UNIQUE NOT NULL,
                password VARCHAR(255) NOT NULL,
                avatar VARCHAR(255) DEFAULT NULL,
                balance DECIMAL(10, 2) DEFAULT 0.00,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Create transactions table
        print("Creating transactions table...")
        cursor.execute("""
            CREATE TABLE transactions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                sender_id INT DEFAULT NULL,
                receiver_id INT DEFAULT NULL,
                amount DECIMAL(10, 2) NOT NULL,
                type ENUM('add', 'send') NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE SET NULL,
                FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE SET NULL
            )
        """)
        
        connection.commit()
        
        # Verify
        print("\n✅ Tables created successfully!")
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        print("\nTables in ewallet database:")
        for table in tables:
            print(f"  - {list(table.values())[0]}")
        
        # Show structure
        print("\n📋 Users table structure:")
        cursor.execute("DESCRIBE users")
        for row in cursor.fetchall():
            print(f"  {row}")
        
        print("\n📋 Transactions table structure:")
        cursor.execute("DESCRIBE transactions")
        for row in cursor.fetchall():
            print(f"  {row}")

except Exception as e:
    print(f"❌ Error: {e}")
finally:
    connection.close()
    print("\n✅ Database setup complete!")