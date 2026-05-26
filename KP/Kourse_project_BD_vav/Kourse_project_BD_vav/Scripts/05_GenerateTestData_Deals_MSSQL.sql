-- =============================================
-- Скрипт для генерации 100000 тестовых записей в таблицу Deals
-- =============================================

-- Проверка существования необходимых данных
-- Если таблицы пустые, создадим минимальные тестовые данные
IF NOT EXISTS (SELECT 1 FROM Properties)
BEGIN
    PRINT 'Создание тестовых Properties...';
    -- Создаем 1000 тестовых объектов недвижимости
    DECLARE @i INT = 1;
    WHILE @i <= 1000
    BEGIN
        INSERT INTO Properties (address, property_type, area, price, rooms, floor, total_floors, is_available, realtor_id)
        VALUES (
            'Тестовый адрес ' + CAST(@i AS VARCHAR),
            CASE (@i % 3) WHEN 0 THEN 'Квартира' WHEN 1 THEN 'Дом' ELSE 'Офис' END,
            CAST(RAND() * 200 + 20 AS DECIMAL(10,2)),
            CAST(RAND() * 50000000 + 1000000 AS DECIMAL(15,2)),
            CAST(RAND() * 5 + 1 AS INT),
            CAST(RAND() * 20 + 1 AS INT),
            CAST(RAND() * 20 + 5 AS INT),
            1,
            NULL
        );
        SET @i = @i + 1;
    END;
    PRINT 'Создано 1000 тестовых Properties';
END;

IF NOT EXISTS (SELECT 1 FROM Clients)
BEGIN
    PRINT 'Создание тестовых Clients...';
    -- Создаем 1000 тестовых клиентов
    DECLARE @j INT = 1;
    WHILE @j <= 1000
    BEGIN
        INSERT INTO Clients (full_name, email, phone_number, passport_number, registration_date, user_id)
        VALUES (
            'Тестовый клиент ' + CAST(@j AS VARCHAR),
            'client' + CAST(@j AS VARCHAR) + '@test.com',
            '+7' + CAST(CAST(RAND() * 9000000000 + 1000000000 AS BIGINT) AS VARCHAR),
            CAST(CAST(RAND() * 9000000000 + 1000000000 AS BIGINT) AS VARCHAR),
            DATEADD(DAY, -CAST(RAND() * 365 AS INT), GETDATE()),
            NULL
        );
        SET @j = @j + 1;
    END;
    PRINT 'Создано 1000 тестовых Clients';
END;

IF NOT EXISTS (SELECT 1 FROM Realtors)
BEGIN
    PRINT 'Создание тестовых Realtors...';
    -- Создаем 100 тестовых риэлторов
    DECLARE @k INT = 1;
    WHILE @k <= 100
    BEGIN
        INSERT INTO Realtors (full_name, email, phone_number, hire_date, commission_rate, user_id)
        VALUES (
            'Тестовый риэлтор ' + CAST(@k AS VARCHAR),
            'realtor' + CAST(@k AS VARCHAR) + '@test.com',
            '+7' + CAST(CAST(RAND() * 9000000000 + 1000000000 AS BIGINT) AS VARCHAR),
            DATEADD(DAY, -CAST(RAND() * 1000 AS INT), GETDATE()),
            CAST(RAND() * 0.1 + 0.02 AS DECIMAL(5,2)),
            NULL
        );
        SET @k = @k + 1;
    END;
    PRINT 'Создано 100 тестовых Realtors';
END;

-- Проверяем, есть ли данные в таблицах
IF NOT EXISTS (SELECT 1 FROM Properties) OR NOT EXISTS (SELECT 1 FROM Clients) OR NOT EXISTS (SELECT 1 FROM Realtors)
BEGIN
    PRINT 'ОШИБКА: Не удалось создать тестовые данные или таблицы пусты!';
    RETURN;
END

-- Очистка существующих данных (опционально, раскомментируйте если нужно)
-- TRUNCATE TABLE Deals;
-- PRINT 'Таблица Deals очищена';

-- =============================================
-- Генерация 100000 записей в таблицу Deals
-- =============================================
PRINT 'Начало генерации 100000 записей в таблицу Deals...';
DECLARE @StartTime DATETIME = GETDATE();

-- Получаем диапазоны ID для случайного выбора
DECLARE @MinPropertyId INT, @MaxPropertyId INT;
DECLARE @MinClientId INT, @MaxClientId INT;
DECLARE @MinRealtorId INT, @MaxRealtorId INT;

SELECT @MinPropertyId = MIN(property_id), @MaxPropertyId = MAX(property_id) FROM Properties;
SELECT @MinClientId = MIN(client_id), @MaxClientId = MAX(client_id) FROM Clients;
SELECT @MinRealtorId = MIN(realtor_id), @MaxRealtorId = MAX(realtor_id) FROM Realtors;

PRINT 'Диапазоны ID:';
PRINT 'Properties: ' + CAST(@MinPropertyId AS VARCHAR) + ' - ' + CAST(@MaxPropertyId AS VARCHAR);
PRINT 'Clients: ' + CAST(@MinClientId AS VARCHAR) + ' - ' + CAST(@MaxClientId AS VARCHAR);
PRINT 'Realtors: ' + CAST(@MinRealtorId AS VARCHAR) + ' - ' + CAST(@MaxRealtorId AS VARCHAR);

-- Генерация данных пакетами по 1000 записей для оптимизации
DECLARE @BatchSize INT = 1000;
DECLARE @TotalRecords INT = 100000;
DECLARE @CurrentBatch INT = 0;
DECLARE @RecordsInBatch INT = 0;
DECLARE @TotalDealsCount INT = 0;

-- Создаем временную таблицу для хранения счетчика
CREATE TABLE #TempCount (cnt INT);

-- Сохраняем общее количество записей во временную таблицу
INSERT INTO #TempCount (cnt) VALUES (0);

WHILE @CurrentBatch * @BatchSize < @TotalRecords
BEGIN
    SET @RecordsInBatch = CASE 
        WHEN (@CurrentBatch + 1) * @BatchSize > @TotalRecords 
        THEN @TotalRecords - @CurrentBatch * @BatchSize 
        ELSE @BatchSize 
    END;

    -- Используем табличную переменную для генерации чисел
    DECLARE @Numbers TABLE (RowNum INT);
    
    -- Заполняем табличную переменную
    DECLARE @counter INT = 1;
    WHILE @counter <= @RecordsInBatch
    BEGIN
        INSERT INTO @Numbers (RowNum) VALUES (@counter + (@CurrentBatch * @BatchSize));
        SET @counter = @counter + 1;
    END;

    -- Вставка данных
    INSERT INTO Deals (property_id, client_id, realtor_id, deal_type, deal_status, deal_date, deal_price)
    SELECT 
        -- Случайный property_id в диапазоне
        CAST(@MinPropertyId + (ABS(CHECKSUM(NEWID())) % (@MaxPropertyId - @MinPropertyId + 1)) AS INT) AS property_id,
        -- Случайный client_id в диапазоне
        CAST(@MinClientId + (ABS(CHECKSUM(NEWID())) % (@MaxClientId - @MinClientId + 1)) AS INT) AS client_id,
        -- Случайный realtor_id (может быть NULL с вероятностью 10%)
        CASE 
            WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN NULL
            ELSE CAST(@MinRealtorId + (ABS(CHECKSUM(NEWID())) % (@MaxRealtorId - @MinRealtorId + 1)) AS INT)
        END AS realtor_id,
        -- Случайный тип сделки
        CASE (ABS(CHECKSUM(NEWID())) % 3)
            WHEN 0 THEN 'Продажа'
            WHEN 1 THEN 'Аренда'
            ELSE 'Обмен'
        END AS deal_type,
        -- Случайный статус сделки
        CASE (ABS(CHECKSUM(NEWID())) % 4)
            WHEN 0 THEN 'Завершена'
            WHEN 1 THEN 'В обработке'
            WHEN 2 THEN 'Отменена'
            ELSE 'Ожидает подтверждения'
        END AS deal_status,
        -- Случайная дата за последние 2 года
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 730, GETDATE()) AS deal_date,
        -- Случайная цена от 100000 до 100000000
        CAST(100000 + (ABS(CHECKSUM(NEWID())) % 99900000) AS DECIMAL(15,2)) AS deal_price
    FROM @Numbers;

    SET @CurrentBatch = @CurrentBatch + 1;
    
    -- Обновляем счетчик
    UPDATE #TempCount SET cnt = cnt + @RecordsInBatch;
    
    IF @CurrentBatch % 10 = 0
    BEGIN
        DECLARE @Processed INT;
        SELECT @Processed = cnt FROM #TempCount;
        PRINT 'Обработано записей: ' + CAST(@Processed AS VARCHAR) + ' / ' + CAST(@TotalRecords AS VARCHAR);
    END;
END;

-- Получаем общее количество записей
SELECT @TotalDealsCount = cnt FROM #TempCount;

DECLARE @EndTime DATETIME = GETDATE();
DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, @EndTime);

PRINT '========================================';
PRINT 'Генерация завершена!';
PRINT 'Всего записей: ' + CAST(@TotalDealsCount AS VARCHAR);
PRINT 'Время выполнения: ' + CAST(@Duration AS VARCHAR) + ' секунд';
PRINT 'Скорость: ~' + CAST(CAST(@TotalDealsCount * 1.0 / @Duration AS DECIMAL(10,2)) AS VARCHAR) + ' записей/сек';
PRINT '========================================';

-- Очищаем временную таблицу
DROP TABLE #TempCount;

-- Проверка статистики (разделяем на отдельные запросы)
PRINT '';
PRINT 'Статистика по сгенерированным данным:';
PRINT '----------------------------------------';

DECLARE @TotalCount INT;
SELECT @TotalCount = COUNT(*) FROM Deals;
PRINT 'Всего сделок: ' + CAST(@TotalCount AS VARCHAR);
PRINT '';

-- Статистика по типам сделок
PRINT 'Распределение по типам сделок:';
SELECT 
    deal_type,
    COUNT(*) AS count,
    CAST(COUNT(*) * 100.0 / @TotalCount AS DECIMAL(5,2)) AS percentage
FROM Deals
GROUP BY deal_type
ORDER BY count DESC;
PRINT '';

-- Статистика по статусам сделок
PRINT 'Распределение по статусам сделок:';
SELECT 
    deal_status,
    COUNT(*) AS count,
    CAST(COUNT(*) * 100.0 / @TotalCount AS DECIMAL(5,2)) AS percentage
FROM Deals
GROUP BY deal_status
ORDER BY count DESC;
PRINT '';

-- Статистика по годам
PRINT 'Распределение по годам:';
SELECT 
    YEAR(deal_date) AS year,
    COUNT(*) AS count,
    CAST(COUNT(*) * 100.0 / @TotalCount AS DECIMAL(5,2)) AS percentage
FROM Deals
GROUP BY YEAR(deal_date)
ORDER BY year DESC;
PRINT '';

-- Средняя цена сделки
PRINT 'Средняя цена сделки:';
SELECT 
    AVG(deal_price) AS avg_price,
    MIN(deal_price) AS min_price,
    MAX(deal_price) AS max_price
FROM Deals;
PRINT '';

PRINT '========================================';
GO