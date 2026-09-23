CREATE OR REPLACE FUNCTION booking.fn_get_court_status
(
    p_branch_id UUID,
    p_date DATE
)
RETURNS TABLE
(
    branch_id UUID,
    branch_name VARCHAR,
    open_time TIME,
    close_time TIME,
    court_id UUID,
    court_number VARCHAR,
    court_name VARCHAR,
    court_status VARCHAR,
    booking_id UUID,
    start_time TIME,
    end_time TIME,
    booking_type VARCHAR,
    booking_status VARCHAR,
    payment_status VARCHAR,
    customer_name VARCHAR,
    phone_number VARCHAR,
    title VARCHAR,
    color VARCHAR
)
LANGUAGE SQL
AS
$$

SELECT

    b.id,
    b.name,
    oh.open_time,
    oh.close_time,
    c.id,
    c.court_number,
    COALESCE(c.name,'') AS court_name,
    c.status,
    bk.id,
    bd.start_time,
    bd.end_time,
    bk.booking_type,
    bk.status,
    COALESCE(pay.status,'UNPAID'),
    cust.full_name,
    cust.phone_number,
    CONCAT(
        cust.full_name,
        ' - ',
        cust.phone_number
    ),

    CASE
        WHEN bk.booking_type = 'FIXED'
            THEN '#35A8DB'

        WHEN bk.booking_type = 'DAILY'
            THEN '#31D37D'

        WHEN bk.booking_type = 'FLEXIBLE'
            THEN '#E2B93B'

        ELSE '#CCCCCC'
    END

FROM core.branches b INNER JOIN core.operating_hours oh ON oh.branch_id = b.id
INNER JOIN core.courts c ON c.branch_id = b.id
INNER JOIN booking.booking_details bd on bd.court_id = c.id AND bd.booking_date = p_date
INNER JOIN booking.bookings bk ON bk.id  = bd.booking_id  AND  bk.deleted_at IS NULL
LEFT JOIN customer.customers cust ON cust.id = bk.customer_id
LEFT JOIN
(
    SELECT
        booking_id,
        status
    FROM payment.payments
    GROUP BY booking_id, status
) pay ON pay.booking_id = bk.id

WHERE
    b.id = p_branch_id
    AND c.deleted_at IS NULL

ORDER BY
    c.court_number,
    bd.start_time;

$$;

SELECT *
FROM booking.fn_get_court_status
(
    'e30d74f1-2db6-4e42-bd9f-77431e59f501',
    '2026-08-14'
);