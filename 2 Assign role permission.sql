INSERT INTO auth.role_permissions (
    role_id,
    permission_id
)
SELECT
    r.id,
    p.id
FROM auth.roles r
CROSS JOIN auth.permissions p
WHERE r.code = 'ADMIN'
AND p.code IN (
    'user.view',
    'user.create',
    'user.update',
    'user.delete',

    'role.view',
    'role.create',
    'role.update',
    'role.delete',

    'permission.view',
    'permission.create',
    'permission.update',
    'permission.delete',

    'court.view',
    'court.create',
    'court.update',
    'court.delete',

    'booking.view',
    'booking.create',
    'booking.update',
    'booking.cancel',

    'payment.view',
    'payment.create',
    'payment.refund',

    'dashboard.view',
    'report.view'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;