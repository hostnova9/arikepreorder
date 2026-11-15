CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,

    username VARCHAR(50) UNIQUE NOT NULL,

    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30) UNIQUE NOT NULL,

    password_hash TEXT NOT NULL,

    profile_photo TEXT,

    country VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),

    phone_verified BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,

    account_status VARCHAR(20) DEFAULT 'active'
        CHECK (account_status IN ('active', 'suspended', 'blocked')),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username
ON users(username);

CREATE INDEX IF NOT EXISTS idx_users_phone
ON users(phone);

CREATE INDEX IF NOT EXISTS idx_users_email
ON users(email);