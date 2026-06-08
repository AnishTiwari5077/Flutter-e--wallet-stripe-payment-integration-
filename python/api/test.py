from flask import Blueprint, jsonify
from api.db import db

test_bp = Blueprint('test', __name__)

# ---------------- TEST DB CONNECTION ----------------
@test_bp.route("/test-db")
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
