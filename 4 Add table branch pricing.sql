ALTER TABLE core.branches
    ADD COLUMN IF NOT EXISTS description varchar(1000);

CREATE TABLE core.branch_pricings (
id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
branch_id UUID NOT NULL REFERENCES core.branches(id),
pricing_type VARCHAR(30) NOT NULL,
start_time TIME NOT NULL,
end_time TIME NOT NULL,
price_per_hour NUMERIC(12,2) NOT NULL,
is_active BOOLEAN NOT NULL DEFAULT TRUE,
created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- WITH
-- pricing_type
-- PEAK
-- NORMAL

select * from core.branches b 

INSERT INTO core.branch_pricings
(
    branch_id,
    pricing_type,
    start_time,
    end_time,
    price_per_hour
)
VALUES

-- =====================================================
-- BRANCH 1
-- =====================================================

(
    'a66e69ce-5711-49df-bb0c-e45e1140cffb',
    'NORMAL',
    '05:00',
    '17:00',
    80000
),
(
    'a66e69ce-5711-49df-bb0c-e45e1140cffb',
    'PEAK',
    '17:00',
    '23:00',
    120000
),

-- =====================================================
-- BRANCH 2
-- =====================================================

(
    'd3b43956-305e-47db-ad84-c24f33c68767',
    'NORMAL',
    '05:00',
    '17:00',
    70000
),
(
    'd3b43956-305e-47db-ad84-c24f33c68767',
    'PEAK',
    '17:00',
    '23:00',
    100000
),

-- =====================================================
-- BRANCH 3 (PREMIUM)
-- =====================================================

(
    '7bbd6ee2-6856-49f6-9821-3169edfd7d92',
    'NORMAL',
    '05:00',
    '17:00',
    100000
),
(
    '7bbd6ee2-6856-49f6-9821-3169edfd7d92',
    'PEAK',
    '17:00',
    '23:00',
    150000
);


