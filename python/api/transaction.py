from flask import Blueprint, jsonify
from api.db import db

transaction_bp = Blueprint('transaction', __name__)

# ---------------- GET ALL TRANSACTIONS ----------------
@transaction_bp.route("/")
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
@transaction_bp.route("/<int:user_id>")
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
