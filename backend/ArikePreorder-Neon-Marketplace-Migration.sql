-- ArikePreorder marketplace schema migration extracted from backend/migrate.js
-- Requires existing public.users table from database/schema.sql.
-- Admin credentials must be configured on backend hosting, not in SQL.
-- Legacy wallet balance reset intentionally removed.
-- Run once in Neon SQL Editor on the intended development database.
BEGIN;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_hash TEXT;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS kyc_status VARCHAR(20) DEFAULT 'not_submitted';
    ALTER TABLE users ADD COLUMN IF NOT EXISTS account_type VARCHAR(20) DEFAULT 'buyer';
    ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
    CREATE TABLE IF NOT EXISTS password_reset_codes(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      code VARCHAR(6) NOT NULL, expires_at TIMESTAMPTZ NOT NULL, used BOOLEAN DEFAULT FALSE, created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS kyc_submissions(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      legal_name VARCHAR(200) NOT NULL, document_type VARCHAR(40) NOT NULL, document_number VARCHAR(100) NOT NULL,
      status VARCHAR(20) DEFAULT 'pending', submitted_at TIMESTAMPTZ DEFAULT NOW(), reviewed_at TIMESTAMPTZ
    );
    CREATE TABLE IF NOT EXISTS businesses(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      business_name VARCHAR(160) NOT NULL, category VARCHAR(100), description TEXT, city VARCHAR(100),
      status VARCHAR(20) DEFAULT 'pending', plan VARCHAR(20) DEFAULT 'standard', available_balance NUMERIC(14,2) DEFAULT 0,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE UNIQUE INDEX IF NOT EXISTS one_business_per_owner ON businesses(owner_id);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS shopping_state VARCHAR(100);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS shopping_city VARCHAR(100);
    CREATE TABLE IF NOT EXISTS wallets(
      user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      balance NUMERIC(14,2) NOT NULL DEFAULT 0, updated_at TIMESTAMPTZ DEFAULT NOW()
    );
    INSERT INTO wallets(user_id,balance) SELECT id,0 FROM users ON CONFLICT(user_id) DO NOTHING;
    CREATE TABLE IF NOT EXISTS products(
      id SERIAL PRIMARY KEY, store_name VARCHAR(140) NOT NULL, name VARCHAR(180) NOT NULL,
      price NUMERIC(14,2) NOT NULL, emoji VARCHAR(16), category VARCHAR(80), city VARCHAR(100), state VARCHAR(100),
      availability VARCHAR(80), is_trending BOOLEAN DEFAULT FALSE, created_at TIMESTAMPTZ DEFAULT NOW()
    );
    INSERT INTO products(store_name,name,price,emoji,category,city,state,availability,is_trending)
    SELECT * FROM (VALUES
      ('Ari Atelier','Satin Occasion Dress',42500,'👗','Fashion','Lekki','Lagos','PREORDER · 4–6 DAYS',TRUE),
      ('Kicks District','Cloud Runner',48500,'👟','Fashion','Ikeja','Lagos','READY TO ORDER',TRUE),
      ('Sugar Room','Celebration Cake Box',32000,'🎂','Food & treats','Ajah','Lagos','PREORDER · 3 DAYS',FALSE),
      ('Naya Beauty','Silk Straight Unit',95000,'💇','Beauty','Sangotedo','Lagos','LIMITED STOCK',TRUE),
      ('Maison Mini','Structured Mini Bag',26500,'👜','Fashion','Surulere','Lagos','NEW DROP',FALSE),
      ('Tech Corner','Wireless Buds Pro',38900,'🎧','Phones & tech','Yaba','Lagos','IN STOCK',TRUE),
      ('Abuja Home','Cloud Throw Set',28500,'🛋️','Home','Wuse','FCT','IN STOCK',FALSE),
      ('Ibadan Glow','Body Glow Set',18000,'✨','Beauty','Bodija','Oyo','READY TO ORDER',TRUE)
    ) AS v(store_name,name,price,emoji,category,city,state,availability,is_trending)
    WHERE NOT EXISTS (SELECT 1 FROM products);
    CREATE TABLE IF NOT EXISTS product_likes(
      user_id UUID REFERENCES users(id) ON DELETE CASCADE, product_id INT REFERENCES products(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ DEFAULT NOW(), PRIMARY KEY(user_id,product_id)
    );
    CREATE TABLE IF NOT EXISTS product_comments(
      id BIGSERIAL PRIMARY KEY, user_id UUID REFERENCES users(id) ON DELETE CASCADE, product_id INT REFERENCES products(id) ON DELETE CASCADE,
      body VARCHAR(500) NOT NULL, created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS cart_items(
      user_id UUID REFERENCES users(id) ON DELETE CASCADE, product_id INT REFERENCES products(id) ON DELETE CASCADE,
      quantity INT NOT NULL DEFAULT 1 CHECK(quantity>0 AND quantity<=20), created_at TIMESTAMPTZ DEFAULT NOW(),
      PRIMARY KEY(user_id,product_id)
    );
    CREATE TABLE IF NOT EXISTS help_pay_requests(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      code VARCHAR(10) UNIQUE NOT NULL, amount NUMERIC(14,2) NOT NULL, snapshot JSONB NOT NULL,
      status VARCHAR(20) DEFAULT 'requested', expires_at TIMESTAMPTZ NOT NULL, paid_by UUID REFERENCES users(id),
      created_at TIMESTAMPTZ DEFAULT NOW(), paid_at TIMESTAMPTZ
    );
    CREATE TABLE IF NOT EXISTS orders(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), buyer_id UUID NOT NULL REFERENCES users(id), paid_by UUID REFERENCES users(id),
      amount NUMERIC(14,2) NOT NULL, items JSONB NOT NULL, payment_method VARCHAR(30) NOT NULL,
      status VARCHAR(30) DEFAULT 'processing', created_at TIMESTAMPTZ DEFAULT NOW()
    );
    ALTER TABLE businesses ADD COLUMN IF NOT EXISTS held_balance NUMERIC(14,2) DEFAULT 0;
    ALTER TABLE businesses ADD COLUMN IF NOT EXISTS state VARCHAR(100);
    ALTER TABLE businesses ADD COLUMN IF NOT EXISTS lga VARCHAR(120);
    ALTER TABLE businesses ADD COLUMN IF NOT EXISTS business_address TEXT;
    ALTER TABLE businesses ADD COLUMN IF NOT EXISTS location_confirmed BOOLEAN DEFAULT FALSE;
    ALTER TABLE businesses ADD COLUMN IF NOT EXISTS cac_registered BOOLEAN DEFAULT FALSE;
    ALTER TABLE businesses ADD COLUMN IF NOT EXISTS cac_number VARCHAR(100);
    ALTER TABLE businesses ADD COLUMN IF NOT EXISTS cac_registered_name VARCHAR(180);
    ALTER TABLE businesses ADD COLUMN IF NOT EXISTS cac_document TEXT;
    CREATE TABLE IF NOT EXISTS seller_wallet_transfers(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, amount NUMERIC(14,2) NOT NULL CHECK(amount>0),
      reference VARCHAR(80) UNIQUE NOT NULL, created_at TIMESTAMPTZ DEFAULT NOW()
    );
    ALTER TABLE products ADD COLUMN IF NOT EXISTS business_id UUID REFERENCES businesses(id) ON DELETE CASCADE;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS description TEXT;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS stock INT DEFAULT 0;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS product_mode VARCHAR(20) DEFAULT 'stock';
    ALTER TABLE products ADD COLUMN IF NOT EXISTS preorder_date DATE;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS listing_status VARCHAR(20) DEFAULT 'active';
    ALTER TABLE orders ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
    CREATE TABLE IF NOT EXISTS seller_withdrawals(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
      amount NUMERIC(14,2) NOT NULL, bank_name VARCHAR(120), account_name VARCHAR(160), account_number VARCHAR(30),
      status VARCHAR(20) DEFAULT 'pending', created_at TIMESTAMPTZ DEFAULT NOW(), reviewed_at TIMESTAMPTZ
    );
    ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';
    ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_payment_method VARCHAR(30) DEFAULT 'wallet';
    CREATE TABLE IF NOT EXISTS deposit_requests(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      amount NUMERIC(14,2) NOT NULL CHECK(amount>0), method VARCHAR(30) NOT NULL, reference VARCHAR(60) UNIQUE NOT NULL,
      status VARCHAR(20) DEFAULT 'pending', created_at TIMESTAMPTZ DEFAULT NOW(), reviewed_at TIMESTAMPTZ,
      reviewed_by UUID REFERENCES users(id)
    );
    CREATE TABLE IF NOT EXISTS wallet_transactions(
      id BIGSERIAL PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type VARCHAR(30) NOT NULL, amount NUMERIC(14,2) NOT NULL, reference VARCHAR(80), note TEXT, created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS app_meta(key VARCHAR(80) PRIMARY KEY,value TEXT);
    -- Legacy wallet balance reset intentionally omitted for safety.
    CREATE TABLE IF NOT EXISTS payment_deposits(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      amount NUMERIC(14,2) NOT NULL CHECK(amount>0), amount_kobo BIGINT NOT NULL, reference VARCHAR(80) UNIQUE NOT NULL,
      status VARCHAR(20) DEFAULT 'pending', channel VARCHAR(40), access_code TEXT, authorization_url TEXT, provider_payload JSONB,
      created_at TIMESTAMPTZ DEFAULT NOW(), paid_at TIMESTAMPTZ
    );
    CREATE UNIQUE INDEX IF NOT EXISTS wallet_transactions_reference_unique ON wallet_transactions(reference) WHERE reference IS NOT NULL;
    CREATE TABLE IF NOT EXISTS admin_users(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), email VARCHAR(255) UNIQUE NOT NULL,
      password_hash TEXT NOT NULL, display_name VARCHAR(120) DEFAULT 'ArikePreorder Admin',
      status VARCHAR(20) DEFAULT 'active', created_at TIMESTAMPTZ DEFAULT NOW(), last_login_at TIMESTAMPTZ
    );
    CREATE TABLE IF NOT EXISTS marketplace_banners(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), title VARCHAR(180) NOT NULL, subtitle TEXT, tag VARCHAR(80),
      action_label VARCHAR(80), action_url TEXT, tone VARCHAR(30) DEFAULT 'plum', priority INT DEFAULT 0,
      status VARCHAR(20) DEFAULT 'active', starts_at TIMESTAMPTZ, ends_at TIMESTAMPTZ, created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS marketplace_trending(
      product_id INT PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE, priority INT DEFAULT 0,
      starts_at TIMESTAMPTZ, ends_at TIMESTAMPTZ, created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS notifications(
      id BIGSERIAL PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      title VARCHAR(160) NOT NULL, message TEXT NOT NULL, type VARCHAR(40) DEFAULT 'general', is_read BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS verification_codes(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      channel VARCHAR(20) NOT NULL, code_hash TEXT NOT NULL, expires_at TIMESTAMPTZ NOT NULL, used BOOLEAN DEFAULT FALSE, created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS arike_conversations(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE, business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
      status VARCHAR(20) DEFAULT 'open', last_message_at TIMESTAMPTZ DEFAULT NOW(), created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS arike_messages(
      id BIGSERIAL PRIMARY KEY, conversation_id UUID REFERENCES arike_conversations(id) ON DELETE CASCADE,
      sender_type VARCHAR(20) NOT NULL, sender_user_id UUID REFERENCES users(id) ON DELETE SET NULL, body TEXT NOT NULL, created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS admin_messages(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(), admin_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
      subject VARCHAR(180) NOT NULL, body TEXT NOT NULL, action_label VARCHAR(80), action_url TEXT,
      audience VARCHAR(30) NOT NULL, channels VARCHAR(30) NOT NULL DEFAULT 'in_app', recipient_count INT DEFAULT 0,
      in_app_sent INT DEFAULT 0, email_sent INT DEFAULT 0, email_failed INT DEFAULT 0,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS admin_message_recipients(
      id BIGSERIAL PRIMARY KEY, message_id UUID NOT NULL REFERENCES admin_messages(id) ON DELETE CASCADE,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, in_app_status VARCHAR(20) DEFAULT 'not_requested',
      email_status VARCHAR(20) DEFAULT 'not_requested', email_error TEXT, created_at TIMESTAMPTZ DEFAULT NOW(),
      UNIQUE(message_id,user_id)
    );
COMMIT;
