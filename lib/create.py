import pymysql

connection = pymysql.connect(
    host='localhost',
    user='root',
    password='Aaa123@@@',  # Set via environment variable in production
    cursorclass=pymysql.cursors.DictCursor
)

try:
    with connection.cursor() as cursor:
        # Create database
        print("Creating database...")
        cursor.execute("CREATE DATABASE IF NOT EXISTS ewallet")
        cursor.execute("USE ewallet")
        
        # Drop existing tables in correct order (foreign keys)
        print("Dropping existing tables...")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        cursor.execute("DROP TABLE IF EXISTS transactions")
        cursor.execute("DROP TABLE IF EXISTS sessions")
        cursor.execute("DROP TABLE IF EXISTS users")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        
        # Create users table with improvements
        print("Creating users table...")
        cursor.execute("""
            CREATE TABLE users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                phone VARCHAR(20) UNIQUE NOT NULL,
                password VARCHAR(255) NOT NULL,  -- Increased for bcrypt
                avatar MEDIUMTEXT,  -- Changed to MEDIUMTEXT for base64
                balance DECIMAL(12, 2) DEFAULT 0.00,  -- Increased precision
                is_active BOOLEAN DEFAULT TRUE,
                email_verified BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                last_login TIMESTAMP NULL,
                INDEX idx_email (email),
                INDEX idx_phone (phone),
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        """)
        
        # Create sessions table for JWT/auth management
        print("Creating sessions table...")
        cursor.execute("""
            CREATE TABLE sessions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                token VARCHAR(500) NOT NULL,
                refresh_token VARCHAR(500),
                device_info VARCHAR(255),
                ip_address VARCHAR(45),
                expires_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_token (token(255)),
                INDEX idx_user_id (user_id),
                INDEX idx_expires_at (expires_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)
        
        # Create transactions table with ALL types
        print("Creating transactions table...")
        cursor.execute("""
            CREATE TABLE transactions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                sender_id INT DEFAULT NULL,
                receiver_id INT DEFAULT NULL,
                amount DECIMAL(12, 2) NOT NULL,
                type ENUM(
                    'add', 
                    'send', 
                    'bank_transfer', 
                    'college_payment', 
                    'mobile_topup', 
                    'bill_payment', 
                    'shopping'
                ) NOT NULL,
                status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'completed',
                reference_id VARCHAR(100) UNIQUE,  -- For external references (Stripe, etc)
                metadata JSON,  -- Store additional transaction details
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE SET NULL,
                FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE SET NULL,
                INDEX idx_sender_id (sender_id),
                INDEX idx_receiver_id (receiver_id),
                INDEX idx_type (type),
                INDEX idx_status (status),
                INDEX idx_created_at (created_at),
                INDEX idx_reference_id (reference_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)
        
        # Create audit log table
        print("Creating audit_logs table...")
        cursor.execute("""
            CREATE TABLE audit_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT,
                action VARCHAR(100) NOT NULL,
                entity_type VARCHAR(50),
                entity_id INT,
                old_value JSON,
                new_value JSON,
                ip_address VARCHAR(45),
                user_agent TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
                INDEX idx_user_id (user_id),
                INDEX idx_action (action),
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)
        
        connection.commit()
        
        # Verify tables
        print("\n✅ Tables created successfully!")
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        print("\nTables in ewallet database:")
        for table in tables:
            print(f"  ✓ {list(table.values())[0]}")
        
        # Show structures
        for table_name in ['users', 'sessions', 'transactions', 'audit_logs']:
            print(f"\n📋 {table_name} table structure:")
            cursor.execute(f"DESCRIBE {table_name}")
            for row in cursor.fetchall():
                print(f"  {row}")

except Exception as e:
    print(f"❌ Error: {e}")
    connection.rollback()
finally:
    connection.close()
    print("\n✅ Database setup complete!")