DO $$
DECLARE
    v_org_ids UUID[] := ARRAY[
        'a0000000-0000-0000-0000-000000000001'::uuid,
        'a0000000-0000-0000-0000-000000000002'::uuid,
        'a0000000-0000-0000-0000-000000000003'::uuid,
        'a0000000-0000-0000-0000-000000000004'::uuid,
        'a0000000-0000-0000-0000-000000000005'::uuid
    ];
    v_cities TEXT[] := ARRAY['delhi', 'mumbai', 'bangalore', 'jaipur', 'goa', 'hyderabad', 'chennai', 'kolkata'];
    v_statuses TEXT[] := ARRAY['CONFIRMED', 'CANCELLED', 'CHECKED_IN', 'CHECKED_OUT', 'PENDING'];
    v_hotels TEXT[] := ARRAY['HOTEL_RADISSON', 'HOTEL_TAJ', 'HOTEL_MARRIOTT', 'HOTEL_HYATT', 'HOTEL_LEELA', 'HOTEL_NOVOTEL', 'HOTEL_HILTON'];
    v_channels TEXT[] := ARRAY['web', 'mobile_ios', 'mobile_android', 'corporate_portal', 'api_partner'];
    v_payment_methods TEXT[] := ARRAY['credit_card', 'upi', 'net_banking', 'corporate_account'];
    
    v_booking_id UUID;
    v_org_id UUID;
    v_hotel_id VARCHAR(100);
    v_city VARCHAR(100);
    v_status VARCHAR(50);
    v_amount NUMERIC(12,2);
    v_created_at TIMESTAMP;
    v_checkin DATE;
    v_checkout DATE;
    v_days_ago INT;
    i INT;
BEGIN
    FOR i IN 1..160 LOOP
        v_booking_id := ('b' || LPAD(i::text, 7, '0') || '-0000-0000-0000-000000000000')::uuid;
        v_org_id := v_org_ids[1 + ((i * 3) % array_length(v_org_ids, 1))];
        v_city := v_cities[1 + ((i * 5) % array_length(v_cities, 1))];
        v_hotel_id := v_hotels[1 + ((i * 2) % array_length(v_hotels, 1))] || '_' || UPPER(v_city);
        v_status := v_statuses[1 + ((i * 7) % array_length(v_statuses, 1))];
        v_amount := ROUND((2500 + ((i * 437) % 35000))::numeric, 2);
        
        v_days_ago := (i % 60);
        v_created_at := (CURRENT_TIMESTAMP - (v_days_ago || ' days')::interval - ((i * 13 % 23) || ' hours')::interval);
        v_checkin := (v_created_at + INTERVAL '5 days')::date;
        v_checkout := (v_checkin + ((1 + (i % 5)) || ' days')::interval)::date;

        INSERT INTO hotel_bookings (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
        VALUES (v_booking_id, v_org_id, v_hotel_id, v_city, v_checkin, v_checkout, v_amount, v_status, v_created_at)
        ON CONFLICT (id) DO NOTHING;

        INSERT INTO booking_events (booking_id, event_type, payload, created_at)
        VALUES (
            v_booking_id,
            'BOOKING_CREATED',
            jsonb_build_object(
                'channel', v_channels[1 + ((i * 4) % array_length(v_channels, 1))],
                'booking_amount', v_amount,
                'currency', 'INR',
                'customer_tier', CASE WHEN i % 3 = 0 THEN 'PLATINUM' WHEN i % 2 = 0 THEN 'GOLD' ELSE 'STANDARD' END
            ),
            v_created_at
        );

        IF v_status IN ('CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT') THEN
            INSERT INTO booking_events (booking_id, event_type, payload, created_at)
            VALUES (
                v_booking_id,
                'PAYMENT_SUCCESS',
                jsonb_build_object(
                    'transaction_id', 'TXN_' || MD5(v_booking_id::text),
                    'payment_method', v_payment_methods[1 + ((i * 3) % array_length(v_payment_methods, 1))],
                    'status', 'CAPTURED',
                    'amount_paid', v_amount
                ),
                v_created_at + INTERVAL '2 minutes'
            );
        END IF;

        IF v_status IN ('CHECKED_IN', 'CHECKED_OUT') THEN
            INSERT INTO booking_events (booking_id, event_type, payload, created_at)
            VALUES (
                v_booking_id,
                'GUEST_CHECKED_IN',
                jsonb_build_object(
                    'room_assigned', 100 + (i % 400),
                    'keycard_issued', true,
                    'checkin_time', v_checkin::text || ' 14:00:00'
                ),
                (v_checkin::text || ' 14:00:00')::timestamp
            );
        END IF;

        IF v_status = 'CANCELLED' THEN
            INSERT INTO booking_events (booking_id, event_type, payload, created_at)
            VALUES (
                v_booking_id,
                'BOOKING_CANCELLED',
                jsonb_build_object(
                    'reason', 'Customer requested cancellation via portal',
                    'refund_status', 'PROCESSED',
                    'refund_amount', v_amount
                ),
                v_created_at + INTERVAL '1 day'
            );
        END IF;
    END LOOP;
END $$;
