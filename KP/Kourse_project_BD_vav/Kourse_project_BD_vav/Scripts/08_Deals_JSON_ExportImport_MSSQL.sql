-- =============================================
-- Процедуры для экспорта и импорта таблицы Deals в JSON
-- =============================================

-- =============================================
-- ПРОЦЕДУРА ЭКСПОРТА: Экспорт всех сделок в JSON
-- =============================================
CREATE OR ALTER PROCEDURE sp_ExportDealsToJson
    @json_output NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Экспорт всех сделок в JSON формат
    SELECT @json_output = (
        SELECT 
            deal_id,
            property_id,
            client_id,
            realtor_id,
            deal_type,
            deal_status,
            deal_date,
            deal_price
        FROM Deals
        ORDER BY deal_id
        FOR JSON PATH, ROOT('deals')
    );
    
    -- Если данных нет, возвращаем пустой массив
    IF @json_output IS NULL
        SET @json_output = '{"deals":[]}';
END
GO

-- =============================================
-- ПРОЦЕДУРА ЭКСПОРТА: Экспорт сделок в JSON с фильтрацией
-- =============================================
CREATE OR ALTER PROCEDURE sp_ExportDealsToJsonFiltered
    @start_date DATETIME = NULL,
    @end_date DATETIME = NULL,
    @deal_status NVARCHAR(50) = NULL,
    @deal_type NVARCHAR(50) = NULL,
    @realtor_id INT = NULL,
    @client_id INT = NULL,
    @json_output NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Экспорт сделок с фильтрацией
    SELECT @json_output = (
        SELECT 
            deal_id,
            property_id,
            client_id,
            realtor_id,
            deal_type,
            deal_status,
            deal_date,
            deal_price
        FROM Deals
        WHERE 
            (@start_date IS NULL OR deal_date >= @start_date)
            AND (@end_date IS NULL OR deal_date <= @end_date)
            AND (@deal_status IS NULL OR deal_status = @deal_status)
            AND (@deal_type IS NULL OR deal_type = @deal_type)
            AND (@realtor_id IS NULL OR realtor_id = @realtor_id)
            AND (@client_id IS NULL OR client_id = @client_id)
        ORDER BY deal_id
        FOR JSON PATH, ROOT('deals')
    );
    
    -- Если данных нет, возвращаем пустой массив
    IF @json_output IS NULL
        SET @json_output = '{"deals":[]}';
END
GO

-- =============================================
-- ПРОЦЕДУРА ИМПОРТА: Импорт сделок из JSON
-- =============================================
CREATE OR ALTER PROCEDURE sp_ImportDealsFromJson
    @json_input NVARCHAR(MAX),
    @rows_imported INT OUTPUT,
    @rows_skipped INT OUTPUT,
    @error_message NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @rows_inserted INT = 0;
    DECLARE @rows_failed INT = 0;
    DECLARE @current_deal_id INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Проверка валидности JSON
        IF ISJSON(@json_input) = 0
        BEGIN
            SET @error_message = 'Неверный формат JSON';
            SET @rows_skipped = 0;
            SET @rows_imported = 0;
            ROLLBACK TRANSACTION;
            RETURN;
        END;
        
        -- Импорт данных из JSON
        INSERT INTO Deals (
            property_id,
            client_id,
            realtor_id,
            deal_type,
            deal_status,
            deal_date,
            deal_price
        )
        SELECT 
            JSON_VALUE(deal.value, '$.property_id') AS property_id,
            JSON_VALUE(deal.value, '$.client_id') AS client_id,
            CASE 
                WHEN JSON_VALUE(deal.value, '$.realtor_id') = 'null' OR JSON_VALUE(deal.value, '$.realtor_id') IS NULL 
                THEN NULL 
                ELSE CAST(JSON_VALUE(deal.value, '$.realtor_id') AS INT) 
            END AS realtor_id,
            JSON_VALUE(deal.value, '$.deal_type') AS deal_type,
            JSON_VALUE(deal.value, '$.deal_status') AS deal_status,
            CAST(JSON_VALUE(deal.value, '$.deal_date') AS DATETIME) AS deal_date,
            CAST(JSON_VALUE(deal.value, '$.deal_price') AS DECIMAL(15,2)) AS deal_price
        FROM OPENJSON(@json_input, '$.deals') AS deal
        WHERE 
            -- Проверка обязательных полей
            JSON_VALUE(deal.value, '$.property_id') IS NOT NULL
            AND JSON_VALUE(deal.value, '$.client_id') IS NOT NULL
            AND JSON_VALUE(deal.value, '$.deal_date') IS NOT NULL
            AND JSON_VALUE(deal.value, '$.deal_price') IS NOT NULL
            -- Проверка существования связанных записей
            AND EXISTS (SELECT 1 FROM Properties WHERE property_id = CAST(JSON_VALUE(deal.value, '$.property_id') AS INT))
            AND EXISTS (SELECT 1 FROM Clients WHERE client_id = CAST(JSON_VALUE(deal.value, '$.client_id') AS INT))
            AND (
                JSON_VALUE(deal.value, '$.realtor_id') IS NULL 
                OR JSON_VALUE(deal.value, '$.realtor_id') = 'null'
                OR EXISTS (SELECT 1 FROM Realtors WHERE realtor_id = CAST(JSON_VALUE(deal.value, '$.realtor_id') AS INT))
            );
        
        SET @rows_inserted = @@ROWCOUNT;
        
        -- Подсчет пропущенных строк (невалидные данные)
        SELECT @rows_failed = COUNT(*)
        FROM OPENJSON(@json_input, '$.deals') AS deal
        WHERE 
            JSON_VALUE(deal.value, '$.property_id') IS NULL
            OR JSON_VALUE(deal.value, '$.client_id') IS NULL
            OR JSON_VALUE(deal.value, '$.deal_date') IS NULL
            OR JSON_VALUE(deal.value, '$.deal_price') IS NULL
            OR NOT EXISTS (SELECT 1 FROM Properties WHERE property_id = CAST(JSON_VALUE(deal.value, '$.property_id') AS INT))
            OR NOT EXISTS (SELECT 1 FROM Clients WHERE client_id = CAST(JSON_VALUE(deal.value, '$.client_id') AS INT))
            OR (
                JSON_VALUE(deal.value, '$.realtor_id') IS NOT NULL 
                AND JSON_VALUE(deal.value, '$.realtor_id') != 'null'
                AND NOT EXISTS (SELECT 1 FROM Realtors WHERE realtor_id = CAST(JSON_VALUE(deal.value, '$.realtor_id') AS INT))
            );
        
        COMMIT TRANSACTION;
        
        SET @rows_imported = @rows_inserted;
        SET @rows_skipped = @rows_failed;
        SET @error_message = NULL;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @error_message = ERROR_MESSAGE();
        SET @rows_imported = @rows_inserted;
        SET @rows_skipped = @rows_failed;
    END CATCH;
END
GO

-- =============================================
-- ПРОЦЕДУРА ИМПОРТА: Импорт с заменой существующих (по deal_id)
-- =============================================
CREATE OR ALTER PROCEDURE sp_ImportDealsFromJsonWithUpdate
    @json_input NVARCHAR(MAX),
    @rows_imported INT OUTPUT,
    @rows_updated INT OUTPUT,
    @rows_skipped INT OUTPUT,
    @error_message NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @rows_inserted INT = 0;
    DECLARE @rows_updated_count INT = 0;
    DECLARE @rows_failed INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Проверка валидности JSON
        IF ISJSON(@json_input) = 0
        BEGIN
            SET @error_message = 'Неверный формат JSON';
            SET @rows_skipped = 0;
            SET @rows_imported = 0;
            SET @rows_updated = 0;
            ROLLBACK TRANSACTION;
            RETURN;
        END;
        
        -- Создаем временную таблицу для импортируемых данных
        CREATE TABLE #TempDeals (
            deal_id INT NULL,
            property_id INT NOT NULL,
            client_id INT NOT NULL,
            realtor_id INT NULL,
            deal_type NVARCHAR(50),
            deal_status NVARCHAR(50),
            deal_date DATETIME NOT NULL,
            deal_price DECIMAL(15,2) NOT NULL
        );
        
        -- Заполняем временную таблицу из JSON
        INSERT INTO #TempDeals (
            deal_id,
            property_id,
            client_id,
            realtor_id,
            deal_type,
            deal_status,
            deal_date,
            deal_price
        )
        SELECT 
            CASE 
                WHEN JSON_VALUE(deal.value, '$.deal_id') IS NOT NULL 
                THEN CAST(JSON_VALUE(deal.value, '$.deal_id') AS INT)
                ELSE NULL
            END AS deal_id,
            CAST(JSON_VALUE(deal.value, '$.property_id') AS INT) AS property_id,
            CAST(JSON_VALUE(deal.value, '$.client_id') AS INT) AS client_id,
            CASE 
                WHEN JSON_VALUE(deal.value, '$.realtor_id') = 'null' OR JSON_VALUE(deal.value, '$.realtor_id') IS NULL 
                THEN NULL 
                ELSE CAST(JSON_VALUE(deal.value, '$.realtor_id') AS INT) 
            END AS realtor_id,
            JSON_VALUE(deal.value, '$.deal_type') AS deal_type,
            JSON_VALUE(deal.value, '$.deal_status') AS deal_status,
            CAST(JSON_VALUE(deal.value, '$.deal_date') AS DATETIME) AS deal_date,
            CAST(JSON_VALUE(deal.value, '$.deal_price') AS DECIMAL(15,2)) AS deal_price
        FROM OPENJSON(@json_input, '$.deals') AS deal
        WHERE 
            JSON_VALUE(deal.value, '$.property_id') IS NOT NULL
            AND JSON_VALUE(deal.value, '$.client_id') IS NOT NULL
            AND JSON_VALUE(deal.value, '$.deal_date') IS NOT NULL
            AND JSON_VALUE(deal.value, '$.deal_price') IS NOT NULL
            AND EXISTS (SELECT 1 FROM Properties WHERE property_id = CAST(JSON_VALUE(deal.value, '$.property_id') AS INT))
            AND EXISTS (SELECT 1 FROM Clients WHERE client_id = CAST(JSON_VALUE(deal.value, '$.client_id') AS INT))
            AND (
                JSON_VALUE(deal.value, '$.realtor_id') IS NULL 
                OR JSON_VALUE(deal.value, '$.realtor_id') = 'null'
                OR EXISTS (SELECT 1 FROM Realtors WHERE realtor_id = CAST(JSON_VALUE(deal.value, '$.realtor_id') AS INT))
            );
        
        -- Обновляем существующие записи
        UPDATE d
        SET 
            property_id = t.property_id,
            client_id = t.client_id,
            realtor_id = t.realtor_id,
            deal_type = t.deal_type,
            deal_status = t.deal_status,
            deal_date = t.deal_date,
            deal_price = t.deal_price
        FROM Deals d
        INNER JOIN #TempDeals t ON d.deal_id = t.deal_id
        WHERE t.deal_id IS NOT NULL;
        
        SET @rows_updated_count = @@ROWCOUNT;
        
        -- Вставляем новые записи (без deal_id или с несуществующим deal_id)
        INSERT INTO Deals (
            property_id,
            client_id,
            realtor_id,
            deal_type,
            deal_status,
            deal_date,
            deal_price
        )
        SELECT 
            property_id,
            client_id,
            realtor_id,
            deal_type,
            deal_status,
            deal_date,
            deal_price
        FROM #TempDeals
        WHERE deal_id IS NULL 
           OR NOT EXISTS (SELECT 1 FROM Deals WHERE deal_id = #TempDeals.deal_id);
        
        SET @rows_inserted = @@ROWCOUNT;
        
        -- Подсчет пропущенных строк
        SELECT @rows_failed = COUNT(*)
        FROM OPENJSON(@json_input, '$.deals') AS deal
        WHERE 
            JSON_VALUE(deal.value, '$.property_id') IS NULL
            OR JSON_VALUE(deal.value, '$.client_id') IS NULL
            OR JSON_VALUE(deal.value, '$.deal_date') IS NULL
            OR JSON_VALUE(deal.value, '$.deal_price') IS NULL
            OR NOT EXISTS (SELECT 1 FROM Properties WHERE property_id = CAST(JSON_VALUE(deal.value, '$.property_id') AS INT))
            OR NOT EXISTS (SELECT 1 FROM Clients WHERE client_id = CAST(JSON_VALUE(deal.value, '$.client_id') AS INT))
            OR (
                JSON_VALUE(deal.value, '$.realtor_id') IS NOT NULL 
                AND JSON_VALUE(deal.value, '$.realtor_id') != 'null'
                AND NOT EXISTS (SELECT 1 FROM Realtors WHERE realtor_id = CAST(JSON_VALUE(deal.value, '$.realtor_id') AS INT))
            );
        
        DROP TABLE #TempDeals;
        
        COMMIT TRANSACTION;
        
        SET @rows_imported = @rows_inserted;
        SET @rows_updated = @rows_updated_count;
        SET @rows_skipped = @rows_failed;
        SET @error_message = NULL;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        IF OBJECT_ID('tempdb..#TempDeals') IS NOT NULL
            DROP TABLE #TempDeals;
        
        SET @error_message = ERROR_MESSAGE();
        SET @rows_imported = @rows_inserted;
        SET @rows_updated = @rows_updated_count;
        SET @rows_skipped = @rows_failed;
    END CATCH;
END
GO

-- =============================================
-- ПРОЦЕДУРА ЭКСПОРТА: Экспорт в файл (требует xp_cmdshell)
-- =============================================
-- ВНИМАНИЕ: Эта процедура требует включения xp_cmdshell
-- Для включения: EXEC sp_configure 'show advanced options', 1; RECONFIGURE; EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
-- Используйте с осторожностью из-за проблем безопасности
CREATE OR ALTER PROCEDURE sp_ExportDealsToJsonFile
    @file_path NVARCHAR(500),
    @rows_exported INT OUTPUT,
    @error_message NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @json_data NVARCHAR(MAX);
    DECLARE @sql_command NVARCHAR(MAX);
    DECLARE @bcp_command NVARCHAR(MAX);
    
    BEGIN TRY
        -- Получаем JSON данные
        EXEC sp_ExportDealsToJson @json_output = @json_data OUTPUT;
        
        -- Подсчитываем количество экспортированных записей
        SELECT @rows_exported = COUNT(*)
        FROM OPENJSON(@json_data, '$.deals');
        
        -- Создаем временный файл для записи
        DECLARE @temp_file NVARCHAR(500) = @file_path + '.tmp';
        
        -- Используем BCP для записи в файл
        SET @bcp_command = 'echo ' + QUOTENAME(@json_data, '"') + ' > ' + QUOTENAME(@temp_file, '"');
        
        -- Альтернативный способ через xp_cmdshell (требует специальных прав)
        -- EXEC xp_cmdshell @bcp_command;
        
        -- Более безопасный способ: использовать SQL Server Integration Services (SSIS)
        -- или сохранять через приложение
        
        SET @error_message = 'Для записи в файл используйте приложение или BCP утилиту. JSON данные готовы в переменной @json_data';
        
    END TRY
    BEGIN CATCH
        SET @error_message = ERROR_MESSAGE();
        SET @rows_exported = 0;
    END CATCH;
END
GO

-- =============================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ
-- =============================================

/*
-- ПРИМЕР 1: Экспорт всех сделок в JSON
DECLARE @json_result NVARCHAR(MAX);
EXEC sp_ExportDealsToJson @json_output = @json_result OUTPUT;
SELECT @json_result AS JsonData;
-- Сохраните результат в файл через приложение
*/

/*
-- ПРИМЕР 2: Экспорт с фильтрацией
DECLARE @json_result NVARCHAR(MAX);
EXEC sp_ExportDealsToJsonFiltered 
    @start_date = '2024-01-01',
    @end_date = '2024-12-31',
    @deal_status = 'Завершена',
    @json_output = @json_result OUTPUT;
SELECT @json_result AS JsonData;
*/

/*
-- ПРИМЕР 3: Импорт из JSON
DECLARE @json_input NVARCHAR(MAX) = '{
    "deals": [
        {
            "property_id": 1,
            "client_id": 1,
            "realtor_id": 1,
            "deal_type": "Продажа",
            "deal_status": "Завершена",
            "deal_date": "2024-01-15T10:30:00",
            "deal_price": 5000000.00
        },
        {
            "property_id": 2,
            "client_id": 2,
            "realtor_id": null,
            "deal_type": "Аренда",
            "deal_status": "В обработке",
            "deal_date": "2024-02-20T14:00:00",
            "deal_price": 50000.00
        }
    ]
}';

DECLARE @rows_imported INT;
DECLARE @rows_skipped INT;
DECLARE @error_msg NVARCHAR(MAX);

EXEC sp_ImportDealsFromJson 
    @json_input = @json_input,
    @rows_imported = @rows_imported OUTPUT,
    @rows_skipped = @rows_skipped OUTPUT,
    @error_message = @error_msg OUTPUT;

SELECT 
    @rows_imported AS RowsImported,
    @rows_skipped AS RowsSkipped,
    @error_msg AS ErrorMessage;
*/

/*
-- ПРИМЕР 4: Импорт с обновлением существующих
DECLARE @json_input NVARCHAR(MAX) = '{
    "deals": [
        {
            "deal_id": 1,
            "property_id": 1,
            "client_id": 1,
            "realtor_id": 1,
            "deal_type": "Продажа",
            "deal_status": "Завершена",
            "deal_date": "2024-01-15T10:30:00",
            "deal_price": 6000000.00
        }
    ]
}';

DECLARE @rows_imported INT;
DECLARE @rows_updated INT;
DECLARE @rows_skipped INT;
DECLARE @error_msg NVARCHAR(MAX);

EXEC sp_ImportDealsFromJsonWithUpdate 
    @json_input = @json_input,
    @rows_imported = @rows_imported OUTPUT,
    @rows_updated = @rows_updated OUTPUT,
    @rows_skipped = @rows_skipped OUTPUT,
    @error_message = @error_msg OUTPUT;

SELECT 
    @rows_imported AS RowsImported,
    @rows_updated AS RowsUpdated,
    @rows_skipped AS RowsSkipped,
    @error_msg AS ErrorMessage;
*/

GO

