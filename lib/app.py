from flask import Flask, request, jsonify
import pymysql
import bcrypt
import stripe
from flask_cors import CORS
import os


app = Flask(__name__)

CORS(app)


stripe.api_key = os.environ.get("STRIPE_SECRET_KEY", 
    "Your Api secret keys") 


DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_USER = os.environ.get("DB_USER", "root")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "your password")
DB_NAME = os.environ.get("DB_NAME", "ewallet")

# ---------------- DB CONNECTION ----------------
def db():
    """Establishes a connection to the MySQL database."""
    try:
        return pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            cursorclass=pymysql.cursors.DictCursor
        )
    except Exception as e:
        print(f"FATAL DB CONNECTION ERROR: {e}")
        raise e

# ---------------- REGISTER USER ----------------
@app.route("/register", methods=["POST"])
def register():
    data = request.json
    name = data.get("name")
    email = data.get("email")
    phone = data.get("phone", "")
    password = data.get("password")
    avatar = data.get("avatar", "")  # Consistent use of 'avatar'
    
    if not name or not email or not password:
        return jsonify({"error": "Missing required fields"}), 400
    
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    conn = db()
    cur = conn.cursor()
    try:
        # Check if email already exists
        cur.execute("SELECT id FROM users WHERE email=%s", (email,))
        if cur.fetchone():
            return jsonify({"error": "Email already registered"}), 400
        
        # Insert using 'avatar' column
        cur.execute(
            "INSERT INTO users (name, email, phone, password, avatar, balance) VALUES (%s,%s,%s,%s,%s,0)",
            (name, email, phone, hashed_password, avatar)
        )
        conn.commit()
        
        # Get the newly created user, selecting the 'avatar' column
        user_id = cur.lastrowid
        cur.execute("SELECT id, name, email, phone, avatar, balance FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        
        print(f"✅ User registered: {name} (Avatar size: {len(avatar)} bytes)")
        
        return jsonify({
            "user": user,
            "message": "User registered successfully!"
        }), 201
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Registration error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- LOGIN USER ----------------
@app.route("/login", methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")
    
    if not email or not password:
        return jsonify({"error": "Missing email or password"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        # Select user, selecting the 'avatar' column
        cur.execute("SELECT id, name, email, phone, password, avatar, balance FROM users WHERE email=%s", (email,))
        user = cur.fetchone()
        
        if not user:
            return jsonify({"error": "Invalid credentials"}), 401
        
        stored_password = user["password"]
        if isinstance(stored_password, str):
            stored_password = stored_password.encode('utf-8')
        
        if not bcrypt.checkpw(password.encode('utf-8'), stored_password):
            return jsonify({"error": "Invalid credentials"}), 401
        
        # Remove password before sending to client
        user.pop("password", None)
        
        # 'avatar' is already in the dictionary
        
        print(f"✅ User logged in: {user['name']} (Avatar size: {len(user.get('avatar', ''))} bytes)")
        
        return jsonify({"user": user}), 200
        
    except Exception as e:
        print(f"❌ Login error: {e}")
        return jsonify({"error": "Login failed"}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- GET USER DATA ----------------
@app.route("/user/<int:id>")
def get_user(id):
    conn = db()
    cur = conn.cursor()
    try:
        # Select 'avatar' from database
        cur.execute("SELECT id, name, email, phone, avatar, balance FROM users WHERE id=%s", (id,))
        user = cur.fetchone()
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        # 'avatar' is already the correct key
        
        print(f"✅ Fetched user: {user['name']} (Avatar size: {len(user.get('avatar', ''))} bytes)")
        
        return jsonify(user), 200
    except Exception as e:
        print(f"❌ Get user error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- UPDATE USER PROFILE ----------------
@app.route("/user/<int:id>", methods=["PUT"])
def update_user(id):
    data = request.json
    name = data.get("name")
    phone = data.get("phone")
    avatar = data.get("avatar") # Consistent use of 'avatar'
    
    conn = db()
    cur = conn.cursor()
    try:
        # Build dynamic update query
        updates = []
        values = []
        
        if name is not None:
            updates.append("name = %s")
            values.append(name)
        
        if phone is not None:
            updates.append("phone = %s")
            values.append(phone)
        
        if avatar is not None:
            # Update 'avatar' column
            updates.append("avatar = %s")
            values.append(avatar)
            print(f"🖼️  Updating avatar (size: {len(avatar)} bytes)")
        
        if not updates:
            return jsonify({"error": "No fields to update"}), 400
        
        values.append(id)
        
        sql = f"UPDATE users SET {', '.join(updates)} WHERE id=%s"
        cur.execute(sql, values)
        conn.commit()
        
        # Fetch updated user, selecting the 'avatar' column
        cur.execute("SELECT id, name, email, phone, avatar, balance FROM users WHERE id=%s", (id,))
        user = cur.fetchone()
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        print(f"✅ Profile updated for ID: {id}")
        
        return jsonify({
            "success": True,
            "user": user,
            "message": "Profile updated successfully"
        }), 200
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Update profile error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- CREATE PAYMENT INTENT (STRIPE) ----------------
@app.route("/create-payment-intent", methods=["POST"])
def create_payment_intent():
    data = request.json
    amount = float(data.get("amount", 0)) 
    
    if amount <= 0:
        return jsonify({"error": "Invalid amount"}), 400
    
    # Stripe requires amount in cents
    amount_in_cents = int(amount * 100)

    try:
        intent = stripe.PaymentIntent.create(
            amount=amount_in_cents,
            currency="usd", # Hardcoded currency
        )
        return jsonify({"clientSecret": intent.client_secret}), 200
    except Exception as e:
        print(f"❌ Payment intent error: {e}")
        return jsonify({"error": str(e)}), 500

# ---------------- PAYMENT SUCCESS (UPDATE BALANCE) ----------------
@app.route("/payment-success", methods=["POST"])
def payment_success():
    data = request.json
    user_id = data.get("user_id")
    amount = float(data.get("amount", 0))
    
    if not user_id or amount <= 0:
        return jsonify({"error": "Invalid user_id or amount"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        # Atomically update user balance
        cur.execute("UPDATE users SET balance = balance + %s WHERE id=%s", (amount, user_id))
        
        # Record the transaction (type 'add' for wallet top-up)
        cur.execute(
            "INSERT INTO transactions (sender_id, receiver_id, amount, type) VALUES (%s,%s,%s,'add')",
            (None, user_id, amount)
        )
        conn.commit()
        
        # Fetch and return updated user data, selecting the 'avatar' column
        cur.execute("SELECT id, name, email, phone, avatar, balance FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        
        print(f" Balance updated: ${amount} added to user {user_id}")
        
        return jsonify({"message": "Balance updated", "user": user}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ Payment success error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- SEND MONEY (P2P TRANSFER) ----------------
@app.route("/send", methods=["POST"])
def send_money():
    data = request.json
    sender_id = data.get("sender_id")
    phone = data.get("phone")
    amount = float(data.get("amount", 0))
    
    if not sender_id or not phone or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        # Find receiver by phone number
        cur.execute("SELECT id FROM users WHERE phone=%s", (phone,))
        receiver = cur.fetchone()
        if not receiver:
            return jsonify({"error": "Receiver not found"}), 404
        receiver_id = receiver["id"]
        
        if int(sender_id) == receiver_id:
            return jsonify({"error": "Cannot send money to yourself"}), 400

        # Check sender's balance
        cur.execute("SELECT balance FROM users WHERE id=%s", (sender_id,))
        sender = cur.fetchone()
        if not sender:
            return jsonify({"error": "Sender not found"}), 404
            
        if sender["balance"] < amount:
            return jsonify({"error": "Insufficient balance"}), 400

        # Transaction block: Debit sender, Credit receiver, Record transaction
        cur.execute("UPDATE users SET balance = balance - %s WHERE id=%s", (amount, sender_id))
        cur.execute("UPDATE users SET balance = balance + %s WHERE id=%s", (amount, receiver_id))
        cur.execute(
            "INSERT INTO transactions (sender_id, receiver_id, amount, type) VALUES (%s,%s,%s,'send')",
            (sender_id, receiver_id, amount)
        )
        conn.commit()
        
        print(f" Money sent: ${amount} from {sender_id} to {receiver_id}")
        
        return jsonify({"message": "Money sent successfully!"}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ Send money error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- BANK TRANSFER (WITHDRAWAL) ----------------
@app.route("/bank-transfer", methods=["POST"])
def bank_transfer():
    data = request.json
    user_id = data.get("user_id")
    account_number = data.get("account_number")
    bank_name = data.get("bank_name")
    amount = float(data.get("amount", 0))
    
    if not user_id or not account_number or not bank_name or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        # Check balance
        cur.execute("SELECT balance FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        if user["balance"] < amount:
            return jsonify({"error": "Insufficient balance"}), 400

        # Debit user's balance
        cur.execute("UPDATE users SET balance = balance - %s WHERE id=%s", (amount, user_id))
        
        # Record transaction (receiver_id is NULL for external transfers)
        cur.execute(
            "INSERT INTO transactions (sender_id, receiver_id, amount, type) VALUES (%s,%s,%s,'bank_transfer')",
            (user_id, None, amount)
        )
        conn.commit()
        
        print(f" Bank transfer: ${amount} withdrawn by user {user_id}")
        
        return jsonify({"message": f"Bank transfer of ${amount} to {bank_name} successful!"}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ Bank transfer error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- COLLEGE PAYMENT ----------------
@app.route("/college-payment", methods=["POST"])
def college_payment():
    data = request.json
    user_id = data.get("user_id")
    student_id = data.get("student_id")
    college_name = data.get("college_name")
    semester = data.get("semester")
    amount = float(data.get("amount", 0))
    
    if not user_id or not student_id or not college_name or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        # Check balance
        cur.execute("SELECT balance FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        if user["balance"] < amount:
            return jsonify({"error": "Insufficient balance"}), 400

        # Debit user's balance
        cur.execute("UPDATE users SET balance = balance - %s WHERE id=%s", (amount, user_id))
        
        # Record transaction (receiver_id is NULL for external payments)
        cur.execute(
            "INSERT INTO transactions (sender_id, receiver_id, amount, type) VALUES (%s,%s,%s,'college_payment')",
            (user_id, None, amount)
        )
        conn.commit()
        
        print(f"✅ College payment: ${amount} paid by user {user_id} for {college_name}")
        
        return jsonify({"message": f"College payment of ${amount} for {semester} successful!"}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ College payment error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- MOBILE TOPUP ----------------
@app.route("/mobile-topup", methods=["POST"])
def mobile_topup():
    data = request.json
    user_id = data.get("user_id")
    phone_number = data.get("phone_number")
    operator = data.get("operator")
    amount = float(data.get("amount", 0))
    
    if not user_id or not phone_number or not operator or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        # Check balance
        cur.execute("SELECT balance FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        if user["balance"] < amount:
            return jsonify({"error": "Insufficient balance"}), 400

        # Debit user's balance
        cur.execute("UPDATE users SET balance = balance - %s WHERE id=%s", (amount, user_id))
        
        # Record transaction
        cur.execute(
            "INSERT INTO transactions (sender_id, receiver_id, amount, type) VALUES (%s,%s,%s,'mobile_topup')",
            (user_id, None, amount)
        )
        conn.commit()
        
        print(f"✅ Mobile topup: ${amount} to {phone_number} by user {user_id}")
        
        return jsonify({"message": f"Mobile topup of ${amount} to {phone_number} successful!"}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ Mobile topup error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- BILL PAYMENT ----------------
@app.route("/bill-payment", methods=["POST"])
def bill_payment():
    data = request.json
    user_id = data.get("user_id")
    bill_type = data.get("bill_type") # e.g., 'electricity', 'water', 'internet'
    account_number = data.get("account_number")
    amount = float(data.get("amount", 0))
    
    if not user_id or not bill_type or not account_number or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        # Check balance
        cur.execute("SELECT balance FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        if user["balance"] < amount:
            return jsonify({"error": "Insufficient balance"}), 400

        # Debit user's balance
        cur.execute("UPDATE users SET balance = balance - %s WHERE id=%s", (amount, user_id))
        
        # Record transaction
        cur.execute(
            "INSERT INTO transactions (sender_id, receiver_id, amount, type) VALUES (%s,%s,%s,'bill_payment')",
            (user_id, None, amount)
        )
        conn.commit()
        
        print(f"✅ Bill payment: ${amount} for {bill_type} by user {user_id}")
        
        return jsonify({"message": f"{bill_type.capitalize()} bill payment of ${amount} successful!"}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ Bill payment error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- SHOPPING PAYMENT ----------------
@app.route("/shopping-payment", methods=["POST"])
def shopping_payment():
    data = request.json
    user_id = data.get("user_id")
    merchant_name = data.get("merchant_name")
    amount = float(data.get("amount", 0))
    
    if not user_id or not merchant_name or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        # Check balance
        cur.execute("SELECT balance FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        if user["balance"] < amount:
            return jsonify({"error": "Insufficient balance"}), 400

        # Debit user's balance
        cur.execute("UPDATE users SET balance = balance - %s WHERE id=%s", (amount, user_id))
        
        # Record transaction
        cur.execute(
            "INSERT INTO transactions (sender_id, receiver_id, amount, type) VALUES (%s,%s,%s,'shopping')",
            (user_id, None, amount)
        )
        conn.commit()
        
        print(f"✅ Shopping payment: ${amount} to {merchant_name} by user {user_id}")
        
        return jsonify({"message": f"Payment of ${amount} to {merchant_name} successful!"}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ Shopping payment error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- GET ALL TRANSACTIONS ----------------
@app.route("/transactions")
def get_transactions():
    """Fetches all transactions, joining with user names/phones for context."""
    conn = db()
    cur = conn.cursor()
    try:
        sql = """
            SELECT 
                t.id AS transaction_id,
                t.amount,
                t.type,
                t.created_at,
                sender.name AS sender_name,
                sender.phone AS sender_phone,
                receiver.name AS receiver_name,
                receiver.phone AS receiver_phone
            FROM transactions t
            LEFT JOIN users sender ON t.sender_id = sender.id
            LEFT JOIN users receiver ON t.receiver_id = receiver.id
            ORDER BY t.created_at DESC
        """
        cur.execute(sql)
        transactions = cur.fetchall()
        return jsonify(transactions), 200
    except Exception as e:
        print(f"❌ Get transactions error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- GET TRANSACTIONS BY USER ----------------
@app.route("/transactions/<int:user_id>")
def get_user_transactions(user_id):
    """Fetches transactions relevant to a specific user (as sender or receiver)."""
    conn = db()
    cur = conn.cursor()
    try:
        sql = """
            SELECT 
                t.id AS transaction_id,
                t.sender_id,
                t.receiver_id,
                t.amount,
                t.type,
                t.created_at,
                sender.name AS sender_name,
                sender.phone AS sender_phone,
                receiver.name AS receiver_name,
                receiver.phone AS receiver_phone
            FROM transactions t
            LEFT JOIN users sender ON t.sender_id = sender.id
            LEFT JOIN users receiver ON t.receiver_id = receiver.id
            WHERE t.sender_id=%s OR t.receiver_id=%s
            ORDER BY t.created_at DESC
        """
        cur.execute(sql, (user_id, user_id))
        transactions = cur.fetchall()
        return jsonify(transactions), 200
    except Exception as e:
        print(f"❌ Get user transactions error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- TEST DB CONNECTION ----------------
@app.route("/test-db")
def test_db():
    conn = db()
    cur = conn.cursor()
    try:
        cur.execute("SELECT 1")
        return jsonify({"status": "DB Connected!"}), 200
    except Exception as e:
        print(f"❌ DB test error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":

    app.run(host="0.0.0.0", port=5000, debug=True)


