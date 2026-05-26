-- Настройка пользователей базы данных с ролями для MSSQL
-- ВАЖНО: Выполните этот скрипт после создания ролей и процедур
-- Замените 'your_app_user' и 'your_password' на реальные значения

--USE [Kourse_project_BD_vav];
--GO

-- =============================================
-- СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ ПРИЛОЖЕНИЯ
-- =============================================

-- Создать логин на уровне сервера (если еще не создан)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'app_login')
BEGIN
    CREATE LOGIN app_login WITH PASSWORD = 'your_secure_password_here';
END
GO

-- Создать пользователя в базе данных
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'postgres')
BEGIN
    CREATE USER postgres FOR LOGIN postgres;
END
GO

-- Назначить роль администратора пользователю приложения
-- ВАЖНО: В продакшене используйте более ограниченные роли в зависимости от контекста
ALTER ROLE db_admin_role ADD MEMBER postgres;
GO

-- Дать базовые права на схему
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO postgres;
GO

-- =============================================
-- АЛЬТЕРНАТИВНЫЙ ВАРИАНТ: РАЗДЕЛЕНИЕ ПО РОЛЯМ
-- =============================================

-- Если нужно разделить доступ по ролям, создайте отдельных пользователей:

-- Пользователь для администратора
-- IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'admin_login')
-- BEGIN
--     CREATE LOGIN admin_login WITH PASSWORD = 'admin_password';
-- END
-- GO
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'admin_user')
-- BEGIN
--     CREATE USER admin_user FOR LOGIN admin_login;
-- END
-- GO
-- ALTER ROLE db_admin_role ADD MEMBER admin_user;
-- GO

-- Пользователь для риэлторов
-- IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'realtor_login')
-- BEGIN
--     CREATE LOGIN realtor_login WITH PASSWORD = 'realtor_password';
-- END
-- GO
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'realtor_user')
-- BEGIN
--     CREATE USER realtor_user FOR LOGIN realtor_login;
-- END
-- GO
-- ALTER ROLE db_realtor_role ADD MEMBER realtor_user;
-- GO

-- Пользователь для клиентов
-- IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'client_login')
-- BEGIN
--     CREATE LOGIN client_login WITH PASSWORD = 'client_password';
-- END
-- GO
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'client_user')
-- BEGIN
--     CREATE USER client_user FOR LOGIN client_login;
-- END
-- GO
-- ALTER ROLE db_client_role ADD MEMBER client_user;
-- GO

PRINT 'Пользователи базы данных настроены';
GO

