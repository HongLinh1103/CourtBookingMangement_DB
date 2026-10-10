
SELECT *
FROM core.fn_search_branches();
``
CREATE 
OR REPLACE FUNCTION core.fn_search_branches (
  p_keyword TEXT DEFAULT NULL, p_city TEXT DEFAULT NULL, 
  p_district TEXT DEFAULT NULL, p_amenities TEXT[] DEFAULT NULL, 
  p_min_price NUMERIC DEFAULT NULL, 
  p_max_price NUMERIC DEFAULT NULL, 
  p_only_open_now BOOLEAN DEFAULT FALSE, 
  p_only_instant_booking BOOLEAN DEFAULT FALSE, 
  p_sort_by TEXT DEFAULT 'recommended', 
  p_page INTEGER DEFAULT 1, p_page_size INTEGER DEFAULT 20
) RETURNS TABLE (total_count BIGINT, items JSONB) LANGUAGE SQL STABLE AS $$ 
WITH 
  branch_base AS (
    SELECT 
      b.id, 
      b.name, 
      b.address, 
      b.city, 
      b.district, 
      b.latitude, 
      b.longitude, 
      b.phone_number, 
      b.supports_instant_booking, 
      b.time_zone, 
      oh.open_time, 
      oh.close_time, 
      oh.is_closed 
    FROM 
      core.branches b 
      LEFT JOIN core.operating_hours oh ON oh.branch_id = b.id 
    WHERE 
      b.is_active = TRUE 
      AND b.deleted_at IS NULL 
      AND (
        p_city IS NULL 
        OR lower(b.city) = lower(
          trim(p_city)
        )
      ) 
      AND (
        p_district IS NULL 
        OR lower(b.district) = lower(
          trim(p_district)
        )
      ) 
      AND (
        COALESCE(
          trim(p_keyword), 
          ''
        ) = '' 
        OR b.name ILIKE '%' || trim(p_keyword) || '%' 
        OR b.address ILIKE '%' || trim(p_keyword) || '%'
      ) 
      AND (
        cardinality(
          COALESCE(p_amenities, ARRAY[] :: TEXT[])
        ) = 0 
        OR NOT EXISTS (
          SELECT 
            1 
          FROM 
            unnest(p_amenities) req(code) 
          WHERE 
            NOT EXISTS (
              SELECT 
                1 
              FROM 
                core.branches_amenities ba 
                INNER JOIN core.amenities a ON a.id = ba.amenity_id 
              WHERE 
                ba.branch_id = b.id 
                AND lower(a.code) = lower(req.code)
            )
        )
      )
  ), 
  branch_stats AS (
    SELECT 
      bb.*, 
      COALESCE(court_info.court_count, 0) AS court_count, 
      COALESCE(
        court_info.available_court_count, 
        0
      ) AS available_court_count, 
      pricing_info.min_price, 
      pricing_info.max_price, 
      CASE WHEN bb.is_closed THEN FALSE WHEN bb.open_time IS NULL 
      OR bb.close_time IS NULL THEN FALSE WHEN bb.open_time <= bb.close_time THEN (
        CURRENT_TIME >= bb.open_time 
        AND CURRENT_TIME < bb.close_time
      ) ELSE (
        CURRENT_TIME >= bb.open_time 
        OR CURRENT_TIME < bb.close_time
      ) END AS is_open_now 
    FROM 
      branch_base bb 
      LEFT JOIN LATERAL (
        SELECT 
          COUNT(*):: INTEGER AS court_count, 
          COUNT(*) FILTER (
            WHERE 
              lower(c.status) IN ('active', 'available')
          ):: INTEGER AS available_court_count 
        FROM 
          core.courts c 
        WHERE 
          c.branch_id = bb.id 
          AND c.is_active = TRUE 
          AND c.deleted_at IS NULL
      ) court_info ON TRUE 
      LEFT JOIN LATERAL (
        SELECT 
          MIN(bp.price_per_hour) AS min_price, 
          MAX(bp.price_per_hour) AS max_price 
        FROM 
          core.branch_pricings bp 
        WHERE 
          bp.branch_id = bb.id 
          AND bp.is_active = TRUE
      ) pricing_info ON TRUE
  ), 
  filtered AS (
    SELECT 
      * 
    FROM 
      branch_stats 
    WHERE 
      (
        NOT p_only_open_now 
        OR is_open_now
      ) 
      AND (
        NOT p_only_instant_booking 
        OR supports_instant_booking
      ) 
      AND (
        p_min_price IS NULL 
        OR min_price >= p_min_price
      ) 
      AND (
        p_max_price IS NULL 
        OR max_price <= p_max_price
      )
  ), 
  total AS (
    SELECT 
      COUNT(*):: BIGINT AS total_count 
    FROM 
      filtered
  ), 
  paged AS (
    SELECT 
      * 
    FROM 
      filtered 
    ORDER BY 
      CASE WHEN p_sort_by = 'price_asc' THEN min_price END ASC NULLS LAST, 
      CASE WHEN p_sort_by = 'price_desc' THEN min_price END DESC NULLS LAST, 
      CASE WHEN p_sort_by = 'courts_desc' THEN court_count END DESC NULLS LAST, 
      name ASC 
    LIMIT 
      LEAST(
        GREATEST(
          COALESCE(p_page_size, 20), 
          1
        ), 
        100
      ) OFFSET (
        GREATEST(
          COALESCE(p_page, 1), 
          1
        ) -1
      ) * LEAST(
        GREATEST(
          COALESCE(p_page_size, 20), 
          1
        ), 
        100
      )
  ), 
  page_items AS (
    SELECT 
      jsonb_build_object(
        'id', 
        p.id, 
        'name', 
        p.name, 
        'address', 
        p.address, 
        'city', 
        p.city, 
        'district', 
        p.district, 
        'coordinates', 
        jsonb_build_object(
          'lat', p.latitude, 'lng', p.longitude
        ), 
        'phoneNumber', 
        p.phone_number, 
        'courtCount', 
        p.court_count, 
        'availableCourtCount', 
        p.available_court_count, 
        'priceRange', 
        jsonb_build_object(
          'min', p.min_price, 'max', p.max_price, 
          'currency', 'VND'
        ), 
        'isOpenNow', 
        p.is_open_now, 
        'supportsInstantBooking', 
        p.supports_instant_booking, 
        'amenities', 
        (
          SELECT 
            COALESCE(
              jsonb_agg(
                jsonb_build_object(
                  'id', a.id, 'code', a.code, 'name', 
                  a.name, 'icon', a.icon
                ) 
                ORDER BY 
                  a.name
              ), 
              '[]' :: jsonb
            ) 
          FROM 
            core.branches_amenities ba 
            INNER JOIN core.amenities a ON a.id = ba.amenity_id 
          WHERE 
            ba.branch_id = p.id
        ), 
        'operatingHours', 
        jsonb_build_object(
          'open', p.open_time, 'close', p.close_time
        )
      ) AS item 
    FROM 
      paged p
  ) 
SELECT 
  t.total_count, 
  COALESCE(
    (
      SELECT 
        jsonb_agg(item) 
      FROM 
        page_items
    ), 
    '[]' :: jsonb
  ) 
FROM 
  total t;
$$;
