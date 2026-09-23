
-- ---------------------------------------------------------------------
-- EXTENSIONS
-- ---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- gen_random_uuId()
CREATE EXTENSION IF NOT EXISTS pg_trgm;       -- fuzzy text search

-- Fallback UUID v7-ish generator wrapper (swap for pg_uuIdv7 extension in prod
-- if available, for time-ordered keys and better index locality at scale).
CREATE OR REPLACE FUNCTION uuid_generate_v7() RETURNS uuId AS $$
  SELECT gen_random_uuid();  -- placeholder: replace with true UUIDv7 impl/extension in production
$$ LANGUAGE sql VOLATILE;

-- ---------------------------------------------------------------------
-- SCHEMAS
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS Auth;
CREATE SCHEMA IF NOT EXISTS Core;
CREATE SCHEMA IF NOT EXISTS Scheduling;
CREATE SCHEMA IF NOT EXISTS Customer;
CREATE SCHEMA IF NOT EXISTS Booking;
CREATE SCHEMA IF NOT EXISTS Payment;
CREATE SCHEMA IF NOT EXISTS Notification;

-- =====================================================================
-- AUTH & AUTHORIZATION
-- =====================================================================

CREATE TABLE Auth.Users (
    Id                  UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    Email               VARCHAR(100) NOT NULL,
    Phone_Number        VARCHAR(20),
    Password_Hash       TEXT NOT NULL,
    Is_Active           BOOLEAN NOT NULL DEFAULT TRUE,
    Is_Email_Verified   BOOLEAN NOT NULL DEFAULT FALSE,
    Last_Login_At       TIMESTAMPTZ,
    Created_At          TIMESTAMPTZ NOT NULL DEFAULT now(),
    Created_By          UUID,
    Updated_At          TIMESTAMPTZ NOT NULL DEFAULT now(),
    Updated_By          UUID,
    Deleted_At          TIMESTAMPTZ,
    Deleted_By          UUID
);
CREATE UNIQUE INDEX ux_users_email ON auth.users (email) WHERE Deleted_At IS NULL;
CREATE INDEX ix_users_phone ON auth.users (phone_number);


CREATE TABLE Auth.roles (
    Id            UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    Code          VARCHAR(50) NOT NULL,
    Name          VARCHAR(100) NOT NULL,
    Description   TEXT,
    Is_Active     BOOLEAN NOT NULL DEFAULT TRUE,
    Created_At    TIMESTAMPTZ NOT NULL DEFAULT now(),
    Created_By    UUID REFERENCES auth.users(Id),
    Updated_At    TIMESTAMPTZ NOT NULL DEFAULT now(),
    Updated_By    UUID REFERENCES auth.users(Id),
    Deleted_At    TIMESTAMPTZ,
    Deleted_By    UUID REFERENCES auth.users(Id)
);
CREATE UNIQUE INDEX ux_roles_code ON auth.roles (code) WHERE Deleted_At IS NULL;


CREATE TABLE Auth.permissions (
    Id            UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    code          VARCHAR(100) NOT NULL,
    name          VARCHAR(150) NOT NULL,
    description   TEXT,  
    Created_At    TIMESTAMPTZ NOT NULL DEFAULT now(),
    Updated_At    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_permissions_code ON auth.permissions (code);

CREATE TABLE Auth.user_roles (
    user_Id     UUID NOT NULL REFERENCES auth.users(Id) ON DELETE CASCADE,
    role_Id     UUID NOT NULL REFERENCES auth.roles(Id) ON DELETE RESTRICT,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by UUID REFERENCES auth.users(Id),
    PRIMARY KEY (user_Id, role_Id)
);



CREATE TABLE Auth.role_permissions (
    role_Id       UUID NOT NULL REFERENCES auth.roles(Id) ,
    permission_Id UUID NOT NULL REFERENCES auth.permissions(Id) ,
    CONSTRAINT pk_role_permissions
    PRIMARY KEY (role_Id, permission_Id)
);


CREATE TABLE Auth.refresh_tokens (
    Id                UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    user_Id           UUID NOT NULL REFERENCES auth.users(Id) ON DELETE CASCADE,
    token_hash        TEXT NOT NULL,
    issued_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at        TIMESTAMPTZ NOT NULL,
    revoked_at        TIMESTAMPTZ,
    replaced_by_token UUID REFERENCES auth.refresh_tokens(Id),
    device_info       TEXT
);

CREATE UNIQUE INDEX ux_refresh_tokens_hash ON auth.refresh_tokens (token_hash);
CREATE INDEX ix_refresh_tokens_user ON auth.refresh_tokens (user_Id) WHERE revoked_at IS NULL;


CREATE TABLE Auth.user_sessions (
    Id           UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    user_Id      UUID NOT NULL REFERENCES auth.users(Id) ON DELETE CASCADE,
    ip_address   INET,
    user_agent   TEXT,
    started_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at     TIMESTAMPTZ
);
CREATE INDEX ix_user_sessions_user ON auth.user_sessions (user_Id, started_at DESC);

-- =====================================================================
-- CORE: OWNERS / BRANCHES / COURTS
-- =====================================================================

CREATE TABLE core.owners (
    Id            UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    user_Id       UUID NOT NULL REFERENCES auth.users(Id),
    business_name VARCHAR(150) NOT NULL,
    tax_Id        VARCHAR(50),
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    Created_At    TIMESTAMPTZ NOT NULL DEFAULT now(),
    Created_By    UUID REFERENCES auth.users(Id),
    Updated_At    TIMESTAMPTZ NOT NULL DEFAULT now(),
    Updated_By    UUID REFERENCES auth.users(Id),
    Deleted_At    TIMESTAMPTZ,
    Deleted_By    UUID REFERENCES auth.users(Id)
);
CREATE UNIQUE INDEX ux_owners_user ON core.owners (user_Id) WHERE Deleted_At IS NULL;

CREATE TABLE core.branches (
    Id           UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    owner_Id     UUID NOT NULL REFERENCES core.owners(Id),
    name         VARCHAR(150) NOT NULL,
    address		 VARCHAR(255) NOT NULL,
    latitude     NUMERIC(9,6),
    longitude    NUMERIC(9,6),
    phone_number VARCHAR(20),
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    Created_At   TIMESTAMPTZ NOT NULL DEFAULT now(),
    Created_By   UUID REFERENCES auth.users(Id),
    Updated_At   TIMESTAMPTZ NOT NULL DEFAULT now(),
    Updated_By   UUID REFERENCES auth.users(Id),
    Deleted_At   TIMESTAMPTZ,
    Deleted_By   UUID REFERENCES auth.users(Id)
);
CREATE INDEX ix_branches_owner ON core.branches (owner_Id) WHERE Deleted_At IS NULL;  -- Không index dữ liệu đã xóa. (Lợi ích:  Index nhỏ hơn, Nhanh hơn, Ít tốn RAM)
CREATE INDEX ix_branches_name_trgm ON core.branches USING gin (name gin_trgm_ops); -- GIN Index , tránh scan name toàn toàn bộ table 

    
CREATE TABLE core.operating_hours (
    Id           UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    branch_Id    UUID NOT NULL REFERENCES core.branches(Id) ,
    open_time    TIME NOT NULL,
    close_time   TIME NOT NULL,
    is_closed    BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_operating_hours_range CHECK (close_time > open_time),
    CONSTRAINT ux_operating_hours UNIQUE (branch_Id)
);

CREATE TABLE core.court_types (
    Id          UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    code        VARCHAR(30) NOT NULL,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE UNIQUE INDEX ux_court_types_code ON core.court_types (code);

CREATE TABLE core.courts (
    Id             UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    branch_Id      UUID NOT NULL REFERENCES core.branches(Id),
    court_type_Id  UUID REFERENCES core.court_types(Id),
    court_number   VARCHAR(20) NOT NULL,
    name           VARCHAR(100),
    status         VARCHAR(20) NOT NULL DEFAULT 'active',
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    Created_At     TIMESTAMPTZ NOT NULL DEFAULT now(),
    Created_By     UUID REFERENCES auth.users(Id),
    Updated_At     TIMESTAMPTZ NOT NULL DEFAULT now(),
    Updated_By     UUID REFERENCES auth.users(Id),
    Deleted_At     TIMESTAMPTZ,
    Deleted_By     UUID REFERENCES auth.users(Id),
    CONSTRAINT ux_courts_branch_number UNIQUE (branch_Id, court_number)
);
CREATE INDEX ix_courts_branch_status ON core.courts (branch_Id, status) WHERE Deleted_At IS NULL;

CREATE TABLE core.court_images (
    Id         UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    court_Id   UUID NOT NULL REFERENCES core.courts(Id) ON DELETE CASCADE,
    image_url  TEXT NOT NULL,
    sort_order SMALLINT NOT NULL DEFAULT 0,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    Created_At TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_court_images_court ON core.court_images (court_Id);

CREATE TABLE scheduling.time_slots (
    Id          UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    label       VARCHAR(20) NOT NULL,   -- e.g. '06:00-07:00'
    start_time  TIME NOT NULL,
    end_time    TIME NOT NULL,
    CONSTRAINT chk_time_slots_range CHECK (end_time > start_time)
);

CREATE TABLE customer.membership_levels (
    Id             UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    code           VARCHAR(20) NOT NULL,   -- BRONZE / SILVER / GOLD / PLATINUM
    name           VARCHAR(50) NOT NULL,
    min_points     INTEGER NOT NULL DEFAULT 0,
    discount_pct   NUMERIC(5,2) NOT NULL DEFAULT 0,
    sort_order     SMALLINT NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX ux_membership_levels_code ON customer.membership_levels (code);

CREATE TABLE customer.customers (
    Id                   UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    user_Id              UUID REFERENCES auth.users(Id),  -- NULL for guest customers
    membership_level_Id  UUID REFERENCES customer.membership_levels(Id),
    full_name            VARCHAR(150) NOT NULL,
    email                VARCHAR(20),
    phone_number         VARCHAR(20) NOT NULL,
    is_guest             BOOLEAN NOT NULL DEFAULT FALSE,
    loyalty_points_balance INTEGER NOT NULL DEFAULT 0,  -- cached, source of truth is the ledger
    is_active    		BOOLEAN NOT NULL DEFAULT TRUE,
    Created_At           TIMESTAMPTZ NOT NULL DEFAULT now(),
    Created_By           UUID REFERENCES auth.users(Id),
    Updated_At           TIMESTAMPTZ NOT NULL DEFAULT now(),
    Updated_By           UUID REFERENCES auth.users(Id),
    Deleted_At           TIMESTAMPTZ,
    Deleted_By           UUID REFERENCES auth.users(Id)
);
CREATE UNIQUE INDEX ux_customers_user ON customer.customers (user_Id) WHERE Deleted_At IS NULL AND user_Id IS NOT NULL;
CREATE INDEX ix_customers_phone ON customer.customers (phone_number);
CREATE INDEX ix_customers_name_trgm ON customer.customers USING gin (full_name gin_trgm_ops);


-- =====================================================================
-- BOOKING (partitioned)
-- =====================================================================

CREATE TABLE booking.bookings (
    Id               UUID NOT NULL DEFAULT uuId_generate_v7(),
    booking_code     VARCHAR(20) NOT NULL,
    customer_Id      UUID NOT NULL REFERENCES customer.customers(Id),
    branch_Id        UUID NOT NULL REFERENCES core.branches(Id),
    status           VARCHAR(20) NOT NULL DEFAULT 'pending',
    booking_type     VARCHAR(20) NOT NULL DEFAULT 'instant',
    subtotal_amount  NUMERIC(12,2) NOT NULL CHECK (subtotal_amount >= 0),
    discount_amount  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount     NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
    recurrence_rule  TEXT,
    notes            TEXT,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    Created_At       TIMESTAMPTZ NOT NULL DEFAULT now(),
    Created_By       UUID REFERENCES auth.users(Id),
    Updated_At       TIMESTAMPTZ NOT NULL DEFAULT now(),
    Updated_By       UUID REFERENCES auth.users(Id),
    Deleted_At       TIMESTAMPTZ,
    Deleted_By       UUID REFERENCES auth.users(Id),
    CONSTRAINT chk_bookings_total CHECK (total_amount = subtotal_amount - discount_amount),
    PRIMARY KEY (Id, Created_At)
);

CREATE TABLE booking.booking_details (
    Id            UUID PRIMARY KEY DEFAULT uuId_generate_v7(),
    booking_Id    UUID NOT NULL,
    court_Id      UUID NOT NULL REFERENCES core.courts(Id),
    booking_date  DATE NOT NULL,
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL,
    slot_range    tstzrange NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'reserved', 
    price_charged NUMERIC(10,2) NOT NULL CHECK (price_charged >= 0),
    CONSTRAINT chk_booking_details_range CHECK (end_time > start_time)
);
CREATE INDEX ix_booking_details_booking ON booking.booking_details (booking_Id);
CREATE INDEX ix_booking_details_court_date ON booking.booking_details (court_Id, booking_date);


-- =====================================================================
-- PAYMENT (partitioned)
-- =====================================================================

CREATE TABLE payment.payment_methods (
    id        UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    code      VARCHAR(30) NOT NULL,   -- CASH / BANK_TRANSFER / QR / VNPAY / MOMO
    name      VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE UNIQUE INDEX ux_payment_methods_code ON payment.payment_methods (code);

CREATE TABLE payment.payments (
    id                UUID NOT NULL DEFAULT uuid_generate_v7(),
    booking_id        UUID NOT NULL,
    payment_method_id UUID NOT NULL REFERENCES payment.payment_methods(id),
    amount            NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    status            VARCHAR(20) NOT NULL DEFAULT 'pending',
    paid_at           TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by        UUID REFERENCES auth.users(id),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE INDEX ix_payments_booking ON payment.payments (booking_id);

CREATE TABLE payment.transactions (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    payment_id        UUID NOT NULL,
    gateway_reference VARCHAR(100),
    status            VARCHAR(20) NOT NULL DEFAULT 'pending',
    raw_response      JSONB,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_transactions_payment ON payment.transactions (payment_id);
CREATE UNIQUE INDEX ux_transactions_gateway_ref ON payment.transactions (gateway_reference) WHERE gateway_reference IS NOT NULL;

CREATE TABLE payment.invoices (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    booking_id   UUID NOT NULL,
    invoice_number VARCHAR(30) NOT NULL,
    issued_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0)
);
CREATE UNIQUE INDEX ux_invoices_booking ON payment.invoices (booking_id);
CREATE UNIQUE INDEX ux_invoices_number ON payment.invoices (invoice_number);

CREATE TABLE payment.invoice_items (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    invoice_id  UUID NOT NULL REFERENCES payment.invoices(id) ON DELETE CASCADE,
    description VARCHAR(255) NOT NULL,
    quantity    NUMERIC(10,2) NOT NULL DEFAULT 1,
    unit_price  NUMERIC(10,2) NOT NULL,
    line_total  NUMERIC(12,2) NOT NULL
);
CREATE INDEX ix_invoice_items_invoice ON payment.invoice_items (invoice_id);

CREATE TABLE payment.refunds (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    payment_id  UUID NOT NULL,
    amount      NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    status      VARCHAR(20) NOT NULL DEFAULT 'pending',
    reason      TEXT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ,
    processed_by UUID REFERENCES auth.users(id)
);
CREATE INDEX ix_refunds_payment ON payment.refunds (payment_id);


 
































