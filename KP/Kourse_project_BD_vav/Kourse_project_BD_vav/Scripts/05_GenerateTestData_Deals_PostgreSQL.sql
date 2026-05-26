-- Генерация 100000 тестовых записей в таблицу deals (PostgreSQL)
-- ВАЖНО: предполагается, что в таблицах properties, clients, realtors есть данные.

DO $$
DECLARE
    v_property_ids INT[];
    v_client_ids INT[];
    v_realtor_ids INT[];
    v_property_count INT;
    v_client_count INT;
    v_realtor_count INT;
BEGIN
    -- ВАЖНО: берем реальные существующие ID (с учетом "дырок" после удалений),
    -- чтобы не нарушать внешние ключи.
    SELECT array_agg(property_id ORDER BY property_id), COUNT(*)
    INTO v_property_ids, v_property_count
    FROM properties;

    SELECT array_agg(client_id ORDER BY client_id), COUNT(*)
    INTO v_client_ids, v_client_count
    FROM clients;

    SELECT array_agg(realtor_id ORDER BY realtor_id), COUNT(*)
    INTO v_realtor_ids, v_realtor_count
    FROM realtors;

    IF v_property_count = 0 OR v_client_count = 0 OR v_realtor_count = 0 THEN
        RAISE EXCEPTION 'Нужно сначала заполнить properties/clients/realtors';
    END IF;

    INSERT INTO deals (property_id, client_id, realtor_id, deal_type, deal_price, deal_date, deal_status)
    SELECT
        v_property_ids[1 + floor(random() * v_property_count)::int] AS property_id,
        v_client_ids[1 + floor(random() * v_client_count)::int] AS client_id,
        v_realtor_ids[1 + floor(random() * v_realtor_count)::int] AS realtor_id,
        (ARRAY['Продажа', 'Аренда'])[1 + floor(random() * 2)::int]::varchar(50) AS deal_type,
        round((100000 + random() * 99900000)::numeric, 2)::decimal(15,2) AS deal_price,
        (CURRENT_DATE - (floor(random() * 3650)::int || ' days')::interval) AS deal_date,
        (ARRAY['Завершена', 'В обработке', 'Отменена'])[1 + floor(random() * 3)::int]::varchar(50) AS deal_status
    FROM generate_series(1, 100000);

    PERFORM setval(
        pg_get_serial_sequence('deals', 'deal_id'),
        COALESCE((SELECT MAX(deal_id) FROM deals), 1),
        true
    );

    RAISE NOTICE 'Сгенерировано 100000 записей в deals';
END $$;
