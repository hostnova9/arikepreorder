ArikePreorder v0.7.2 — Onboarding & Login Rules

Changes:
- Email and phone are both required at registration.
- New registration automatically signs the user in.
- New users go to /welcome instead of back to /login.
- Transaction PIN is created once during onboarding.
- Existing PIN cannot be overwritten through the create-PIN endpoint.
- Returning users log in using email OR phone + password (username is marketplace identity only).
- Returning users without a PIN are sent to /welcome; users with a PIN go directly to /dashboard.
- Existing marketplace/dashboard, Help Pay, KYC and seller features are preserved.

Keep/copy your existing backend/.env into this build before running.
