

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ USERS
-- =============================================

-- Получить пользователя по ID
CREATE OR ALTER PROCEDURE sp_GetUserById
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetUserById для user_id = ' + CAST(@user_id AS VARCHAR(10));
        
        SELECT * FROM Users WHERE user_id = @user_id;
        
        PRINT 'Процедура sp_GetUserById успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetUserById: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetUserById
-- EXEC sp_GetUserById @user_id = 1;
-- SELECT 'Вызов процедуры sp_GetUserById завершен' AS Status;

-- Получить пользователя по username
CREATE OR ALTER PROCEDURE sp_GetUserByUsername
    @username NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetUserByUsername для username = ' + @username;
        
        SELECT * FROM Users WHERE username = @username;
        
        PRINT 'Процедура sp_GetUserByUsername успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetUserByUsername: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetUserByUsername
-- EXEC sp_GetUserByUsername @username = 'admin';
-- SELECT 'Вызов процедуры sp_GetUserByUsername завершен' AS Status;

-- Получить всех пользователей (только для Admin)
CREATE OR ALTER PROCEDURE sp_GetAllUsers
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetAllUsers';
        
        SELECT * FROM Users ORDER BY user_id;
        
        PRINT 'Процедура sp_GetAllUsers успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetAllUsers: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetAllUsers
-- EXEC sp_GetAllUsers;
-- SELECT 'Вызов процедуры sp_GetAllUsers завершен' AS Status;

-- Создать пользователя
CREATE OR ALTER PROCEDURE sp_CreateUser
    @username NVARCHAR(50),
    @password_hash NVARCHAR(255),
    @email NVARCHAR(100),
    @full_name NVARCHAR(100),
    @role NVARCHAR(20),
    @created_at DATETIME,
    @user_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_CreateUser для пользователя: ' + @username;
        
        INSERT INTO Users (username, password_hash, email, full_name, role, created_at)
        VALUES (@username, @password_hash, @email, @full_name, @role, @created_at);
        
        SET @user_id = SCOPE_IDENTITY();
        
        PRINT 'Процедура sp_CreateUser успешно выполнена. Создан пользователь с ID: ' + 
              CAST(@user_id AS VARCHAR(10));
        
        -- Возвращаем созданного пользователя
        SELECT * FROM Users WHERE user_id = @user_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_CreateUser: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_CreateUser
/*
DECLARE @new_user_id INT;
EXEC sp_CreateUser 
    @username = 'testuser',
    @password_hash = 'hashedpassword123',
    @email = 'test@example.com',
    @full_name = 'Test User',
    @role = 'Client',
    @created_at = GETDATE(),
    @user_id = @new_user_id OUTPUT;
PRINT 'Создан новый пользователь с ID: ' + CAST(@new_user_id AS VARCHAR(10));
*/

-- Обновить пользователя
CREATE OR ALTER PROCEDURE sp_UpdateUser
    @user_id INT,
    @username NVARCHAR(50),
    @email NVARCHAR(100),
    @full_name NVARCHAR(100),
    @role NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_UpdateUser для user_id = ' + CAST(@user_id AS VARCHAR(10));
        
        UPDATE Users 
        SET username = @username, email = @email, full_name = @full_name, role = @role
        WHERE user_id = @user_id;
        
        PRINT 'Процедура sp_UpdateUser успешно выполнена. Обновлено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Возвращаем обновленного пользователя
        SELECT * FROM Users WHERE user_id = @user_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_UpdateUser: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_UpdateUser
/*
EXEC sp_UpdateUser 
    @user_id = 1,
    @username = 'updateduser',
    @email = 'updated@example.com',
    @full_name = 'Updated Name',
    @role = 'Admin';
SELECT 'Процедура sp_UpdateUser выполнена' AS Status;
*/

-- Удалить пользователя
CREATE OR ALTER PROCEDURE sp_DeleteUser
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_DeleteUser для user_id = ' + CAST(@user_id AS VARCHAR(10));
        
        -- Сохраняем информацию о пользователе перед удалением
        DECLARE @username NVARCHAR(50);
        SELECT @username = username FROM Users WHERE user_id = @user_id;
        
        BEGIN TRANSACTION;
        
        -- Проверяем, есть ли связанные записи
        DECLARE @client_id INT, @realtor_id INT;
        SELECT @client_id = client_id, @realtor_id = realtor_id 
        FROM Users WHERE user_id = @user_id;
        
        -- Если есть связанный клиент, удаляем его
        IF @client_id IS NOT NULL
        BEGIN
            PRINT 'Удаление связанных записей клиента с ID: ' + CAST(@client_id AS VARCHAR(10));
            DELETE FROM PropertyReservations WHERE client_id = @client_id;
            DELETE FROM Deals WHERE client_id = @client_id;
            DELETE FROM Clients WHERE client_id = @client_id;
        END
        
        -- Если есть связанный риэлтор, удаляем его
        IF @realtor_id IS NOT NULL
        BEGIN
            PRINT 'Удаление связанных записей риэлтора с ID: ' + CAST(@realtor_id AS VARCHAR(10));
            DELETE FROM PropertyReservations WHERE realtor_id = @realtor_id;
            DELETE FROM Deals WHERE realtor_id = @realtor_id;
            DELETE FROM Properties WHERE realtor_id = @realtor_id;
            DELETE FROM Realtors WHERE realtor_id = @realtor_id;
        END
        
        -- Удаляем пользователя
        DELETE FROM Users WHERE user_id = @user_id;
        
        COMMIT TRANSACTION;
        
        PRINT 'Процедура sp_DeleteUser успешно выполнена. Удален пользователь: ' + @username;
        
        -- Выводим список оставшихся пользователей
        SELECT 'Удален пользователь: ' + @username + ' (ID: ' + CAST(@user_id AS VARCHAR(10)) + ')' AS DeletionInfo;
        SELECT COUNT(*) AS RemainingUsers FROM Users;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_DeleteUser: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_DeleteUser (ОСТОРОЖНО: удаляет данные!)
-- EXEC sp_DeleteUser @user_id = 10;
-- SELECT 'Процедура sp_DeleteUser выполнена' AS Status;

-- Получить пользователей по роли
CREATE OR ALTER PROCEDURE sp_GetUsersByRole
    @role NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetUsersByRole для роли: ' + @role;
        
        SELECT * FROM Users WHERE role = @role ORDER BY user_id;
        
        PRINT 'Процедура sp_GetUsersByRole успешно выполнена. Найдено пользователей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10)) + ' с ролью: ' + @role;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetUsersByRole: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetUsersByRole
-- EXEC sp_GetUsersByRole @role = 'Client';
-- SELECT 'Вызов процедуры sp_GetUsersByRole завершен' AS Status;

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ CLIENTS
-- =============================================

-- Получить всех клиентов
CREATE OR ALTER PROCEDURE sp_GetAllClients
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetAllClients';
        
        SELECT * FROM Clients ORDER BY client_id;
        
        PRINT 'Процедура sp_GetAllClients успешно выполнена. Найдено клиентов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetAllClients: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetAllClients
-- EXEC sp_GetAllClients;
-- SELECT 'Вызов процедуры sp_GetAllClients завершен' AS Status;

-- Получить клиента по ID
CREATE OR ALTER PROCEDURE sp_GetClientById
    @client_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetClientById для client_id = ' + CAST(@client_id AS VARCHAR(10));
        
        SELECT * FROM Clients WHERE client_id = @client_id;
        
        PRINT 'Процедура sp_GetClientById успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetClientById: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetClientById
-- EXEC sp_GetClientById @client_id = 1;
-- SELECT 'Вызов процедуры sp_GetClientById завершен' AS Status;

-- Получить клиента по user_id
CREATE OR ALTER PROCEDURE sp_GetClientByUserId
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetClientByUserId для user_id = ' + CAST(@user_id AS VARCHAR(10));
        
        SELECT * FROM Clients WHERE user_id = @user_id;
        
        PRINT 'Процедура sp_GetClientByUserId успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetClientByUserId: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetClientByUserId
-- EXEC sp_GetClientByUserId @user_id = 1;
-- SELECT 'Вызов процедуры sp_GetClientByUserId завершен' AS Status;

-- Получить клиента по email
CREATE OR ALTER PROCEDURE sp_GetClientByEmail
    @email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetClientByEmail для email = ' + @email;
        
        SELECT * FROM Clients WHERE email = @email;
        
        PRINT 'Процедура sp_GetClientByEmail успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetClientByEmail: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetClientByEmail
-- EXEC sp_GetClientByEmail @email = 'client@example.com';
-- SELECT 'Вызов процедуры sp_GetClientByEmail завершен' AS Status;

-- Создать клиента
CREATE OR ALTER PROCEDURE sp_CreateClient
    @full_name NVARCHAR(100),
    @phone_number NVARCHAR(20),
    @email NVARCHAR(100),
    @passport_number NVARCHAR(20),
    @user_id INT,
    @client_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_CreateClient для клиента: ' + @full_name;
        
        INSERT INTO Clients (full_name, phone_number, email, passport_number, registration_date, user_id)
        VALUES (@full_name, @phone_number, @email, @passport_number, GETDATE(), @user_id);
        
        SET @client_id = SCOPE_IDENTITY();
        
        PRINT 'Процедура sp_CreateClient успешно выполнена. Создан клиент с ID: ' + 
              CAST(@client_id AS VARCHAR(10));
        
        -- Возвращаем созданного клиента
        SELECT * FROM Clients WHERE client_id = @client_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_CreateClient: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_CreateClient
/*
DECLARE @new_client_id INT;
EXEC sp_CreateClient 
    @full_name = 'Новый Клиент',
    @phone_number = '+79990001122',
    @email = 'newclient@example.com',
    @passport_number = '1234567890',
    @user_id = 1,
    @client_id = @new_client_id OUTPUT;
PRINT 'Создан новый клиент с ID: ' + CAST(@new_client_id AS VARCHAR(10));
*/

-- Обновить клиента
CREATE OR ALTER PROCEDURE sp_UpdateClient
    @client_id INT,
    @full_name NVARCHAR(100),
    @phone_number NVARCHAR(20),
    @email NVARCHAR(100),
    @passport_number NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_UpdateClient для client_id = ' + CAST(@client_id AS VARCHAR(10));
        
        UPDATE Clients 
        SET full_name = @full_name, phone_number = @phone_number, email = @email, passport_number = @passport_number
        WHERE client_id = @client_id;
        
        PRINT 'Процедура sp_UpdateClient успешно выполнена. Обновлено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Возвращаем обновленного клиента
        SELECT * FROM Clients WHERE client_id = @client_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_UpdateClient: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_UpdateClient
/*
EXEC sp_UpdateClient 
    @client_id = 1,
    @full_name = 'Обновленное Имя',
    @phone_number = '+79998887766',
    @email = 'updated@example.com',
    @passport_number = '0987654321';
SELECT 'Процедура sp_UpdateClient выполнена' AS Status;
*/

-- Удалить клиента
CREATE OR ALTER PROCEDURE sp_DeleteClient
    @client_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_DeleteClient для client_id = ' + CAST(@client_id AS VARCHAR(10));
        
        -- Сохраняем информацию о клиенте перед удалением
        DECLARE @client_name NVARCHAR(100);
        SELECT @client_name = full_name FROM Clients WHERE client_id = @client_id;
        
        BEGIN TRANSACTION;
        
        -- Удаляем все резервации для этого клиента
        DELETE FROM PropertyReservations WHERE client_id = @client_id;
        
        -- Deals удалятся автоматически благодаря CASCADE, но можно удалить явно для безопасности
        DELETE FROM Deals WHERE client_id = @client_id;
        
        -- Удаляем самого клиента
        DELETE FROM Clients WHERE client_id = @client_id;
        
        COMMIT TRANSACTION;
        
        PRINT 'Процедура sp_DeleteClient успешно выполнена. Удален клиент: ' + @client_name;
        
        -- Выводим информацию об удалении
        SELECT 'Удален клиент: ' + @client_name + ' (ID: ' + CAST(@client_id AS VARCHAR(10)) + ')' AS DeletionInfo;
        SELECT COUNT(*) AS RemainingClients FROM Clients;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_DeleteClient: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_DeleteClient (ОСТОРОЖНО: удаляет данные!)
-- EXEC sp_DeleteClient @client_id = 5;
-- SELECT 'Процедура sp_DeleteClient выполнена' AS Status;

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ REALTORS
-- =============================================

-- Получить всех риэлторов
CREATE OR ALTER PROCEDURE sp_GetAllRealtors
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetAllRealtors';
        
        SELECT * FROM Realtors ORDER BY realtor_id;
        
        PRINT 'Процедура sp_GetAllRealtors успешно выполнена. Найдено риэлторов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetAllRealtors: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetAllRealtors
-- EXEC sp_GetAllRealtors;
-- SELECT 'Вызов процедуры sp_GetAllRealtors завершен' AS Status;

-- Получить риэлтора по ID
CREATE OR ALTER PROCEDURE sp_GetRealtorById
    @realtor_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetRealtorById для realtor_id = ' + CAST(@realtor_id AS VARCHAR(10));
        
        SELECT * FROM Realtors WHERE realtor_id = @realtor_id;
        
        PRINT 'Процедура sp_GetRealtorById успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetRealtorById: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetRealtorById
-- EXEC sp_GetRealtorById @realtor_id = 1;
-- SELECT 'Вызов процедуры sp_GetRealtorById завершен' AS Status;

-- Получить риэлтора по user_id
CREATE OR ALTER PROCEDURE sp_GetRealtorByUserId
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetRealtorByUserId для user_id = ' + CAST(@user_id AS VARCHAR(10));
        
        SELECT * FROM Realtors WHERE user_id = @user_id;
        
        PRINT 'Процедура sp_GetRealtorByUserId успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetRealtorByUserId: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetRealtorByUserId
-- EXEC sp_GetRealtorByUserId @user_id = 1;
-- SELECT 'Вызов процедуры sp_GetRealtorByUserId завершен' AS Status;

-- Получить риэлтора по email
CREATE OR ALTER PROCEDURE sp_GetRealtorByEmail
    @email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetRealtorByEmail для email = ' + @email;
        
        SELECT * FROM Realtors WHERE email = @email;
        
        PRINT 'Процедура sp_GetRealtorByEmail успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetRealtorByEmail: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetRealtorByEmail
-- EXEC sp_GetRealtorByEmail @email = 'realtor@example.com';
-- SELECT 'Вызов процедуры sp_GetRealtorByEmail завершен' AS Status;

-- Создать риэлтора
CREATE OR ALTER PROCEDURE sp_CreateRealtor
    @full_name NVARCHAR(100),
    @phone_number NVARCHAR(20),
    @email NVARCHAR(100),
    @user_id INT = NULL,
    @hire_date DATETIME = NULL,
    @commission_rate DECIMAL(5,2) = NULL,
    @realtor_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_CreateRealtor для риэлтора: ' + @full_name;
        
        INSERT INTO Realtors (full_name, phone_number, email, user_id, hire_date, commission_rate)
        VALUES (
            @full_name, 
            @phone_number, 
            @email, 
            @user_id,
            ISNULL(@hire_date, GETDATE()),
            ISNULL(@commission_rate, 5.0)
        );
        
        SET @realtor_id = SCOPE_IDENTITY();
        
        PRINT 'Процедура sp_CreateRealtor успешно выполнена. Создан риэлтор с ID: ' + 
              CAST(@realtor_id AS VARCHAR(10));
        
        -- Возвращаем созданного риэлтора
        SELECT * FROM Realtors WHERE realtor_id = @realtor_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_CreateRealtor: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_CreateRealtor
/*
DECLARE @new_realtor_id INT;
EXEC sp_CreateRealtor 
    @full_name = 'Новый Риэлтор',
    @phone_number = '+79991112233',
    @email = 'newrealtor@example.com',
    @user_id = 1,
    @hire_date = GETDATE(),
    @commission_rate = 6.5,
    @realtor_id = @new_realtor_id OUTPUT;
PRINT 'Создан новый риэлтор с ID: ' + CAST(@new_realtor_id AS VARCHAR(10));
*/

-- Обновить риэлтора
CREATE OR ALTER PROCEDURE sp_UpdateRealtor
    @realtor_id INT,
    @full_name NVARCHAR(100),
    @phone_number NVARCHAR(20),
    @email NVARCHAR(100),
    @hire_date DATETIME = NULL,
    @commission_rate DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_UpdateRealtor для realtor_id = ' + CAST(@realtor_id AS VARCHAR(10));
        
        UPDATE Realtors 
        SET full_name = @full_name, 
            phone_number = @phone_number, 
            email = @email,
            hire_date = ISNULL(@hire_date, hire_date),
            commission_rate = ISNULL(@commission_rate, commission_rate)
        WHERE realtor_id = @realtor_id;
        
        PRINT 'Процедура sp_UpdateRealtor успешно выполнена. Обновлено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Возвращаем обновленного риэлтора
        SELECT * FROM Realtors WHERE realtor_id = @realtor_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_UpdateRealtor: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_UpdateRealtor
/*
EXEC sp_UpdateRealtor 
    @realtor_id = 1,
    @full_name = 'Обновленный Риэлтор',
    @phone_number = '+79992223344',
    @email = 'updatedrealtor@example.com',
    @commission_rate = 7.0;
SELECT 'Процедура sp_UpdateRealtor выполнена' AS Status;
*/

-- Удалить риэлтора
CREATE OR ALTER PROCEDURE sp_DeleteRealtor
    @realtor_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_DeleteRealtor для realtor_id = ' + CAST(@realtor_id AS VARCHAR(10));
        
        -- Сохраняем информацию о риэлторе перед удалением
        DECLARE @realtor_name NVARCHAR(100);
        SELECT @realtor_name = full_name FROM Realtors WHERE realtor_id = @realtor_id;
        
        BEGIN TRANSACTION;
        
        -- Удаляем все резервации для этого риэлтора
        DELETE FROM PropertyReservations WHERE realtor_id = @realtor_id;
        
        -- Удаляем все сделки для этого риэлтора (FK без CASCADE)
        DELETE FROM Deals WHERE realtor_id = @realtor_id;
        
        -- Удаляем все объекты недвижимости для этого риэлтора
        -- Сначала удаляем связанные данные для объектов
        DELETE pr FROM PropertyReservations pr
        INNER JOIN Properties p ON pr.property_id = p.property_id
        WHERE p.realtor_id = @realtor_id;
        
        DELETE d FROM Deals d
        INNER JOIN Properties p ON d.property_id = p.property_id
        WHERE p.realtor_id = @realtor_id;
        
        -- Удаляем сами объекты
        DELETE FROM Properties WHERE realtor_id = @realtor_id;
        
        -- Удаляем самого риэлтора
        DELETE FROM Realtors WHERE realtor_id = @realtor_id;
        
        COMMIT TRANSACTION;
        
        PRINT 'Процедура sp_DeleteRealtor успешно выполнена. Удален риэлтор: ' + @realtor_name;
        
        -- Выводим информацию об удалении
        SELECT 'Удален риэлтор: ' + @realtor_name + ' (ID: ' + CAST(@realtor_id AS VARCHAR(10)) + ')' AS DeletionInfo;
        SELECT COUNT(*) AS RemainingRealtors FROM Realtors;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_DeleteRealtor: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_DeleteRealtor (ОСТОРОЖНО: удаляет данные!)
-- EXEC sp_DeleteRealtor @realtor_id = 3;
-- SELECT 'Процедура sp_DeleteRealtor выполнена' AS Status;

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ PROPERTIES
-- =============================================

-- Получить все объекты недвижимости
CREATE OR ALTER PROCEDURE sp_GetAllProperties
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetAllProperties';
        
        SELECT * FROM Properties ORDER BY property_id;
        
        PRINT 'Процедура sp_GetAllProperties успешно выполнена. Найдено объектов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetAllProperties: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetAllProperties
-- EXEC sp_GetAllProperties;
-- SELECT 'Вызов процедуры sp_GetAllProperties завершен' AS Status;

-- Получить объект по ID
CREATE OR ALTER PROCEDURE sp_GetPropertyById
    @property_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetPropertyById для property_id = ' + CAST(@property_id AS VARCHAR(10));
        
        SELECT * FROM Properties WHERE property_id = @property_id;
        
        PRINT 'Процедура sp_GetPropertyById успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetPropertyById: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetPropertyById
-- EXEC sp_GetPropertyById @property_id = 1;
-- SELECT 'Вызов процедуры sp_GetPropertyById завершен' AS Status;

-- Получить объекты риэлтора
CREATE OR ALTER PROCEDURE sp_GetPropertiesByRealtorId
    @realtor_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetPropertiesByRealtorId для realtor_id = ' + CAST(@realtor_id AS VARCHAR(10));
        
        SELECT * FROM Properties WHERE realtor_id = @realtor_id ORDER BY property_id;
        
        PRINT 'Процедура sp_GetPropertiesByRealtorId успешно выполнена. Найдено объектов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetPropertiesByRealtorId: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetPropertiesByRealtorId
-- EXEC sp_GetPropertiesByRealtorId @realtor_id = 1;
-- SELECT 'Вызов процедуры sp_GetPropertiesByRealtorId завершен' AS Status;

-- Получить доступные объекты
CREATE OR ALTER PROCEDURE sp_GetAvailableProperties
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetAvailableProperties';
        
        SELECT * FROM Properties WHERE is_available = 1 ORDER BY price;
        
        PRINT 'Процедура sp_GetAvailableProperties успешно выполнена. Найдено доступных объектов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetAvailableProperties: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetAvailableProperties
-- EXEC sp_GetAvailableProperties;
-- SELECT 'Вызов процедуры sp_GetAvailableProperties завершен' AS Status;

-- Получить объекты по типу
CREATE OR ALTER PROCEDURE sp_GetPropertiesByType
    @property_type NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetPropertiesByType для типа: ' + @property_type;
        
        SELECT * FROM Properties WHERE property_type = @property_type ORDER BY price;
        
        PRINT 'Процедура sp_GetPropertiesByType успешно выполнена. Найдено объектов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetPropertiesByType: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetPropertiesByType
-- EXEC sp_GetPropertiesByType @property_type = 'Apartment';
-- SELECT 'Вызов процедуры sp_GetPropertiesByType завершен' AS Status;

-- Получить объекты по диапазону цены
CREATE OR ALTER PROCEDURE sp_GetPropertiesByPriceRange
    @min_price DECIMAL(15,2),
    @max_price DECIMAL(15,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetPropertiesByPriceRange для диапазона цен: ' + 
              CAST(@min_price AS VARCHAR(20)) + ' - ' + CAST(@max_price AS VARCHAR(20));
        
        SELECT * FROM Properties 
        WHERE price >= @min_price AND price <= @max_price 
        ORDER BY price;
        
        PRINT 'Процедура sp_GetPropertiesByPriceRange успешно выполнена. Найдено объектов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetPropertiesByPriceRange: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetPropertiesByPriceRange
-- EXEC sp_GetPropertiesByPriceRange @min_price = 100000, @max_price = 500000;
-- SELECT 'Вызов процедуры sp_GetPropertiesByPriceRange завершен' AS Status;

-- Создать объект недвижимости
CREATE OR ALTER PROCEDURE sp_CreateProperty
    @address NVARCHAR(255),
    @property_type NVARCHAR(50),
    @area DECIMAL(10,2),
    @price DECIMAL(15,2),
    @description TEXT,
    @realtor_id INT,
    @is_available BIT,
    @rooms INT,
    @floor INT,
    @total_floors INT,
    @main_image_url NVARCHAR(500),
    @image_urls TEXT,
    @property_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_CreateProperty для объекта по адресу: ' + @address;
        
        INSERT INTO Properties (address, property_type, area, price, description, realtor_id, is_available, rooms, floor, total_floors, main_image_url, image_urls)
        VALUES (@address, @property_type, @area, @price, @description, @realtor_id, @is_available, @rooms, @floor, @total_floors, @main_image_url, @image_urls);
        
        SET @property_id = SCOPE_IDENTITY();
        
        PRINT 'Процедура sp_CreateProperty успешно выполнена. Создан объект с ID: ' + 
              CAST(@property_id AS VARCHAR(10));
        
        -- Возвращаем созданный объект
        SELECT * FROM Properties WHERE property_id = @property_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_CreateProperty: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_CreateProperty
/*
DECLARE @new_property_id INT;
EXEC sp_CreateProperty 
    @address = 'ул. Примерная, д. 123',
    @property_type = 'Apartment',
    @area = 75.5,
    @price = 3500000.00,
    @description = 'Просторная квартира в центре города',
    @realtor_id = 1,
    @is_available = 1,
    @rooms = 3,
    @floor = 5,
    @total_floors = 9,
    @main_image_url = 'https://example.com/image1.jpg',
    @image_urls = 'https://example.com/image2.jpg,https://example.com/image3.jpg',
    @property_id = @new_property_id OUTPUT;
PRINT 'Создан новый объект недвижимости с ID: ' + CAST(@new_property_id AS VARCHAR(10));
*/

-- Обновить объект недвижимости
CREATE OR ALTER PROCEDURE sp_UpdateProperty
    @property_id INT,
    @address NVARCHAR(255),
    @property_type NVARCHAR(50),
    @area DECIMAL(10,2),
    @price DECIMAL(15,2),
    @description TEXT,
    @realtor_id INT,
    @is_available BIT,
    @rooms INT,
    @floor INT,
    @total_floors INT,
    @main_image_url NVARCHAR(500),
    @image_urls TEXT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_UpdateProperty для property_id = ' + CAST(@property_id AS VARCHAR(10));
        
        UPDATE Properties 
        SET address = @address, property_type = @property_type, area = @area, price = @price,
            description = @description, realtor_id = @realtor_id, is_available = @is_available,
            rooms = @rooms, floor = @floor, total_floors = @total_floors,
            main_image_url = @main_image_url, image_urls = @image_urls
        WHERE property_id = @property_id;
        
        PRINT 'Процедура sp_UpdateProperty успешно выполнена. Обновлено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Возвращаем обновленный объект
        SELECT * FROM Properties WHERE property_id = @property_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_UpdateProperty: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_UpdateProperty
/*
EXEC sp_UpdateProperty 
    @property_id = 1,
    @address = 'ул. Обновленная, д. 456',
    @property_type = 'Apartment',
    @area = 80.0,
    @price = 3800000.00,
    @description = 'Обновленное описание квартиры',
    @realtor_id = 1,
    @is_available = 1,
    @rooms = 3,
    @floor = 7,
    @total_floors = 12,
    @main_image_url = 'https://example.com/new_image.jpg',
    @image_urls = 'https://example.com/image1.jpg,https://example.com/image2.jpg';
SELECT 'Процедура sp_UpdateProperty выполнена' AS Status;
*/

-- Изменить статус доступности объекта
CREATE OR ALTER PROCEDURE sp_UpdatePropertyAvailability
    @property_id INT,
    @is_available BIT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_UpdatePropertyAvailability для property_id = ' + 
              CAST(@property_id AS VARCHAR(10)) + ' с is_available = ' + CAST(@is_available AS VARCHAR(5));
        
        UPDATE Properties 
        SET is_available = @is_available
        WHERE property_id = @property_id;
        
        PRINT 'Процедура sp_UpdatePropertyAvailability успешно выполнена. Обновлено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Возвращаем обновленный объект
        SELECT property_id, address, is_available FROM Properties WHERE property_id = @property_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_UpdatePropertyAvailability: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_UpdatePropertyAvailability
-- EXEC sp_UpdatePropertyAvailability @property_id = 1, @is_available = 0;
-- SELECT 'Процедура sp_UpdatePropertyAvailability выполнена' AS Status;

-- Удалить объект недвижимости
CREATE OR ALTER PROCEDURE sp_DeleteProperty
    @property_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_DeleteProperty для property_id = ' + CAST(@property_id AS VARCHAR(10));
        
        -- Сохраняем информацию об объекте перед удалением
        DECLARE @property_address NVARCHAR(255);
        SELECT @property_address = address FROM Properties WHERE property_id = @property_id;
        
        BEGIN TRANSACTION;
        
        -- Удаляем все резервации для этого объекта
        DELETE FROM PropertyReservations WHERE property_id = @property_id;
        
        -- Удаляем все избранное для этого объекта (если таблица существует)
        IF OBJECT_ID('Favorites', 'U') IS NOT NULL
        BEGIN
            DELETE FROM Favorites WHERE property_id = @property_id;
        END
        
        -- Удаляем все сделки для этого объекта (если не удаляются каскадно)
        DELETE FROM Deals WHERE property_id = @property_id;
        
        -- Удаляем сам объект
        DELETE FROM Properties WHERE property_id = @property_id;
        
        COMMIT TRANSACTION;
        
        PRINT 'Процедура sp_DeleteProperty успешно выполнена. Удален объект: ' + @property_address;
        
        -- Выводим информацию об удалении
        SELECT 'Удален объект недвижимости: ' + @property_address + ' (ID: ' + CAST(@property_id AS VARCHAR(10)) + ')' AS DeletionInfo;
        SELECT COUNT(*) AS RemainingProperties FROM Properties;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_DeleteProperty: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_DeleteProperty (ОСТОРОЖНО: удаляет данные!)
-- EXEC sp_DeleteProperty @property_id = 5;
-- SELECT 'Процедура sp_DeleteProperty выполнена' AS Status;

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ DEALS
-- =============================================

-- Получить все сделки
CREATE OR ALTER PROCEDURE sp_GetAllDeals
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetAllDeals';
        
        SELECT * FROM Deals ORDER BY deal_date DESC;
        
        PRINT 'Процедура sp_GetAllDeals успешно выполнена. Найдено сделок: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetAllDeals: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetAllDeals
-- EXEC sp_GetAllDeals;
-- SELECT 'Вызов процедуры sp_GetAllDeals завершен' AS Status;

-- Получить сделку по ID
CREATE OR ALTER PROCEDURE sp_GetDealById
    @deal_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetDealById для deal_id = ' + CAST(@deal_id AS VARCHAR(10));
        
        SELECT * FROM Deals WHERE deal_id = @deal_id;
        
        PRINT 'Процедура sp_GetDealById успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetDealById: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetDealById
-- EXEC sp_GetDealById @deal_id = 1;
-- SELECT 'Вызов процедуры sp_GetDealById завершен' AS Status;

-- Получить сделки риэлтора
CREATE OR ALTER PROCEDURE sp_GetDealsByRealtorId
    @realtor_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetDealsByRealtorId для realtor_id = ' + CAST(@realtor_id AS VARCHAR(10));
        
        SELECT * FROM Deals WHERE realtor_id = @realtor_id ORDER BY deal_date DESC;
        
        PRINT 'Процедура sp_GetDealsByRealtorId успешно выполнена. Найдено сделок: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetDealsByRealtorId: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetDealsByRealtorId
-- EXEC sp_GetDealsByRealtorId @realtor_id = 1;
-- SELECT 'Вызов процедуры sp_GetDealsByRealtorId завершен' AS Status;

-- Получить сделки клиента
CREATE OR ALTER PROCEDURE sp_GetDealsByClientId
    @client_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetDealsByClientId для client_id = ' + CAST(@client_id AS VARCHAR(10));
        
        SELECT * FROM Deals WHERE client_id = @client_id ORDER BY deal_date DESC;
        
        PRINT 'Процедура sp_GetDealsByClientId успешно выполнена. Найдено сделок: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetDealsByClientId: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetDealsByClientId
-- EXEC sp_GetDealsByClientId @client_id = 1;
-- SELECT 'Вызов процедуры sp_GetDealsByClientId завершен' AS Status;

-- Получить сделки по дате
CREATE OR ALTER PROCEDURE sp_GetDealsByDateRange
    @start_date DATETIME,
    @end_date DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetDealsByDateRange для периода: ' + 
              CONVERT(VARCHAR, @start_date, 120) + ' - ' + CONVERT(VARCHAR, @end_date, 120);
        
        SELECT * FROM Deals 
        WHERE deal_date >= @start_date AND deal_date <= @end_date 
        ORDER BY deal_date DESC;
        
        PRINT 'Процедура sp_GetDealsByDateRange успешно выполнена. Найдено сделок: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetDealsByDateRange: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetDealsByDateRange
/*
EXEC sp_GetDealsByDateRange 
    @start_date = '2024-01-01',
    @end_date = '2024-12-31';
SELECT 'Вызов процедуры sp_GetDealsByDateRange завершен' AS Status;
*/

-- Получить статистику сделок риэлтора за период
CREATE OR ALTER PROCEDURE sp_GetRealtorDealStats
    @realtor_id INT,
    @start_date DATETIME,
    @end_date DATETIME,
    @deal_count INT OUTPUT,
    @deal_amount DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetRealtorDealStats для realtor_id = ' + CAST(@realtor_id AS VARCHAR(10));
        
        SELECT @deal_count = COUNT(*), @deal_amount = ISNULL(SUM(deal_price), 0)
        FROM Deals 
        WHERE realtor_id = @realtor_id AND deal_date >= @start_date AND deal_date <= @end_date;
        
        PRINT 'Процедура sp_GetRealtorDealStats успешно выполнена. Статистика для риэлтора ' + 
              CAST(@realtor_id AS VARCHAR(10)) + ': ' +
              CAST(@deal_count AS VARCHAR(10)) + ' сделок на сумму ' + 
              CAST(@deal_amount AS VARCHAR(20));
        
        -- Возвращаем статистику
        SELECT 
            @realtor_id AS realtor_id,
            @deal_count AS deal_count,
            @deal_amount AS deal_amount,
            @start_date AS start_date,
            @end_date AS end_date;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetRealtorDealStats: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetRealtorDealStats
/*
DECLARE @deal_count INT, @deal_amount DECIMAL(18,2);
EXEC sp_GetRealtorDealStats 
    @realtor_id = 1,
    @start_date = '2024-01-01',
    @end_date = '2024-12-31',
    @deal_count = @deal_count OUTPUT,
    @deal_amount = @deal_amount OUTPUT;
PRINT 'Статистика: ' + CAST(@deal_count AS VARCHAR(10)) + ' сделок на сумму ' + CAST(@deal_amount AS VARCHAR(20));
*/

-- Создать сделку
CREATE OR ALTER PROCEDURE sp_CreateDeal
    @property_id INT,
    @client_id INT,
    @realtor_id INT,
    @deal_type NVARCHAR(50),
    @deal_price DECIMAL(15,2),
    @deal_date DATETIME,
    @deal_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_CreateDeal для сделки типа: ' + @deal_type;
        
        INSERT INTO Deals (property_id, client_id, realtor_id, deal_type, deal_price, deal_date)
        VALUES (@property_id, @client_id, @realtor_id, @deal_type, @deal_price, @deal_date);
        
        SET @deal_id = SCOPE_IDENTITY();
        
        PRINT 'Процедура sp_CreateDeal успешно выполнена. Создана сделка с ID: ' + 
              CAST(@deal_id AS VARCHAR(10));
        
        -- Возвращаем созданную сделку
        SELECT * FROM Deals WHERE deal_id = @deal_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_CreateDeal: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_CreateDeal
/*
DECLARE @new_deal_id INT;
EXEC sp_CreateDeal 
    @property_id = 1,
    @client_id = 1,
    @realtor_id = 1,
    @deal_type = 'Sale',
    @deal_price = 3500000.00,
    @deal_date = GETDATE(),
    @deal_id = @new_deal_id OUTPUT;
PRINT 'Создана новая сделка с ID: ' + CAST(@new_deal_id AS VARCHAR(10));
*/

-- Обновить сделку
CREATE OR ALTER PROCEDURE sp_UpdateDeal
    @deal_id INT,
    @property_id INT,
    @client_id INT,
    @realtor_id INT,
    @deal_type NVARCHAR(50),
    @deal_price DECIMAL(15,2),
    @deal_date DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_UpdateDeal для deal_id = ' + CAST(@deal_id AS VARCHAR(10));
        
        UPDATE Deals 
        SET property_id = @property_id, client_id = @client_id, realtor_id = @realtor_id,
            deal_type = @deal_type, deal_price = @deal_price, deal_date = @deal_date
        WHERE deal_id = @deal_id;
        
        PRINT 'Процедура sp_UpdateDeal успешно выполнена. Обновлено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Возвращаем обновленную сделку
        SELECT * FROM Deals WHERE deal_id = @deal_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_UpdateDeal: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_UpdateDeal
/*
EXEC sp_UpdateDeal 
    @deal_id = 1,
    @property_id = 2,
    @client_id = 1,
    @realtor_id = 1,
    @deal_type = 'Rent',
    @deal_price = 4000000.00,
    @deal_date = GETDATE();
SELECT 'Процедура sp_UpdateDeal выполнена' AS Status;
*/

-- Удалить сделку
CREATE OR ALTER PROCEDURE sp_DeleteDeal
    @deal_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_DeleteDeal для deal_id = ' + CAST(@deal_id AS VARCHAR(10));
        
        BEGIN TRANSACTION;
        
        -- Удаляем все контракты для этой сделки (если таблица существует)
        IF OBJECT_ID('Contracts', 'U') IS NOT NULL
        BEGIN
            DELETE FROM Contracts WHERE deal_id = @deal_id;
        END
        
        -- Удаляем саму сделку
        DELETE FROM Deals WHERE deal_id = @deal_id;
        
        COMMIT TRANSACTION;
        
        PRINT 'Процедура sp_DeleteDeal успешно выполнена. Удалена сделка с ID: ' + CAST(@deal_id AS VARCHAR(10));
        
        -- Выводим информацию об удалении
        SELECT 'Удалена сделка с ID: ' + CAST(@deal_id AS VARCHAR(10)) AS DeletionInfo;
        SELECT COUNT(*) AS RemainingDeals FROM Deals;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_DeleteDeal: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_DeleteDeal (ОСТОРОЖНО: удаляет данные!)
-- EXEC sp_DeleteDeal @deal_id = 5;
-- SELECT 'Процедура sp_DeleteDeal выполнена' AS Status;

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ PROPERTY RESERVATIONS
-- =============================================

-- Получить все резервирования
CREATE OR ALTER PROCEDURE sp_GetAllPropertyReservations
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetAllPropertyReservations';
        
        SELECT * FROM PropertyReservations ORDER BY reservation_date DESC;
        
        PRINT 'Процедура sp_GetAllPropertyReservations успешно выполнена. Найдено резервирований: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetAllPropertyReservations: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetAllPropertyReservations
-- EXEC sp_GetAllPropertyReservations;
-- SELECT 'Вызов процедуры sp_GetAllPropertyReservations завершен' AS Status;

-- Получить резервирование по ID
CREATE OR ALTER PROCEDURE sp_GetPropertyReservationById
    @reservation_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetPropertyReservationById для reservation_id = ' + CAST(@reservation_id AS VARCHAR(10));
        
        SELECT * FROM PropertyReservations WHERE reservation_id = @reservation_id;
        
        PRINT 'Процедура sp_GetPropertyReservationById успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetPropertyReservationById: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetPropertyReservationById
-- EXEC sp_GetPropertyReservationById @reservation_id = 1;
-- SELECT 'Вызов процедуры sp_GetPropertyReservationById завершен' AS Status;

-- Получить резервирования риэлтора
CREATE OR ALTER PROCEDURE sp_GetPropertyReservationsByRealtorId
    @realtor_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetPropertyReservationsByRealtorId для realtor_id = ' + CAST(@realtor_id AS VARCHAR(10));
        
        SELECT * FROM PropertyReservations WHERE realtor_id = @realtor_id ORDER BY reservation_date DESC;
        
        PRINT 'Процедура sp_GetPropertyReservationsByRealtorId успешно выполнена. Найдено резервирований: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetPropertyReservationsByRealtorId: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetPropertyReservationsByRealtorId
-- EXEC sp_GetPropertyReservationsByRealtorId @realtor_id = 1;
-- SELECT 'Вызов процедуры sp_GetPropertyReservationsByRealtorId завершен' AS Status;

-- Получить резервирования клиента
CREATE OR ALTER PROCEDURE sp_GetPropertyReservationsByClientId
    @client_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetPropertyReservationsByClientId для client_id = ' + CAST(@client_id AS VARCHAR(10));
        
        SELECT * FROM PropertyReservations WHERE client_id = @client_id ORDER BY reservation_date DESC;
        
        PRINT 'Процедура sp_GetPropertyReservationsByClientId успешно выполнена. Найдено резервирований: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetPropertyReservationsByClientId: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetPropertyReservationsByClientId
-- EXEC sp_GetPropertyReservationsByClientId @client_id = 1;
-- SELECT 'Вызов процедуры sp_GetPropertyReservationsByClientId завершен' AS Status;

-- Получить активные резервирования
CREATE OR ALTER PROCEDURE sp_GetActivePropertyReservations
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetActivePropertyReservations';
        
        SELECT * FROM PropertyReservations WHERE status = 'Active' ORDER BY reservation_date DESC;
        
        PRINT 'Процедура sp_GetActivePropertyReservations успешно выполнена. Найдено активных резервирований: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetActivePropertyReservations: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetActivePropertyReservations
-- EXEC sp_GetActivePropertyReservations;
-- SELECT 'Вызов процедуры sp_GetActivePropertyReservations завершен' AS Status;

-- Проверить активное резервирование
CREATE OR ALTER PROCEDURE sp_CheckActiveReservation
    @property_id INT,
    @client_id INT,
    @exists BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_CheckActiveReservation для property_id = ' + 
              CAST(@property_id AS VARCHAR(10)) + ' и client_id = ' + CAST(@client_id AS VARCHAR(10));
        
        IF EXISTS (SELECT 1 FROM PropertyReservations WHERE property_id = @property_id AND client_id = @client_id AND status = 'Active')
            SET @exists = 1;
        ELSE
            SET @exists = 0;
        
        PRINT 'Процедура sp_CheckActiveReservation успешно выполнена. Результат: ' + 
              CASE WHEN @exists = 1 THEN 'Резервирование существует' ELSE 'Резервирование не найдено' END;
        
        -- Возвращаем результат
        SELECT 
            @property_id AS property_id,
            @client_id AS client_id,
            @exists AS reservation_exists,
            CASE WHEN @exists = 1 THEN 'Резервирование активно' ELSE 'Резервирование отсутствует' END AS status_description;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_CheckActiveReservation: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_CheckActiveReservation
/*
DECLARE @reservation_exists BIT;
EXEC sp_CheckActiveReservation 
    @property_id = 1,
    @client_id = 1,
    @exists = @reservation_exists OUTPUT;
PRINT 'Резервирование существует: ' + CAST(@reservation_exists AS VARCHAR(5));
*/

-- Создать резервирование
CREATE OR ALTER PROCEDURE sp_CreatePropertyReservation
    @property_id INT,
    @client_id INT,
    @realtor_id INT,
    @reservation_date DATETIME,
    @expiry_date DATETIME,
    @status NVARCHAR(20),
    @reservation_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_CreatePropertyReservation для property_id = ' + 
              CAST(@property_id AS VARCHAR(10)) + ' и client_id = ' + CAST(@client_id AS VARCHAR(10));
        
        INSERT INTO PropertyReservations (property_id, client_id, realtor_id, reservation_date, expiry_date, status)
        VALUES (@property_id, @client_id, @realtor_id, @reservation_date, @expiry_date, @status);
        
        SET @reservation_id = SCOPE_IDENTITY();
        
        PRINT 'Процедура sp_CreatePropertyReservation успешно выполнена. Создано резервирование с ID: ' + 
              CAST(@reservation_id AS VARCHAR(10));
        
        -- Возвращаем созданное резервирование
        SELECT * FROM PropertyReservations WHERE reservation_id = @reservation_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_CreatePropertyReservation: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_CreatePropertyReservation
/*
DECLARE @new_reservation_id INT;
EXEC sp_CreatePropertyReservation 
    @property_id = 1,
    @client_id = 1,
    @realtor_id = 1,
    @reservation_date = GETDATE(),
    @expiry_date = DATEADD(DAY, 7, GETDATE()),
    @status = 'Active',
    @reservation_id = @new_reservation_id OUTPUT;
PRINT 'Создано новое резервирование с ID: ' + CAST(@new_reservation_id AS VARCHAR(10));
*/

-- Обновить резервирование
CREATE OR ALTER PROCEDURE sp_UpdatePropertyReservation
    @reservation_id INT,
    @status NVARCHAR(20),
    @expiry_date DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_UpdatePropertyReservation для reservation_id = ' + CAST(@reservation_id AS VARCHAR(10));
        
        UPDATE PropertyReservations 
        SET status = @status, expiry_date = @expiry_date
        WHERE reservation_id = @reservation_id;
        
        PRINT 'Процедура sp_UpdatePropertyReservation успешно выполнена. Обновлено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Возвращаем обновленное резервирование
        SELECT * FROM PropertyReservations WHERE reservation_id = @reservation_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_UpdatePropertyReservation: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_UpdatePropertyReservation
/*
EXEC sp_UpdatePropertyReservation 
    @reservation_id = 1,
    @status = 'Completed',
    @expiry_date = GETDATE();
SELECT 'Процедура sp_UpdatePropertyReservation выполнена' AS Status;
*/

-- Обновить статус резервирования
CREATE OR ALTER PROCEDURE sp_UpdateReservationStatus
    @reservation_id INT,
    @status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_UpdateReservationStatus для reservation_id = ' + 
              CAST(@reservation_id AS VARCHAR(10)) + ' со статусом: ' + @status;
        
        UPDATE PropertyReservations 
        SET status = @status
        WHERE reservation_id = @reservation_id;
        
        PRINT 'Процедура sp_UpdateReservationStatus успешно выполнена. Обновлено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Возвращаем обновленное резервирование
        SELECT reservation_id, property_id, client_id, status, expiry_date 
        FROM PropertyReservations WHERE reservation_id = @reservation_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_UpdateReservationStatus: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_UpdateReservationStatus
-- EXEC sp_UpdateReservationStatus @reservation_id = 1, @status = 'Cancelled';
-- SELECT 'Процедура sp_UpdateReservationStatus выполнена' AS Status;

-- Удалить резервирование
CREATE OR ALTER PROCEDURE sp_DeletePropertyReservation
    @reservation_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_DeletePropertyReservation для reservation_id = ' + CAST(@reservation_id AS VARCHAR(10));
        
        DELETE FROM PropertyReservations WHERE reservation_id = @reservation_id;
        
        PRINT 'Процедура sp_DeletePropertyReservation успешно выполнена. Удалено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Выводим информацию об удалении
        SELECT 'Удалено резервирование с ID: ' + CAST(@reservation_id AS VARCHAR(10)) AS DeletionInfo;
        SELECT COUNT(*) AS RemainingReservations FROM PropertyReservations;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_DeletePropertyReservation: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_DeletePropertyReservation (ОСТОРОЖНО: удаляет данные!)
-- EXEC sp_DeletePropertyReservation @reservation_id = 5;
-- SELECT 'Процедура sp_DeletePropertyReservation выполнена' AS Status;

-- =============================================
-- ПРОЦЕДУРЫ ДЛЯ CONTRACTS
-- =============================================

-- Получить все контракты
CREATE OR ALTER PROCEDURE sp_GetAllContracts
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetAllContracts';
        
        SELECT * FROM Contracts ORDER BY contract_date DESC;
        
        PRINT 'Процедура sp_GetAllContracts успешно выполнена. Найдено контрактов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetAllContracts: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetAllContracts
-- EXEC sp_GetAllContracts;
-- SELECT 'Вызов процедуры sp_GetAllContracts завершен' AS Status;

-- Получить контракт по ID
CREATE OR ALTER PROCEDURE sp_GetContractById
    @contract_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetContractById для contract_id = ' + CAST(@contract_id AS VARCHAR(10));
        
        SELECT * FROM Contracts WHERE contract_id = @contract_id;
        
        PRINT 'Процедура sp_GetContractById успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetContractById: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetContractById
-- EXEC sp_GetContractById @contract_id = 1;
-- SELECT 'Вызов процедуры sp_GetContractById завершен' AS Status;

-- Получить контракты по deal_id
CREATE OR ALTER PROCEDURE sp_GetContractsByDealId
    @deal_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetContractsByDealId для deal_id = ' + CAST(@deal_id AS VARCHAR(10));
        
        SELECT * FROM Contracts WHERE deal_id = @deal_id ORDER BY contract_date DESC;
        
        PRINT 'Процедура sp_GetContractsByDealId успешно выполнена. Найдено контрактов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetContractsByDealId: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetContractsByDealId
-- EXEC sp_GetContractsByDealId @deal_id = 1;
-- SELECT 'Вызов процедуры sp_GetContractsByDealId завершен' AS Status;

-- Получить контракты по дате
CREATE OR ALTER PROCEDURE sp_GetContractsByDateRange
    @start_date DATETIME,
    @end_date DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetContractsByDateRange для периода: ' + 
              CONVERT(VARCHAR, @start_date, 120) + ' - ' + CONVERT(VARCHAR, @end_date, 120);
        
        SELECT * FROM Contracts 
        WHERE contract_date >= @start_date AND contract_date <= @end_date 
        ORDER BY contract_date DESC;
        
        PRINT 'Процедура sp_GetContractsByDateRange успешно выполнена. Найдено контрактов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetContractsByDateRange: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetContractsByDateRange
/*
EXEC sp_GetContractsByDateRange 
    @start_date = '2024-01-01',
    @end_date = '2024-12-31';
SELECT 'Вызов процедуры sp_GetContractsByDateRange завершен' AS Status;
*/

-- Создать контракт
CREATE OR ALTER PROCEDURE sp_CreateContract
    @deal_id INT,
    @contract_date DATETIME,
    @contract_file NVARCHAR(255),
    @notes TEXT,
    @contract_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_CreateContract для deal_id = ' + CAST(@deal_id AS VARCHAR(10));
        
        INSERT INTO Contracts (deal_id, contract_date, contract_file, notes)
        VALUES (@deal_id, @contract_date, @contract_file, @notes);
        
        SET @contract_id = SCOPE_IDENTITY();
        
        PRINT 'Процедура sp_CreateContract успешно выполнена. Создан контракт с ID: ' + 
              CAST(@contract_id AS VARCHAR(10));
        
        -- Возвращаем созданный контракт
        SELECT * FROM Contracts WHERE contract_id = @contract_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_CreateContract: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_CreateContract
/*
DECLARE @new_contract_id INT;
EXEC sp_CreateContract 
    @deal_id = 1,
    @contract_date = GETDATE(),
    @contract_file = 'contract_123.pdf',
    @notes = 'Дополнительные условия договора',
    @contract_id = @new_contract_id OUTPUT;
PRINT 'Создан новый контракт с ID: ' + CAST(@new_contract_id AS VARCHAR(10));
*/

-- Обновить контракт
CREATE OR ALTER PROCEDURE sp_UpdateContract
    @contract_id INT,
    @contract_date DATETIME,
    @contract_file NVARCHAR(255),
    @notes TEXT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_UpdateContract для contract_id = ' + CAST(@contract_id AS VARCHAR(10));
        
        UPDATE Contracts 
        SET contract_date = @contract_date, contract_file = @contract_file, notes = @notes
        WHERE contract_id = @contract_id;
        
        PRINT 'Процедура sp_UpdateContract успешно выполнена. Обновлено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Возвращаем обновленный контракт
        SELECT * FROM Contracts WHERE contract_id = @contract_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_UpdateContract: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_UpdateContract
/*
EXEC sp_UpdateContract 
    @contract_id = 1,
    @contract_date = GETDATE(),
    @contract_file = 'updated_contract_123.pdf',
    @notes = 'Обновленные условия договора';
SELECT 'Процедура sp_UpdateContract выполнена' AS Status;
*/

-- Удалить контракт
CREATE OR ALTER PROCEDURE sp_DeleteContract
    @contract_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_DeleteContract для contract_id = ' + CAST(@contract_id AS VARCHAR(10));
        
        DELETE FROM Contracts WHERE contract_id = @contract_id;
        
        PRINT 'Процедура sp_DeleteContract успешно выполнена. Удалено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
        
        -- Выводим информацию об удалении
        SELECT 'Удален контракт с ID: ' + CAST(@contract_id AS VARCHAR(10)) AS DeletionInfo;
        SELECT COUNT(*) AS RemainingContracts FROM Contracts;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_DeleteContract: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_DeleteContract (ОСТОРОЖНО: удаляет данные!)
-- EXEC sp_DeleteContract @contract_id = 5;
-- SELECT 'Процедура sp_DeleteContract выполнена' AS Status;

-- =============================================
-- ДОПОЛНИТЕЛЬНЫЕ ПРОЦЕДУРЫ
-- =============================================

-- Получить статистику по объектам недвижимости
CREATE OR ALTER PROCEDURE sp_GetPropertyStatistics
    @total_properties INT OUTPUT,
    @available_properties INT OUTPUT,
    @total_value DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetPropertyStatistics';
        
        SELECT @total_properties = COUNT(*)
        FROM Properties;
        
        SELECT @available_properties = COUNT(*)
        FROM Properties 
        WHERE is_available = 1;
        
        SELECT @total_value = ISNULL(SUM(price), 0)
        FROM Properties;
        
        PRINT 'Процедура sp_GetPropertyStatistics успешно выполнена. Статистика:';
        PRINT 'Всего объектов: ' + CAST(@total_properties AS VARCHAR(10));
        PRINT 'Доступных объектов: ' + CAST(@available_properties AS VARCHAR(10));
        PRINT 'Общая стоимость: ' + CAST(@total_value AS VARCHAR(20));
        
        -- Возвращаем статистику
        SELECT 
            @total_properties AS total_properties,
            @available_properties AS available_properties,
            @total_value AS total_value,
            ROUND(CAST(@available_properties AS FLOAT) / NULLIF(@total_properties, 0) * 100, 2) AS availability_percentage;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetPropertyStatistics: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetPropertyStatistics
/*
DECLARE @total_props INT, @available_props INT, @total_val DECIMAL(18,2);
EXEC sp_GetPropertyStatistics 
    @total_properties = @total_props OUTPUT,
    @available_properties = @available_props OUTPUT,
    @total_value = @total_val OUTPUT;
PRINT 'Статистика: ' + CAST(@total_props AS VARCHAR(10)) + ' объектов, ' + 
      CAST(@available_props AS VARCHAR(10)) + ' доступных на сумму ' + 
      CAST(@total_val AS VARCHAR(20));
*/

-- Получить общую статистику
CREATE OR ALTER PROCEDURE sp_GetOverallStatistics
    @total_users INT OUTPUT,
    @total_clients INT OUTPUT,
    @total_realtors INT OUTPUT,
    @total_deals INT OUTPUT,
    @total_reservations INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetOverallStatistics';
        
        SELECT @total_users = COUNT(*) FROM Users;
        SELECT @total_clients = COUNT(*) FROM Clients;
        SELECT @total_realtors = COUNT(*) FROM Realtors;
        SELECT @total_deals = COUNT(*) FROM Deals;
        SELECT @total_reservations = COUNT(*) FROM PropertyReservations;
        
        PRINT 'Процедура sp_GetOverallStatistics успешно выполнена. Статистика:';
        PRINT 'Всего пользователей: ' + CAST(@total_users AS VARCHAR(10));
        PRINT 'Всего клиентов: ' + CAST(@total_clients AS VARCHAR(10));
        PRINT 'Всего риэлторов: ' + CAST(@total_realtors AS VARCHAR(10));
        PRINT 'Всего сделок: ' + CAST(@total_deals AS VARCHAR(10));
        PRINT 'Всего резервирований: ' + CAST(@total_reservations AS VARCHAR(10));
        
        -- Возвращаем статистику
        SELECT 
            @total_users AS total_users,
            @total_clients AS total_clients,
            @total_realtors AS total_realtors,
            @total_deals AS total_deals,
            @total_reservations AS total_reservations,
            ROUND(CAST(@total_deals AS FLOAT) / NULLIF(@total_clients, 0), 2) AS avg_deals_per_client,
            ROUND(CAST(@total_deals AS FLOAT) / NULLIF(@total_realtors, 0), 2) AS avg_deals_per_realtor;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetOverallStatistics: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetOverallStatistics
/*
DECLARE @users INT, @clients INT, @realtors INT, @deals INT, @reservations INT;
EXEC sp_GetOverallStatistics 
    @total_users = @users OUTPUT,
    @total_clients = @clients OUTPUT,
    @total_realtors = @realtors OUTPUT,
    @total_deals = @deals OUTPUT,
    @total_reservations = @reservations OUTPUT;
PRINT 'Общая статистика системы';
*/

-- Поиск объектов по параметрам
CREATE OR ALTER PROCEDURE sp_SearchProperties
    @property_type NVARCHAR(50) = NULL,
    @min_price DECIMAL(15,2) = NULL,
    @max_price DECIMAL(15,2) = NULL,
    @min_rooms INT = NULL,
    @max_rooms INT = NULL,
    @is_available BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_SearchProperties с параметрами:';
        PRINT 'Тип: ' + ISNULL(@property_type, 'Любой');
        PRINT 'Цена от: ' + ISNULL(CAST(@min_price AS VARCHAR(20)), 'Любая');
        PRINT 'Цена до: ' + ISNULL(CAST(@max_price AS VARCHAR(20)), 'Любая');
        PRINT 'Комнат от: ' + ISNULL(CAST(@min_rooms AS VARCHAR(10)), 'Любое');
        PRINT 'Комнат до: ' + ISNULL(CAST(@max_rooms AS VARCHAR(10)), 'Любое');
        PRINT 'Доступность: ' + CASE WHEN @is_available IS NULL THEN 'Любая' 
                                     WHEN @is_available = 1 THEN 'Да' 
                                     ELSE 'Нет' END;
        
        SELECT * FROM Properties
        WHERE (@property_type IS NULL OR property_type = @property_type)
            AND (@min_price IS NULL OR price >= @min_price)
            AND (@max_price IS NULL OR price <= @max_price)
            AND (@min_rooms IS NULL OR rooms >= @min_rooms)
            AND (@max_rooms IS NULL OR rooms <= @max_rooms)
            AND (@is_available IS NULL OR is_available = @is_available)
        ORDER BY price;
        
        PRINT 'Процедура sp_SearchProperties успешно выполнена. Найдено объектов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_SearchProperties: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_SearchProperties
/*
EXEC sp_SearchProperties 
    @property_type = 'Apartment',
    @min_price = 100000,
    @max_price = 500000,
    @min_rooms = 2,
    @max_rooms = 4,
    @is_available = 1;
SELECT 'Вызов процедуры sp_SearchProperties завершен' AS Status;
*/

-- Получить детали сделки с информацией о клиенте и риэлторе
CREATE OR ALTER PROCEDURE sp_GetDealDetails
    @deal_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetDealDetails для deal_id = ' + CAST(@deal_id AS VARCHAR(10));
        
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
        FROM Deals d
        INNER JOIN Properties p ON d.property_id = p.property_id
        INNER JOIN Clients c ON d.client_id = c.client_id
        INNER JOIN Realtors r ON d.realtor_id = r.realtor_id
        WHERE d.deal_id = @deal_id;
        
        PRINT 'Процедура sp_GetDealDetails успешно выполнена. Найдено записей: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetDealDetails: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetDealDetails
-- EXEC sp_GetDealDetails @deal_id = 1;
-- SELECT 'Вызов процедуры sp_GetDealDetails завершен' AS Status;

-- Получить список клиентов с их сделками
CREATE OR ALTER PROCEDURE sp_GetClientsWithDeals
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetClientsWithDeals';
        
        SELECT 
            c.client_id,
            c.full_name,
            c.email,
            c.phone_number,
            COUNT(d.deal_id) AS total_deals,
            ISNULL(SUM(d.deal_price), 0) AS total_spent
        FROM Clients c
        LEFT JOIN Deals d ON c.client_id = d.client_id
        GROUP BY c.client_id, c.full_name, c.email, c.phone_number
        ORDER BY total_spent DESC;
        
        PRINT 'Процедура sp_GetClientsWithDeals успешно выполнена. Найдено клиентов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetClientsWithDeals: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetClientsWithDeals
-- EXEC sp_GetClientsWithDeals;
-- SELECT 'Вызов процедуры sp_GetClientsWithDeals завершен' AS Status;

-- Получить список риэлторов с их статистикой
CREATE OR ALTER PROCEDURE sp_GetRealtorsWithStatistics
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        PRINT 'Выполняется процедура sp_GetRealtorsWithStatistics';
        
        SELECT 
            r.realtor_id,
            r.full_name,
            r.email,
            r.phone_number,
            r.commission_rate,
            COUNT(p.property_id) AS total_properties,
            COUNT(d.deal_id) AS total_deals,
            ISNULL(SUM(d.deal_price), 0) AS total_deal_amount,
            ISNULL(SUM(d.deal_price * r.commission_rate / 100), 0) AS total_commission
        FROM Realtors r
        LEFT JOIN Properties p ON r.realtor_id = p.realtor_id
        LEFT JOIN Deals d ON r.realtor_id = d.realtor_id
        GROUP BY r.realtor_id, r.full_name, r.email, r.phone_number, r.commission_rate
        ORDER BY total_commission DESC;
        
        PRINT 'Процедура sp_GetRealtorsWithStatistics успешно выполнена. Найдено риэлторов: ' + 
              CAST(@@ROWCOUNT AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Ошибка в процедуре sp_GetRealtorsWithStatistics: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Пример вызова процедуры sp_GetRealtorsWithStatistics
-- EXEC sp_GetRealtorsWithStatistics;
-- SELECT 'Вызов процедуры sp_GetRealtorsWithStatistics завершен' AS Status;

PRINT 'Все хранимые процедуры созданы с обработкой ошибок и выводом информации';
GO

-- =============================================
-- ТЕСТОВЫЕ ВЫЗОВЫ ПРОЦЕДУР
-- =============================================

/*
-- Примеры вызова основных процедур для тестирования:

-- 1. Получить всех пользователей
PRINT '=== Тест 1: Получить всех пользователей ===';
EXEC sp_GetAllUsers;

-- 2. Получить клиента по ID
PRINT '=== Тест 2: Получить клиента по ID ===';
EXEC sp_GetClientById @client_id = 1;

-- 3. Получить всех риэлторов
PRINT '=== Тест 3: Получить всех риэлторов ===';
EXEC sp_GetAllRealtors;

-- 4. Получить доступные объекты недвижимости
PRINT '=== Тест 4: Получить доступные объекты недвижимости ===';
EXEC sp_GetAvailableProperties;

-- 5. Получить статистику по объектам
PRINT '=== Тест 5: Получить статистику по объектам недвижимости ===';
DECLARE @total INT, @available INT, @value DECIMAL(18,2);
EXEC sp_GetPropertyStatistics 
    @total_properties = @total OUTPUT,
    @available_properties = @available OUTPUT,
    @total_value = @value OUTPUT;

-- 6. Получить общую статистику системы
PRINT '=== Тест 6: Получить общую статистику системы ===';
DECLARE @users INT, @clients INT, @realtors INT, @deals INT, @reservations INT;
EXEC sp_GetOverallStatistics 
    @total_users = @users OUTPUT,
    @total_clients = @clients OUTPUT,
    @total_realtors = @realtors OUTPUT,
    @total_deals = @deals OUTPUT,
    @total_reservations = @reservations OUTPUT;

-- 7. Поиск объектов с параметрами
PRINT '=== Тест 7: Поиск объектов с параметрами ===';
EXEC sp_SearchProperties 
    @property_type = 'Apartment',
    @min_price = 100000,
    @max_price = 1000000,
    @is_available = 1;

PRINT '=== Тестирование завершено ===';
*/