-- Создание ролей в MSSQL
-- Выполните этот скрипт от имени администратора БД

--USE [master];
--GO

-- Создаем роли, если их нет
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_admin_role' AND type = 'R')
BEGIN
    CREATE ROLE db_admin_role;
    PRINT 'Роль db_admin_role создана';
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_realtor_role' AND type = 'R')
BEGIN
    CREATE ROLE db_realtor_role;
    PRINT 'Роль db_realtor_role создана';
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_client_role' AND type = 'R')
BEGIN
    CREATE ROLE db_client_role;
    PRINT 'Роль db_client_role создана';
END
GO

-- Отключаем прямое чтение таблиц для всех ролей
DENY SELECT ON SCHEMA::dbo TO db_admin_role;
DENY SELECT ON SCHEMA::dbo TO db_realtor_role;
DENY SELECT ON SCHEMA::dbo TO db_client_role;
GO

-- Разрешаем выполнение процедур (будет настроено после создания процедур)
-- GRANT EXECUTE ON SCHEMA::dbo TO db_admin_role;
-- GRANT EXECUTE ON SCHEMA::dbo TO db_realtor_role;
-- GRANT EXECUTE ON SCHEMA::dbo TO db_client_role;
GO

PRINT 'Роли созданы. Прямой доступ к таблицам запрещен.';
GO

