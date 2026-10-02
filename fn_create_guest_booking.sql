
drop FUNCTION booking.fn_create_guest_booking

CREATE OR REPLACE FUNCTION booking.fn_create_guest_booking
(
    p_branch_id      UUID,
    p_court_id       UUID,
    p_booking_date   DATE,
    p_start_time     TIME,
    p_end_time       TIME,
    p_customer_name  VARCHAR,
    p_phone_number   VARCHAR,
    p_note           TEXT,
    p_payment_method VARCHAR
)
RETURNS TABLE
(
    booking_id      UUID,
    booking_code    VARCHAR,
    booking_status  VARCHAR,
    customer_name   VARCHAR,  
    total_amount    NUMERIC,
    payment_method  VARCHAR,
    booking_date    DATE,
    branch_name   VARCHAR,
    start_time      TIME,
    end_time        TIME,
    created_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
AS
$$
DECLARE

    v_customer_id      UUID;
    v_booking_id       UUID;
    v_booking_code     VARCHAR(50);

    v_branch_exists    BOOLEAN;
	v_branch_name      VARCHAR(50);
    v_court_exists     BOOLEAN;
    v_court_active     BOOLEAN;

    v_open_time        TIME;
    v_close_time       TIME;

    v_price            NUMERIC(12,2) := 0;

BEGIN

    --------------------------------------------------
    -- Validate branch
    --------------------------------------------------

    SELECT EXISTS
    (
        SELECT 1
        FROM core.branches
        WHERE id = p_branch_id
          AND is_active = TRUE
          AND deleted_at IS NULL
    )
    INTO v_branch_exists;

    IF NOT v_branch_exists THEN
        RAISE EXCEPTION 'Branch not found';
    END IF;

    --------------------------------------------------
    -- Validate court
    --------------------------------------------------

    SELECT EXISTS
    (
        SELECT 1
        FROM core.courts c
        WHERE c.id = p_court_id
          AND c.branch_id = p_branch_id
          AND c.is_active = TRUE
          AND c.deleted_at IS NULL
    )
    INTO v_court_exists;

    IF NOT v_court_exists THEN
        RAISE EXCEPTION 'Court not found';
    END IF;

    --------------------------------------------------
    -- Get operating hours
    --------------------------------------------------

    SELECT
        open_time,
        close_time
    INTO
        v_open_time,
        v_close_time
    FROM core.operating_hours
    WHERE branch_id = p_branch_id;

    IF v_open_time IS NULL THEN
        RAISE EXCEPTION 'Operating hours not configured';
    END IF;

    --------------------------------------------------
    -- Validate operating hours
    --------------------------------------------------

    IF p_start_time < v_open_time
       OR p_end_time > v_close_time THEN

        RAISE EXCEPTION
            'Booking time is outside operating hours';

    END IF;

    --------------------------------------------------
    -- Validate time range
    --------------------------------------------------

    IF p_end_time <= p_start_time THEN
        RAISE EXCEPTION
            'End time must be greater than start time';
    END IF;

	--------------------------------------------------
    -- Find existing customer
    --------------------------------------------------

    SELECT id
    INTO v_customer_id
    FROM customer.customers
    WHERE phone_number = p_phone_number
    LIMIT 1;

    --------------------------------------------------
    -- Create customer if not exists
    --------------------------------------------------

    IF v_customer_id IS NULL THEN

        v_customer_id := uuid_generate_v7();

        INSERT INTO customer.customers
        (
            id,
            full_name,
            phone_number,
            created_at
        )
        VALUES
        (
            v_customer_id,
            p_customer_name,
            p_phone_number,
            NOW()
        );

    END IF;


    --------------------------------------------------
    -- Generate booking id
    --------------------------------------------------

    v_booking_id := uuid_generate_v7();

	v_branch_name = (SELECT b.name
        FROM core.branches b
        WHERE b.id = p_branch_id);

    v_booking_code :=
        'BK'
        || TO_CHAR(NOW(),'YYYYMMDD')
        || LPAD(
            FLOOR(RANDOM() * 9999)::TEXT,
            4,
            '0'
        );

    --------------------------------------------------
    -- TODO:
    -- Calculate pricing
    --------------------------------------------------

    v_price := 0;

    --------------------------------------------------
    -- Create booking
    --------------------------------------------------

    INSERT INTO booking.bookings
    (
        id,
        booking_code,
        customer_id,
        branch_id,
        status,
        booking_type,
        subtotal_amount,
        discount_amount,
        total_amount,
        payment_method,
        notes
    )
    VALUES
    (
        v_booking_id,
        v_booking_code,
        v_customer_id,
        p_branch_id,
        'Pending',
        'WalkIn',
        v_price,
        0,
        v_price,
        p_payment_method,
        p_note
    );

    --------------------------------------------------
    -- Create booking detail
    --------------------------------------------------

    INSERT INTO booking.booking_details
    (
        booking_id,
        court_id,
        booking_date,
        start_time,
        end_time,
        price_charged
    )
    VALUES
    (
        v_booking_id,
        p_court_id,
        p_booking_date,
        p_start_time,
        p_end_time,        
        v_price
    );

    --------------------------------------------------
    -- Return result
    --------------------------------------------------

    RETURN QUERY

    SELECT
        v_booking_id,
        v_booking_code,
        'Pending' ::VARCHAR,
        p_customer_name,
        v_price,
        p_payment_method,
        p_booking_date,
        v_branch_name,
        p_start_time,
        p_end_time,
        NOW();

END;
$$;