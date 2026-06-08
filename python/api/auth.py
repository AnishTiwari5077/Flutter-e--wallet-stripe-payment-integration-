from flask import Blueprint, request, jsonify
import bcrypt
from api.db import db

auth_bp = Blueprint('auth', __name__)

# ---------------- REGISTER USER ----------------
@auth_bp.route("/register", methods=["POST"])
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
@auth_bp.route("/login", methods=["POST"])
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
