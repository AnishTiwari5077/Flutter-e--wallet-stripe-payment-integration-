from flask import Blueprint, request, jsonify
from api.db import db

user_bp = Blueprint('user', __name__)

# ---------------- GET USER DATA ----------------
@user_bp.route("/<int:id>")
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
@user_bp.route("/<int:id>", methods=["PUT"])
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
