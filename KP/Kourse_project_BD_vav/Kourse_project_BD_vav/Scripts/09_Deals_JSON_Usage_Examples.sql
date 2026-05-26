-- =============================================
-- Примеры использования процедур экспорта/импорта Deals в JSON
-- =============================================

-- =============================================
-- ПРИМЕР 1: Экспорт всех сделок
-- =============================================
DECLARE @json_result NVARCHAR(MAX);

EXEC sp_ExportDealsToJson @json_output = @json_result OUTPUT;

-- Просмотр результата
SELECT @json_result AS JsonData;

-- Сохранение в переменную для дальнейшего использования
-- В приложении можно сохранить эту строку в файл .json

-- =============================================
-- ПРИМЕР 2: Экспорт с фильтрацией по дате
-- =============================================
DECLARE @json_result NVARCHAR(MAX);

EXEC sp_ExportDealsToJsonFiltered 
    @start_date = '2024-01-01',
    @end_date = '2024-12-31',
    @json_output = @json_result OUTPUT;

SELECT @json_result AS JsonData;

-- =============================================
-- ПРИМЕР 3: Экспорт с фильтрацией по статусу
-- =============================================
DECLARE @json_result NVARCHAR(MAX);

EXEC sp_ExportDealsToJsonFiltered 
    @deal_status = 'Завершена',
    @json_output = @json_result OUTPUT;

SELECT @json_result AS JsonData;

-- =============================================
-- ПРИМЕР 4: Экспорт сделок конкретного риэлтора
-- =============================================
DECLARE @json_result NVARCHAR(MAX);

EXEC sp_ExportDealsToJsonFiltered 
    @realtor_id = 1,
    @json_output = @json_result OUTPUT;

SELECT @json_result AS JsonData;

-- =============================================
-- ПРИМЕР 5: Импорт одной сделки
-- =============================================
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

-- =============================================
-- ПРИМЕР 6: Импорт нескольких сделок
-- =============================================
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
        },
        {
            "property_id": 3,
            "client_id": 3,
            "realtor_id": 2,
            "deal_type": "Обмен",
            "deal_status": "Ожидает подтверждения",
            "deal_date": "2024-03-10T09:15:00",
            "deal_price": 3000000.00
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

-- =============================================
-- ПРИМЕР 7: Импорт с обновлением существующих записей
-- =============================================
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
        },
        {
            "property_id": 5,
            "client_id": 5,
            "realtor_id": 3,
            "deal_type": "Аренда",
            "deal_status": "В обработке",
            "deal_date": "2024-04-01T12:00:00",
            "deal_price": 75000.00
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

-- =============================================
-- ПРИМЕР 8: Экспорт и сохранение в файл через приложение
-- =============================================
-- В приложении (C#):
/*
DECLARE @json_result NVARCHAR(MAX);
EXEC sp_ExportDealsToJson @json_output = @json_result OUTPUT;

-- В C# коде:
string jsonData = (string)command.Parameters["@json_output"].Value;
File.WriteAllText("deals_export.json", jsonData, Encoding.UTF8);
*/

-- =============================================
-- ПРИМЕР 9: Импорт из файла через приложение
-- =============================================
-- В приложении (C#):
/*
string jsonData = File.ReadAllText("deals_import.json", Encoding.UTF8);

var command = new SqlCommand("sp_ImportDealsFromJson", connection);
command.CommandType = CommandType.StoredProcedure;
command.Parameters.Add("@json_input", SqlDbType.NVarChar, -1).Value = jsonData;
command.Parameters.Add("@rows_imported", SqlDbType.Int).Direction = ParameterDirection.Output;
command.Parameters.Add("@rows_skipped", SqlDbType.Int).Direction = ParameterDirection.Output;
command.Parameters.Add("@error_message", SqlDbType.NVarChar, -1).Direction = ParameterDirection.Output;

command.ExecuteNonQuery();

int rowsImported = (int)command.Parameters["@rows_imported"].Value;
int rowsSkipped = (int)command.Parameters["@rows_skipped"].Value;
string errorMessage = command.Parameters["@error_message"].Value?.ToString();
*/

-- =============================================
-- ПРИМЕР 10: Проверка валидности JSON перед импортом
-- =============================================
DECLARE @json_input NVARCHAR(MAX) = '{
    "deals": [
        {
            "property_id": 999999,
            "client_id": 1,
            "deal_type": "Продажа",
            "deal_status": "Завершена",
            "deal_date": "2024-01-15T10:30:00",
            "deal_price": 5000000.00
        }
    ]
}';

-- Проверка валидности JSON
IF ISJSON(@json_input) = 1
BEGIN
    PRINT 'JSON валиден';
    
    DECLARE @rows_imported INT;
    DECLARE @rows_skipped INT;
    DECLARE @error_msg NVARCHAR(MAX);
    
    EXEC sp_ImportDealsFromJson 
        @json_input = @json_input,
        @rows_imported = @rows_imported OUTPUT,
        @rows_skipped = @rows_skipped OUTPUT,
        @error_message = @error_msg OUTPUT;
    
    -- Строка с несуществующим property_id будет пропущена
    SELECT 
        @rows_imported AS RowsImported,
        @rows_skipped AS RowsSkipped,
        @error_msg AS ErrorMessage;
END
ELSE
BEGIN
    PRINT 'JSON невалиден';
END;

GO

