# Процедуры экспорта/импорта таблицы Deals в JSON

## Описание

Набор хранимых процедур для экспорта данных из таблицы `Deals` в JSON формат и импорта данных из JSON обратно в таблицу.

## Созданные процедуры

### Экспорт

1. **`sp_ExportDealsToJson`** - Экспорт всех сделок в JSON
2. **`sp_ExportDealsToJsonFiltered`** - Экспорт с фильтрацией по различным параметрам
3. **`sp_ExportDealsToJsonFile`** - Экспорт в файл (требует дополнительных настроек)

### Импорт

1. **`sp_ImportDealsFromJson`** - Импорт сделок из JSON (только новые записи)
2. **`sp_ImportDealsFromJsonWithUpdate`** - Импорт с обновлением существующих записей

---

## Установка

Выполните скрипт `08_Deals_JSON_ExportImport_MSSQL.sql` в вашей базе данных:

```sql
-- В SQL Server Management Studio
-- Откройте файл 08_Deals_JSON_ExportImport_MSSQL.sql
-- Выполните скрипт (F5)
```

---

## Использование

### Экспорт всех сделок

```sql
DECLARE @json_result NVARCHAR(MAX);
EXEC sp_ExportDealsToJson @json_output = @json_result OUTPUT;
SELECT @json_result AS JsonData;
```

**Результат:**
```json
{
    "deals": [
        {
            "deal_id": 1,
            "property_id": 1,
            "client_id": 1,
            "realtor_id": 1,
            "deal_type": "Продажа",
            "deal_status": "Завершена",
            "deal_date": "2024-01-15T10:30:00",
            "deal_price": 5000000.00
        },
        ...
    ]
}
```

### Экспорт с фильтрацией

```sql
DECLARE @json_result NVARCHAR(MAX);
EXEC sp_ExportDealsToJsonFiltered 
    @start_date = '2024-01-01',
    @end_date = '2024-12-31',
    @deal_status = 'Завершена',
    @realtor_id = 1,
    @json_output = @json_result OUTPUT;
SELECT @json_result AS JsonData;
```

**Параметры фильтрации:**
- `@start_date` - Начальная дата (NULL = без ограничения)
- `@end_date` - Конечная дата (NULL = без ограничения)
- `@deal_status` - Статус сделки (NULL = все статусы)
- `@deal_type` - Тип сделки (NULL = все типы)
- `@realtor_id` - ID риэлтора (NULL = все риэлторы)
- `@client_id` - ID клиента (NULL = все клиенты)

### Импорт сделок

```sql
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
```

### Импорт с обновлением существующих

```sql
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
```

---

## Формат JSON

### Структура для экспорта/импорта

```json
{
    "deals": [
        {
            "deal_id": 1,                    // Опционально при импорте (автогенерация)
            "property_id": 1,                // Обязательно
            "client_id": 1,                 // Обязательно
            "realtor_id": 1,                 // Опционально (может быть null)
            "deal_type": "Продажа",          // Опционально
            "deal_status": "Завершена",      // Опционально
            "deal_date": "2024-01-15T10:30:00", // Обязательно (ISO 8601)
            "deal_price": 5000000.00         // Обязательно
        }
    ]
}
```

### Формат даты

Дата должна быть в формате ISO 8601:
- `YYYY-MM-DDTHH:mm:ss` (например: `2024-01-15T10:30:00`)
- `YYYY-MM-DDTHH:mm:ss.fff` (с миллисекундами)

---

## Валидация данных

При импорте проверяется:

1. **Валидность JSON** - формат должен быть корректным
2. **Обязательные поля:**
   - `property_id` - должен существовать в таблице `Properties`
   - `client_id` - должен существовать в таблице `Clients`
   - `deal_date` - должна быть валидной датой
   - `deal_price` - должна быть числом
3. **Связанные записи:**
   - `property_id` должен существовать в таблице `Properties`
   - `client_id` должен существовать в таблице `Clients`
   - `realtor_id` (если указан) должен существовать в таблице `Realtors`

**Пропущенные записи:**
- Записи с невалидными данными пропускаются
- Количество пропущенных записей возвращается в параметре `@rows_skipped`

---

## Использование в приложении (C#)

### Экспорт

```csharp
using (var connection = new SqlConnection(connectionString))
{
    connection.Open();
    
    var command = new SqlCommand("sp_ExportDealsToJson", connection);
    command.CommandType = CommandType.StoredProcedure;
    
    var jsonOutput = new SqlParameter("@json_output", SqlDbType.NVarChar, -1)
    {
        Direction = ParameterDirection.Output
    };
    command.Parameters.Add(jsonOutput);
    
    command.ExecuteNonQuery();
    
    string jsonData = jsonOutput.Value?.ToString() ?? "{}";
    
    // Сохранение в файл
    File.WriteAllText("deals_export.json", jsonData, Encoding.UTF8);
}
```

### Импорт

```csharp
string jsonData = File.ReadAllText("deals_import.json", Encoding.UTF8);

using (var connection = new SqlConnection(connectionString))
{
    connection.Open();
    
    var command = new SqlCommand("sp_ImportDealsFromJson", connection);
    command.CommandType = CommandType.StoredProcedure;
    
    command.Parameters.Add("@json_input", SqlDbType.NVarChar, -1).Value = jsonData;
    
    var rowsImported = new SqlParameter("@rows_imported", SqlDbType.Int)
    {
        Direction = ParameterDirection.Output
    };
    command.Parameters.Add(rowsImported);
    
    var rowsSkipped = new SqlParameter("@rows_skipped", SqlDbType.Int)
    {
        Direction = ParameterDirection.Output
    };
    command.Parameters.Add(rowsSkipped);
    
    var errorMessage = new SqlParameter("@error_message", SqlDbType.NVarChar, -1)
    {
        Direction = ParameterDirection.Output
    };
    command.Parameters.Add(errorMessage);
    
    command.ExecuteNonQuery();
    
    int imported = (int)rowsImported.Value;
    int skipped = (int)rowsSkipped.Value;
    string error = errorMessage.Value?.ToString();
    
    Console.WriteLine($"Импортировано: {imported}, Пропущено: {skipped}");
    if (!string.IsNullOrEmpty(error))
        Console.WriteLine($"Ошибка: {error}");
}
```

---

## Обработка ошибок

Все процедуры импорта возвращают:
- `@rows_imported` - количество успешно импортированных записей
- `@rows_skipped` - количество пропущенных записей (невалидные данные)
- `@error_message` - сообщение об ошибке (NULL если ошибок нет)

**Типичные ошибки:**
- `"Неверный формат JSON"` - JSON невалиден
- Ошибки транзакций - откат всех изменений при ошибке

---

## Производительность

- **Экспорт:** Быстрый, использует `FOR JSON PATH`
- **Импорт:** Использует транзакции для целостности данных
- **Большие объемы:** Рекомендуется импортировать пакетами по 1000-10000 записей

---

## Дополнительные примеры

См. файл `09_Deals_JSON_Usage_Examples.sql` для подробных примеров использования.

---

## Примечания

1. Процедуры не интегрированы в логику приложения - используются только через прямые вызовы
2. Для записи в файл используйте приложение или утилиту BCP
3. Все операции импорта выполняются в транзакциях для обеспечения целостности данных
4. При импорте `deal_id` генерируется автоматически (если не указан в JSON)

