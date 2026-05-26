# Миграция на хранимые процедуры

## Шаги выполнения

### 1. Создание ролей в БД
Выполните скрипты в следующем порядке:

**MSSQL:**
1. `Scripts/01_CreateRoles_MSSQL.sql` - создание ролей
2. `Scripts/02_CreateStoredProcedures_MSSQL.sql` - создание процедур
3. `Scripts/03_GrantPermissions_MSSQL.sql` - настройка прав доступа

**PostgreSQL:**
1. `Scripts/01_CreateRoles_PostgreSQL.sql` - создание ролей
2. `Scripts/02_CreateStoredProcedures_PostgreSQL.sql` - создание процедур
3. `Scripts/03_GrantPermissions_PostgreSQL.sql` - настройка прав доступа
4. `Scripts/04_SetupDatabaseUsers_PostgreSQL.sql` - создание пользователей БД (опционально)

**MSSQL:**
1. `Scripts/01_CreateRoles_MSSQL.sql` - создание ролей
2. `Scripts/02_CreateStoredProcedures_MSSQL.sql` - создание процедур
3. `Scripts/03_GrantPermissions_MSSQL.sql` - настройка прав доступа
4. `Scripts/04_SetupDatabaseUsers_MSSQL.sql` - создание пользователей БД (опционально)

### 2. Настройка подключений с ролями
В `appsettings.json` обновите строки подключения для использования ролей:

```json
{
  "ConnectionStrings": {
    "MssqlConnection": "Server=...;Database=...;User Id=app_user;Password=...;",
    "PgConnection": "Host=...;Database=...;Username=app_user;Password=..."
  }
}
```

**ВАЖНО:** 
- Все процедуры PostgreSQL исправлены для соответствия реальной структуре таблиц
- Процедуры для Realtors используют `hire_date` и `commission_rate` вместо несуществующих полей
- Прямой доступ к таблицам запрещен для всех ролей - доступ только через процедуры
- Выполните скрипт `04_SetupDatabaseUsers_*.sql` для создания пользователей БД с соответствующими ролями

### 3. Использование в коде
Все контроллеры должны использовать `StoredProcedureService` вместо прямых запросов к `DbContext`.

Пример:
```csharp
// Старый способ (НЕ ИСПОЛЬЗОВАТЬ):
var properties = await _context.Properties.ToListAsync();

// Новый способ:
var properties = await _spService.GetAllPropertiesAsync();
```

### 4. Статус миграции
- [x] StoredProcedureService создан и исправлен
- [x] PropertyController - переписан на процедуры
- [x] ClientController - переписан на процедуры
- [x] DealController - переписан на процедуры
- [x] PropertyReservationController - переписан на процедуры
- [x] HomeController - переписан на процедуры
- [x] AccountController - переписан на процедуры
- [ ] SyncService - требует переписывания (опционально)

## Важно
- ✅ Все SELECT запросы заменены на вызовы процедур
- ✅ Прямой доступ к таблицам через DbSet запрещен
- ✅ Права доступа ролей настроены в скриптах
- ✅ Процедуры PostgreSQL исправлены для соответствия структуре таблиц
- ✅ Исправлены ошибки с несуществующими полями (license_number → hire_date, commission_rate)

## Исправления для PostgreSQL
- Процедуры для Realtors обновлены: используются `hire_date` и `commission_rate` вместо `license_number` и `registration_date`
- Все процедуры соответствуют реальной структуре таблиц из миграций
- Права доступа настроены корректно для всех ролей

## Использование ролей
По умолчанию приложение использует MSSQL. Для переключения на PostgreSQL измените параметр `usePostgres` в вызовах `StoredProcedureService` (по умолчанию `false`).

Пример:
```csharp
// Использование MSSQL (по умолчанию)
var properties = await _spService.GetAllPropertiesAsync();

// Использование PostgreSQL
var properties = await _spService.GetAllPropertiesAsync(usePostgres: true);
```

