-- Удаляем существующие таблицы (в обратном порядке из-за foreign keys)
DROP TABLE IF EXISTS Contracts;
DROP TABLE IF EXISTS Deals;
DROP TABLE IF EXISTS Properties;
DROP TABLE IF EXISTS Realtors;
DROP TABLE IF EXISTS Clients;



-- Таблица пользователей
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'Client',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    client_id INT NULL,
    realtor_id INT NULL
);

-- Добавляем связь с clients
ALTER TABLE clients 
ADD COLUMN IF NOT EXISTS user_id INT NULL;

-- Добавляем связь с realtors
ALTER TABLE realtors 
ADD COLUMN IF NOT EXISTS user_id INT NULL;

-- Индексы
CREATE INDEX IF NOT EXISTS ix_users_username ON users(username);
CREATE INDEX IF NOT EXISTS ix_users_email ON users(email);
CREATE INDEX IF NOT EXISTS ix_clients_user ON clients(user_id);
CREATE INDEX IF NOT EXISTS ix_realtors_user ON realtors(user_id);




-- Создаем таблицы для PostgreSQL
CREATE TABLE Clients (
    client_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    passport_number VARCHAR(20),
    registration_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE Realtors (
    realtor_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    hire_date DATE DEFAULT CURRENT_DATE,
    commission_rate DECIMAL(5,2)
);

CREATE TABLE Properties (
    property_id SERIAL PRIMARY KEY,
    address VARCHAR(255) NOT NULL,
    property_type VARCHAR(50),
    area DECIMAL(10,2),
    price DECIMAL(15,2),
    description TEXT,
    realtor_id INT NULL,
    is_available BOOLEAN DEFAULT true,
    FOREIGN KEY (realtor_id) REFERENCES Realtors(realtor_id)
);

CREATE TABLE Deals (
    deal_id SERIAL PRIMARY KEY,
    property_id INT NOT NULL,
    client_id INT NOT NULL,
    realtor_id INT NULL,
    deal_type VARCHAR(50),
    deal_date DATE DEFAULT CURRENT_DATE,
    deal_price DECIMAL(15,2),
    FOREIGN KEY (property_id) REFERENCES Properties(property_id),
    FOREIGN KEY (client_id) REFERENCES Clients(client_id),
    FOREIGN KEY (realtor_id) REFERENCES Realtors(realtor_id)
);

CREATE TABLE Contracts (
    contract_id SERIAL PRIMARY KEY,
    deal_id INT NOT NULL,
    contract_date DATE DEFAULT CURRENT_DATE,
    contract_file TEXT,
    notes TEXT,
    FOREIGN KEY (deal_id) REFERENCES Deals(deal_id)
);




CREATE TABLE UserActivities (
    activity_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица резервирования
CREATE TABLE PropertyReservations (
    reservation_id SERIAL PRIMARY KEY,
    property_id INT NOT NULL,
    client_id INT NOT NULL,
    realtor_id INT NULL,
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'Active',
    notes TEXT NULL
);








-- Добавляем таблицу Избранное
CREATE TABLE IF NOT EXISTS favorites (
    favorite_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    property_id INTEGER NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_favorites_users FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_favorites_properties FOREIGN KEY (property_id) REFERENCES properties(property_id),
    CONSTRAINT uq_user_property UNIQUE (user_id, property_id)
);

-- Добавляем колонки для картинок в properties
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'properties' AND column_name = 'main_image_url') THEN
        ALTER TABLE properties
        ADD COLUMN main_image_url VARCHAR(500),
        ADD COLUMN image_urls TEXT,
        ADD COLUMN rooms INTEGER,
        ADD COLUMN floor INTEGER,
        ADD COLUMN total_floors INTEGER;
    END IF;
END $$;

-- Добавляем индексы
CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_property ON favorites(property_id);



SELECT * FROM "users";
SELECT * FROM "clients"; 


-- Подключитесь к PostgreSQL (через pgAdmin или psql)
-- Выполните последовательно:

-- Отключаем триггеры и ограничения
SET session_replication_role = replica;

-- Очищаем таблицы в правильном порядке (чтобы избежать ошибок внешних ключей)
TRUNCATE TABLE "propertyreservations" CASCADE;
TRUNCATE TABLE "favorites" CASCADE;
TRUNCATE TABLE "deals" CASCADE;
TRUNCATE TABLE "contracts" CASCADE;
TRUNCATE TABLE "properties" CASCADE;
TRUNCATE TABLE "useractivities" CASCADE;
TRUNCATE TABLE "realtors" CASCADE;
TRUNCATE TABLE "clients" CASCADE;
TRUNCATE TABLE "users" CASCADE;

-- Включаем обратно
SET session_replication_role = DEFAULT;

-- Проверяем, что все таблицы пустые
SELECT 
    table_name, 
    COUNT(*) as record_count
FROM information_schema.tables 
WHERE table_schema = 'public'
    AND table_name IN (
        'users', 'clients', 'realtors', 'properties', 
        'deals', 'contracts', 'favorites', 'useractivities', 
        'propertyreservations'
    )
GROUP BY table_name
ORDER BY table_name;



-- Выполнить в PostgreSQL (psql, pgAdmin)
ALTER TABLE deals ADD COLUMN deal_status VARCHAR(50) NULL;
-- В PostgreSQL используется VARCHAR, а не NVARCHAR





-- PostgreSQL: Создание таблицы PropertyReservations
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'propertyreservations') THEN
        CREATE TABLE propertyreservations (
            reservation_id SERIAL PRIMARY KEY,
            property_id INTEGER NOT NULL,
            client_id INTEGER NOT NULL,
            realtor_id INTEGER,
            reservation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            expiry_date TIMESTAMP NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'Active',
            notes TEXT,
            
            -- Внешние ключи
            CONSTRAINT fk_propertyreservations_properties 
                FOREIGN KEY (property_id) REFERENCES properties(property_id) 
                ON DELETE RESTRICT,
            CONSTRAINT fk_propertyreservations_clients 
                FOREIGN KEY (client_id) REFERENCES clients(client_id) 
                ON DELETE RESTRICT,
            CONSTRAINT fk_propertyreservations_realtors 
                FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id) 
                ON DELETE RESTRICT
        );
        
        -- Индексы для улучшения производительности
        CREATE INDEX ix_propertyreservations_property_id ON propertyreservations(property_id);
        CREATE INDEX ix_propertyreservations_client_id ON propertyreservations(client_id);
        CREATE INDEX ix_propertyreservations_status ON propertyreservations(status);
        CREATE INDEX ix_propertyreservations_expiry_date ON propertyreservations(expiry_date);
        
        RAISE NOTICE 'Таблица PropertyReservations создана';
    ELSE
        RAISE NOTICE 'Таблица PropertyReservations уже существует';
    END IF;
END $$;

-- Проверяем наличие внешних ключей
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
   AND tc.table_name = 'propertyreservations';


drop table favorites






drop table propertyreservations 

CREATE TABLE "propertyreservations" (
    "reservation_id" SERIAL PRIMARY KEY,
    "property_id" INT NOT NULL,
    "client_id" INT NOT NULL,
    "realtor_id" INT NOT NULL,
    "status" VARCHAR(20) DEFAULT 'Active',
    "reservation_date" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "expiry_date" TIMESTAMP NOT NULL,
    
    -- Внешние ключи
    CONSTRAINT fk_res_prop FOREIGN KEY (property_id) REFERENCES "properties"(property_id) ON DELETE RESTRICT,
    CONSTRAINT fk_res_client FOREIGN KEY (client_id) REFERENCES "clients"(client_id) ON DELETE RESTRICT,
    CONSTRAINT fk_res_realtor FOREIGN KEY (realtor_id) REFERENCES "realtors"(realtor_id) ON DELETE RESTRICT
);






CREATE TABLE IF NOT EXISTS propertyreservations (
    reservation_id SERIAL PRIMARY KEY,
    property_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    realtor_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'Active',
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP NOT NULL,
    
    -- Внешние ключи для связи с другими таблицами
    CONSTRAINT fk_reservations_property FOREIGN KEY (property_id) REFERENCES properties(property_id),
    CONSTRAINT fk_reservations_client FOREIGN KEY (client_id) REFERENCES clients(client_id),
    CONSTRAINT fk_reservations_realtor FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id)
);

-- Создаем индексы для улучшения производительности
CREATE INDEX IF NOT EXISTS ix_propertyreservations_property_id ON propertyreservations(property_id);
CREATE INDEX IF NOT EXISTS ix_propertyreservations_client_id ON propertyreservations(client_id);
CREATE INDEX IF NOT EXISTS ix_propertyreservations_realtor_id ON propertyreservations(realtor_id);
CREATE INDEX IF NOT EXISTS ix_propertyreservations_status ON propertyreservations(status);

-- Комментарии к таблице и столбцам
COMMENT ON TABLE propertyreservations IS 'Таблица резервирований объектов недвижимости для просмотра';
COMMENT ON COLUMN propertyreservations.reservation_id IS 'Уникальный идентификатор резервирования';
COMMENT ON COLUMN propertyreservations.property_id IS 'Идентификатор объекта недвижимости';
COMMENT ON COLUMN propertyreservations.client_id IS 'Идентификатор клиента';
COMMENT ON COLUMN propertyreservations.realtor_id IS 'Идентификатор риэлтора';
COMMENT ON COLUMN propertyreservations.status IS 'Статус резервирования (Active, Completed, Cancelled)';
COMMENT ON COLUMN propertyreservations.reservation_date IS 'Дата создания резервирования';
COMMENT ON COLUMN propertyreservations.expiry_date IS 'Дата и время запланированного просмотра';











   ALTER TABLE favorites 
ADD COLUMN added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;