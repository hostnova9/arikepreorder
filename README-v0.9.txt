ArikePreorder v0.9 — Seller Approval, Admin Centre, Wallet & Payments

NEW
- /admin Admin Centre: seller applications, KYC review, deposit approvals and seller withdrawal review.
- /wallet Wallet & Payments: real account balance UI, deposit requests, payment preference and history.
- Seller applications are approved/rejected by Admin; approved sellers can publish products.
- Removed the old automatic ₦250,000 demo-wallet seed. Existing demo balances are reset once by migration.
- Deposit requests do NOT move real money. In this local build they require admin approval for testing.
- Seller order money is placed in held balance when checkout succeeds and becomes available on delivery.
- Multi-seller orders release only that seller's portion on delivery.

LOCAL ADMIN SETUP
Add your own ArikePreorder login email to backend/.env:
ADMIN_EMAILS=you@example.com
Restart node server.js, sign in with that account, then open http://localhost:5000/admin

IMPORTANT
Card and bank-transfer funding are UI/workflow placeholders until a licensed payment provider is connected. Do not use the manual admin approval flow as a production payment gateway.
