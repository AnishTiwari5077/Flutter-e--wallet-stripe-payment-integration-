# 💳 E‑Wallet & Stripe Payment Integration

**Flask • MySQL • Stripe • Flutter**

> A robust, production‑grade backend for an electronic wallet system. Built with Python (Flask), MySQL, and Stripe for payment processing. Designed for reliability, security, observability, and maintainability.

---

## 📸 Screenshots

Here is a glimpse of the E-Wallet interface:

| Dashboard | Transfer | Payment | Profile |
|:---:|:---:|:---:|:---:|
| <img width="200" src="https://github.com/user-attachments/assets/3b95a628-5bd2-499a-8a34-6a11d67f2dfa" /> | <img width="200" src="https://github.com/user-attachments/assets/5d47de05-fe92-452d-ba24-c3dd0392ceca" /> | <img width="200" src="https://github.com/user-attachments/assets/97969fd2-cb7e-47c8-9f82-d6018a245c63" /> | <img width="200" src="https://github.com/user-attachments/assets/590576a0-4690-4e71-8d37-716cd5aad783" /> |
| <img width="200" src="https://github.com/user-attachments/assets/6b27f1d3-43fd-4089-a462-b87d0e3292b5" /> | <img width="200" src="https://github.com/user-attachments/assets/26cda236-42ac-480c-ad57-a7a2edf3c103" /> | <img width="200" src="https://github.com/user-attachments/assets/ce449b78-0929-479f-bc70-560711ad47ba" /> | <img width="200" src="https://github.com/user-attachments/assets/291f990d-1c6c-4116-8795-4c9f0cc2d3e0" /> |

*(Additional screens available in the repository assets)*

---

## 🌟 Key Features

This service provides the backend for an E‑Wallet product that supports:

* 🔐 **Authentication**: User registration, login, and camera uploads.
* 💰 **Digital Wallets**: Per‑user wallets and multi‑currency balances.
* 💳 **Card Deposits**: Integration with Stripe Payment Intents.
* 🔄 **P2P Transfers**: In‑app transfers (wallet → wallet).
* 🏦 **Bank Payouts**: External bank transfers and withdrawals.
* 🎓 **Institutional Payments**: College fee transfers with structured metadata.
* 📱 **Mobile Top-ups**: Third‑party integrations for operator top-ups.
* 🧾 **Audit Trails**: Transactional audit logging and reconciliation.

---

## 🚀 Getting Started

### 1. Prerequisites
- Python 3.10+
- MySQL Server (XAMPP/WAMP or standalone)

### 2. Environment Setup
1. Open the `python` directory.
2. Create a virtual environment and install dependencies:
   ```bash
   python -m venv venv
   .\venv\Scripts\Activate.ps1   # On Windows
   pip install -r requirements.txt
   ```
3. Create a `.env` file in the `python/` folder and configure your secrets:
   ```env
   # Stripe Configuration
   STRIPE_SECRET_KEY=sk_test_YOUR_ACTUAL_STRIPE_KEY_HERE

   # Database Configuration
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_actual_db_password
   DB_NAME=ewallet
   ```

### 3. Database Initialization
Ensure your MySQL server is running, then automatically build your tables:
```bash
cd python
python create.py
```

### 4. Run the Server
```bash
cd python
python app.py
```
The Flask API will start running on `http://0.0.0.0:5000/`.

---

## 🏗️ Architecture & Data Model

**High Level Flow:**
```text
Client (Web/Mobile) ──> Flask REST API ──> Service Layer ──> MySQL
                                         │
                                         ├─> Stripe API (Payment Intents)
                                         └─> Background Workers
```

### Core Data Models:
* **`users`**: Manages authentication, KYC status, and base details.
* **`wallets` / balances**: Stored securely using precise integer minor units (e.g., cents).
* **`transactions`**: Tracks deposits, withdrawals, transfers, and top-ups (`pending`, `completed`, `failed`).
* **`audit_logs`**: Permanent records for compliance and financial disputes.

> ⚠️ **Money Rule**: Never store or operate financial data in floating point. Always use integer minor units!

---

## 🛡️ Security & Idempotency

* **Idempotency**: Implemented for all payment flows to prevent accidental double credits.
* **Env Secrets**: Sensitive data (`DB_PASSWORD`, `STRIPE_SECRET_KEY`) is securely pulled from `.env` and excluded from source control.
* **Hashing**: Passwords securely hashed with `bcrypt`.

---

## 📡 API Reference

> Base URL: `http://<your-server-ip>:5000`
> All request/response bodies use **JSON**. Endpoints that mutate state accept an optional `Idempotency-Key` header to prevent double-processing.

---

### 🔐 Auth

#### `POST /register`
Register a new user.

**Request body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "secret123",
  "avatar": ""
}
```
**Response `201`:**
```json
{ "user": { "id": 1, "name": "John Doe", "email": "...", "phone": "...", "avatar": "", "balance": 0 }, "message": "User registered successfully!" }
```

---

#### `POST /login`
Authenticate a user and retrieve their profile.

**Request body:**
```json
{ "email": "john@example.com", "password": "secret123" }
```
**Response `200`:**
```json
{ "user": { "id": 1, "name": "John Doe", "email": "...", "phone": "...", "avatar": "", "balance": 250.0 } }
```

---

### 👤 User

#### `GET /user/<id>`
Fetch a user's profile and current balance.

**Response `200`:**
```json
{ "id": 1, "name": "John Doe", "email": "...", "phone": "...", "avatar": "", "balance": 250.0 }
```

---

#### `PUT /user/<id>`
Update a user's name, phone, or avatar.

**Request body** *(send only fields to update)*:
```json
{ "name": "Jane Doe", "phone": "+9876543210", "avatar": "<base64-string>" }
```
**Response `200`:**
```json
{ "success": true, "user": { ... }, "message": "Profile updated successfully" }
```

---

### 💳 Payments

> All payment endpoints accept an **`Idempotency-Key`** header (string UUID recommended). Requests with a previously seen key are safely replayed without double-charging.

#### `POST /process-deposit`
Charge a card via Stripe and credit the user's wallet. *(Test card: `4242 4242 4242 4242`)*

**Headers:** `Idempotency-Key: <uuid>` *(required)*

**Request body:**
```json
{
  "user_id": 1,
  "amount": 100.00,
  "card_number": "4242424242424242",
  "exp_month": 12,
  "exp_year": 2026,
  "cvc": "123"
}
```
**Response `200`:**
```json
{ "success": true, "message": "Deposit successful", "user": { "balance": 350.0, ... } }
```

---

#### `POST /create-payment-intent`
Create a Stripe PaymentIntent and return a `clientSecret` for front-end confirmation.

**Request body:**
```json
{ "amount": 50.00 }
```
**Response `200`:**
```json
{ "clientSecret": "pi_xxx_secret_xxx" }
```

---

#### `POST /payment-success`
Confirm a payment and update the user's balance after front-end Stripe confirmation.

**Headers:** `Idempotency-Key: <uuid>` *(optional but recommended)*

**Request body:**
```json
{ "user_id": 1, "amount": 50.00 }
```
**Response `200`:**
```json
{ "message": "Balance updated", "user": { "balance": 300.0, ... } }
```

---

#### `POST /send`
Transfer money between two users (P2P, wallet-to-wallet).

**Headers:** `Idempotency-Key: <uuid>` *(optional)*

**Request body:**
```json
{ "sender_id": 1, "phone": "+9876543210", "amount": 150.00 }
```
**Response `200`:**
```json
{ "message": "Money sent successfully!" }
```

---

#### `POST /bank-transfer`
Withdraw funds from the wallet to an external bank account.

**Headers:** `Idempotency-Key: <uuid>` *(optional)*

**Request body:**
```json
{ "user_id": 1, "account_number": "9876543210", "bank_name": "Chase", "amount": 75.00 }
```
**Response `200`:**
```json
{ "message": "Bank transfer of $75.0 to Chase successful!" }
```

---

#### `POST /college-payment`
Pay institutional (college/university) fees from the wallet.

**Headers:** `Idempotency-Key: <uuid>` *(optional)*

**Request body:**
```json
{ "user_id": 1, "student_id": "STU001", "college_name": "MIT", "semester": "Fall 2026", "amount": 500.00 }
```
**Response `200`:**
```json
{ "message": "College payment of $500.0 for Fall 2026 successful!" }
```

---

#### `POST /mobile-topup`
Top-up a mobile number via a third-party operator.

**Headers:** `Idempotency-Key: <uuid>` *(optional)*

**Request body:**
```json
{ "user_id": 1, "phone_number": "+1234567890", "operator": "Verizon", "amount": 20.00 }
```
**Response `200`:**
```json
{ "message": "Mobile topup of $20.0 to +1234567890 successful!" }
```

---

#### `POST /bill-payment`
Pay utility or service bills (electricity, water, internet, etc.).

**Headers:** `Idempotency-Key: <uuid>` *(optional)*

**Request body:**
```json
{ "user_id": 1, "bill_type": "electricity", "account_number": "ACC123", "amount": 45.00 }
```
**Response `200`:**
```json
{ "message": "Electricity bill payment of $45.0 successful!" }
```

---

#### `POST /shopping-payment`
Pay a merchant for a shopping transaction.

**Headers:** `Idempotency-Key: <uuid>` *(optional)*

**Request body:**
```json
{ "user_id": 1, "merchant_name": "Amazon", "amount": 199.99 }
```
**Response `200`:**
```json
{ "message": "Payment of $199.99 to Amazon successful!" }
```

---

### 🧾 Transactions

#### `GET /transactions/`
List all transactions across all users (with sender/receiver names and phones).

**Response `200`:** Array of transaction objects.

---

#### `GET /transactions/<user_id>`
List all transactions where the user is either the sender or receiver.

**Response `200`:** Array of transaction objects:
```json
[
  {
    "transaction_id": 5,
    "sender_id": 1,
    "receiver_id": 2,
    "amount": 150.0,
    "type": "send",
    "created_at": "2026-06-09T09:54:41",
    "sender_name": "John Doe",
    "sender_phone": "+1234567890",
    "receiver_name": "Jane Doe",
    "receiver_phone": "+9876543210"
  }
]
```

---

## 🤝 Contributing
1. Follow PEP8 and use autoformatters (`black`).
2. Write unit tests for new logic.
3. Keep secrets out of your commits! Ensure `.env` remains in `.gitignore`.
