
# E‑Wallet using Stripe payment integration using my SQl 

**Flask • MySQL • Stripe**

> A robust, production‑grade backend for an electronic wallet system. Built with Python (Flask), MySQL, and Stripe for payment processing. Designed for reliability, security, observability, and maintainability.



---

## 1. Project summary

This service provides the backend for an E‑Wallet product that supports:

* User registration, authentication,upload camera
* Per‑user wallets and multi‑currency balances (stored in minor units)
* Deposits (card payments) via Stripe
* In‑app transfers (wallet → wallet)
* Bank payouts (external bank transfers / payouts)
* Institutional/college transfers with structured metadata
* Mobile operator top‑ups (third‑party integration)
* Transactional audit trail and reconciliation utilities

Primary goals: **correct money handling**, **fault tolerance**, **security**, and **clear operational observability**.

---


####screenshot

<img width="315" height="700" alt="Screenshot_1764834662" src="https://github.com/user-attachments/assets/3b95a628-5bd2-499a-8a34-6a11d67f2dfa" />
<img width="315" height="700" alt="Screenshot_1764834656" src="https://github.com/user-attachments/assets/5d47de05-fe92-452d-ba24-c3dd0392ceca" />
<img width="315" height="700" alt="Screenshot_1764834760" src="https://github.com/user-attachments/assets/97969fd2-cb7e-47c8-9f82-d6018a245c63" />
<img width="315" height="700" alt="Screenshot_1764834810" src="https://github.com/user-attachments/assets/590576a0-4690-4e71-8d37-716cd5aad783" />
<img width="315" height="700" alt="Screenshot_1764834766" src="https://github.com/user-attachments/assets/6b27f1d3-43fd-4089-a462-b87d0e3292b5" />
<img width="315" height="700" alt="Screenshot_1764835971" src="https://github.com/user-attachments/assets/26cda236-42ac-480c-ad57-a7a2edf3c103" />
<img width="315" height="700" alt="Screenshot_1764834837" src="https://github.com/user-attachments/assets/ce449b78-0929-479f-bc70-560711ad47ba" />
<img width="315" height="700" alt="Screenshot_1764834834" src="https://github.com/user-attachments/assets/291f990d-1c6c-4116-8795-4c9f0cc2d3e0" />
<img width="315" height="700" alt="Screenshot_1764834826" src="https://github.com/user-attachments/assets/8ddc39b6-4485-4971-a8ef-eccf6d573e52" />
<img width="315" height="700" alt="Screenshot_1764834822" src="https://github.com/user-attachments/assets/4a29fd65-a719-405c-b97f-0fb35d3eb88b" />
<img width="315" height="700" alt="Screenshot_1764834817" src="https://github.com/user-attachments/assets/5f812fc8-d818-4ca8-b948-943a37305ca9" />
<img width="315" height="700" alt="Screenshot_1764834813" src="https://github.com/user-attachments/assets/1a3eea8c-1202-4250-b238-362b4662573a" />
<img width="315" height="700" alt="Screenshot_1764834786" src="https://github.com/user-attachments/assets/11d6bb89-bef6-421d-91f4-c3bda59d44d6" />
<img width="315" height="700" alt="Screenshot_1764834781" src="https://github.com/user-attachments/assets/5e51cc67-e673-464e-8b65-926042f13e18" />
<img width="315" height="700" alt="Screenshot_1764834773" src="https://github.com/user-attachments/assets/b0c29d1a-0ee0-43e4-b609-e1d0a48ca4e3" />
<img width="315" height="700" alt="Screenshot_1764834766" src="https://github.com/user-attachments/assets/5747b8a8-68bc-410b-97a9-0f5bb579d005" />






## . Key capabilities

* **Safe money arithmetic** using integers (cents/paise)
* **Idempotent payment flows** to prevent double credits
* **Webhook‑driven reconciliation** for external payment confirmations
* **Background workers** for long‑running payouts and retries
* **Comprehensive audit logs** for financial compliance and dispute handling
* **Structured API responses** and standardized error codes

---

## 3. Architecture overview

High level:

```
Client (Web/Mobile) ──> Flask REST API ──> Service Layer ──> Repositories (MySQL)
                                         │
                                         ├─> Stripe (PaymentIntents)
                                         ├─> Background Workers (Celery/RQ + Redis)
                                         └─> External Topup Provider / Bank API
```

* Use **JWT** for user authentication and refresh tokens for session management.
* Use **database transactions** for all wallet balance changes and ledger writes.
* Offload external calls (bank payouts, topups) to background workers with retries and exponential backoff.

---








## . Detailed data model (summary)

Use SQLAlchemy models in `models/`. Example core fields:

### users

* id: UUID (PK)
* email: varchar (unique)
* password_hash: varchar
* phone: varchar
* kyc_status: enum (none, pending, verified, rejected)
* created_at, updated_at

### wallets

* id: UUID (PK)
* user_id: FK -> users.id
* currency: CHAR(3)
* balance: BIGINT — stored in minor units (e.g., cents)
* reserved: BIGINT — funds reserved for pending operations
* created_at, updated_at

### transactions

* id: UUID (PK)
* wallet_id: FK -> wallets.id
* kind: enum (deposit, withdrawal, transfer, payout, topup)
* amount: BIGINT (minor units)
* status: enum (pending, succeeded, failed, reversed)
* metadata: JSON
* external_id: varchar (Stripe paymentIntent id / payout id)
* idempotency_key: varchar
* created_at, updated_at

### bank_accounts

* id
* user_id
* provider_token (tokenized)
* last4
* bank_name
* currency

### audit_logs

* id
* event_type
* resource_id
* actor_id
* payload (JSON)
* created_at

**Money rule**: never store or operate in floating point. Use integer minor units. All arithmetic must be done with integers or a dedicated Money class.

---

## 6. API design — selected endpoints

Return a standardized envelope for all responses:

```json
{ "status": "success"|"error", "data": {...}, "error": {"code": "", "message": "", "details": {...} } }
```

### Authentication

* `POST /api/v1/auth/register`

  * body: `{ "email", "password", "phone" }`
  * response: `{ user, access_token, refresh_token }`

* `POST /api/v1/auth/login`

  * body: `{ "email", "password" }`
  * response: `{ access_token, refresh_token }`

### Wallets

* `GET /api/v1/wallets` — list user wallets and balances
* `GET /api/v1/wallets/{wallet_id}/transactions?limit=50` — list transactions

### Deposits (Stripe)

* `POST /api/v1/wallets/{wallet_id}/deposit`

  * body: `{ amount: 5000, currency: "USD", idempotency_key: "uuid-or-client-key" }`
  * creates PaymentIntent server side, records a `transaction` with status `pending`, returns `{ client_secret }`.

* `POST /api/v1/webhooks/stripe` — receive and verify webhooks

  * On `payment_intent.succeeded`:

    * Verify  signature
    * Load matching transaction by `external_id` or `idempotency_key`
    * In a DB transaction mark transaction succeeded and credit wallet
    * Produce audit log

### Send money (wallet → wallet)

* `POST /api/v1/transfers`

  * body: `{ from_wallet_id, to_wallet_id_or_user_id, amount, currency, idempotency_key }`
  * Server-side checks: ownership of `from_wallet_id`, sufficient available balance, same currency, anti-fraud rate limits
  * In a DB transaction: debit sender, credit recipient, write two transaction records and an audit entry

### Bank payout

* `POST /api/v1/payouts/bank`

  * body: `{ wallet_id, bank_account_id, amount, idempotency_key }`
  * Create a pending transaction, enqueue background job to call bank/Stripe Connect Payout API, update transaction status based on result

### Mobile top‑up

* `POST /api/v1/topup/mobile`

  * body: `{ wallet_id, mobile_number, operator, amount }`
  * Enqueue background topup call, mark transaction success/failure, add provider details to metadata

---

## 7. Stripe & payments architecture

**Recommended approach**:

* Use **Payment Intents API** for deposits (handles SCA and modern flows).
* Always create and persist a `transaction` record with `idempotency_key` **before** creating the PaymentIntent. This prevents double-credits.
* Return the `client_secret` to the frontend. Let frontend complete card authentication.
* Use the **webhook** (`payment_intent.succeeded`) to finalize and credit the wallet.
* Validate webhook signatures using `STRIPE_WEBHOOK_SECRET`.

**Payouts**:

* For bank payouts, use **Stripe Connect** (if acting as platform) or your bank provider’s API.
* Payout creation should be done in background workers and tracked by `external_id`.

**Idempotency**:

* Use an `idempotency_key` supplied by client or generated server-side. Store it on the transaction record with an expiry window.
* If a duplicate request with same key arrives, return the existing transaction result.

---

## 8. Error handling, idempotency & retries

### Error patterns

* Validate inputs (return 422 with field errors).
* Auth failures → 401; insufficient privileges → 403.
* External provider temporary failures → 502 or 503 with retry instructions and correlation ID.
* Use `400` or `422` for client errors.

### Idempotency handling

* Implement an `idempotency` middleware that checks for an existing key for operations that mutate money.
* Only accept each idempotency key once per operation type for a configurable TTL (e.g., 1 hour).

### Retries

* Background workers should implement exponential backoff and maximum retry limits for external calls.
* Keep a `retries` count and `next_attempt_at` on retryable jobs.

---

## 9. Security, compliance & data protection

* Use TLS everywhere.
* Keep secrets in environment variables or secret manager (AWS Secrets Manager, Vault).
* Use a strong password hashing algorithm (bcrypt/argon2) with per‑user salts.
* Do not log sensitive data (card PANs, full bank account numbers). Only log tokens or last4 digits.
* PCI compliance: never store raw card data. Use Stripe to handle card collection and tokenization.
* Apply role-based access control for payout operations and KYC protected endpoints.
* Rate limit critical endpoints (transfer, payout, topup).
* Monitor for suspicious patterns and escalate locked accounts automatically when thresholds exceeded.

---

## 10. Observability: logging, monitoring & tracing

* Use structured JSON logs with `request_id` and `user_id` where appropriate.
* Capture metrics: requests/sec, error rates, average latency, queue length, payment success rates, payout latency.
* Integrate with APM/tracing (OpenTelemetry, Jaeger) to trace requests across API → worker → external provider.
* Configure alerts for: webhook failures, payment processing errors > threshold, DB replication lag, worker queue growth.

---





## . Scaling & performance

* Use connection pooling for MySQL; tune `max_connections` and pool size.
* Cache read-heavy endpoints (balances should still be authoritative from DB for writes; consider read replicas for heavy read load).
* Use background workers for any blocking network calls.
* Partition large tables (transactions) by date if needed; index queries on `wallet_id`, `created_at`.
* Implement optimistic locking on wallet rows: increment a `version` column or use `SELECT ... FOR UPDATE` in transactions.

---

## . Operational runbook & troubleshooting

Common procedures:

* **Duplicate deposit detected**: check idempotency key, verify webhook event history, perform manual reconciliation with audit logs.
* **Webhook processing failures**: inspect recent webhook deliveries in Stripe dashboard; replay via Stripe CLI; check worker backlog.
* **Balance mismatch**: run ledger reconciliation job; compare sum(transactions) vs wallets; freeze affected accounts during investigation.
* **Slow payouts**: check provider status page, retry queue, and bank account verification state.

Keep a list of escalation contacts and retention policy for logs and audit records.

---

## 15. Roadmap & extensions

* Add multi-currency FX conversion with clear exchange rate feeds and fees.
* Add recurring payments and scheduled payouts.
* Integrate KYC provider for automated verification.
* Add support for ACH and local bank transfer rails (where applicable).

---

## 16. Contributing & code style

* Follow PEP8 and use autoformatters (`black`) and linters (`ruff`/`flake8`).
* Write unit tests for new logic and update integration tests.
* Use feature branches and PR reviews. Include migration scripts with DB changes.

---






