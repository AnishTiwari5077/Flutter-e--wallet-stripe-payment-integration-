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

## 🤝 Contributing
1. Follow PEP8 and use autoformatters (`black`).
2. Write unit tests for new logic.
3. Keep secrets out of your commits! Ensure `.env` remains in `.gitignore`.
