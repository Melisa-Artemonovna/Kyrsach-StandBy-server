-- Скрипт для создания профиля риелтора для существующего пользователя (PostgreSQL)
-- Используйте этот скрипт, если у пользователя с ролью Realtor нет профиля в таблице realtors

-- Замените :user_id на нужный user_id (например, 6)
DO $$
DECLARE
    v_user_id INTEGER := 6; -- Замените на нужный user_id
    v_user_full_name VARCHAR(100);
    v_user_email VARCHAR(100);
    v_realtor_id INTEGER;
BEGIN
    -- Получаем данные пользователя
    SELECT full_name, email INTO v_user_full_name, v_user_email
    FROM users
    WHERE user_id = v_user_id AND role = 'Realtor';
    
    -- Проверяем, существует ли уже профиль
    IF NOT EXISTS (SELECT 1 FROM realtors WHERE user_id = v_user_id) THEN
        -- Создаем профиль риелтора
        INSERT INTO realtors (full_name, phone_number, email, hire_date, commission_rate, user_id)
        VALUES (
            v_user_full_name,
            '+375 (29) 000-00-00', -- Телефон по умолчанию (можно изменить позже)
            v_user_email,
            CURRENT_TIMESTAMP,
            5.0, -- Комиссия по умолчанию
            v_user_id
        )
        RETURNING realtor_id INTO v_realtor_id;
        
        -- Обновляем realtor_id в таблице users
        UPDATE users
        SET realtor_id = v_realtor_id
        WHERE user_id = v_user_id;
        
        RAISE NOTICE 'Профиль риелтора успешно создан! Realtor ID: %', v_realtor_id;
    ELSE
        RAISE NOTICE 'Профиль риелтора уже существует для этого пользователя.';
    END IF;
END $$;

