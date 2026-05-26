USE [kursovoy_project_VAV];
GO

-- Получить всех пользователей
EXEC sp_GetAllUsers;
GO

-- Получить пользователей с ролью Client
EXEC sp_GetUsersByRole @role = 'Client';
GO

-- 2. Тестирование процедур для Clients
PRINT '=== Тестирование процедур для Clients ===';
GO

-- Получить всех клиентов
EXEC sp_GetAllClients;
GO

-- 3. Тестирование процедур для Realtors
PRINT '=== Тестирование процедур для Realtors ===';
GO

-- Получить всех риэлторов
EXEC sp_GetAllRealtors;
GO

-- 4. Тестирование процедур для Properties
PRINT '=== Тестирование процедур для Properties ===';
GO

-- Получить все объекты
EXEC sp_GetAllProperties;
GO

-- Получить доступные объекты
EXEC sp_GetAvailableProperties;
GO

-- Поиск объектов
EXEC sp_SearchProperties 
    @property_type = 'Квартира',
    @min_price = 100000,
    @max_price = 500000,
    @is_available = 1;
GO

-- 5. Тестирование процедур для Deals
PRINT '=== Тестирование процедур для Deals ===';
GO

-- Получить все сделки
EXEC sp_GetAllDeals;
GO

-- 6. Тестирование статистических процедур
PRINT '=== Тестирование статистических процедур ===';
GO

-- Получить статистику по объектам
DECLARE @total INT, @available INT, @value DECIMAL(18,2);
EXEC sp_GetPropertyStatistics 
    @total_properties = @total OUTPUT,
    @available_properties = @available OUTPUT,
    @total_value = @value OUTPUT;
PRINT 'Всего объектов: ' + CAST(@total AS VARCHAR(10));
PRINT 'Доступных объектов: ' + CAST(@available AS VARCHAR(10));
PRINT 'Общая стоимость: ' + CAST(@value AS VARCHAR(20));
GO

-- Получить общую статистику
DECLARE @users INT, @clients INT, @realtors INT, @deals INT, @reservations INT;
EXEC sp_GetOverallStatistics 
    @total_users = @users OUTPUT,
    @total_clients = @clients OUTPUT,
    @total_realtors = @realtors OUTPUT,
    @total_deals = @deals OUTPUT,
    @total_reservations = @reservations OUTPUT;
PRINT 'Всего пользователей: ' + CAST(@users AS VARCHAR(10));
PRINT 'Всего клиентов: ' + CAST(@clients AS VARCHAR(10));
PRINT 'Всего риэлторов: ' + CAST(@realtors AS VARCHAR(10));
PRINT 'Всего сделок: ' + CAST(@deals AS VARCHAR(10));
PRINT 'Всего резервирований: ' + CAST(@reservations AS VARCHAR(10));
GO

-- 7. Тестирование сложных отчетов
PRINT '=== Тестирование сложных отчетов ===';
GO

-- Клиенты с их сделками
EXEC sp_GetClientsWithDeals;
GO

-- Риэлторы со статистикой
EXEC sp_GetRealtorsWithStatistics;
GO

PRINT '=== Тестирование завершено ===';
GO