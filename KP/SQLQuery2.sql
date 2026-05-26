
create database RealEstate_Main;

-- Таблица пользователей
CREATE TABLE [Users] (
    [user_id] INT IDENTITY(1,1) PRIMARY KEY,
    [username] NVARCHAR(50) UNIQUE NOT NULL,
    [password_hash] NVARCHAR(255) NOT NULL,
    [email] NVARCHAR(100) UNIQUE NOT NULL,
    [full_name] NVARCHAR(100) NOT NULL,
    [role] NVARCHAR(20) NOT NULL DEFAULT 'Client',
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [client_id] INT NULL,
    [realtor_id] INT NULL
);

-- Добавляем связь с Clients
ALTER TABLE [Clients] 
ADD [user_id] INT NULL;

ALTER TABLE [Clients]
ADD CONSTRAINT [FK_Clients_Users] 
FOREIGN KEY ([user_id]) REFERENCES [Users]([user_id]);

-- Добавляем связь с Realtors
ALTER TABLE [Realtors] 
ADD [user_id] INT NULL;

ALTER TABLE [Realtors]
ADD CONSTRAINT [FK_Realtors_Users] 
FOREIGN KEY ([user_id]) REFERENCES [Users]([user_id]);

-- Индексы
CREATE INDEX [IX_Users_Username] ON [Users]([username]);
CREATE INDEX [IX_Users_Email] ON [Users]([email]);
CREATE INDEX [IX_Clients_User] ON [Clients]([user_id]);
CREATE INDEX [IX_Realtors_User] ON [Realtors]([user_id]);








-- ==================== ОСНОВНЫЕ ТАБЛИЦЫ (уже есть) ====================
-- Clients, Realtors, Properties, Deals, Contracts

-- ==================== ПОЛЬЗОВАТЕЛИ ====================
CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'Client',
    created_at DATETIME2 DEFAULT GETDATE(),
    client_id INT NULL,
    realtor_id INT NULL
);

-- Связываем с существующими таблицами
ALTER TABLE Clients ADD user_id INT NULL;
ALTER TABLE Realtors ADD user_id INT NULL;

-- ==================== ДЛЯ АНАЛИТИКИ ====================
-- Таблица активности
CREATE TABLE UserActivities (
    activity_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL,
    created_at DATETIME2 DEFAULT GETDATE()
);

-- Таблица резервирования
CREATE TABLE PropertyReservations (
    reservation_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    client_id INT NOT NULL,
    realtor_id INT NULL,
    reservation_date DATETIME2 DEFAULT GETDATE(),
    expiry_date DATETIME2 NOT NULL,
    status VARCHAR(20) DEFAULT 'Active',
    notes TEXT NULL
);








USE [kursovoy_project_VAV]
GO

-- 1. Таблица Users
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE [dbo].[Users] (
        [user_id] INT IDENTITY(1,1) PRIMARY KEY,
        [username] NVARCHAR(50) UNIQUE NOT NULL,
        [password_hash] NVARCHAR(255) NOT NULL,
        [email] NVARCHAR(100) UNIQUE NOT NULL,
        [full_name] NVARCHAR(100) NOT NULL,
        [role] NVARCHAR(20) NOT NULL DEFAULT 'Client',
        [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [client_id] INT NULL,
        [realtor_id] INT NULL
    );
    
    CREATE INDEX [IX_Users_Username] ON [Users]([username]);
    CREATE INDEX [IX_Users_Email] ON [Users]([email]);
    
    PRINT '✅ Таблица Users создана';
END
ELSE
BEGIN
    PRINT 'ℹ️ Таблица Users уже существует';
END
GO

-- 2. Добавляем user_id в Clients
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Clients')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Clients') AND name = 'user_id')
    BEGIN
        ALTER TABLE [dbo].[Clients] ADD [user_id] INT NULL;
        CREATE INDEX [IX_Clients_UserId] ON [dbo].[Clients]([user_id]);
        PRINT '✅ Колонка user_id добавлена в Clients';
    END
    ELSE
    BEGIN
        PRINT 'ℹ️ Колонка user_id уже есть в Clients';
    END
END
ELSE
BEGIN
    PRINT '⚠️ Таблица Clients не существует';
END
GO

-- 3. Добавляем user_id в Realtors
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Realtors')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Realtors') AND name = 'user_id')
    BEGIN
        ALTER TABLE [dbo].[Realtors] ADD [user_id] INT NULL;
        CREATE INDEX [IX_Realtors_UserId] ON [dbo].[Realtors]([user_id]);
        PRINT '✅ Колонка user_id добавлена в Realtors';
    END
    ELSE
    BEGIN
        PRINT 'ℹ️ Колонка user_id уже есть в Realtors';
    END
END
ELSE
BEGIN
    PRINT '⚠️ Таблица Realtors не существует';
END
GO

-- 4. Таблица UserActivities
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserActivities')
BEGIN
    CREATE TABLE [dbo].[UserActivities] (
        [activity_id] INT IDENTITY(1,1) PRIMARY KEY,
        [user_id] INT NOT NULL,
        [activity_type] NVARCHAR(50) NOT NULL,
        [description] NVARCHAR(255) NULL,
        [created_at] DATETIME2 DEFAULT GETDATE()
    );
    
    CREATE INDEX [IX_UserActivities_UserId] ON [dbo].[UserActivities]([user_id]);
    PRINT '✅ Таблица UserActivities создана';
END
ELSE
BEGIN
    PRINT 'ℹ️ Таблица UserActivities уже существует';
END
GO

-- 5. Таблица PropertyReservations
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PropertyReservations')
BEGIN
    CREATE TABLE [dbo].[PropertyReservations] (
        [reservation_id] INT IDENTITY(1,1) PRIMARY KEY,
        [property_id] INT NOT NULL,
        [client_id] INT NOT NULL,
        [realtor_id] INT NULL,
        [reservation_date] DATETIME2 DEFAULT GETDATE(),
        [expiry_date] DATETIME2 NOT NULL,
        [status] NVARCHAR(20) DEFAULT 'Active',
        [notes] TEXT NULL
    );
    
    CREATE INDEX [IX_PropertyReservations_PropertyId] ON [dbo].[PropertyReservations]([property_id]);
    CREATE INDEX [IX_PropertyReservations_ClientId] ON [dbo].[PropertyReservations]([client_id]);
    PRINT '✅ Таблица PropertyReservations создана';
END
ELSE
BEGIN
    PRINT 'ℹ️ Таблица PropertyReservations уже существует';
END
GO

-- 6. Создаем тестового администратора
IF NOT EXISTS (SELECT * FROM [dbo].[Users] WHERE [username] = 'admin')
BEGIN
    -- Пароль 'admin123!' захешированный через SHA256 -> base64
    DECLARE @password_hash NVARCHAR(255) = 'hTfqNvB6ZKA24C3c8E8qJ0JBXb5D4M+uzkXw4Xp5h3A=';
    
    INSERT INTO [dbo].[Users] ([username], [password_hash], [email], [full_name], [role], [created_at])
    VALUES ('admin', @password_hash, 'admin@example.com', 'Администратор системы', 'Admin', GETDATE());
    
    PRINT '✅ Администратор создан';
    PRINT '   Логин: admin';
    PRINT '   Пароль: admin123!';
END
ELSE
BEGIN
    PRINT 'ℹ️ Администратор уже существует';
END
GO

-- 7. Создаем тестового риэлтора
IF NOT EXISTS (SELECT * FROM [dbo].[Users] WHERE [username] = 'realtor')
BEGIN
    DECLARE @realtor_hash NVARCHAR(255) = 'hTfqNvB6ZKA24C3c8E8qJ0JBXb5D4M+uzkXw4Xp5h3A='; -- тот же пароль
    
    INSERT INTO [dbo].[Users] ([username], [password_hash], [email], [full_name], [role], [created_at])
    VALUES ('realtor', @realtor_hash, 'realtor@example.com', 'Иван Риэлторов', 'Realtor', GETDATE());
    
    PRINT '✅ Риэлтор создан';
    PRINT '   Логин: realtor';
    PRINT '   Пароль: admin123!';
END
ELSE
BEGIN
    PRINT 'ℹ️ Риэлтор уже существует';
END
GO

-- 8. Создаем тестового клиента
IF NOT EXISTS (SELECT * FROM [dbo].[Users] WHERE [username] = 'client')
BEGIN
    DECLARE @client_hash NVARCHAR(255) = 'hTfqNvB6ZKA24C3c8E8qJ0JBXb5D4M+uzkXw4Xp5h3A='; -- тот же пароль
    
    INSERT INTO [dbo].[Users] ([username], [password_hash], [email], [full_name], [role], [created_at])
    VALUES ('client', @client_hash, 'client@example.com', 'Петр Клиентов', 'Client', GETDATE());
    
    PRINT '✅ Клиент создан';
    PRINT '   Логин: client';
    PRINT '   Пароль: admin123!';
END
ELSE
BEGIN
    PRINT 'ℹ️ Клиент уже существует';
END
GO

PRINT '=========================================';
PRINT 'БАЗА ДАННЫХ ГОТОВА К РАБОТЕ!';
PRINT '=========================================';
PRINT 'Тестовые пользователи:';
PRINT '1. admin / admin123! (Администратор)';
PRINT '2. realtor / admin123! (Риэлтор)';
PRINT '3. client / admin123! (Клиент)';
PRINT '=========================================';




-- Обновляем пароли на правильный хэш
-- Обновляем пароли на правильный хэш 'admin123!'
UPDATE [Users] 
SET [password_hash] = 'hTfqNvB6ZKA24C3c8E8qJ0JBXb5D4M+uzkXw4Xp5h3A='
WHERE [username] IN ('admin', 'realtor', 'client');

-- Проверяем
SELECT username, password_hash FROM Users;

-- Посмотрите что в таблице Users
SELECT username, password_hash, role FROM Users;