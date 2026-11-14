# ArikePreorder Cloudflare Worker adaptation — EXPERIMENTAL

This is a source-code adaptation, **not a tested production deployment**. Original backend and frontend routes are retained. The existing `server.js` no longer starts a listening server when imported by the Worker. The Worker uses Cloudflare Node.js HTTP compatibility for the Express API and Cloudflare Assets for the frontend.

## Critical caveats

- Worker Node.js HTTP server adapter and `pg` TCP socket compatibility MUST be verified in a Cloudflare preview deployment. Wrangler may require additional code changes; no successful build/runtime test has been completed here.
- `migrate.js` is deliberately NOT run inside the Worker. The Neon schema was already imported manually. To create the first admin account, use a separate secure one-time admin bootstrap procedure (not included in this package); merely adding ADMIN_EMAIL/ADMIN_PASSWORD as Worker secrets will NOT create an admin.
- No live payments or customer balances until end-to-end transaction, webhook, authorization and data-safety testing is completed. Do not expose this as a production financial service.
- Do not upload `.env` or a real DATABASE_URL to GitHub. Set Worker secrets in Cloudflare after a successful preview build: `DATABASE_URL`, `JWT_SECRET`, and email/payment credentials as needed. Set `NODE_ENV=production` as a Worker variable. Use Neon's pooled TLS connection string. Ensure that the PostgreSQL pool connection is compatible with your Neon account.
- Frontend is bundled with the Worker as static assets. You do not need to create a separate Pages project for this test.
- `package-lock.json` is intentionally removed because package.json changed; regenerate with `npm install --package-lock-only` or `npm install` before deploying. This needs Node/npm (or a CI build that installs dependencies).
- `wrangler.jsonc` is at repository root. Cloudflare Git build settings must point to root, with build/deploy through Wrangler. A plain click-through deploy of the old repo will not work.

## Next steps
1. Replace the GitHub repository files with this extracted source (do not upload ZIP as one file).
2. Configure Cloudflare Workers Git deployment with project root and Wrangler; stop if build errors occur and share the logs.
3. Add secrets privately in Cloudflare, then test `/api/health`, authentication, storefront and admin in a preview URL.
4. Create initial admin via a reviewed one-time bootstrap, never by exposing credentials in a public URL.
5. Connect `arikepreorder.site` only after tests pass.
