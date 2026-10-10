select * from auth.user_roles
select * from auth.users
select * from auth.roles r 

INSERT INTO auth.roles
(
id,
code,
name,
description,
is_active,
created_at,
updated_at
)
VALUES
(
uuid_generate_v7(),
'PLAYER',
'Người chơi',
'Khách hàng sử dụng hệ thống để tìm sân, đặt sân, thanh toán, tham gia ghép trận và quản lý hồ sơ cá nhân.',
TRUE,
NOW(),
NOW()
),
(
uuid_generate_v7(),
'STAFF',
'Nhân viên',
'Nhân viên vận hành sân, hỗ trợ đặt sân, check-in khách hàng và quản lý lịch sân.',
TRUE,
NOW(),
NOW()
),
(
uuid_generate_v7(),
'BRANCH_OWNER',
'Chủ chi nhánh',
'Quản lý hoạt động của một hoặc nhiều chi nhánh, sân, booking, nhân viên và báo cáo doanh thu.',
TRUE,
NOW(),
NOW()
),
(
uuid_generate_v7(),
'ADMIN',
'Quản trị viên hệ thống',
'Quản lý toàn bộ hệ thống, người dùng, phân quyền, chi nhánh, cấu hình và dữ liệu hệ thống.',
TRUE,
NOW(),
NOW()
);



INSERT INTO auth.user_roles (
user_id,
role_id,
assigned_at
)
SELECT
'be922ecc-128e-4955-88cd-da00ea061d5f'::uuid,
r.id,
NOW()
FROM auth.roles r
WHERE r.code = 'ADMIN';

INSERT INTO auth.user_roles (
user_id,
role_id,
assigned_at
)
SELECT
'be922ecc-128e-4955-88cd-da00ea061d5f'::uuid,
r.id,
NOW()
FROM auth.roles r
WHERE r.code = 'BRANCH_OWNER';

select * from auth.user_roles
select * from auth.users
select * from auth.roles r 
select * from auth.permissions
select * from auth.role_permissions
