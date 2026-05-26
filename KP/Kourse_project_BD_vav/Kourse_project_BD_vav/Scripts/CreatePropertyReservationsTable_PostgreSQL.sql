-- Скрипт создания таблицы PropertyReservations для PostgreSQL
-- Используйте этот скрипт, если таблица отсутствует в базе данных

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

