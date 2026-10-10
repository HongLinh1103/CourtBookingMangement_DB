--drop FUNCTION core.fn_search_branches

SELECT *
FROM core.fn_search_branches();

CREATE 
OR REPLACE FUNCTION core.fn_search_branches (
  p_keyword TEXT DEFAULT NULL, 
  p_city TEXT DEFAULT NULL,
  p_district TEXT DEFAULT NULL, 
  p_amenities TEXT[] DEFAULT NULL, 
  p_min_price NUMERIC DEFAULT NULL, 
  p_max_price NUMERIC DEFAULT NULL, 
  p_only_open_now BOOLEAN DEFAULT FALSE, 
  p_only_instant_booking BOOLEAN DEFAULT FALSE, 
  p_date DATE DEFAULT NULL, 
  p_start_time TIME DEFAULT NULL, 
  p_end_time TIME DEFAULT NULL,
  p_time_slot TEXT DEFAULT 'all', 
  p_sort_by TEXT DEFAULT 'recommended', 
  p_page INTEGER DEFAULT 1, 
  p_page_size INTEGER DEFAULT 10
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
      oh.is_closed, 
      COALESCE (
        NOT oh.is_closed 
        AND CASE WHEN oh.open_time <= oh.close_time THEN (
          statement_timestamp() AT TIME ZONE b.time_zone
        ):: TIME >= oh.open_time 
        AND (
          statement_timestamp() AT TIME ZONE b.time_zone
        ):: TIME < oh.close_time ELSE (
          statement_timestamp() AT TIME ZONE b.time_zone
        ):: TIME >= oh.open_time 
        OR (
          statement_timestamp() AT TIME ZONE b.time_zone
        ):: TIME < oh.close_time END, 
        FALSE
      ) AS is_open_now 
    FROM 
      core.branches b 
      LEFT JOIN core.operating_hours oh ON oh.branch_id = b.id 
    WHERE 
      b.is_active = TRUE 
      AND b.deleted_at IS NULL 
      AND (
        p_city IS NULL 
        OR LOWER(b.city) = LOWER(
          TRIM(p_city)
        )
      ) 
      AND (
        p_district IS NULL 
        OR LOWER(b.district) = LOWER(
          TRIM(p_district)
        )
      ) 
      AND (
        NULLIF(
          TRIM(p_keyword), 
          ''
        ) IS NULL 
        OR b.name ILIKE '%' || TRIM(p_keyword) || '%' 
        OR b.address ILIKE '%' || TRIM(p_keyword) || '%'
      ) 
      AND (
        COALESCE(
          cardinality(p_amenities), 
          0
        ) = 0 
        OR NOT EXISTS (
          SELECT 
            1 
          FROM 
            unnest(p_amenities) requested(code) 
          WHERE 
            NOT EXISTS (
              SELECT 
                1 
              FROM 
                core.branches_amenities ba 
                INNER JOIN core.amenities a ON a.id = ba.amenity_id 
              WHERE 
                ba.branch_id = b.id 
                AND LOWER(a.code) = LOWER(
                  TRIM(requested.code)
                )
            )
        )
      )
  ), 
  branch_metrics AS (
    SELECT 
      bb.*, 
      court_stats.court_count, 
      court_stats.available_court_count, 
      pricing_stats.min_price, 
      pricing_stats.max_price 
    FROM 
      branch_base bb 
      LEFT JOIN LATERAL (
        SELECT 
          COUNT(*) FILTER (
            WHERE 
              c.is_active 
              AND c.deleted_at IS NULL 
              AND LOWER(c.status) IN ('active', 'available')
          ):: INTEGER AS court_count, 
          CASE WHEN p_date IS NULL THEN NULL WHEN p_time_slot = 'all' 
          AND p_start_time IS NULL THEN NULL ELSE COUNT(*) FILTER (
            WHERE 
              c.is_active
              AND c.deleted_at IS NULL 
              AND LOWER(c.status) IN ('active', 'avail*ble')
          ):: INTEGER END AS available_court_count 
        FROM 
          core.courts c 
        WHERE 
          c.branch_id = bb.id
      ) court_stats ON TRUE 
      LEFT JOIN LATERAL (
        SELECT 
          MIN(bp.price_per_hour) AS min_price, 
          MAX(bp.price_per_hour) AS max_price 
        FROM 
          core.branch_pricings bp 
        WHERE 
          bp.branch_id = bb.id 
          AND bp.is_active = TRUE
      ) pricing_stats ON TRUE
  ), 
  filtered AS (
    SELECT 
      * 
    FROM 
      branch_metrics 
    WHERE 
      (
        NOT COALESCE(p_only_open_now, FALSE) 
        OR is_open_now
      ) 
      AND (
        NOT COALESCE(p_only_instant_booking, FALSE) 
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
      id ASC 
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
      p.id, 
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
            COALESCE (
              jsonb_agg (
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
        'images', 
        (
          SELECT 
            COALESCE (
              jsonb_agg(img.image), 
              '[]' :: jsonb
            ) 
          FROM 
            (
              SELECT 
                jsonb_build_object(
                  'url', ci.image_url, 'sortOrder', 
                  ci.sort_order, 'courtId', c.id
                ) AS image 
              FROM 
                core.courts c 
                INNER JOIN core.court_images ci ON ci.court_id = c.id 
              WHERE 
                c.branch_id = p.id 
                AND c.is_active 
                AND c.deleted_at IS NULL 
                AND ci.is_active 
              ORDER BY 
                ci.sort_order 
              LIMIT 
                10
            ) img
        ), 
        'operatingHours', 
        jsonb_build_object(
          'open', p.open_time, 'close', p.close_time, 
          'isClosed', p.is_closed
        )
      ) AS item 
    FROM 
      paged p
  ) 
SELECT 
  t.total_count, 
  COALESCE (
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
