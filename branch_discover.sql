WITH params AS
(
SELECT
NULL::VARCHAR AS keyword,
NULL::VARCHAR AS city,
NULL::VARCHAR AS district,
NULL::NUMERIC AS min_price,
NULL::NUMERIC AS max_price,
NULL::DATE AS booking_date,
NULL::TIME AS start_time,
NULL::TIME AS end_time
)

SELECT
    b.id AS Id,
    b.name AS Name,
    b.address AS Address,
    b.district AS District,
    b.city AS City,
    b.latitude AS Latitude,
    b.longitude AS Longitude,
    b.phone_number AS Phone,

    (
        SELECT COUNT(*)::INT
        FROM core.courts c
        WHERE c.branch_id = b.id
          AND c.is_active = TRUE
          AND c.deleted_at IS NULL
          AND LOWER(c.status) = 'active'
    ) AS CourtsCount,

    pricing.min_price AS MinPrice,
    pricing.max_price AS MaxPrice,

    oh.open_time AS OpenTime,
    oh.close_time AS CloseTime,

    COALESCE(
        NOT oh.is_closed
        AND (NOW() AT TIME ZONE b.time_zone)::TIME >= oh.open_time
        AND (NOW() AT TIME ZONE b.time_zone)::TIME < oh.close_time,
        FALSE
    ) AS IsOpenNow,

    COUNT(*) OVER() AS TotalCount

FROM core.branches b
CROSS JOIN params p
LEFT JOIN core.operating_hours oh
    ON oh.branch_id = b.id

LEFT JOIN LATERAL
(
    SELECT
        MIN(bp.price_per_hour) AS min_price,
        MAX(bp.price_per_hour) AS max_price
    FROM core.branch_pricings bp
    WHERE bp.branch_id = b.id
      AND bp.is_active = TRUE
      AND (
            p.start_time IS NULL
            OR (
                bp.start_time < p.end_time
                AND p.start_time < bp.end_time
            )
          )
) pricing
ON TRUE
---

----
WHERE b.is_active = TRUE
  AND b.deleted_at IS NULL

  AND (
        p.keyword IS NULL
        OR b.name ILIKE '%' || p.keyword || '%'
        OR b.address ILIKE '%' || p.keyword || '%'
        OR COALESCE(b.city, '') ILIKE '%' || p.keyword || '%'
        OR COALESCE(b.district, '') ILIKE '%' || p.keyword || '%'
      )

  AND (
        p.city IS NULL
        OR b.city ILIKE p.city
      )

  AND (
        p.district IS NULL
        OR b.district ILIKE p.district
      )

  AND (
        p.min_price IS NULL
        OR pricing.max_price >= p.min_price
      )

  AND (
        p.max_price IS NULL
        OR pricing.min_price <= p.max_price
      )

  AND (
        p.booking_date IS NULL
        OR
        (
            oh.branch_id IS NOT NULL
            AND NOT oh.is_closed

            AND EXISTS
            (
                SELECT 1
                FROM core.courts c
                WHERE c.branch_id = b.id
                  AND c.is_active = TRUE
                  AND c.deleted_at IS NULL
                  AND LOWER(c.status) = 'active'

                  AND
                  (
                      (
                          p.start_time IS NOT NULL

                          AND p.start_time >= oh.open_time
                          AND p.end_time <= oh.close_time

                          AND NOT EXISTS
                          (
                              SELECT 1
                              FROM booking.booking_details bd
                              JOIN booking.bookings bk
                                  ON bk.id = bd.booking_id
                              WHERE bd.court_id = c.id
                                AND bd.booking_date = p.booking_date
                                AND bd.start_time < p.end_time
                                AND p.start_time < bd.end_time
                                AND bk.is_active = TRUE
                                AND bk.deleted_at IS NULL
                                AND LOWER(bk.status)
                                    NOT IN ('cancelled', 'completed')
                          )
                      )

                      OR

                      (
                          p.start_time IS NULL

                          AND EXISTS
                          (
                              SELECT 1
                              FROM
                              (
                                  SELECT oh.open_time AS candidate_time

                                  UNION

                                  SELECT bd.end_time
                                  FROM booking.booking_details bd
                                  JOIN booking.bookings bk
                                      ON bk.id = bd.booking_id
                                  WHERE bd.court_id = c.id
                                    AND bd.booking_date = p.booking_date
                                    AND bd.end_time > oh.open_time
                                    AND bd.end_time < oh.close_time
                                    AND bk.is_active = TRUE
                                    AND bk.deleted_at IS NULL
                                    AND LOWER(bk.status)
                                        NOT IN ('cancelled', 'completed')
                              ) candidates

                              WHERE NOT EXISTS
                              (
                                  SELECT 1
                                  FROM booking.booking_details bd
                                  JOIN booking.bookings bk
                                      ON bk.id = bd.booking_id
                                  WHERE bd.court_id = c.id
                                    AND bd.booking_date = p.booking_date
                                    AND bd.start_time <= candidates.candidate_time
                                    AND candidates.candidate_time < bd.end_time
                                    AND bk.is_active = TRUE
                                    AND bk.deleted_at IS NULL
                                    AND LOWER(bk.status)
                                        NOT IN ('cancelled', 'completed')
                              )
                          )
                      )
                  )
            )
        )
      )