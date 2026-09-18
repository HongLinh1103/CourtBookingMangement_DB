-- Seed Roles
INSERT INTO auth.roles
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
    'SUPER_ADMIN',
    'Super Admin',
    'System administrator with full permissions',
    TRUE
),
(
    uuid_generate_v7(),
    'STAFF',
    'Staff',
    'Court management staff',
    TRUE
),
(
    uuid_generate_v7(),
    'CUSTOMER',
    'Customer',
    'Customer role',
    TRUE
);

--select * from auth.roles

-- Seed Permissions
-- User Management
INSERT INTO auth.permissions
(
    id,
    code,
    name,
    description
)
VALUES
(uuid_generate_v7(),'user.view','View Users','View users'),
(uuid_generate_v7(),'user.create','Create User','Create users'),
(uuid_generate_v7(),'user.update','Update User','Update users'),
(uuid_generate_v7(),'user.delete','Delete User','Delete users');

-- Role Management
INSERT INTO auth.permissions
(
    id,
    code,
    name,
    description
)
VALUES
(uuid_generate_v7(),'role.view','View Roles','View roles'),
(uuid_generate_v7(),'role.create','Create Role','Create roles'),
(uuid_generate_v7(),'role.update','Update Role','Update roles'),
(uuid_generate_v7(),'role.delete','Delete Role','Delete roles');

-- Permission Management
INSERT INTO auth.permissions
(
    id,
    code,
    name,
    description
)
VALUES
(uuid_generate_v7(),'permission.view','View Permissions','View permissions'),
(uuid_generate_v7(),'permission.create','Create Permission','Create permissions'),
(uuid_generate_v7(),'permission.update','Update Permission','Update permissions'),
(uuid_generate_v7(),'permission.delete','Delete Permission','Delete permissions');

-- Court Management
INSERT INTO auth.permissions
(
    id,
    code,
    name,
    description
)
VALUES
(uuid_generate_v7(),'court.view','View Courts','View courts'),
(uuid_generate_v7(),'court.create','Create Court','Create courts'),
(uuid_generate_v7(),'court.update','Update Court','Update courts'),
(uuid_generate_v7(),'court.delete','Delete Court','Delete courts');

-- Booking Management
INSERT INTO auth.permissions
(
    id,
    code,
    name,
    description
)
VALUES
(uuid_generate_v7(),'booking.view','View Bookings','View bookings'),
(uuid_generate_v7(),'booking.create','Create Booking','Create bookings'),
(uuid_generate_v7(),'booking.update','Update Booking','Update bookings'),
(uuid_generate_v7(),'booking.cancel','Cancel Booking','Cancel bookings');

-- Payment Management
INSERT INTO auth.permissions
(
    id,
    code,
    name,
    description
)
VALUES
(uuid_generate_v7(),'payment.view','View Payments','View payments'),
(uuid_generate_v7(),'payment.create','Create Payment','Create payments'),
(uuid_generate_v7(),'payment.refund','Refund Payment','Refund payments');

-- Dashboard & Reports
INSERT INTO auth.permissions
(
    id,
    code,
    name,
    description
)
VALUES
(uuid_generate_v7(),'dashboard.view','View Dashboard','View dashboard'),
(uuid_generate_v7(),'report.view','View Reports','View reports');

--3. Seed Role-Permission Mapping

Giả sử bảng:

auth.role_permissions
(
    role_id UUID,
    permission_id UUID
)

Super Admin

Gán toàn bộ permissions:

INSERT INTO auth.role_permissions
(
    role_id,
    permission_id
)
SELECT
    r.id,
    p.id
FROM auth.roles r
CROSS JOIN auth.permissions p
WHERE r.code = 'SUPER_ADMIN';

Staff
INSERT INTO auth.role_permissions
(
    role_id,
    permission_id
)
SELECT
    r.id,
    p.id
FROM auth.roles r
JOIN auth.permissions p
ON p.code IN
(
    'court.view',
    'court.create',
    'court.update',

    'booking.view',
    'booking.update',
    'booking.cancel',

    'payment.view',

    'dashboard.view'
)
WHERE r.code = 'STAFF';

Customer
INSERT INTO auth.role_permissions
(
    role_id,
    permission_id
)
SELECT
    r.id,
    p.id
FROM auth.roles r
JOIN auth.permissions p
ON p.code IN
(
    'court.view',

    'booking.view',
    'booking.create',
    'booking.cancel'
)
WHERE r.code = 'CUSTOMER';

-- Kiểm tra Role-Permission
SELECT
    r.code AS role_code,
    p.code AS permission_code
FROM auth.role_permissions rp
INNER JOIN auth.roles r
    ON rp.role_id = r.id
INNER JOIN auth.permissions p
    ON rp.permission_id = p.id
ORDER BY r.code, p.code;



