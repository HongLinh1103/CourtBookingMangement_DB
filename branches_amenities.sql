--Amenities
--├── Parking
--├── Locker
--├── Shower
--├── Wifi
--├── Rental Racket
--├── Pro Shop
--└── Cafe

CREATE TABLE core.amenities (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    code        VARCHAR(30) NOT NULL,
    name        VARCHAR(100) NOT NULL,
    icon        VARCHAR(50)
);
CREATE UNIQUE INDEX ux_amenities_code ON core.amenities (code);

select * from core.branches b 

CREATE TABLE core.branches_amenities ( 
    branch_id    UUID NOT NULL REFERENCES core.branches(id) ,
    amenity_id  UUID NOT NULL REFERENCES core.amenities(id),
    PRIMARY KEY (branch_id, amenity_id)
);


INSERT INTO core.amenities (id, code, name, icon) VALUES
(uuid_generate_v7(), 'PARKING', 'Bãi đỗ xe', 'parking'),
(uuid_generate_v7(), 'LOCKER', 'Tủ gửi đồ', 'locker'),
(uuid_generate_v7(), 'SHOWER', 'Phòng tắm', 'shower'),
(uuid_generate_v7(), 'TOILET', 'Nhà vệ sinh', 'toilet'),
(uuid_generate_v7(), 'WIFI', 'Wifi miễn phí', 'wifi'),
(uuid_generate_v7(), 'AIRCON', 'Máy lạnh', 'air-conditioner'),
(uuid_generate_v7(), 'DRINK', 'Quầy nước giải khát', 'drink'),
(uuid_generate_v7(), 'RENT_RACKET', 'Cho thuê vợt', 'racket'),
(uuid_generate_v7(), 'RENT_SHOES', 'Cho thuê giày', 'shoes'),
(uuid_generate_v7(), 'PROSHOP', 'Cửa hàng dụng cụ cầu lông', 'shop'),
(uuid_generate_v7(), 'CAMERA', 'Camera an ninh', 'camera'),
(uuid_generate_v7(), 'SEATING', 'Khu vực ghế chờ', 'chair'),
(uuid_generate_v7(), 'CANTEEN', 'Căng tin', 'canteen'),
(uuid_generate_v7(), 'TRAINER', 'Huấn luyện viên', 'coach'),
(uuid_generate_v7(), 'FIRST_AID', 'Tủ sơ cứu', 'medical');


INSERT INTO core.branches_amenities (branch_id, amenity_id) VALUES

-- Chi nhánh 1 (Premium)
('a66e69ce-5711-49df-bb0c-e45e1140cffb', '336e9d7e-26d7-4dba-a749-29c85580cd19'),
('a66e69ce-5711-49df-bb0c-e45e1140cffb', '686db52e-e4f8-4919-b5ac-1a049341ae2a'),
('a66e69ce-5711-49df-bb0c-e45e1140cffb', '8c8e8f2d-470b-4ecd-a5b5-76f5b095ec6b'),
('a66e69ce-5711-49df-bb0c-e45e1140cffb', 'd7820c55-cca7-4c7f-9d66-fba470525f4f'),
('a66e69ce-5711-49df-bb0c-e45e1140cffb', '13f19ac6-45d9-4566-81d3-16f85763c26e'),
('a66e69ce-5711-49df-bb0c-e45e1140cffb', '6316cb01-f152-416e-8695-766275a3c109'),
('a66e69ce-5711-49df-bb0c-e45e1140cffb', '46638534-f8cb-4700-98ee-c3f66598cb42'),
('a66e69ce-5711-49df-bb0c-e45e1140cffb', '9e034031-0337-4712-b993-7c2c3951b4c4'),

-- Chi nhánh 2 (Standard)
('d3b43956-305e-47db-ad84-c24f33c68767', '336e9d7e-26d7-4dba-a749-29c85580cd19'),
('d3b43956-305e-47db-ad84-c24f33c68767', '686db52e-e4f8-4919-b5ac-1a049341ae2a'),
('d3b43956-305e-47db-ad84-c24f33c68767', '13f19ac6-45d9-4566-81d3-16f85763c26e'),
('d3b43956-305e-47db-ad84-c24f33c68767', '46638534-f8cb-4700-98ee-c3f66598cb42'),
('d3b43956-305e-47db-ad84-c24f33c68767', '9e034031-0337-4712-b993-7c2c3951b4c4'),
('d3b43956-305e-47db-ad84-c24f33c68767', 'e24940b1-889a-4fd8-9614-855c28820662'),

-- Chi nhánh 3 (VIP Full Service)
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '336e9d7e-26d7-4dba-a749-29c85580cd19'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '686db52e-e4f8-4919-b5ac-1a049341ae2a'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '8c8e8f2d-470b-4ecd-a5b5-76f5b095ec6b'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', 'd7820c55-cca7-4c7f-9d66-fba470525f4f'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '13f19ac6-45d9-4566-81d3-16f85763c26e'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '6316cb01-f152-416e-8695-766275a3c109'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '46638534-f8cb-4700-98ee-c3f66598cb42'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '9e034031-0337-4712-b993-7c2c3951b4c4'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', 'e24940b1-889a-4fd8-9614-855c28820662'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '27c728f4-321d-4048-a633-6a921a592de5'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '8bc389ae-70fe-4384-bbc1-a5878b290aff'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '32a2a907-33dd-4cb3-9a9d-04c69805a47f'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '1dc9f45d-ff2d-4e18-9c94-306c38b444b6'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', '7f2bc687-ddc6-4a2f-ae04-a1cad13bcf79'),
('7bbd6ee2-6856-49f6-9821-3169edfd7d92', 'a2f1b86c-7cc3-41b4-b361-40a124de4f2d')
