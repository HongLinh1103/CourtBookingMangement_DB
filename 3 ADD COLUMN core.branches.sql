    ALTER TABLE core.branches
    ADD COLUMN IF NOT EXISTS city varchar(100),
    ADD COLUMN IF NOT EXISTS district varchar(100),
    ADD COLUMN IF NOT EXISTS time_zone varchar(100) NOT NULL DEFAULT 'Asia/Ho_Chi_Minh'
    ADD COLUMN IF NOT EXISTS supports_instant_booking boolean NOT NULL DEFAULT false
    
    
    
CREATE INDEX idx_branch_pricings_branch
ON core.branch_pricings(branch_id);

CREATE INDEX idx_branch_pricings_active
ON core.branch_pricings(branch_id, is_active);

CREATE INDEX idx_branch_amenities_branch
ON core.branch_amenities(branch_id);

CREATE INDEX idx_branches_city
ON core.branches(city);

CREATE INDEX idx_branches_district
ON core.branches(district);

CREATE INDEX idx_branches_name_trgm
ON core.branches
USING gin(name gin_trgm_ops);