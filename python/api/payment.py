from flask import Blueprint, request, jsonify
import stripe
import os
from api.db import db

payment_bp = Blueprint('payment', __name__)

# Stripe API Key — raise loudly if missing, never fall back to a placeholder
stripe.api_key = os.environ["STRIPE_SECRET_KEY"]

# ---------------- PROCESS DEPOSIT (DIRECT CARD) ----------------
@payment_bp.route("/process-deposit", methods=["POST"])
def process_deposit():
    data = request.json
    user_id = data.get("user_id")
    amount = float(data.get("amount", 0))
    card_number = data.get("card_number")
    exp_month = data.get("exp_month")
    exp_year = data.get("exp_year")
    cvc = data.get("cvc")
    idempotency_key = request.headers.get("Idempotency-Key")
    
    if amount <= 0 or not user_id or not card_number or not exp_month or not exp_year or not cvc:
        return jsonify({"error": "Invalid parameters"}), 400
    
    amount_in_cents = int(amount * 100)

    try:
        # 1. Check idempotency FIRST (close connection before charging Stripe)
        if idempotency_key:
            conn = db()
            cur = conn.cursor()
            try:
                cur.execute("SELECT id FROM transactions WHERE idempotency_key=%s", (idempotency_key,))
                if cur.fetchone():
                    cur.execute("SELECT id, name, email, phone, avatar, balance FROM users WHERE id=%s", (user_id,))
                    user = cur.fetchone()
                    return jsonify({"success": True, "message": "Deposit successful (Recovered)", "user": user}), 200
            finally:
                cur.close()
                conn.close()

        # Check for Stripe test cards to bypass raw card data restriction
        clean_card = card_number.replace(" ", "").replace("-", "")
        card_param = {}
        
        if clean_card == "4242424242424242":
            card_param = {"token": "tok_visa"}
        elif clean_card.startswith("5555555555554444"):
            card_param = {"token": "tok_mastercard"}
        else:
            card_param = {
                "number": card_number,
                "exp_month": exp_month,
                "exp_year": exp_year,
                "cvc": cvc,
            }

        # 2. Create PaymentMethod
        payment_method = stripe.PaymentMethod.create(
            type="card",
            card=card_param,  # type: ignore
        )
        
        # 3. Create and confirm PaymentIntent without redirects
        intent_kwargs = {
            "amount": amount_in_cents,
            "currency": "usd",
            "payment_method": payment_method.id,
            "confirm": True,
            "automatic_payment_methods": {"enabled": True, "allow_redirects": "never"}
        }
        if idempotency_key:
            intent_kwargs["idempotency_key"] = idempotency_key

        intent = stripe.PaymentIntent.create(**intent_kwargs)  # type: ignore
        
        if intent.status == "succeeded":
            # 4. Update balance — if this fails, Stripe already charged the card.
            # We log the Stripe intent ID so the charge can be manually reconciled.
            conn = db()
            cur = conn.cursor()
            try:
                cur.execute("UPDATE users SET balance = balance + %s WHERE id=%s", (amount, user_id))
                cur.execute(
                    """INSERT INTO transactions 
                       (sender_id, receiver_id, amount, type, idempotency_key, reference_id) 
                       VALUES (%s,%s,%s,'add',%s,%s)""",
                    (None, user_id, amount, idempotency_key, intent.id)
                )
                conn.commit()
                
                cur.execute("SELECT id, name, email, phone, avatar, balance FROM users WHERE id=%s", (user_id,))
                user = cur.fetchone()
                
                return jsonify({"success": True, "message": "Deposit successful", "user": user}), 200
            except Exception as db_err:
                conn.rollback()
                # CRITICAL: Stripe was charged but DB update failed.
                # The intent.id is needed to manually reconcile / issue refund.
                print(f"🚨 CRITICAL: Stripe charged {intent.id} but DB update failed for user {user_id}: {db_err}")
                return jsonify({
                    "error": f"Payment recorded by Stripe but balance update failed. "
                             f"Please contact support with reference: {intent.id}"
                }), 500
            finally:
                cur.close()
                conn.close()
        else:
            return jsonify({"error": "Payment failed"}), 400

    except stripe.error.CardError as e:
        return jsonify({"error": e.user_message}), 400
    except Exception as e:
        print(f"❌ Process deposit error: {e}")
        return jsonify({"error": str(e)}), 500

# ---------------- CREATE PAYMENT INTENT (STRIPE) ----------------
@payment_bp.route("/create-payment-intent", methods=["POST"])
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
@payment_bp.route("/payment-success", methods=["POST"])
def payment_success():
    data = request.json
    user_id = data.get("user_id")
    amount = float(data.get("amount", 0))
    idempotency_key = request.headers.get("Idempotency-Key")
    
    if not user_id or amount <= 0:
        return jsonify({"error": "Invalid user_id or amount"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        if idempotency_key:
            cur.execute("SELECT id FROM transactions WHERE idempotency_key=%s", (idempotency_key,))
            if cur.fetchone():
                cur.execute("SELECT id, name, email, phone, avatar, balance FROM users WHERE id=%s", (user_id,))
                user = cur.fetchone()
                return jsonify({"message": "Balance updated (Recovered)", "user": user}), 200

        # Atomically update user balance
        cur.execute("UPDATE users SET balance = balance + %s WHERE id=%s", (amount, user_id))
        
        # Record the transaction (type 'add' for wallet top-up)
        cur.execute(
            "INSERT INTO transactions (sender_id, receiver_id, amount, type, idempotency_key) VALUES (%s,%s,%s,'add',%s)",
            (None, user_id, amount, idempotency_key)
        )
        conn.commit()
        
        # Fetch and return updated user data, selecting the 'avatar' column
        cur.execute("SELECT id, name, email, phone, avatar, balance FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        
        print(f"✅ Balance updated: ${amount} added to user {user_id}")
        
        return jsonify({"message": "Balance updated", "user": user}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ Payment success error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- SEND MONEY (P2P TRANSFER) ----------------
@payment_bp.route("/send", methods=["POST"])
def send_money():
    data = request.json
    sender_id = data.get("sender_id")
    phone = data.get("phone")
    amount = float(data.get("amount", 0))
    idempotency_key = request.headers.get("Idempotency-Key")
    
    if not sender_id or not phone or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        if idempotency_key:
            cur.execute("SELECT id FROM transactions WHERE idempotency_key=%s", (idempotency_key,))
            if cur.fetchone():
                return jsonify({"message": "Money sent successfully! (Recovered)"}), 200

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
            "INSERT INTO transactions (sender_id, receiver_id, amount, type, idempotency_key) VALUES (%s,%s,%s,'send',%s)",
            (sender_id, receiver_id, amount, idempotency_key)
        )
        conn.commit()
        
        print(f"✅ Money sent: ${amount} from {sender_id} to {receiver_id}")
        
        return jsonify({"message": "Money sent successfully!"}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ Send money error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- BANK TRANSFER (WITHDRAWAL) ----------------
@payment_bp.route("/bank-transfer", methods=["POST"])
def bank_transfer():
    data = request.json
    user_id = data.get("user_id")
    account_number = data.get("account_number")
    bank_name = data.get("bank_name")
    amount = float(data.get("amount", 0))
    idempotency_key = request.headers.get("Idempotency-Key")
    
    if not user_id or not account_number or not bank_name or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        if idempotency_key:
            cur.execute("SELECT id FROM transactions WHERE idempotency_key=%s", (idempotency_key,))
            if cur.fetchone():
                return jsonify({"message": f"Bank transfer of ${amount} to {bank_name} successful! (Recovered)"}), 200

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
            "INSERT INTO transactions (sender_id, receiver_id, amount, type, idempotency_key) VALUES (%s,%s,%s,'bank_transfer',%s)",
            (user_id, None, amount, idempotency_key)
        )
        conn.commit()
        
        print(f"✅ Bank transfer: ${amount} withdrawn by user {user_id}")
        
        return jsonify({"message": f"Bank transfer of ${amount} to {bank_name} successful!"}), 200
    except Exception as e:
        conn.rollback()
        print(f"❌ Bank transfer error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# ---------------- COLLEGE PAYMENT ----------------
@payment_bp.route("/college-payment", methods=["POST"])
def college_payment():
    data = request.json
    user_id = data.get("user_id")
    student_id = data.get("student_id")
    college_name = data.get("college_name")
    semester = data.get("semester")
    amount = float(data.get("amount", 0))
    idempotency_key = request.headers.get("Idempotency-Key")
    
    if not user_id or not student_id or not college_name or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        if idempotency_key:
            cur.execute("SELECT id FROM transactions WHERE idempotency_key=%s", (idempotency_key,))
            if cur.fetchone():
                return jsonify({"message": f"College payment of ${amount} for {semester} successful! (Recovered)"}), 200

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
            "INSERT INTO transactions (sender_id, receiver_id, amount, type, idempotency_key) VALUES (%s,%s,%s,'college_payment',%s)",
            (user_id, None, amount, idempotency_key)
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
@payment_bp.route("/mobile-topup", methods=["POST"])
def mobile_topup():
    data = request.json
    user_id = data.get("user_id")
    phone_number = data.get("phone_number")
    operator = data.get("operator")
    amount = float(data.get("amount", 0))
    idempotency_key = request.headers.get("Idempotency-Key")
    
    if not user_id or not phone_number or not operator or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        if idempotency_key:
            cur.execute("SELECT id FROM transactions WHERE idempotency_key=%s", (idempotency_key,))
            if cur.fetchone():
                return jsonify({"message": f"Mobile topup of ${amount} to {phone_number} successful! (Recovered)"}), 200

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
            "INSERT INTO transactions (sender_id, receiver_id, amount, type, idempotency_key) VALUES (%s,%s,%s,'mobile_topup',%s)",
            (user_id, None, amount, idempotency_key)
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
@payment_bp.route("/bill-payment", methods=["POST"])
def bill_payment():
    data = request.json
    user_id = data.get("user_id")
    bill_type = data.get("bill_type") # e.g., 'electricity', 'water', 'internet'
    account_number = data.get("account_number")
    amount = float(data.get("amount", 0))
    idempotency_key = request.headers.get("Idempotency-Key")
    
    if not user_id or not bill_type or not account_number or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        if idempotency_key:
            cur.execute("SELECT id FROM transactions WHERE idempotency_key=%s", (idempotency_key,))
            if cur.fetchone():
                return jsonify({"message": f"{bill_type.capitalize()} bill payment of ${amount} successful! (Recovered)"}), 200

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
            "INSERT INTO transactions (sender_id, receiver_id, amount, type, idempotency_key) VALUES (%s,%s,%s,'bill_payment',%s)",
            (user_id, None, amount, idempotency_key)
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
@payment_bp.route("/shopping-payment", methods=["POST"])
def shopping_payment():
    data = request.json
    user_id = data.get("user_id")
    merchant_name = data.get("merchant_name")
    amount = float(data.get("amount", 0))
    idempotency_key = request.headers.get("Idempotency-Key")
    
    if not user_id or not merchant_name or amount <= 0:
        return jsonify({"error": "Invalid parameters"}), 400

    conn = db()
    cur = conn.cursor()
    try:
        if idempotency_key:
            cur.execute("SELECT id FROM transactions WHERE idempotency_key=%s", (idempotency_key,))
            if cur.fetchone():
                return jsonify({"message": f"Payment of ${amount} to {merchant_name} successful! (Recovered)"}), 200

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
            "INSERT INTO transactions (sender_id, receiver_id, amount, type, idempotency_key) VALUES (%s,%s,%s,'shopping',%s)",
            (user_id, None, amount, idempotency_key)
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
