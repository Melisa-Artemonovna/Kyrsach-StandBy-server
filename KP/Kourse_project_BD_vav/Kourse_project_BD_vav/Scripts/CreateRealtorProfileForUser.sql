-- Скрипт для создания профиля риелтора для существующего пользователя
-- Используйте этот скрипт, если у пользователя с ролью Realtor нет профиля в таблице Realtors

-- Для MSSQL Server
-- Замените @UserId на нужный user_id (например, 6)

DECLARE @UserId INT = 6; -- Замените на нужный user_id
DECLARE @UserFullName NVARCHAR(100);
DECLARE @UserEmail NVARCHAR(100);

-- Получаем данные пользователя
SELECT @UserFullName = full_name, @UserEmail = email
FROM Users
WHERE user_id = @UserId AND role = 'Realtor';

-- Проверяем, существует ли уже профиль
IF NOT EXISTS (SELECT 1 FROM Realtors WHERE user_id = @UserId)
BEGIN
    -- Создаем профиль риелтора
    INSERT INTO Realtors (full_name, phone_number, email, hire_date, commission_rate, user_id)
    VALUES (
        @UserFullName,
        '+375 (29) 000-00-00', -- Телефон по умолчанию (можно изменить позже)
        @UserEmail,
        GETDATE(),
        5.0, -- Комиссия по умолчанию
        @UserId
    );
    
    -- Обновляем user_id в таблице Users
    UPDATE Users
    SET realtor_id = (SELECT realtor_id FROM Realtors WHERE user_id = @UserId)
    WHERE user_id = @UserId;
    
    PRINT 'Профиль риелтора успешно создан!';
END
ELSE
BEGIN
    PRINT 'Профиль риелтора уже существует для этого пользователя.';
END
GO

