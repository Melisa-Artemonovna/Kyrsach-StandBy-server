-- Создание хранимых процедур для PostgreSQL
-- Все операции с данными выполняются через процедуры
-- Дополнены выводами информации и вызовами

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ USERS
-- =============================================

-- Получить пользователя по ID
CREATE OR REPLACE FUNCTION sp_getuserbyid(p_user_id INTEGER)
RETURNS TABLE (
    user_id INTEGER,
    username VARCHAR(50),
    password_hash VARCHAR(255),
    email VARCHAR(100),
    full_name VARCHAR(100),
    role VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    client_id INTEGER,
    realtor_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getuserbyid для user_id = %', p_user_id;
    
    BEGIN
        RETURN QUERY
        SELECT u.user_id, u.username, u.password_hash, u.email, u.full_name, u.role, u.created_at, u.client_id, u.realtor_id
        FROM users u
        WHERE u.user_id = p_user_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getuserbyid успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getuserbyid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getuserbyid
-- SELECT * FROM sp_getuserbyid(1);
-- SELECT 'Вызов процедуры sp_getuserbyid завершен' AS Status;

-- Получить пользователя по username
CREATE OR REPLACE FUNCTION sp_getuserbyusername(p_username VARCHAR(50))
RETURNS TABLE (
    user_id INTEGER,
    username VARCHAR(50),
    password_hash VARCHAR(255),
    email VARCHAR(100),
    full_name VARCHAR(100),
    role VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    client_id INTEGER,
    realtor_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getuserbyusername для username = %', p_username;
    
    BEGIN
        RETURN QUERY
        SELECT u.user_id, u.username, u.password_hash, u.email, u.full_name, u.role, u.created_at, u.client_id, u.realtor_id
        FROM users u
        WHERE u.username = p_username;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getuserbyusername успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getuserbyusername: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getuserbyusername
-- SELECT * FROM sp_getuserbyusername('admin');
-- SELECT 'Вызов процедуры sp_getuserbyusername завершен' AS Status;

-- Получить всех пользователей
CREATE OR REPLACE FUNCTION sp_getallusers()
RETURNS TABLE (
    user_id INTEGER,
    username VARCHAR(50),
    password_hash VARCHAR(255),
    email VARCHAR(100),
    full_name VARCHAR(100),
    role VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    client_id INTEGER,
    realtor_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getallusers';
    
    BEGIN
        RETURN QUERY
        SELECT u.user_id, u.username, u.password_hash, u.email, u.full_name, u.role, u.created_at, u.client_id, u.realtor_id
        FROM users u
        ORDER BY u.user_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getallusers успешно выполнена. Найдено пользователей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getallusers: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getallusers
-- SELECT * FROM sp_getallusers();
-- SELECT 'Вызов процедуры sp_getallusers завершен' AS Status;

-- Создать пользователя
CREATE OR REPLACE FUNCTION sp_createuser(
    p_username VARCHAR(50),
    p_password_hash VARCHAR(255),
    p_email VARCHAR(100),
    p_full_name VARCHAR(100),
    p_role VARCHAR(20),
    p_created_at TIMESTAMP WITH TIME ZONE
)
RETURNS INTEGER AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_createuser для пользователя: %', p_username;
    
    BEGIN
        INSERT INTO users (username, password_hash, email, full_name, role, created_at)
        VALUES (p_username, p_password_hash, p_email, p_full_name, p_role, p_created_at)
        RETURNING user_id INTO v_user_id;
        
        RAISE NOTICE 'Процедура sp_createuser успешно выполнена. Создан пользователь с ID: %', v_user_id;
        
        -- Возвращаем созданного пользователя
        RAISE NOTICE 'Информация о созданном пользователе:';
        PERFORM * FROM sp_getuserbyid(v_user_id);
        
        RETURN v_user_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_createuser: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_createuser
/*
DO $$
DECLARE
    v_new_user_id INTEGER;
BEGIN
    v_new_user_id := sp_createuser(
        'testuser',
        'hashedpassword123',
        'test@example.com',
        'Test User',
        'Client',
        CURRENT_TIMESTAMP
    );
    RAISE NOTICE 'Создан новый пользователь с ID: %', v_new_user_id;
END $$;
*/

-- Обновить пользователя
CREATE OR REPLACE FUNCTION sp_updateuser(
    p_user_id INTEGER,
    p_username VARCHAR(50),
    p_email VARCHAR(100),
    p_full_name VARCHAR(100),
    p_role VARCHAR(20)
)
RETURNS VOID AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_updateuser для user_id = %', p_user_id;
    
    BEGIN
        UPDATE users 
        SET username = p_username, email = p_email, full_name = p_full_name, role = p_role
        WHERE user_id = p_user_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_updateuser успешно выполнена. Обновлено записей: %', v_row_count;
        
        -- Возвращаем обновленного пользователя
        RAISE NOTICE 'Информация об обновленном пользователе:';
        PERFORM * FROM sp_getuserbyid(p_user_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_updateuser: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_updateuser
/*
SELECT sp_updateuser(
    1,
    'updateduser',
    'updated@example.com',
    'Updated Name',
    'Admin'
);
SELECT 'Процедура sp_updateuser выполнена' AS Status;
*/

-- Удалить пользователя
CREATE OR REPLACE FUNCTION sp_deleteuser(p_user_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_client_id INTEGER;
    v_realtor_id INTEGER;
    v_username VARCHAR(50);
    v_remaining_users INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_deleteuser для user_id = %', p_user_id;
    
    BEGIN
        -- Сохраняем информацию о пользователе перед удалением
        SELECT username INTO v_username FROM users WHERE user_id = p_user_id;
        
        -- Проверяем, есть ли связанные записи
        SELECT client_id, realtor_id INTO v_client_id, v_realtor_id
        FROM users WHERE user_id = p_user_id;
        
        -- Если есть связанный клиент, удаляем его
        IF v_client_id IS NOT NULL THEN
            RAISE NOTICE 'Удаление связанных записей клиента с ID: %', v_client_id;
            DELETE FROM propertyreservations WHERE client_id = v_client_id;
            DELETE FROM deals WHERE client_id = v_client_id;
            DELETE FROM clients WHERE client_id = v_client_id;
        END IF;
        
        -- Если есть связанный риэлтор, удаляем его
        IF v_realtor_id IS NOT NULL THEN
            RAISE NOTICE 'Удаление связанных записей риэлтора с ID: %', v_realtor_id;
            DELETE FROM propertyreservations WHERE realtor_id = v_realtor_id;
            DELETE FROM deals WHERE realtor_id = v_realtor_id;
            DELETE FROM properties WHERE realtor_id = v_realtor_id;
            DELETE FROM realtors WHERE realtor_id = v_realtor_id;
        END IF;
        
        -- Удаляем пользователя
        DELETE FROM users WHERE user_id = p_user_id;
        
        RAISE NOTICE 'Процедура sp_deleteuser успешно выполнена. Удален пользователь: %', v_username;
        
        -- Выводим список оставшихся пользователей
        SELECT COUNT(*) INTO v_remaining_users FROM users;
        RAISE NOTICE 'Оставшееся количество пользователей: %', v_remaining_users;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_deleteuser: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_deleteuser (ОСТОРОЖНО: удаляет данные!)
/*
SELECT sp_deleteuser(10);
SELECT 'Процедура sp_deleteuser выполнена' AS Status;
*/

-- Получить пользователей по роли
CREATE OR REPLACE FUNCTION sp_getusersbyrole(p_role VARCHAR(20))
RETURNS TABLE (
    user_id INTEGER,
    username VARCHAR(50),
    password_hash VARCHAR(255),
    email VARCHAR(100),
    full_name VARCHAR(100),
    role VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    client_id INTEGER,
    realtor_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getusersbyrole для роли: %', p_role;
    
    BEGIN
        RETURN QUERY
        SELECT u.user_id, u.username, u.password_hash, u.email, u.full_name, u.role, u.created_at, u.client_id, u.realtor_id
        FROM users u
        WHERE u.role = p_role
        ORDER BY u.user_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getusersbyrole успешно выполнена. Найдено пользователей: % с ролью: %', v_row_count, p_role;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getusersbyrole: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getusersbyrole
-- SELECT * FROM sp_getusersbyrole('Client');
-- SELECT 'Вызов процедуры sp_getusersbyrole завершен' AS Status;

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ CLIENTS
-- =============================================

-- Получить всех клиентов
DROP FUNCTION IF EXISTS sp_getallclients() CASCADE;
CREATE OR REPLACE FUNCTION sp_getallclients()
RETURNS TABLE (
    client_id INTEGER,
    full_name VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    passport_number VARCHAR(20),
    registration_date TIMESTAMP,
    user_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getallclients';
    
    BEGIN
        RETURN QUERY
        SELECT c.client_id, c.full_name, c.phone_number, c.email, c.passport_number, c.registration_date::timestamp, c.user_id
        FROM clients c
        ORDER BY c.client_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getallclients успешно выполнена. Найдено клиентов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getallclients: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getallclients
-- SELECT * FROM sp_getallclients();
-- SELECT 'Вызов процедуры sp_getallclients завершен' AS Status;

-- Получить клиента по ID
DROP FUNCTION IF EXISTS sp_getclientbyid(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION sp_getclientbyid(p_client_id INTEGER)
RETURNS TABLE (
    client_id INTEGER,
    full_name VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    passport_number VARCHAR(20),
    registration_date TIMESTAMP,
    user_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getclientbyid для client_id = %', p_client_id;
    
    BEGIN
        RETURN QUERY
        SELECT c.client_id, c.full_name, c.phone_number, c.email, c.passport_number, c.registration_date::timestamp, c.user_id
        FROM clients c
        WHERE c.client_id = p_client_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getclientbyid успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getclientbyid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getclientbyid
-- SELECT * FROM sp_getclientbyid(1);
-- SELECT 'Вызов процедуры sp_getclientbyid завершен' AS Status;

-- Получить клиента по user_id
DROP FUNCTION IF EXISTS sp_getclientbyuserid(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION sp_getclientbyuserid(p_user_id INTEGER)
RETURNS TABLE (
    client_id INTEGER,
    full_name VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    passport_number VARCHAR(20),
    registration_date TIMESTAMP,
    user_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getclientbyuserid для user_id = %', p_user_id;
    
    BEGIN
        RETURN QUERY
        SELECT c.client_id, c.full_name, c.phone_number, c.email, c.passport_number, c.registration_date::timestamp, c.user_id
        FROM clients c
        WHERE c.user_id = p_user_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getclientbyuserid успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getclientbyuserid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getclientbyuserid
-- SELECT * FROM sp_getclientbyuserid(1);
-- SELECT 'Вызов процедуры sp_getclientbyuserid завершен' AS Status;

-- Получить клиента по email
CREATE OR REPLACE FUNCTION sp_getclientbyemail(p_email VARCHAR(100))
RETURNS TABLE (
    client_id INTEGER,
    full_name VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    passport_number VARCHAR(20),
    registration_date DATE,
    user_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getclientbyemail для email = %', p_email;
    
    BEGIN
        RETURN QUERY
        SELECT c.client_id, c.full_name, c.phone_number, c.email, c.passport_number, c.registration_date, c.user_id
        FROM clients c
        WHERE c.email = p_email;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getclientbyemail успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getclientbyemail: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getclientbyemail
-- SELECT * FROM sp_getclientbyemail('client@example.com');
-- SELECT 'Вызов процедуры sp_getclientbyemail завершен' AS Status;

-- Создать клиента
CREATE OR REPLACE FUNCTION sp_createclient(
    p_full_name VARCHAR(100),
    p_phone_number VARCHAR(20),
    p_email VARCHAR(100),
    p_passport_number VARCHAR(20),
    p_user_id INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    v_client_id INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_createclient для клиента: %', p_full_name;
    
    BEGIN
        INSERT INTO clients (full_name, phone_number, email, passport_number, registration_date, user_id)
        VALUES (p_full_name, p_phone_number, p_email, p_passport_number, CURRENT_DATE, p_user_id)
        RETURNING client_id INTO v_client_id;
        
        RAISE NOTICE 'Процедура sp_createclient успешно выполнена. Создан клиент с ID: %', v_client_id;
        
        -- Возвращаем созданного клиента
        RAISE NOTICE 'Информация о созданном клиенте:';
        PERFORM * FROM sp_getclientbyid(v_client_id);
        
        RETURN v_client_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_createclient: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_createclient
/*
DO $$
DECLARE
    v_new_client_id INTEGER;
BEGIN
    v_new_client_id := sp_createclient(
        'Новый Клиент',
        '+79990001122',
        'newclient@example.com',
        '1234567890',
        1
    );
    RAISE NOTICE 'Создан новый клиент с ID: %', v_new_client_id;
END $$;
*/

-- Обновить клиента
CREATE OR REPLACE FUNCTION sp_updateclient(
    p_client_id INTEGER,
    p_full_name VARCHAR(100),
    p_phone_number VARCHAR(20),
    p_email VARCHAR(100),
    p_passport_number VARCHAR(20)
)
RETURNS VOID AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_updateclient для client_id = %', p_client_id;
    
    BEGIN
        UPDATE clients 
        SET full_name = p_full_name, phone_number = p_phone_number, email = p_email, passport_number = p_passport_number
        WHERE client_id = p_client_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_updateclient успешно выполнена. Обновлено записей: %', v_row_count;
        
        -- Возвращаем обновленного клиента
        RAISE NOTICE 'Информация об обновленном клиенте:';
        PERFORM * FROM sp_getclientbyid(p_client_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_updateclient: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_updateclient
/*
SELECT sp_updateclient(
    1,
    'Обновленное Имя',
    '+79998887766',
    'updated@example.com',
    '0987654321'
);
SELECT 'Процедура sp_updateclient выполнена' AS Status;
*/

-- Удалить клиента
CREATE OR REPLACE FUNCTION sp_deleteclient(p_client_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_client_name VARCHAR(100);
    v_remaining_clients INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_deleteclient для client_id = %', p_client_id;
    
    BEGIN
        -- Сохраняем информацию о клиенте перед удалением
        SELECT full_name INTO v_client_name FROM clients WHERE client_id = p_client_id;
        
        -- Удаляем все резервации для этого клиента
        DELETE FROM propertyreservations WHERE client_id = p_client_id;
        
        -- Удаляем все сделки для этого клиента
        DELETE FROM deals WHERE client_id = p_client_id;
        
        -- Удаляем самого клиента
        DELETE FROM clients WHERE client_id = p_client_id;
        
        RAISE NOTICE 'Процедура sp_deleteclient успешно выполнена. Удален клиент: %', v_client_name;
        
        -- Выводим информацию об удалении
        SELECT COUNT(*) INTO v_remaining_clients FROM clients;
        RAISE NOTICE 'Оставшееся количество клиентов: %', v_remaining_clients;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_deleteclient: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_deleteclient (ОСТОРОЖНО: удаляет данные!)
/*
SELECT sp_deleteclient(5);
SELECT 'Процедура sp_deleteclient выполнена' AS Status;
*/

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ REALTORS
-- =============================================

-- Получить всех риэлторов
DROP FUNCTION IF EXISTS sp_getallrealtors() CASCADE;
CREATE OR REPLACE FUNCTION sp_getallrealtors()
RETURNS TABLE (
    realtor_id INTEGER,
    full_name VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    hire_date TIMESTAMP WITH TIME ZONE,
    commission_rate NUMERIC(5,2),
    user_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getallrealtors';
    
    BEGIN
        RETURN QUERY
        SELECT r.realtor_id, r.full_name, r.phone_number, r.email, r.hire_date, r.commission_rate, r.user_id
        FROM realtors r
        ORDER BY r.realtor_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getallrealtors успешно выполнена. Найдено риэлторов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getallrealtors: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getallrealtors
-- SELECT * FROM sp_getallrealtors();
-- SELECT 'Вызов процедуры sp_getallrealtors завершен' AS Status;

-- Получить риэлтора по ID
DROP FUNCTION IF EXISTS sp_getrealtorbyid(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION sp_getrealtorbyid(p_realtor_id INTEGER)
RETURNS TABLE (
    realtor_id INTEGER,
    full_name VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    hire_date TIMESTAMP WITH TIME ZONE,
    commission_rate NUMERIC(5,2),
    user_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getrealtorbyid для realtor_id = %', p_realtor_id;
    
    BEGIN
        RETURN QUERY
        SELECT r.realtor_id, r.full_name, r.phone_number, r.email, r.hire_date, r.commission_rate, r.user_id
        FROM realtors r
        WHERE r.realtor_id = p_realtor_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getrealtorbyid успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getrealtorbyid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getrealtorbyid
-- SELECT * FROM sp_getrealtorbyid(1);
-- SELECT 'Вызов процедуры sp_getrealtorbyid завершен' AS Status;

-- Получить риэлтора по user_id
DROP FUNCTION IF EXISTS sp_getrealtorbyuserid(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION sp_getrealtorbyuserid(p_user_id INTEGER)
RETURNS TABLE (
    realtor_id INTEGER,
    full_name VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    hire_date TIMESTAMP WITH TIME ZONE,
    commission_rate NUMERIC(5,2),
    user_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getrealtorbyuserid для user_id = %', p_user_id;
    
    BEGIN
        RETURN QUERY
        SELECT r.realtor_id, r.full_name, r.phone_number, r.email, r.hire_date, r.commission_rate, r.user_id
        FROM realtors r
        WHERE r.user_id = p_user_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getrealtorbyuserid успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getrealtorbyuserid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getrealtorbyuserid
-- SELECT * FROM sp_getrealtorbyuserid(1);
-- SELECT 'Вызов процедуры sp_getrealtorbyuserid завершен' AS Status;

-- Получить риэлтора по email
CREATE OR REPLACE FUNCTION sp_getrealtorbyemail(p_email VARCHAR(100))
RETURNS TABLE (
    realtor_id INTEGER,
    full_name VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    hire_date TIMESTAMP WITH TIME ZONE,
    commission_rate NUMERIC(5,2),
    user_id INTEGER
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getrealtorbyemail для email = %', p_email;
    
    BEGIN
        RETURN QUERY
        SELECT r.realtor_id, r.full_name, r.phone_number, r.email, r.hire_date, r.commission_rate, r.user_id
        FROM realtors r
        WHERE r.email = p_email;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getrealtorbyemail успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getrealtorbyemail: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getrealtorbyemail
-- SELECT * FROM sp_getrealtorbyemail('realtor@example.com');
-- SELECT 'Вызов процедуры sp_getrealtorbyemail завершен' AS Status;

-- Создать риэлтора
CREATE OR REPLACE FUNCTION sp_createrealtor(
    p_full_name VARCHAR(100),
    p_phone_number VARCHAR(20),
    p_email VARCHAR(100),
    p_user_id INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    v_realtor_id INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_createrealtor для риэлтора: %', p_full_name;
    
    BEGIN
        INSERT INTO realtors (full_name, phone_number, email, hire_date, commission_rate, user_id)
        VALUES (p_full_name, p_phone_number, p_email, CURRENT_TIMESTAMP, 5.0, p_user_id)
        RETURNING realtor_id INTO v_realtor_id;
        
        RAISE NOTICE 'Процедура sp_createrealtor успешно выполнена. Создан риэлтор с ID: %', v_realtor_id;
        
        -- Возвращаем созданного риэлтора
        RAISE NOTICE 'Информация о созданном риэлторе:';
        PERFORM * FROM sp_getrealtorbyid(v_realtor_id);
        
        RETURN v_realtor_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_createrealtor: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_createrealtor
/*
DO $$
DECLARE
    v_new_realtor_id INTEGER;
BEGIN
    v_new_realtor_id := sp_createrealtor(
        'Новый Риэлтор',
        '+79991112233',
        'newrealtor@example.com',
        1
    );
    RAISE NOTICE 'Создан новый риэлтор с ID: %', v_new_realtor_id;
END $$;
*/

-- Обновить риэлтора
CREATE OR REPLACE FUNCTION sp_updaterealtor(
    p_realtor_id INTEGER,
    p_full_name VARCHAR(100),
    p_phone_number VARCHAR(20),
    p_email VARCHAR(100),
    p_hire_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_commission_rate NUMERIC(5,2) DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_updaterealtor для realtor_id = %', p_realtor_id;
    
    BEGIN
        UPDATE realtors 
        SET full_name = p_full_name, 
            phone_number = p_phone_number, 
            email = p_email,
            hire_date = COALESCE(p_hire_date, hire_date),
            commission_rate = COALESCE(p_commission_rate, commission_rate)
        WHERE realtor_id = p_realtor_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_updaterealtor успешно выполнена. Обновлено записей: %', v_row_count;
        
        -- Возвращаем обновленного риэлтора
        RAISE NOTICE 'Информация об обновленном риэлторе:';
        PERFORM * FROM sp_getrealtorbyid(p_realtor_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_updaterealtor: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_updaterealtor
/*
SELECT sp_updaterealtor(
    1,
    'Обновленный Риэлтор',
    '+79992223344',
    'updatedrealtor@example.com',
    NULL,
    7.0
);
SELECT 'Процедура sp_updaterealtor выполнена' AS Status;
*/

-- Удалить риэлтора
CREATE OR REPLACE FUNCTION sp_deleterealtor(p_realtor_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_realtor_name VARCHAR(100);
    v_remaining_realtors INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_deleterealtor для realtor_id = %', p_realtor_id;
    
    BEGIN
        -- Сохраняем информацию о риэлторе перед удалением
        SELECT full_name INTO v_realtor_name FROM realtors WHERE realtor_id = p_realtor_id;
        
        -- Удаляем все резервации для этого риэлтора
        DELETE FROM propertyreservations WHERE realtor_id = p_realtor_id;
        
        -- Удаляем все сделки для этого риэлтора
        DELETE FROM deals WHERE realtor_id = p_realtor_id;
        
        -- Удаляем все объекты недвижимости для этого риэлтора
        DELETE FROM propertyreservations 
        WHERE property_id IN (SELECT property_id FROM properties WHERE realtor_id = p_realtor_id);
        
        DELETE FROM deals 
        WHERE property_id IN (SELECT property_id FROM properties WHERE realtor_id = p_realtor_id);
        
        -- Удаляем сами объекты
        DELETE FROM properties WHERE realtor_id = p_realtor_id;
        
        -- Удаляем самого риэлтора
        DELETE FROM realtors WHERE realtor_id = p_realtor_id;
        
        RAISE NOTICE 'Процедура sp_deleterealtor успешно выполнена. Удален риэлтор: %', v_realtor_name;
        
        -- Выводим информацию об удалении
        SELECT COUNT(*) INTO v_remaining_realtors FROM realtors;
        RAISE NOTICE 'Оставшееся количество риэлторов: %', v_remaining_realtors;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_deleterealtor: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_deleterealtor (ОСТОРОЖНО: удаляет данные!)
/*
SELECT sp_deleterealtor(3);
SELECT 'Процедура sp_deleterealtor выполнена' AS Status;
*/

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ PROPERTIES
-- =============================================

-- Получить все объекты недвижимости
CREATE OR REPLACE FUNCTION sp_getallproperties()
RETURNS TABLE (
    property_id INTEGER,
    address VARCHAR(255),
    property_type VARCHAR(50),
    area NUMERIC(10,2),
    price NUMERIC(15,2),
    description TEXT,
    realtor_id INTEGER,
    is_available BOOLEAN,
    rooms INTEGER,
    floor INTEGER,
    total_floors INTEGER,
    main_image_url VARCHAR(500),
    image_urls TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getallproperties';
    
    BEGIN
        RETURN QUERY
        SELECT p.property_id, p.address, p.property_type, p.area, p.price, p.description, p.realtor_id,
               p.is_available, p.rooms, p.floor, p.total_floors, p.main_image_url, p.image_urls
        FROM properties p
        ORDER BY p.property_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getallproperties успешно выполнена. Найдено объектов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getallproperties: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getallproperties
-- SELECT * FROM sp_getallproperties();
-- SELECT 'Вызов процедуры sp_getallproperties завершен' AS Status;

-- Получить объект по ID
CREATE OR REPLACE FUNCTION sp_getpropertybyid(p_property_id INTEGER)
RETURNS TABLE (
    property_id INTEGER,
    address VARCHAR(255),
    property_type VARCHAR(50),
    area NUMERIC(10,2),
    price NUMERIC(15,2),
    description TEXT,
    realtor_id INTEGER,
    is_available BOOLEAN,
    rooms INTEGER,
    floor INTEGER,
    total_floors INTEGER,
    main_image_url VARCHAR(500),
    image_urls TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getpropertybyid для property_id = %', p_property_id;
    
    BEGIN
        RETURN QUERY
        SELECT p.property_id, p.address, p.property_type, p.area, p.price, p.description, p.realtor_id,
               p.is_available, p.rooms, p.floor, p.total_floors, p.main_image_url, p.image_urls
        FROM properties p
        WHERE p.property_id = p_property_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getpropertybyid успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getpropertybyid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getpropertybyid
-- SELECT * FROM sp_getpropertybyid(1);
-- SELECT 'Вызов процедуры sp_getpropertybyid завершен' AS Status;

-- Получить объекты риэлтора
CREATE OR REPLACE FUNCTION sp_getpropertiesbyrealtorid(p_realtor_id INTEGER)
RETURNS TABLE (
    property_id INTEGER,
    address VARCHAR(255),
    property_type VARCHAR(50),
    area NUMERIC(10,2),
    price NUMERIC(15,2),
    description TEXT,
    realtor_id INTEGER,
    is_available BOOLEAN,
    rooms INTEGER,
    floor INTEGER,
    total_floors INTEGER,
    main_image_url VARCHAR(500),
    image_urls TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getpropertiesbyrealtorid для realtor_id = %', p_realtor_id;
    
    BEGIN
        RETURN QUERY
        SELECT p.property_id, p.address, p.property_type, p.area, p.price, p.description, p.realtor_id,
               p.is_available, p.rooms, p.floor, p.total_floors, p.main_image_url, p.image_urls
        FROM properties p
        WHERE p.realtor_id = p_realtor_id
        ORDER BY p.property_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getpropertiesbyrealtorid успешно выполнена. Найдено объектов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getpropertiesbyrealtorid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getpropertiesbyrealtorid
-- SELECT * FROM sp_getpropertiesbyrealtorid(1);
-- SELECT 'Вызов процедуры sp_getpropertiesbyrealtorid завершен' AS Status;

-- Получить доступные объекты
CREATE OR REPLACE FUNCTION sp_getavailableproperties()
RETURNS TABLE (
    property_id INTEGER,
    address VARCHAR(255),
    property_type VARCHAR(50),
    area NUMERIC(10,2),
    price NUMERIC(15,2),
    description TEXT,
    realtor_id INTEGER,
    is_available BOOLEAN,
    rooms INTEGER,
    floor INTEGER,
    total_floors INTEGER,
    main_image_url VARCHAR(500),
    image_urls TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getavailableproperties';
    
    BEGIN
        RETURN QUERY
        SELECT p.property_id, p.address, p.property_type, p.area, p.price, p.description, p.realtor_id,
               p.is_available, p.rooms, p.floor, p.total_floors, p.main_image_url, p.image_urls
        FROM properties p
        WHERE p.is_available = true
        ORDER BY p.price;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getavailableproperties успешно выполнена. Найдено доступных объектов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getavailableproperties: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getavailableproperties
-- SELECT * FROM sp_getavailableproperties();
-- SELECT 'Вызов процедуры sp_getavailableproperties завершен' AS Status;

-- Получить объекты по типу
CREATE OR REPLACE FUNCTION sp_getpropertiesbytype(p_property_type VARCHAR(50))
RETURNS TABLE (
    property_id INTEGER,
    address VARCHAR(255),
    property_type VARCHAR(50),
    area NUMERIC(10,2),
    price NUMERIC(15,2),
    description TEXT,
    realtor_id INTEGER,
    is_available BOOLEAN,
    rooms INTEGER,
    floor INTEGER,
    total_floors INTEGER,
    main_image_url VARCHAR(500),
    image_urls TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getpropertiesbytype для типа: %', p_property_type;
    
    BEGIN
        RETURN QUERY
        SELECT p.property_id, p.address, p.property_type, p.area, p.price, p.description, p.realtor_id,
               p.is_available, p.rooms, p.floor, p.total_floors, p.main_image_url, p.image_urls
        FROM properties p
        WHERE p.property_type = p_property_type
        ORDER BY p.price;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getpropertiesbytype успешно выполнена. Найдено объектов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getpropertiesbytype: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getpropertiesbytype
-- SELECT * FROM sp_getpropertiesbytype('Apartment');
-- SELECT 'Вызов процедуры sp_getpropertiesbytype завершен' AS Status;

-- Получить объекты по диапазону цены
CREATE OR REPLACE FUNCTION sp_getpropertiesbypricerange(
    p_min_price NUMERIC(15,2),
    p_max_price NUMERIC(15,2)
)
RETURNS TABLE (
    property_id INTEGER,
    address VARCHAR(255),
    property_type VARCHAR(50),
    area NUMERIC(10,2),
    price NUMERIC(15,2),
    description TEXT,
    realtor_id INTEGER,
    is_available BOOLEAN,
    rooms INTEGER,
    floor INTEGER,
    total_floors INTEGER,
    main_image_url VARCHAR(500),
    image_urls TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getpropertiesbypricerange для диапазона цен: % - %', p_min_price, p_max_price;
    
    BEGIN
        RETURN QUERY
        SELECT p.property_id, p.address, p.property_type, p.area, p.price, p.description, p.realtor_id,
               p.is_available, p.rooms, p.floor, p.total_floors, p.main_image_url, p.image_urls
        FROM properties p
        WHERE p.price >= p_min_price AND p.price <= p_max_price
        ORDER BY p.price;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getpropertiesbypricerange успешно выполнена. Найдено объектов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getpropertiesbypricerange: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getpropertiesbypricerange
-- SELECT * FROM sp_getpropertiesbypricerange(100000, 500000);
-- SELECT 'Вызов процедуры sp_getpropertiesbypricerange завершен' AS Status;

-- Создать объект недвижимости
CREATE OR REPLACE FUNCTION sp_createproperty(
    p_address VARCHAR(255),
    p_property_type VARCHAR(50),
    p_area NUMERIC(10,2),
    p_price NUMERIC(15,2),
    p_description TEXT,
    p_realtor_id INTEGER,
    p_is_available BOOLEAN,
    p_rooms INTEGER,
    p_floor INTEGER,
    p_total_floors INTEGER,
    p_main_image_url VARCHAR(500),
    p_image_urls TEXT
)
RETURNS INTEGER AS $$
DECLARE
    v_property_id INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_createproperty для объекта по адресу: %', p_address;
    
    BEGIN
        INSERT INTO properties (address, property_type, area, price, description, realtor_id, is_available, rooms, floor, total_floors, main_image_url, image_urls)
        VALUES (p_address, p_property_type, p_area, p_price, p_description, p_realtor_id, p_is_available, p_rooms, p_floor, p_total_floors, p_main_image_url, p_image_urls)
        RETURNING property_id INTO v_property_id;
        
        RAISE NOTICE 'Процедура sp_createproperty успешно выполнена. Создан объект с ID: %', v_property_id;
        
        -- Возвращаем созданный объект
        RAISE NOTICE 'Информация о созданном объекте:';
        PERFORM * FROM sp_getpropertybyid(v_property_id);
        
        RETURN v_property_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_createproperty: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_createproperty
/*
DO $$
DECLARE
    v_new_property_id INTEGER;
BEGIN
    v_new_property_id := sp_createproperty(
        'ул. Примерная, д. 123',
        'Apartment',
        75.5,
        3500000.00,
        'Просторная квартира в центре города',
        1,
        true,
        3,
        5,
        9,
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg,https://example.com/image3.jpg'
    );
    RAISE NOTICE 'Создан новый объект недвижимости с ID: %', v_new_property_id;
END $$;
*/

-- Обновить объект недвижимости
CREATE OR REPLACE FUNCTION sp_updateproperty(
    p_property_id INTEGER,
    p_address VARCHAR(255),
    p_property_type VARCHAR(50),
    p_area NUMERIC(10,2),
    p_price NUMERIC(15,2),
    p_description TEXT,
    p_realtor_id INTEGER,
    p_is_available BOOLEAN,
    p_rooms INTEGER,
    p_floor INTEGER,
    p_total_floors INTEGER,
    p_main_image_url VARCHAR(500),
    p_image_urls TEXT
)
RETURNS VOID AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_updateproperty для property_id = %', p_property_id;
    
    BEGIN
        UPDATE properties 
        SET address = p_address, property_type = p_property_type, area = p_area, price = p_price,
            description = p_description, realtor_id = p_realtor_id, is_available = p_is_available,
            rooms = p_rooms, floor = p_floor, total_floors = p_total_floors,
            main_image_url = p_main_image_url, image_urls = p_image_urls
        WHERE property_id = p_property_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_updateproperty успешно выполнена. Обновлено записей: %', v_row_count;
        
        -- Возвращаем обновленный объект
        RAISE NOTICE 'Информация об обновленном объекте:';
        PERFORM * FROM sp_getpropertybyid(p_property_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_updateproperty: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_updateproperty
/*
SELECT sp_updateproperty(
    1,
    'ул. Обновленная, д. 456',
    'Apartment',
    80.0,
    3800000.00,
    'Обновленное описание квартиры',
    1,
    true,
    3,
    7,
    12,
    'https://example.com/new_image.jpg',
    'https://example.com/image1.jpg,https://example.com/image2.jpg'
);
SELECT 'Процедура sp_updateproperty выполнена' AS Status;
*/

-- Изменить статус доступности объекта
CREATE OR REPLACE FUNCTION sp_updatepropertyavailability(
    p_property_id INTEGER,
    p_is_available BOOLEAN
)
RETURNS VOID AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_updatepropertyavailability для property_id = % с is_available = %', 
                 p_property_id, p_is_available;
    
    BEGIN
        UPDATE properties 
        SET is_available = p_is_available
        WHERE property_id = p_property_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_updatepropertyavailability успешно выполнена. Обновлено записей: %', v_row_count;
        
        -- Возвращаем обновленный объект
        RAISE NOTICE 'Информация об обновленном объекте:';
        PERFORM property_id, address, is_available FROM properties WHERE property_id = p_property_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_updatepropertyavailability: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_updatepropertyavailability
-- SELECT sp_updatepropertyavailability(1, false);
-- SELECT 'Процедура sp_updatepropertyavailability выполнена' AS Status;

-- Удалить объект недвижимости
CREATE OR REPLACE FUNCTION sp_deleteproperty(p_property_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_property_address VARCHAR(255);
    v_remaining_properties INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_deleteproperty для property_id = %', p_property_id;
    
    BEGIN
        -- Сохраняем информацию об объекте перед удалением
        SELECT address INTO v_property_address FROM properties WHERE property_id = p_property_id;
        
        -- Удаляем все резервации для этого объекта
        DELETE FROM propertyreservations WHERE property_id = p_property_id;
        
        -- Удаляем все избранное для этого объекта (если таблица существует)
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'favorites') THEN
            DELETE FROM favorites WHERE property_id = p_property_id;
        END IF;
        
        -- Удаляем все сделки для этого объекта
        DELETE FROM deals WHERE property_id = p_property_id;
        
        -- Удаляем сам объект
        DELETE FROM properties WHERE property_id = p_property_id;
        
        RAISE NOTICE 'Процедура sp_deleteproperty успешно выполнена. Удален объект: %', v_property_address;
        
        -- Выводим информацию об удалении
        SELECT COUNT(*) INTO v_remaining_properties FROM properties;
        RAISE NOTICE 'Оставшееся количество объектов: %', v_remaining_properties;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_deleteproperty: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_deleteproperty (ОСТОРОЖНО: удаляет данные!)
/*
SELECT sp_deleteproperty(5);
SELECT 'Процедура sp_deleteproperty выполнена' AS Status;
*/

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ DEALS
-- =============================================

-- Получить все сделки
DROP FUNCTION IF EXISTS sp_getalldeals() CASCADE;
CREATE OR REPLACE FUNCTION sp_getalldeals()
RETURNS TABLE (
    deal_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    deal_type VARCHAR(50),
    deal_status VARCHAR(50),
    deal_price NUMERIC(15,2),
    deal_date TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getalldeals';
    
    BEGIN
        RETURN QUERY
        SELECT d.deal_id, d.property_id, d.client_id, d.realtor_id, d.deal_type, d.deal_status, d.deal_price, d.deal_date
        FROM deals d
        ORDER BY d.deal_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getalldeals успешно выполнена. Найдено сделок: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getalldeals: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getalldeals
-- SELECT * FROM sp_getalldeals();
-- SELECT 'Вызов процедуры sp_getalldeals завершен' AS Status;

-- Получить сделку по ID
DROP FUNCTION IF EXISTS sp_getdealbyid(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION sp_getdealbyid(p_deal_id INTEGER)
RETURNS TABLE (
    deal_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    deal_type VARCHAR(50),
    deal_status VARCHAR(50),
    deal_price NUMERIC(15,2),
    deal_date TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getdealbyid для deal_id = %', p_deal_id;
    
    BEGIN
        RETURN QUERY
        SELECT d.deal_id, d.property_id, d.client_id, d.realtor_id, d.deal_type, d.deal_status, d.deal_price, d.deal_date
        FROM deals d
        WHERE d.deal_id = p_deal_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getdealbyid успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getdealbyid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getdealbyid
-- SELECT * FROM sp_getdealbyid(1);
-- SELECT 'Вызов процедуры sp_getdealbyid завершен' AS Status;

-- Получить сделки риэлтора
DROP FUNCTION IF EXISTS sp_getdealsbyrealtorid(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION sp_getdealsbyrealtorid(p_realtor_id INTEGER)
RETURNS TABLE (
    deal_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    deal_type VARCHAR(50),
    deal_status VARCHAR(50),
    deal_price NUMERIC(15,2),
    deal_date TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getdealsbyrealtorid для realtor_id = %', p_realtor_id;
    
    BEGIN
        RETURN QUERY
        SELECT d.deal_id, d.property_id, d.client_id, d.realtor_id, d.deal_type, d.deal_status, d.deal_price, d.deal_date
        FROM deals d
        WHERE d.realtor_id = p_realtor_id
        ORDER BY d.deal_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getdealsbyrealtorid успешно выполнена. Найдено сделок: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getdealsbyrealtorid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getdealsbyrealtorid
-- SELECT * FROM sp_getdealsbyrealtorid(1);
-- SELECT 'Вызов процедуры sp_getdealsbyrealtorid завершен' AS Status;

-- Получить сделки клиента
DROP FUNCTION IF EXISTS sp_getdealsbyclientid(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION sp_getdealsbyclientid(p_client_id INTEGER)
RETURNS TABLE (
    deal_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    deal_type VARCHAR(50),
    deal_status VARCHAR(50),
    deal_price NUMERIC(15,2),
    deal_date TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getdealsbyclientid для client_id = %', p_client_id;
    
    BEGIN
        RETURN QUERY
        SELECT d.deal_id, d.property_id, d.client_id, d.realtor_id, d.deal_type, d.deal_status, d.deal_price, d.deal_date
        FROM deals d
        WHERE d.client_id = p_client_id
        ORDER BY d.deal_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getdealsbyclientid успешно выполнена. Найдено сделок: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getdealsbyclientid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getdealsbyclientid
-- SELECT * FROM sp_getdealsbyclientid(1);
-- SELECT 'Вызов процедуры sp_getdealsbyclientid завершен' AS Status;

-- Получить сделки по дате
CREATE OR REPLACE FUNCTION sp_getdealsbydaterange(
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    deal_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    deal_type VARCHAR(50),
    deal_price NUMERIC(15,2),
    deal_date TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getdealsbydaterange для периода: % - %', p_start_date, p_end_date;
    
    BEGIN
        RETURN QUERY
        SELECT d.deal_id, d.property_id, d.client_id, d.realtor_id, d.deal_type, d.deal_price, d.deal_date
        FROM deals d
        WHERE d.deal_date >= p_start_date AND d.deal_date <= p_end_date
        ORDER BY d.deal_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getdealsbydaterange успешно выполнена. Найдено сделок: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getdealsbydaterange: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getdealsbydaterange
/*
SELECT * FROM sp_getdealsbydaterange(
    '2024-01-01'::TIMESTAMP WITH TIME ZONE,
    '2024-12-31'::TIMESTAMP WITH TIME ZONE
);
SELECT 'Вызов процедуры sp_getdealsbydaterange завершен' AS Status;
*/

-- Получить статистику сделок риэлтора за период
CREATE OR REPLACE FUNCTION sp_getrealtordealstats(
    p_realtor_id INTEGER,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    deal_count BIGINT,
    deal_amount NUMERIC
) AS $$
DECLARE
    v_deal_count BIGINT;
    v_deal_amount NUMERIC;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getrealtordealstats для realtor_id = %', p_realtor_id;
    
    BEGIN
        RETURN QUERY
        SELECT COUNT(*)::BIGINT, COALESCE(SUM(deal_price), 0)::NUMERIC
        FROM deals 
        WHERE realtor_id = p_realtor_id AND deal_date >= p_start_date AND deal_date <= p_end_date;
        
        GET DIAGNOSTICS v_deal_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getrealtordealstats успешно выполнена. Статистика для риэлтора %: % сделок', 
                     p_realtor_id, v_deal_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getrealtordealstats: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getrealtordealstats
/*
SELECT * FROM sp_getrealtordealstats(
    1,
    '2024-01-01'::TIMESTAMP WITH TIME ZONE,
    '2024-12-31'::TIMESTAMP WITH TIME ZONE
);
*/

-- Создать сделку
CREATE OR REPLACE FUNCTION sp_createdeal(
    p_property_id INTEGER,
    p_client_id INTEGER,
    p_realtor_id INTEGER,
    p_deal_type VARCHAR(50),
    p_deal_price NUMERIC(15,2),
    p_deal_date TIMESTAMP WITH TIME ZONE
)
RETURNS INTEGER AS $$
DECLARE
    v_deal_id INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_createdeal для сделки типа: %', p_deal_type;
    
    BEGIN
        INSERT INTO deals (property_id, client_id, realtor_id, deal_type, deal_price, deal_date)
        VALUES (p_property_id, p_client_id, p_realtor_id, p_deal_type, p_deal_price, p_deal_date)
        RETURNING deal_id INTO v_deal_id;
        
        RAISE NOTICE 'Процедура sp_createdeal успешно выполнена. Создана сделка с ID: %', v_deal_id;
        
        -- Возвращаем созданную сделку
        RAISE NOTICE 'Информация о созданной сделке:';
        PERFORM * FROM sp_getdealbyid(v_deal_id);
        
        RETURN v_deal_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_createdeal: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_createdeal
/*
DO $$
DECLARE
    v_new_deal_id INTEGER;
BEGIN
    v_new_deal_id := sp_createdeal(
        1,
        1,
        1,
        'Sale',
        3500000.00,
        CURRENT_TIMESTAMP
    );
    RAISE NOTICE 'Создана новая сделка с ID: %', v_new_deal_id;
END $$;
*/

-- Обновить сделку
CREATE OR REPLACE FUNCTION sp_updatedeal(
    p_deal_id INTEGER,
    p_property_id INTEGER,
    p_client_id INTEGER,
    p_realtor_id INTEGER,
    p_deal_type VARCHAR(50),
    p_deal_price NUMERIC(15,2),
    p_deal_date TIMESTAMP WITH TIME ZONE
)
RETURNS VOID AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_updatedeal для deal_id = %', p_deal_id;
    
    BEGIN
        UPDATE deals 
        SET property_id = p_property_id, client_id = p_client_id, realtor_id = p_realtor_id,
            deal_type = p_deal_type, deal_price = p_deal_price, deal_date = p_deal_date
        WHERE deal_id = p_deal_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_updatedeal успешно выполнена. Обновлено записей: %', v_row_count;
        
        -- Возвращаем обновленную сделку
        RAISE NOTICE 'Информация об обновленной сделке:';
        PERFORM * FROM sp_getdealbyid(p_deal_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_updatedeal: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_updatedeal
/*
SELECT sp_updatedeal(
    1,
    2,
    1,
    1,
    'Rent',
    4000000.00,
    CURRENT_TIMESTAMP
);
SELECT 'Процедура sp_updatedeal выполнена' AS Status;
*/

-- Удалить сделку
CREATE OR REPLACE FUNCTION sp_deletedeal(p_deal_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_remaining_deals INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_deletedeal для deal_id = %', p_deal_id;
    
    BEGIN
        -- Удаляем все контракты для этой сделки (если таблица существует)
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'contracts') THEN
            DELETE FROM contracts WHERE deal_id = p_deal_id;
        END IF;
        
        -- Удаляем саму сделку
        DELETE FROM deals WHERE deal_id = p_deal_id;
        
        RAISE NOTICE 'Процедура sp_deletedeal успешно выполнена. Удалена сделка с ID: %', p_deal_id;
        
        -- Выводим информацию об удалении
        SELECT COUNT(*) INTO v_remaining_deals FROM deals;
        RAISE NOTICE 'Оставшееся количество сделок: %', v_remaining_deals;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_deletedeal: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_deletedeal (ОСТОРОЖНО: удаляет данные!)
/*
SELECT sp_deletedeal(5);
SELECT 'Процедура sp_deletedeal выполнена' AS Status;
*/

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ PROPERTY RESERVATIONS
-- =============================================

-- Получить все резервирования
CREATE OR REPLACE FUNCTION sp_getallpropertyreservations()
RETURNS TABLE (
    reservation_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    status VARCHAR(20),
    reservation_date TIMESTAMP,
    expiry_date TIMESTAMP
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getallpropertyreservations';
    
    BEGIN
        RETURN QUERY
        SELECT pr.reservation_id, pr.property_id, pr.client_id, pr.realtor_id, pr.status, pr.reservation_date, pr.expiry_date
        FROM propertyreservations pr
        ORDER BY pr.reservation_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getallpropertyreservations успешно выполнена. Найдено резервирований: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getallpropertyreservations: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getallpropertyreservations
-- SELECT * FROM sp_getallpropertyreservations();
-- SELECT 'Вызов процедуры sp_getallpropertyreservations завершен' AS Status;

-- Получить резервирование по ID
CREATE OR REPLACE FUNCTION sp_getpropertyreservationbyid(p_reservation_id INTEGER)
RETURNS TABLE (
    reservation_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    status VARCHAR(20),
    reservation_date TIMESTAMP,
    expiry_date TIMESTAMP
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getpropertyreservationbyid для reservation_id = %', p_reservation_id;
    
    BEGIN
        RETURN QUERY
        SELECT pr.reservation_id, pr.property_id, pr.client_id, pr.realtor_id, pr.status, pr.reservation_date, pr.expiry_date
        FROM propertyreservations pr
        WHERE pr.reservation_id = p_reservation_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getpropertyreservationbyid успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getpropertyreservationbyid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getpropertyreservationbyid
-- SELECT * FROM sp_getpropertyreservationbyid(1);
-- SELECT 'Вызов процедуры sp_getpropertyreservationbyid завершен' AS Status;

-- Получить резервирования риэлтора
CREATE OR REPLACE FUNCTION sp_getpropertyreservationsbyrealtorid(p_realtor_id INTEGER)
RETURNS TABLE (
    reservation_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    status VARCHAR(20),
    reservation_date TIMESTAMP,
    expiry_date TIMESTAMP
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getpropertyreservationsbyrealtorid для realtor_id = %', p_realtor_id;
    
    BEGIN
        RETURN QUERY
        SELECT pr.reservation_id, pr.property_id, pr.client_id, pr.realtor_id, pr.status, pr.reservation_date, pr.expiry_date
        FROM propertyreservations pr
        WHERE pr.realtor_id = p_realtor_id
        ORDER BY pr.reservation_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getpropertyreservationsbyrealtorid успешно выполнена. Найдено резервирований: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getpropertyreservationsbyrealtorid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getpropertyreservationsbyrealtorid
-- SELECT * FROM sp_getpropertyreservationsbyrealtorid(1);
-- SELECT 'Вызов процедуры sp_getpropertyreservationsbyrealtorid завершен' AS Status;

-- Получить резервирования клиента
CREATE OR REPLACE FUNCTION sp_getpropertyreservationsbyclientid(p_client_id INTEGER)
RETURNS TABLE (
    reservation_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    status VARCHAR(20),
    reservation_date TIMESTAMP,
    expiry_date TIMESTAMP
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getpropertyreservationsbyclientid для client_id = %', p_client_id;
    
    BEGIN
        RETURN QUERY
        SELECT pr.reservation_id, pr.property_id, pr.client_id, pr.realtor_id, pr.status, pr.reservation_date, pr.expiry_date
        FROM propertyreservations pr
        WHERE pr.client_id = p_client_id
        ORDER BY pr.reservation_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getpropertyreservationsbyclientid успешно выполнена. Найдено резервирований: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getpropertyreservationsbyclientid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getpropertyreservationsbyclientid
-- SELECT * FROM sp_getpropertyreservationsbyclientid(1);
-- SELECT 'Вызов процедуры sp_getpropertyreservationsbyclientid завершен' AS Status;

-- Получить активные резервирования
CREATE OR REPLACE FUNCTION sp_getactivepropertyreservations()
RETURNS TABLE (
    reservation_id INTEGER,
    property_id INTEGER,
    client_id INTEGER,
    realtor_id INTEGER,
    status VARCHAR(20),
    reservation_date TIMESTAMP,
    expiry_date TIMESTAMP
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getactivepropertyreservations';
    
    BEGIN
        RETURN QUERY
        SELECT pr.reservation_id, pr.property_id, pr.client_id, pr.realtor_id, pr.status, pr.reservation_date, pr.expiry_date
        FROM propertyreservations pr
        WHERE pr.status = 'Active'
        ORDER BY pr.reservation_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getactivepropertyreservations успешно выполнена. Найдено активных резервирований: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getactivepropertyreservations: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getactivepropertyreservations
-- SELECT * FROM sp_getactivepropertyreservations();
-- SELECT 'Вызов процедуры sp_getactivepropertyreservations завершен' AS Status;

-- Проверить активное резервирование
CREATE OR REPLACE FUNCTION sp_checkactivereservation(
    p_property_id INTEGER,
    p_client_id INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_checkactivereservation для property_id = % и client_id = %', 
                 p_property_id, p_client_id;
    
    BEGIN
        SELECT EXISTS (
            SELECT 1 FROM propertyreservations 
            WHERE property_id = p_property_id AND client_id = p_client_id AND status = 'Active'
        ) INTO v_exists;
        
        RAISE NOTICE 'Процедура sp_checkactivereservation успешно выполнена. Результат: %', 
                     CASE WHEN v_exists THEN 'Резервирование существует' ELSE 'Резервирование не найдено' END;
        
        RETURN v_exists;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_checkactivereservation: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_checkactivereservation
/*
DO $$
DECLARE
    v_reservation_exists BOOLEAN;
BEGIN
    v_reservation_exists := sp_checkactivereservation(1, 1);
    RAISE NOTICE 'Резервирование существует: %', v_reservation_exists;
END $$;
*/

-- Создать резервирование
CREATE OR REPLACE FUNCTION sp_createpropertyreservation(
    p_property_id INTEGER,
    p_client_id INTEGER,
    p_realtor_id INTEGER,
    p_reservation_date TIMESTAMP,
    p_expiry_date TIMESTAMP,
    p_status VARCHAR(20)
)
RETURNS INTEGER AS $$
DECLARE
    v_reservation_id INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_createpropertyreservation для property_id = % и client_id = %', 
                 p_property_id, p_client_id;
    
    BEGIN
        INSERT INTO propertyreservations (property_id, client_id, realtor_id, reservation_date, expiry_date, status)
        VALUES (p_property_id, p_client_id, p_realtor_id, p_reservation_date, p_expiry_date, p_status)
        RETURNING reservation_id INTO v_reservation_id;
        
        RAISE NOTICE 'Процедура sp_createpropertyreservation успешно выполнена. Создано резервирование с ID: %', v_reservation_id;
        
        -- Возвращаем созданное резервирование
        RAISE NOTICE 'Информация о созданном резервировании:';
        PERFORM * FROM sp_getpropertyreservationbyid(v_reservation_id);
        
        RETURN v_reservation_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_createpropertyreservation: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_createpropertyreservation
/*
DO $$
DECLARE
    v_new_reservation_id INTEGER;
BEGIN
    v_new_reservation_id := sp_createpropertyreservation(
        1,
        1,
        1,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days',
        'Active'
    );
    RAISE NOTICE 'Создано новое резервирование с ID: %', v_new_reservation_id;
END $$;
*/

-- Обновить резервирование
CREATE OR REPLACE FUNCTION sp_updatepropertyreservation(
    p_reservation_id INTEGER,
    p_status VARCHAR(20),
    p_expiry_date TIMESTAMP
)
RETURNS VOID AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_updatepropertyreservation для reservation_id = %', p_reservation_id;
    
    BEGIN
        UPDATE propertyreservations 
        SET status = p_status, expiry_date = p_expiry_date
        WHERE reservation_id = p_reservation_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_updatepropertyreservation успешно выполнена. Обновлено записей: %', v_row_count;
        
        -- Возвращаем обновленное резервирование
        RAISE NOTICE 'Информация об обновленном резервировании:';
        PERFORM * FROM sp_getpropertyreservationbyid(p_reservation_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_updatepropertyreservation: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_updatepropertyreservation
/*
SELECT sp_updatepropertyreservation(
    1,
    'Completed',
    CURRENT_TIMESTAMP
);
SELECT 'Процедура sp_updatepropertyreservation выполнена' AS Status;
*/

-- Обновить статус резервирования
CREATE OR REPLACE FUNCTION sp_updatereservationstatus(
    p_reservation_id INTEGER,
    p_status VARCHAR(20)
)
RETURNS VOID AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_updatereservationstatus для reservation_id = % со статусом: %', 
                 p_reservation_id, p_status;
    
    BEGIN
        UPDATE propertyreservations 
        SET status = p_status
        WHERE reservation_id = p_reservation_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_updatereservationstatus успешно выполнена. Обновлено записей: %', v_row_count;
        
        -- Возвращаем обновленное резервирование
        RAISE NOTICE 'Информация об обновленном резервировании:';
        PERFORM reservation_id, property_id, client_id, status, expiry_date 
        FROM propertyreservations WHERE reservation_id = p_reservation_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_updatereservationstatus: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_updatereservationstatus
-- SELECT sp_updatereservationstatus(1, 'Cancelled');
-- SELECT 'Процедура sp_updatereservationstatus выполнена' AS Status;

-- Удалить резервирование
CREATE OR REPLACE FUNCTION sp_deletepropertyreservation(p_reservation_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_remaining_reservations INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_deletepropertyreservation для reservation_id = %', p_reservation_id;
    
    BEGIN
        DELETE FROM propertyreservations WHERE reservation_id = p_reservation_id;
        
        GET DIAGNOSTICS v_remaining_reservations = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_deletepropertyreservation успешно выполнена. Удалено записей: %', v_remaining_reservations;
        
        -- Выводим информацию об удалении
        SELECT COUNT(*) INTO v_remaining_reservations FROM propertyreservations;
        RAISE NOTICE 'Оставшееся количество резервирований: %', v_remaining_reservations;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_deletepropertyreservation: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_deletepropertyreservation (ОСТОРОЖНО: удаляет данные!)
/*
SELECT sp_deletepropertyreservation(5);
SELECT 'Процедура sp_deletepropertyreservation выполнена' AS Status;
*/

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ CONTRACTS
-- =============================================

-- Получить все контракты
CREATE OR REPLACE FUNCTION sp_getallcontracts()
RETURNS TABLE (
    contract_id INTEGER,
    deal_id INTEGER,
    contract_date TIMESTAMP WITH TIME ZONE,
    contract_file VARCHAR(255),
    notes TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getallcontracts';
    
    BEGIN
        RETURN QUERY
        SELECT c.contract_id, c.deal_id, c.contract_date, c.contract_file, c.notes
        FROM contracts c
        ORDER BY c.contract_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getallcontracts успешно выполнена. Найдено контрактов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getallcontracts: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getallcontracts
-- SELECT * FROM sp_getallcontracts();
-- SELECT 'Вызов процедуры sp_getallcontracts завершен' AS Status;

-- Получить контракт по ID
CREATE OR REPLACE FUNCTION sp_getcontractbyid(p_contract_id INTEGER)
RETURNS TABLE (
    contract_id INTEGER,
    deal_id INTEGER,
    contract_date TIMESTAMP WITH TIME ZONE,
    contract_file VARCHAR(255),
    notes TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getcontractbyid для contract_id = %', p_contract_id;
    
    BEGIN
        RETURN QUERY
        SELECT c.contract_id, c.deal_id, c.contract_date, c.contract_file, c.notes
        FROM contracts c
        WHERE c.contract_id = p_contract_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getcontractbyid успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getcontractbyid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getcontractbyid
-- SELECT * FROM sp_getcontractbyid(1);
-- SELECT 'Вызов процедуры sp_getcontractbyid завершен' AS Status;

-- Получить контракты по deal_id
CREATE OR REPLACE FUNCTION sp_getcontractsbydealid(p_deal_id INTEGER)
RETURNS TABLE (
    contract_id INTEGER,
    deal_id INTEGER,
    contract_date TIMESTAMP WITH TIME ZONE,
    contract_file VARCHAR(255),
    notes TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getcontractsbydealid для deal_id = %', p_deal_id;
    
    BEGIN
        RETURN QUERY
        SELECT c.contract_id, c.deal_id, c.contract_date, c.contract_file, c.notes
        FROM contracts c
        WHERE c.deal_id = p_deal_id
        ORDER BY c.contract_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getcontractsbydealid успешно выполнена. Найдено контрактов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getcontractsbydealid: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getcontractsbydealid
-- SELECT * FROM sp_getcontractsbydealid(1);
-- SELECT 'Вызов процедуры sp_getcontractsbydealid завершен' AS Status;

-- Получить контракты по дате
CREATE OR REPLACE FUNCTION sp_getcontractsbydaterange(
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    contract_id INTEGER,
    deal_id INTEGER,
    contract_date TIMESTAMP WITH TIME ZONE,
    contract_file VARCHAR(255),
    notes TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getcontractsbydaterange для периода: % - %', p_start_date, p_end_date;
    
    BEGIN
        RETURN QUERY
        SELECT c.contract_id, c.deal_id, c.contract_date, c.contract_file, c.notes
        FROM contracts c
        WHERE c.contract_date >= p_start_date AND c.contract_date <= p_end_date
        ORDER BY c.contract_date DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getcontractsbydaterange успешно выполнена. Найдено контрактов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getcontractsbydaterange: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getcontractsbydaterange
/*
SELECT * FROM sp_getcontractsbydaterange(
    '2024-01-01'::TIMESTAMP WITH TIME ZONE,
    '2024-12-31'::TIMESTAMP WITH TIME ZONE
);
SELECT 'Вызов процедуры sp_getcontractsbydaterange завершен' AS Status;
*/

-- Создать контракт
CREATE OR REPLACE FUNCTION sp_createcontract(
    p_deal_id INTEGER,
    p_contract_date TIMESTAMP WITH TIME ZONE,
    p_contract_file VARCHAR(255),
    p_notes TEXT
)
RETURNS INTEGER AS $$
DECLARE
    v_contract_id INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_createcontract для deal_id = %', p_deal_id;
    
    BEGIN
        INSERT INTO contracts (deal_id, contract_date, contract_file, notes)
        VALUES (p_deal_id, p_contract_date, p_contract_file, p_notes)
        RETURNING contract_id INTO v_contract_id;
        
        RAISE NOTICE 'Процедура sp_createcontract успешно выполнена. Создан контракт с ID: %', v_contract_id;
        
        -- Возвращаем созданный контракт
        RAISE NOTICE 'Информация о созданном контракте:';
        PERFORM * FROM sp_getcontractbyid(v_contract_id);
        
        RETURN v_contract_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_createcontract: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_createcontract
/*
DO $$
DECLARE
    v_new_contract_id INTEGER;
BEGIN
    v_new_contract_id := sp_createcontract(
        1,
        CURRENT_TIMESTAMP,
        'contract_123.pdf',
        'Дополнительные условия договора'
    );
    RAISE NOTICE 'Создан новый контракт с ID: %', v_new_contract_id;
END $$;
*/

-- Обновить контракт
CREATE OR REPLACE FUNCTION sp_updatecontract(
    p_contract_id INTEGER,
    p_contract_date TIMESTAMP WITH TIME ZONE,
    p_contract_file VARCHAR(255),
    p_notes TEXT
)
RETURNS VOID AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_updatecontract для contract_id = %', p_contract_id;
    
    BEGIN
        UPDATE contracts 
        SET contract_date = p_contract_date, contract_file = p_contract_file, notes = p_notes
        WHERE contract_id = p_contract_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_updatecontract успешно выполнена. Обновлено записей: %', v_row_count;
        
        -- Возвращаем обновленный контракт
        RAISE NOTICE 'Информация об обновленном контракте:';
        PERFORM * FROM sp_getcontractbyid(p_contract_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_updatecontract: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_updatecontract
/*
SELECT sp_updatecontract(
    1,
    CURRENT_TIMESTAMP,
    'updated_contract_123.pdf',
    'Обновленные условия договора'
);
SELECT 'Процедура sp_updatecontract выполнена' AS Status;
*/

-- Удалить контракт
CREATE OR REPLACE FUNCTION sp_deletecontract(p_contract_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_remaining_contracts INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_deletecontract для contract_id = %', p_contract_id;
    
    BEGIN
        DELETE FROM contracts WHERE contract_id = p_contract_id;
        
        GET DIAGNOSTICS v_remaining_contracts = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_deletecontract успешно выполнена. Удалено записей: %', v_remaining_contracts;
        
        -- Выводим информацию об удалении
        SELECT COUNT(*) INTO v_remaining_contracts FROM contracts;
        RAISE NOTICE 'Оставшееся количество контрактов: %', v_remaining_contracts;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_deletecontract: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_deletecontract (ОСТОРОЖНО: удаляет данные!)
/*
SELECT sp_deletecontract(5);
SELECT 'Процедура sp_deletecontract выполнена' AS Status;
*/

-- =============================================
-- ДОПОЛНИТЕЛЬНЫЕ ПРОЦЕДУРЫ
-- =============================================

-- Получить статистику по объектам недвижимости
CREATE OR REPLACE FUNCTION sp_getpropertystatistics()
RETURNS TABLE (
    total_properties BIGINT,
    available_properties BIGINT,
    total_value NUMERIC
) AS $$
DECLARE
    v_total_properties BIGINT;
    v_available_properties BIGINT;
    v_total_value NUMERIC;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getpropertystatistics';
    
    BEGIN
        RETURN QUERY
        SELECT 
            COUNT(*)::BIGINT AS total_properties,
            COUNT(CASE WHEN is_available THEN 1 END)::BIGINT AS available_properties,
            COALESCE(SUM(price), 0)::NUMERIC AS total_value
        FROM properties;
        
        GET DIAGNOSTICS v_total_properties = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getpropertystatistics успешно выполнена. Статистика:';
        RAISE NOTICE 'Всего объектов: %', v_total_properties;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getpropertystatistics: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getpropertystatistics
/*
SELECT * FROM sp_getpropertystatistics();
*/

-- Получить общую статистику
CREATE OR REPLACE FUNCTION sp_getoverallstatistics()
RETURNS TABLE (
    total_users BIGINT,
    total_clients BIGINT,
    total_realtors BIGINT,
    total_deals BIGINT,
    total_reservations BIGINT
) AS $$
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getoverallstatistics';
    
    BEGIN
        RETURN QUERY
        SELECT 
            (SELECT COUNT(*) FROM users)::BIGINT AS total_users,
            (SELECT COUNT(*) FROM clients)::BIGINT AS total_clients,
            (SELECT COUNT(*) FROM realtors)::BIGINT AS total_realtors,
            (SELECT COUNT(*) FROM deals)::BIGINT AS total_deals,
            (SELECT COUNT(*) FROM propertyreservations)::BIGINT AS total_reservations;
        
        RAISE NOTICE 'Процедура sp_getoverallstatistics успешно выполнена';
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getoverallstatistics: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getoverallstatistics
/*
SELECT * FROM sp_getoverallstatistics();
*/

-- Поиск объектов по параметрам
CREATE OR REPLACE FUNCTION sp_searchproperties(
    p_property_type VARCHAR(50) DEFAULT NULL,
    p_min_price NUMERIC(15,2) DEFAULT NULL,
    p_max_price NUMERIC(15,2) DEFAULT NULL,
    p_min_rooms INTEGER DEFAULT NULL,
    p_max_rooms INTEGER DEFAULT NULL,
    p_is_available BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    property_id INTEGER,
    address VARCHAR(255),
    property_type VARCHAR(50),
    area NUMERIC(10,2),
    price NUMERIC(15,2),
    description TEXT,
    realtor_id INTEGER,
    is_available BOOLEAN,
    rooms INTEGER,
    floor INTEGER,
    total_floors INTEGER,
    main_image_url VARCHAR(500),
    image_urls TEXT
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_searchproperties с параметрами:';
    RAISE NOTICE 'Тип: %', COALESCE(p_property_type, 'Любой');
    RAISE NOTICE 'Цена от: %', COALESCE(p_min_price::TEXT, 'Любая');
    RAISE NOTICE 'Цена до: %', COALESCE(p_max_price::TEXT, 'Любая');
    RAISE NOTICE 'Комнат от: %', COALESCE(p_min_rooms::TEXT, 'Любое');
    RAISE NOTICE 'Комнат до: %', COALESCE(p_max_rooms::TEXT, 'Любое');
    RAISE NOTICE 'Доступность: %', CASE 
        WHEN p_is_available IS NULL THEN 'Любая'
        WHEN p_is_available THEN 'Да'
        ELSE 'Нет'
    END;
    
    BEGIN
        RETURN QUERY
        SELECT 
            p.property_id, p.address, p.property_type, p.area, p.price, p.description, 
            p.realtor_id, p.is_available, p.rooms, p.floor, p.total_floors, 
            p.main_image_url, p.image_urls
        FROM properties p
        WHERE (p_property_type IS NULL OR p.property_type = p_property_type)
            AND (p_min_price IS NULL OR p.price >= p_min_price)
            AND (p_max_price IS NULL OR p.price <= p_max_price)
            AND (p_min_rooms IS NULL OR p.rooms >= p_min_rooms)
            AND (p_max_rooms IS NULL OR p.rooms <= p_max_rooms)
            AND (p_is_available IS NULL OR p.is_available = p_is_available)
        ORDER BY p.price;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_searchproperties успешно выполнена. Найдено объектов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_searchproperties: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_searchproperties
/*
SELECT * FROM sp_searchproperties(
    'Apartment',
    100000,
    500000,
    2,
    4,
    true
);
SELECT 'Вызов процедуры sp_searchproperties завершен' AS Status;
*/

-- Получить детали сделки с информацией о клиенте и риэлторе
CREATE OR REPLACE FUNCTION sp_getdealdetails(p_deal_id INTEGER)
RETURNS TABLE (
    deal_id INTEGER,
    deal_type VARCHAR(50),
    deal_price NUMERIC(15,2),
    deal_date TIMESTAMP WITH TIME ZONE,
    property_id INTEGER,
    address VARCHAR(255),
    property_type VARCHAR(50),
    property_price NUMERIC(15,2),
    client_id INTEGER,
    client_name VARCHAR(100),
    client_email VARCHAR(100),
    realtor_id INTEGER,
    realtor_name VARCHAR(100),
    commission_rate NUMERIC(5,2)
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getdealdetails для deal_id = %', p_deal_id;
    
    BEGIN
        RETURN QUERY
        SELECT 
            d.deal_id,
            d.deal_type,
            d.deal_price,
            d.deal_date,
            p.property_id,
            p.address,
            p.property_type,
            p.price AS property_price,
            c.client_id,
            c.full_name AS client_name,
            c.email AS client_email,
            r.realtor_id,
            r.full_name AS realtor_name,
            r.commission_rate
        FROM deals d
        INNER JOIN properties p ON d.property_id = p.property_id
        INNER JOIN clients c ON d.client_id = c.client_id
        INNER JOIN realtors r ON d.realtor_id = r.realtor_id
        WHERE d.deal_id = p_deal_id;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getdealdetails успешно выполнена. Найдено записей: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getdealdetails: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getdealdetails
-- SELECT * FROM sp_getdealdetails(1);
-- SELECT 'Вызов процедуры sp_getdealdetails завершен' AS Status;

-- Получить список клиентов с их сделками
CREATE OR REPLACE FUNCTION sp_getclientswithdeals()
RETURNS TABLE (
    client_id INTEGER,
    full_name VARCHAR(100),
    email VARCHAR(100),
    phone_number VARCHAR(20),
    total_deals BIGINT,
    total_spent NUMERIC
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getclientswithdeals';
    
    BEGIN
        RETURN QUERY
        SELECT 
            c.client_id,
            c.full_name,
            c.email,
            c.phone_number,
            COUNT(d.deal_id)::BIGINT AS total_deals,
            COALESCE(SUM(d.deal_price), 0)::NUMERIC AS total_spent
        FROM clients c
        LEFT JOIN deals d ON c.client_id = d.client_id
        GROUP BY c.client_id, c.full_name, c.email, c.phone_number
        ORDER BY total_spent DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getclientswithdeals успешно выполнена. Найдено клиентов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getclientswithdeals: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getclientswithdeals
-- SELECT * FROM sp_getclientswithdeals();
-- SELECT 'Вызов процедуры sp_getclientswithdeals завершен' AS Status;

-- Получить список риэлторов с их статистикой
CREATE OR REPLACE FUNCTION sp_getrealtorswithstatistics()
RETURNS TABLE (
    realtor_id INTEGER,
    full_name VARCHAR(100),
    email VARCHAR(100),
    phone_number VARCHAR(20),
    commission_rate NUMERIC(5,2),
    total_properties BIGINT,
    total_deals BIGINT,
    total_deal_amount NUMERIC,
    total_commission NUMERIC
) AS $$
DECLARE
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE 'Выполняется процедура sp_getrealtorswithstatistics';
    
    BEGIN
        RETURN QUERY
        SELECT 
            r.realtor_id,
            r.full_name,
            r.email,
            r.phone_number,
            r.commission_rate,
            COUNT(DISTINCT p.property_id)::BIGINT AS total_properties,
            COUNT(DISTINCT d.deal_id)::BIGINT AS total_deals,
            COALESCE(SUM(d.deal_price), 0)::NUMERIC AS total_deal_amount,
            COALESCE(SUM(d.deal_price * r.commission_rate / 100), 0)::NUMERIC AS total_commission
        FROM realtors r
        LEFT JOIN properties p ON r.realtor_id = p.realtor_id
        LEFT JOIN deals d ON r.realtor_id = d.realtor_id
        GROUP BY r.realtor_id, r.full_name, r.email, r.phone_number, r.commission_rate
        ORDER BY total_commission DESC;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE 'Процедура sp_getrealtorswithstatistics успешно выполнена. Найдено риэлторов: %', v_row_count;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Ошибка в sp_getrealtorswithstatistics: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Пример вызова процедуры sp_getrealtorswithstatistics
-- SELECT * FROM sp_getrealtorswithstatistics();
-- SELECT 'Вызов процедуры sp_getrealtorswithstatistics завершен' AS Status;

-- Вывод сообщения об успешном создании процедур
DO $$
BEGIN
    RAISE NOTICE 'Все хранимые процедуры созданы с обработкой ошибок и выводом информации';
END $$;

-- =============================================
-- ТЕСТОВЫЕ ВЫЗОВЫ ПРОЦЕДУР
-- =============================================

/*
-- Примеры вызова основных процедур для тестирования:

DO $$
BEGIN
    -- 1. Получить всех пользователей
    RAISE NOTICE '=== Тест 1: Получить всех пользователей ===';
    PERFORM * FROM sp_getallusers();
    
    -- 2. Получить клиента по ID
    RAISE NOTICE '=== Тест 2: Получить клиента по ID ===';
    PERFORM * FROM sp_getclientbyid(1);
    
    -- 3. Получить всех риэлторов
    RAISE NOTICE '=== Тест 3: Получить всех риэлторов ===';
    PERFORM * FROM sp_getallrealtors();
    
    -- 4. Получить доступные объекты недвижимости
    RAISE NOTICE '=== Тест 4: Получить доступные объекты недвижимости ===';
    PERFORM * FROM sp_getavailableproperties();
    
    -- 5. Получить статистику по объектам
    RAISE NOTICE '=== Тест 5: Получить статистику по объектам недвижимости ===';
    PERFORM * FROM sp_getpropertystatistics();
    
    -- 6. Получить общую статистику системы
    RAISE NOTICE '=== Тест 6: Получить общую статистику системы ===';
    PERFORM * FROM sp_getoverallstatistics();
    
    -- 7. Поиск объектов с параметрами
    RAISE NOTICE '=== Тест 7: Поиск объектов с параметрами ===';
    PERFORM * FROM sp_searchproperties(
        'Apartment',
        100000,
        1000000,
        NULL,
        NULL,
        true
    );
    
    RAISE NOTICE '=== Тестирование завершено ===';
END $$;

DO $$
BEGIN
    -- 1. Тестирование процедур для Users
    RAISE NOTICE '=== Тестирование процедур для Users ===';
    
    -- Получить всех пользователей
    PERFORM * FROM sp_getallusers();
    
    -- Получить пользователей с ролью Client
    PERFORM * FROM sp_getusersbyrole('Client');
    
    -- 2. Тестирование процедур для Clients
    RAISE NOTICE '=== Тестирование процедур для Clients ===';
    
    -- Получить всех клиентов
    PERFORM * FROM sp_getallclients();
    
    -- 3. Тестирование процедур для Realtors
    RAISE NOTICE '=== Тестирование процедур для Realtors ===';
    
    -- Получить всех риэлторов
    PERFORM * FROM sp_getallrealtors();
    
    -- 4. Тестирование процедур для Properties
    RAISE NOTICE '=== Тестирование процедур для Properties ===';
    
    -- Получить все объекты
    PERFORM * FROM sp_getallproperties();
    
    -- Получить доступные объекты
    PERFORM * FROM sp_getavailableproperties();
    
    -- Поиск объектов
    PERFORM * FROM sp_searchproperties(
        'Apartment',
        100000,
        500000,
        NULL,
        NULL,
        true
    );
    
    -- 5. Тестирование процедур для Deals
    RAISE NOTICE '=== Тестирование процедур для Deals ===';
    
    -- Получить все сделки
    PERFORM * FROM sp_getalldeals();
    
    -- 6. Тестирование статистических процедур
    RAISE NOTICE '=== Тестирование статистических процедур ===';
    
    -- Получить статистику по объектам
    PERFORM * FROM sp_getpropertystatistics();
    
    -- Получить общую статистику
    PERFORM * FROM sp_getoverallstatistics();
    
    -- 7. Тестирование сложных отчетов
    RAISE NOTICE '=== Тестирование сложных отчетов ===';
    
    -- Клиенты с их сделками
    PERFORM * FROM sp_getclientswithdeals();
    
    -- Риэлторы со статистикой
    PERFORM * FROM sp_getrealtorswithstatistics();
    
    RAISE NOTICE '=== Тестирование завершено ===';
END $$;
*/
*/