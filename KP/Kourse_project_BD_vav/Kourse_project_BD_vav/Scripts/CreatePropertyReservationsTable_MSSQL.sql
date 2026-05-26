-- Скрипт создания таблицы PropertyReservations для MSSQL Server
-- Используйте этот скрипт, если таблица отсутствует в базе данных

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PropertyReservations]') AND type in (N'U'))
BEGIN
    CREATE TABLE [PropertyReservations] (
        [reservation_id] INT IDENTITY(1,1) PRIMARY KEY,
        [property_id] INT NOT NULL,
        [client_id] INT NOT NULL,
        [realtor_id] INT NOT NULL,
        [status] NVARCHAR(20) DEFAULT 'Active',
        [reservation_date] DATETIME DEFAULT GETDATE(),
        [expiry_date] DATETIME NOT NULL,
        
        -- Внешние ключи для связи с другими таблицами
        CONSTRAINT FK_Reservations_Property FOREIGN KEY (property_id) REFERENCES Properties(property_id),
        CONSTRAINT FK_Reservations_Client FOREIGN KEY (client_id) REFERENCES Clients(client_id),
        CONSTRAINT FK_Reservations_Realtor FOREIGN KEY (realtor_id) REFERENCES Realtors(realtor_id)
    );
    
    -- Создаем индексы для улучшения производительности
    CREATE INDEX IX_PropertyReservations_PropertyId ON PropertyReservations(property_id);
    CREATE INDEX IX_PropertyReservations_ClientId ON PropertyReservations(client_id);
    CREATE INDEX IX_PropertyReservations_RealtorId ON PropertyReservations(realtor_id);
    CREATE INDEX IX_PropertyReservations_Status ON PropertyReservations(status);
    
    PRINT 'Таблица PropertyReservations успешно создана!';
END
ELSE
BEGIN
    PRINT 'Таблица PropertyReservations уже существует.';
END
GO

