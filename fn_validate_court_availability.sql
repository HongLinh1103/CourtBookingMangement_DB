CREATE
	OR REPLACE FUNCTION booking.fn_validate_court_availability (
	p_court_id UUID
	,p_booking_date DATE
	,p_start_time TIME
	,p_end_time TIME
	)
RETURNS BOOLEAN LANGUAGE SQL AS $$

SELECT NOT EXISTS (
		SELECT 1
		FROM booking.bookings b
		INNER JOIN booking.booking_details bd ON b.id = bd.booking_id

		WHERE bd.court_id = p_court_id
			AND bd.booking_date = p_booking_date
			AND b.deleted_at IS NULL
			AND (
				p_start_time < bd.end_time
				AND p_end_time > bd.start_time
				) 
		);$$;



SELECT booking.fn_validate_court_availability(
    '3fa85f64-5717-4562-b3fc-2c963f66afa6'::UUID,  -- p_court_id
    '2026-09-25'::DATE,                            -- p_booking_date
    '14:00:00'::TIME,                              -- p_start_time
    '16:00:00'::TIME                               -- p_end_time
);



SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'booking';

