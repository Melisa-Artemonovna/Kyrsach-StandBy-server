-- Переключаемся на master базу
USE master;
GO

-- Создаем логин с паролем
CREATE LOGIN postgres WITH PASSWORD = '1234';
GO

-- Создаем пользователя в конкретной базе
USE RealEstate_Main ; -- Замените на имя вашей БД
GO

CREATE USER postgres FOR LOGIN postgres;
GO

-- Назначаем права (примеры)
-- Роль db_owner - полный доступ
ALTER ROLE db_owner ADD MEMBER postgres;
GO

-- Или более ограниченные права:
-- ALTER ROLE db_datareader ADD MEMBER app_user;  -- только чтение
-- ALTER ROLE db_datawriter ADD MEMBER app_user;  -- запись
-- ALTER ROLE db_ddladmin ADD MEMBER app_user;    -- создание/изменение таблиц