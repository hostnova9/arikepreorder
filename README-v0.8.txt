ArikePreorder v0.8 — Seller Operations

Adds:
- Seller product publishing with up to 4 local images (stored as data URLs for development only)
- Stock vs preorder mode, stock quantity, location and description
- Seller product pause/activate/delete
- Seller order queue and fulfilment status updates
- Automatic buyer notifications on order status changes
- Held vs available seller balance structure
- Seller withdrawal requests and history

IMPORTANT:
- Keep your existing backend/.env file. It is intentionally excluded from distributed builds.
- Existing business applications remain subject to approval. Product publishing requires business.status = approved.
- Image storage is development-only. Before production, move images to object/cloud storage.
- Wallet/payment balances remain prototype accounting until a real regulated payment provider is integrated.
