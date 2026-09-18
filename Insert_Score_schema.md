INSERT INTO core.owners
(
    id,
    user_id,
    business_name,
    tax_id,
    is_active
)
SELECT
    uuid_generate_v7(),
    u.id,
    'An Badminton Group',
    '0312345678',
    TRUE
FROM auth.users u
where u.id = 'ab67cde7-3579-4862-a19b-35812f8260c5'


-- 2. Insert Branches
INSERT INTO core.branches
(
    id,
    owner_id,
    name,
    address,
    latitude,
    longitude,
    phone_number,
    is_active
)
SELECT
    uuid_generate_v7(),
    o.id,
    branch_name,
    address,
    latitude,
    longitude,
    phone_number,
    TRUE
FROM core.owners o
CROSS JOIN
(
    VALUES
    (
        'TMT Badminton Center',
        'Tân Bình, Hồ Chí Minh',
        10.801112,
        106.652321,
        '0901000001'
    ),
    (
        'District 7 Badminton Club',
        'Quận 7, Hồ Chí Minh',
        10.729818,
        106.721892,
        '0901000002'
    ),
    (
        'Thu Duc Badminton Arena',
        'Thủ Đức, Hồ Chí Minh',
        10.850114,
        106.772541,
        '0901000003'
    )
) AS b
(
    branch_name,
    address,
    latitude,
    longitude,
    phone_number
);


-- 3. Insert Operating Hours
INSERT INTO core.operating_hours
(
    id,
    branch_id,
    open_time,
    close_time,
    is_closed
)
SELECT
    uuid_generate_v7(),
    b.id,
    '05:00',
    '23:00',
    FALSE
FROM core.branches b;

-- 4. Insert Court Types
INSERT INTO core.court_types
(
    id,
    code,
    name,
    description,
    is_active
)
VALUES
(
    uuid_generate_v7(),
    'STANDARD',
    'Standard Court',
    'Standard badminton court',
    TRUE
),
(
    uuid_generate_v7(),
    'VIP',
    'VIP Court',
    'Premium badminton court',
    TRUE
),
(
    uuid_generate_v7(),
    'TRAINING',
    'Training Court',
    'Coaching and training court',
    TRUE
);

-- 5. Insert 18 Courts cho Branch đầu tiên

Giống UI:

Sân 1
Sân 2
...
Sân 18

INSERT INTO core.courts
(
    id,
    branch_id,
    court_type_id,
    court_number,
    name,
    status,
    is_active
)
SELECT
    uuid_generate_v7(),
    b.id,
    ct.id,
    gs::varchar,
    CONCAT('Sân ', gs),
    'active',
    TRUE
FROM
(
    SELECT id
    FROM core.branches
    ORDER BY created_at
    LIMIT 1
) b
CROSS JOIN
(
    SELECT id
    FROM core.court_types
    WHERE code = 'STANDARD'
    LIMIT 1
) ct
CROSS JOIN generate_series(1,18) gs;

-- Branches
SELECT
    id,
    name,
    address
FROM core.branches;

-- Operating Hours
SELECT
    b.name,
    oh.open_time,
    oh.close_time
FROM core.operating_hours oh
INNER JOIN core.branches b
    ON oh.branch_id = b.id;

-- Courts
SELECT
    b.name AS branch_name,
    c.court_number,
    c.name,
    ct.name AS court_type
FROM core.courts c
INNER JOIN core.branches b
    ON c.branch_id = b.id
INNER JOIN core.court_types ct
    ON c.court_type_id = ct.id
ORDER BY
    c.court_number::int;


SELECT version();
