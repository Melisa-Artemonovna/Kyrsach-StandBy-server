-- Создание хранимых процедур для PostgreSQL
-- Все операции с данными выполняются через процедуры

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
BEGIN
    RETURN QUERY
    SELECT u.user_id, u.username, u.password_hash, u.email, u.full_name, u.role, u.created_at, u.client_id, u.realtor_id
    FROM users u
    WHERE u.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT u.user_id, u.username, u.password_hash, u.email, u.full_name, u.role, u.created_at, u.client_id, u.realtor_id
    FROM users u
    WHERE u.username = p_username;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT u.user_id, u.username, u.password_hash, u.email, u.full_name, u.role, u.created_at, u.client_id, u.realtor_id
    FROM users u
    ORDER BY u.user_id;
END;
$$ LANGUAGE plpgsql;

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
    INSERT INTO users (username, password_hash, email, full_name, role, created_at)
    VALUES (p_username, p_password_hash, p_email, p_full_name, p_role, p_created_at)
    RETURNING user_id INTO v_user_id;
    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql;

-- Обновить пользователя
CREATE OR REPLACE FUNCTION sp_updateuser(
    p_user_id INTEGER,
    p_username VARCHAR(50),
    p_email VARCHAR(100),
    p_full_name VARCHAR(100),
    p_role VARCHAR(20)
)
RETURNS VOID AS $$
BEGIN
    UPDATE users 
    SET username = p_username, email = p_email, full_name = p_full_name, role = p_role
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT c.client_id, c.full_name, c.phone_number, c.email, c.passport_number, c.registration_date::timestamp, c.user_id
    FROM clients c
    ORDER BY c.client_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT c.client_id, c.full_name, c.phone_number, c.email, c.passport_number, c.registration_date::timestamp, c.user_id
    FROM clients c
    WHERE c.client_id = p_client_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT c.client_id, c.full_name, c.phone_number, c.email, c.passport_number, c.registration_date::timestamp, c.user_id
    FROM clients c
    WHERE c.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

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
    INSERT INTO clients (full_name, phone_number, email, passport_number, registration_date, user_id)
    VALUES (p_full_name, p_phone_number, p_email, p_passport_number, CURRENT_DATE, p_user_id)
    RETURNING client_id INTO v_client_id;
    RETURN v_client_id;
END;
$$ LANGUAGE plpgsql;

-- Обновить клиента
CREATE OR REPLACE FUNCTION sp_updateclient(
    p_client_id INTEGER,
    p_full_name VARCHAR(100),
    p_phone_number VARCHAR(20),
    p_email VARCHAR(100),
    p_passport_number VARCHAR(20)
)
RETURNS VOID AS $$
BEGIN
    UPDATE clients 
    SET full_name = p_full_name, phone_number = p_phone_number, email = p_email, passport_number = p_passport_number
    WHERE client_id = p_client_id;
END;
$$ LANGUAGE plpgsql;

-- Удалить клиента
CREATE OR REPLACE FUNCTION sp_deleteclient(p_client_id INTEGER)
RETURNS VOID AS $$
BEGIN
    -- Удаляем все резервации для этого клиента
    DELETE FROM propertyreservations WHERE client_id = p_client_id;
    
    -- Deals удалятся автоматически благодаря CASCADE, но можно удалить явно для безопасности
    DELETE FROM deals WHERE client_id = p_client_id;
    
    -- Удаляем самого клиента
    DELETE FROM clients WHERE client_id = p_client_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT r.realtor_id, r.full_name, r.phone_number, r.email, r.hire_date, r.commission_rate, r.user_id
    FROM realtors r
    ORDER BY r.realtor_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT r.realtor_id, r.full_name, r.phone_number, r.email, r.hire_date, r.commission_rate, r.user_id
    FROM realtors r
    WHERE r.realtor_id = p_realtor_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT r.realtor_id, r.full_name, r.phone_number, r.email, r.hire_date, r.commission_rate, r.user_id
    FROM realtors r
    WHERE r.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

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
    INSERT INTO realtors (full_name, phone_number, email, hire_date, commission_rate, user_id)
    VALUES (p_full_name, p_phone_number, p_email, CURRENT_TIMESTAMP, 5.0, p_user_id)
    RETURNING realtor_id INTO v_realtor_id;
    RETURN v_realtor_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    UPDATE realtors 
    SET full_name = p_full_name, 
        phone_number = p_phone_number, 
        email = p_email,
        hire_date = COALESCE(p_hire_date, hire_date),
        commission_rate = COALESCE(p_commission_rate, commission_rate)
    WHERE realtor_id = p_realtor_id;
END;
$$ LANGUAGE plpgsql;

-- Удалить риэлтора
CREATE OR REPLACE FUNCTION sp_deleterealtor(p_realtor_id INTEGER)
RETURNS VOID AS $$
BEGIN
    -- Удаляем все резервации для этого риэлтора
    DELETE FROM propertyreservations WHERE realtor_id = p_realtor_id;
    
    -- Удаляем все сделки для этого риэлтора (FK без CASCADE)
    DELETE FROM deals WHERE realtor_id = p_realtor_id;
    
    -- Удаляем все объекты недвижимости для этого риэлтора
    -- Сначала удаляем связанные данные для объектов
    DELETE FROM propertyreservations 
    WHERE property_id IN (SELECT property_id FROM properties WHERE realtor_id = p_realtor_id);
    
    DELETE FROM deals 
    WHERE property_id IN (SELECT property_id FROM properties WHERE realtor_id = p_realtor_id);
    
    -- Удаляем сами объекты
    DELETE FROM properties WHERE realtor_id = p_realtor_id;
    
    -- Удаляем самого риэлтора
    DELETE FROM realtors WHERE realtor_id = p_realtor_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT p.property_id, p.address, p.property_type, p.area, p.price, p.description, p.realtor_id,
           p.is_available, p.rooms, p.floor, p.total_floors, p.main_image_url, p.image_urls
    FROM properties p
    ORDER BY p.property_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT p.property_id, p.address, p.property_type, p.area, p.price, p.description, p.realtor_id,
           p.is_available, p.rooms, p.floor, p.total_floors, p.main_image_url, p.image_urls
    FROM properties p
    WHERE p.property_id = p_property_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT p.property_id, p.address, p.property_type, p.area, p.price, p.description, p.realtor_id,
           p.is_available, p.rooms, p.floor, p.total_floors, p.main_image_url, p.image_urls
    FROM properties p
    WHERE p.realtor_id = p_realtor_id
    ORDER BY p.property_id;
END;
$$ LANGUAGE plpgsql;

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
    INSERT INTO properties (address, property_type, area, price, description, realtor_id, is_available, rooms, floor, total_floors, main_image_url, image_urls)
    VALUES (p_address, p_property_type, p_area, p_price, p_description, p_realtor_id, p_is_available, p_rooms, p_floor, p_total_floors, p_main_image_url, p_image_urls)
    RETURNING property_id INTO v_property_id;
    RETURN v_property_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    UPDATE properties 
    SET address = p_address, property_type = p_property_type, area = p_area, price = p_price,
        description = p_description, realtor_id = p_realtor_id, is_available = p_is_available,
        rooms = p_rooms, floor = p_floor, total_floors = p_total_floors,
        main_image_url = p_main_image_url, image_urls = p_image_urls
    WHERE property_id = p_property_id;
END;
$$ LANGUAGE plpgsql;

-- Удалить объект недвижимости
CREATE OR REPLACE FUNCTION sp_deleteproperty(p_property_id INTEGER)
RETURNS VOID AS $$
BEGIN
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
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT d.deal_id, d.property_id, d.client_id, d.realtor_id, d.deal_type, d.deal_status, d.deal_price, d.deal_date
    FROM deals d
    ORDER BY d.deal_date DESC;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT d.deal_id, d.property_id, d.client_id, d.realtor_id, d.deal_type, d.deal_status, d.deal_price, d.deal_date
    FROM deals d
    WHERE d.deal_id = p_deal_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT d.deal_id, d.property_id, d.client_id, d.realtor_id, d.deal_type, d.deal_status, d.deal_price, d.deal_date
    FROM deals d
    WHERE d.realtor_id = p_realtor_id
    ORDER BY d.deal_date DESC;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT d.deal_id, d.property_id, d.client_id, d.realtor_id, d.deal_type, d.deal_status, d.deal_price, d.deal_date
    FROM deals d
    WHERE d.client_id = p_client_id
    ORDER BY d.deal_date DESC;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT COUNT(*)::BIGINT, COALESCE(SUM(deal_price), 0)::NUMERIC
    FROM deals 
    WHERE realtor_id = p_realtor_id AND deal_date >= p_start_date AND deal_date <= p_end_date;
END;
$$ LANGUAGE plpgsql;

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
    INSERT INTO deals (property_id, client_id, realtor_id, deal_type, deal_price, deal_date)
    VALUES (p_property_id, p_client_id, p_realtor_id, p_deal_type, p_deal_price, p_deal_date)
    RETURNING deal_id INTO v_deal_id;
    RETURN v_deal_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    UPDATE deals 
    SET property_id = p_property_id, client_id = p_client_id, realtor_id = p_realtor_id,
        deal_type = p_deal_type, deal_price = p_deal_price, deal_date = p_deal_date
    WHERE deal_id = p_deal_id;
END;
$$ LANGUAGE plpgsql;

-- Удалить сделку
CREATE OR REPLACE FUNCTION sp_deletedeal(p_deal_id INTEGER)
RETURNS VOID AS $$
BEGIN
    -- Удаляем все контракты для этой сделки (если таблица существует)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'contracts') THEN
        DELETE FROM contracts WHERE deal_id = p_deal_id;
    END IF;
    
    -- Удаляем саму сделку
    DELETE FROM deals WHERE deal_id = p_deal_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT pr.reservation_id, pr.property_id, pr.client_id, pr.realtor_id, pr.status, pr.reservation_date, pr.expiry_date
    FROM propertyreservations pr
    ORDER BY pr.reservation_date DESC;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT pr.reservation_id, pr.property_id, pr.client_id, pr.realtor_id, pr.status, pr.reservation_date, pr.expiry_date
    FROM propertyreservations pr
    WHERE pr.reservation_id = p_reservation_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT pr.reservation_id, pr.property_id, pr.client_id, pr.realtor_id, pr.status, pr.reservation_date, pr.expiry_date
    FROM propertyreservations pr
    WHERE pr.realtor_id = p_realtor_id
    ORDER BY pr.reservation_date DESC;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT pr.reservation_id, pr.property_id, pr.client_id, pr.realtor_id, pr.status, pr.reservation_date, pr.expiry_date
    FROM propertyreservations pr
    WHERE pr.client_id = p_client_id
    ORDER BY pr.reservation_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Проверить активное резервирование
CREATE OR REPLACE FUNCTION sp_checkactivereservation(
    p_property_id INTEGER,
    p_client_id INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM propertyreservations 
        WHERE property_id = p_property_id AND client_id = p_client_id AND status = 'Active'
    );
END;
$$ LANGUAGE plpgsql;

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
    INSERT INTO propertyreservations (property_id, client_id, realtor_id, reservation_date, expiry_date, status)
    VALUES (p_property_id, p_client_id, p_realtor_id, p_reservation_date, p_expiry_date, p_status)
    RETURNING reservation_id INTO v_reservation_id;
    RETURN v_reservation_id;
END;
$$ LANGUAGE plpgsql;

-- Обновить резервирование
CREATE OR REPLACE FUNCTION sp_updatepropertyreservation(
    p_reservation_id INTEGER,
    p_status VARCHAR(20),
    p_expiry_date TIMESTAMP
)
RETURNS VOID AS $$
BEGIN
    UPDATE propertyreservations 
    SET status = p_status, expiry_date = p_expiry_date
    WHERE reservation_id = p_reservation_id;
END;
$$ LANGUAGE plpgsql;

-- Удалить резервирование
CREATE OR REPLACE FUNCTION sp_deletepropertyreservation(p_reservation_id INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM propertyreservations WHERE reservation_id = p_reservation_id;
END;
$$ LANGUAGE plpgsql;

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
BEGIN
    RETURN QUERY
    SELECT c.contract_id, c.deal_id, c.contract_date, c.contract_file, c.notes
    FROM contracts c
    ORDER BY c.contract_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Получить контракт по ID
CREATE OR REPLACE FUNCTION sp_getcontractbyid(p_contract_id INTEGER)
RETURNS TABLE (
    contract_id INTEGER,
    deal_id INTEGER,
    contract_date TIMESTAMP WITH TIME ZONE,
    contract_file VARCHAR(255),
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.contract_id, c.deal_id, c.contract_date, c.contract_file, c.notes
    FROM contracts c
    WHERE c.contract_id = p_contract_id;
END;
$$ LANGUAGE plpgsql;

-- Получить контракты по deal_id
CREATE OR REPLACE FUNCTION sp_getcontractsbydealid(p_deal_id INTEGER)
RETURNS TABLE (
    contract_id INTEGER,
    deal_id INTEGER,
    contract_date TIMESTAMP WITH TIME ZONE,
    contract_file VARCHAR(255),
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.contract_id, c.deal_id, c.contract_date, c.contract_file, c.notes
    FROM contracts c
    WHERE c.deal_id = p_deal_id
    ORDER BY c.contract_date DESC;
END;
$$ LANGUAGE plpgsql;

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
    INSERT INTO contracts (deal_id, contract_date, contract_file, notes)
    VALUES (p_deal_id, p_contract_date, p_contract_file, p_notes)
    RETURNING contract_id INTO v_contract_id;
    RETURN v_contract_id;
END;
$$ LANGUAGE plpgsql;

-- Обновить контракт
CREATE OR REPLACE FUNCTION sp_updatecontract(
    p_contract_id INTEGER,
    p_contract_date TIMESTAMP WITH TIME ZONE,
    p_contract_file VARCHAR(255),
    p_notes TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE contracts 
    SET contract_date = p_contract_date, contract_file = p_contract_file, notes = p_notes
    WHERE contract_id = p_contract_id;
END;
$$ LANGUAGE plpgsql;

-- Удалить контракт
CREATE OR REPLACE FUNCTION sp_deletecontract(p_contract_id INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM contracts WHERE contract_id = p_contract_id;
END;
$$ LANGUAGE plpgsql;

SELECT 'Все хранимые процедуры созданы' AS status;

