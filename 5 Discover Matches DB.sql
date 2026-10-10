
SQL
-- =========================================
-- CREATE SCHEMA
-- =========================================
 
CREATE SCHEMA IF NOT EXISTS matching;
--Cần tìm 3 người chơi trình độ Trung Bình
--Ngày: 12/10/2026
--18:00 - 20:00
--Chi nhánh Quận 7

CREATE TABLE matching.player_matches
(
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),

    created_by UUID NOT NULL
        REFERENCES auth.users(id),

    branch_id UUID NOT NULL
        REFERENCES core.branches(id),

    court_id UUID NULL
        REFERENCES core.courts(id),

    title VARCHAR(200) NOT NULL,

    description TEXT,

    match_date DATE NOT NULL,

    start_time TIME NOT NULL,

    end_time TIME NOT NULL,

    skill_level VARCHAR(30) NOT NULL,

    gender_preference VARCHAR(30),

    max_players INT NOT NULL,

    current_players INT NOT NULL DEFAULT 1,

    fee_per_player NUMERIC(12,2),

    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- skill_level stored by string value
BEGINNER
INTERMEDIATE
ADVANCED
PRO

-- status stored by string value
OPEN
FULL
CANCELLED
COMPLETED


-- Match Participants
CREATE TABLE matching.match_participants
(
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),

    match_id UUID NOT NULL
        REFERENCES matching.player_matches(id),

    user_id UUID NOT NULL
        REFERENCES auth.users(id),

    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    role VARCHAR(20) NOT NULL DEFAULT 'PLAYER',

    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT uq_match_participant
    UNIQUE(match_id, user_id)
);

-- role stored by string value
HOST
PLAYER

-- status stored by string value
ACTIVE
LEFT
REMOVED


-- 3. Match Join Requests
-- Người dùng gửi yêu cầu tham gia.

-- Workflow:

--OPEN MATCH

--Người chơi A
     ↓
--REQUEST JOIN
     ↓
--HOST APPROVE
     ↓
--MATCH PARTICIPANTS
     
 CREATE TABLE matching.match_join_requests
(
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),

    match_id UUID NOT NULL
        REFERENCES matching.player_matches(id),

    requester_id UUID NOT NULL
        REFERENCES auth.users(id),

    note VARCHAR(500),

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    reviewed_at TIMESTAMPTZ,

    reviewed_by UUID
        REFERENCES auth.users(id),

    CONSTRAINT uq_join_request
    UNIQUE(match_id, requester_id)
);    

-- status stored by string value
PENDING
APPROVED
REJECTED
CANCELLED

-- 4. Match Notifications
Thông báo cho người chơi.
--Ví dụ:
--Bạn có người muốn tham gia trận.

--Nguyễn Văn A đã tham gia trận.

--Trận đã đủ người.

--Trận bị hủy.

CREATE TABLE matching.match_notifications
(
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),

    user_id UUID NOT NULL
        REFERENCES auth.users(id),

    match_id UUID NULL
        REFERENCES matching.player_matches(id),

    type VARCHAR(50) NOT NULL,

    title VARCHAR(255) NOT NULL,

    message TEXT NOT NULL,

    is_read BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    read_at TIMESTAMPTZ
);

-- Notification type stored by string value
 MATCH_CREATED
JOIN_REQUEST
JOIN_APPROVED
JOIN_REJECTED
PLAYER_JOINED
MATCH_FULL
MATCH_CANCELLED
MATCH_REMINDER


CREATE INDEX idx_player_matches_branch
ON matching.player_matches(branch_id);

CREATE INDEX idx_player_matches_date
ON matching.player_matches(match_date);

CREATE INDEX idx_player_matches_status
ON matching.player_matches(status);

CREATE INDEX idx_match_participants_match
ON matching.match_participants(match_id);

CREATE INDEX idx_match_participants_user
ON matching.match_participants(user_id);

CREATE INDEX idx_join_requests_match
ON matching.match_join_requests(match_id);

CREATE INDEX idx_notifications_user
ON matching.match_notifications(user_id);

CREATE INDEX idx_notifications_unread
ON matching.match_notifications(user_id, is_read);

ALTER TABLE customer.customers
	ALTER COLUMN email TYPE varchar(100);








