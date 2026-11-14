ArikePreorder v0.9.1 — Organized Wallet + Paystack Test Mode

Changes:
- Removed Preferred Payment Mode from wallet dashboard.
- Wallet now shows Available Balance, Orders Paid and Recent Payment.
- Deposit is a dedicated page.
- Removed customer deposit-request/admin-approval UX.
- Added Paystack server-side transaction initialization and verification.
- Wallet is credited only after successful server verification and amount/currency match.
- Duplicate transaction references cannot credit the wallet twice.
- Admin deposit approval UI removed.
- Existing seller held/available balance remains separate from buyer wallet deposits.

Setup:
1. Keep your existing backend/.env.
2. Add PAYSTACK_SECRET_KEY=your Paystack TEST secret key.
3. For local use: APP_BASE_URL=http://localhost:5000
4. Restart: node server.js
5. Open /wallet and choose Deposit.

For webhook testing, localhost cannot receive Paystack webhooks. This build verifies on the callback. Before production, configure a public HTTPS webhook and signature validation.
