# Инструкция по просмотру плана выполнения запросов в MSSQL

## Содержание
1. [Методы просмотра плана выполнения](#методы-просмотра-плана-выполнения)
2. [Использование SQL Server Management Studio (SSMS)](#использование-sql-server-management-studio-ssms)
3. [Использование T-SQL команд](#использование-t-sql-команд)
4. [Анализ плана выполнения](#анализ-плана-выполнения)
5. [Сравнение планов с индексами и без](#сравнение-планов-с-индексами-и-без)

---

## Методы просмотра плана выполнения

В SQL Server есть несколько способов получить план выполнения запроса:

### 1. Графический план выполнения (рекомендуется)
- Самый наглядный способ
- Показывает визуальное дерево операций
- Позволяет увидеть стоимость каждой операции

### 2. Текстовый план выполнения
- Используется через T-SQL команды
- Удобен для автоматизации и скриптов

### 3. XML план выполнения
- Детальная информация в XML формате
- Можно сохранить и проанализировать позже

---

## Использование SQL Server Management Studio (SSMS)

### Способ 1: Включить "Include Actual Execution Plan"

1. **Откройте SQL Server Management Studio (SSMS)**

2. **Подключитесь к вашей базе данных**

3. **Включите отображение плана выполнения:**
   - Нажмите кнопку **"Include Actual Execution Plan"** на панели инструментов
   - Или используйте горячую клавишу: **Ctrl + M**
   - Или в меню: **Query → Include Actual Execution Plan**

   ![Кнопка включения плана выполнения]

4. **Выполните ваш запрос:**
   ```sql
   SELECT COUNT(*) 
   FROM Deals 
   WHERE property_id = 1;
   ```

5. **Просмотрите план выполнения:**
   - После выполнения запроса откройте вкладку **"Execution Plan"**
   - Вы увидите графическое дерево операций

### Способ 2: "Display Estimated Execution Plan"

1. **Включите отображение предполагаемого плана:**
   - Нажмите кнопку **"Display Estimated Execution Plan"**
   - Или используйте горячую клавишу: **Ctrl + L**
   - Или в меню: **Query → Display Estimated Execution Plan**

2. **Выполните запрос** (запрос не будет реально выполняться, только планирование)

3. **Просмотрите предполагаемый план**

### Анализ плана выполнения в SSMS

#### Основные элементы плана:

1. **Операторы (Operators):**
   - **Table Scan** - полное сканирование таблицы (медленно, без индекса)
   - **Index Seek** - поиск по индексу (быстро, с индексом)
   - **Index Scan** - сканирование индекса
   - **Key Lookup** - поиск данных по ключу
   - **Sort** - сортировка данных
   - **Hash Match** - соединение таблиц через хеш

2. **Процент стоимости:**
   - Каждая операция показывает процент от общей стоимости запроса
   - Операции с высокой стоимостью - узкие места

3. **Количество строк:**
   - Показывает, сколько строк обрабатывается на каждом этапе

4. **Подсказки при наведении:**
   - Наведите курсор на оператор для детальной информации
   - Увидите:
     - Estimated Number of Rows (предполагаемое количество строк)
     - Estimated I/O Cost (стоимость ввода/вывода)
     - Estimated CPU Cost (стоимость CPU)
     - Estimated Operator Cost (общая стоимость оператора)

#### Пример анализа:

**БЕЗ ИНДЕКСА:**
```
Table Scan (100%)
  - Estimated Number of Rows: 100000
  - Estimated I/O Cost: 100.0
  - Estimated CPU Cost: 50.0
  - Estimated Operator Cost: 150.0 (100%)
```

**С ИНДЕКСОМ:**
```
Index Seek (5%)
  - Estimated Number of Rows: 100
  - Estimated I/O Cost: 0.5
  - Estimated CPU Cost: 0.1
  - Estimated Operator Cost: 0.6 (5%)
```

---

## Использование T-SQL команд

### 1. SET SHOWPLAN_TEXT ON (текстовый план)

```sql
-- Включить текстовый план
SET SHOWPLAN_TEXT ON;
GO

-- Ваш запрос
SELECT COUNT(*) 
FROM Deals 
WHERE property_id = 1;
GO

-- Выключить
SET SHOWPLAN_TEXT OFF;
GO
```

**Результат:** Текстовое дерево операций

### 2. SET SHOWPLAN_ALL ON (детальный текстовый план)

```sql
SET SHOWPLAN_ALL ON;
GO

SELECT COUNT(*) 
FROM Deals 
WHERE property_id = 1;
GO

SET SHOWPLAN_ALL OFF;
GO
```

**Результат:** Детальная таблица с метриками

### 3. SET STATISTICS PROFILE ON (реальный план с данными)

```sql
SET STATISTICS PROFILE ON;
GO

SELECT COUNT(*) 
FROM Deals 
WHERE property_id = 1;
GO

SET STATISTICS PROFILE OFF;
GO
```

**Результат:** План выполнения + фактические данные о выполнении

### 4. XML план выполнения

```sql
-- Получить XML план
SET STATISTICS XML ON;
GO

SELECT COUNT(*) 
FROM Deals 
WHERE property_id = 1;
GO

SET STATISTICS XML OFF;
GO
```

**Результат:** XML документ с планом выполнения

### 5. Сохранение плана в файл

```sql
-- В SSMS: Query → Include Actual Execution Plan
-- После выполнения: правый клик на плане → "Save Execution Plan As..."
-- Сохраните как .sqlplan файл
```

---

## Анализ плана выполнения

### Ключевые метрики для сравнения:

1. **Estimated Operator Cost** - стоимость оператора
   - Чем меньше, тем лучше
   - Сравните общую стоимость запроса

2. **Estimated Number of Rows** - количество обрабатываемых строк
   - Меньше строк = быстрее выполнение

3. **Estimated I/O Cost** - стоимость операций ввода/вывода
   - Основной фактор производительности
   - Индексы значительно снижают I/O

4. **Estimated CPU Cost** - стоимость CPU операций
   - Обычно меньше, чем I/O

5. **Estimated Subtree Cost** - общая стоимость поддерева
   - Суммарная стоимость всех операций

### Что искать в плане:

#### ✅ Хорошие признаки (с индексами):
- **Index Seek** вместо Table Scan
- Низкая стоимость операций (< 10%)
- Малое количество обрабатываемых строк
- Отсутствие предупреждений (желтые значки)

#### ❌ Плохие признаки (без индексов):
- **Table Scan** или **Clustered Index Scan**
- Высокая стоимость операций (> 50%)
- Большое количество обрабатываемых строк (все строки таблицы)
- Предупреждения о недостающих индексах

---

## Сравнение планов с индексами и без

### Практический пример:

#### ШАГ 1: План БЕЗ индексов

```sql
-- Убедитесь, что индексы удалены
DROP INDEX IF EXISTS IX_Deals_property_id ON Deals;

-- Включите план выполнения
SET STATISTICS XML ON;
GO

-- Выполните запрос
SELECT COUNT(*) 
FROM Deals 
WHERE property_id = 1;
GO

SET STATISTICS XML OFF;
GO
```

**Ожидаемый результат:**
- Оператор: **Clustered Index Scan** или **Table Scan**
- Estimated Number of Rows: **100000** (все строки)
- Estimated Operator Cost: **высокая** (> 100)
- Estimated I/O Cost: **высокая**

#### ШАГ 2: Создайте индекс

```sql
CREATE NONCLUSTERED INDEX IX_Deals_property_id 
ON Deals(property_id);
GO

-- Обновите статистику
UPDATE STATISTICS Deals;
GO
```

#### ШАГ 3: План С индексами

```sql
-- Очистите кэш
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

-- Включите план выполнения
SET STATISTICS XML ON;
GO

-- Выполните тот же запрос
SELECT COUNT(*) 
FROM Deals 
WHERE property_id = 1;
GO

SET STATISTICS XML OFF;
GO
```

**Ожидаемый результат:**
- Оператор: **Index Seek**
- Estimated Number of Rows: **малое** (только совпадающие)
- Estimated Operator Cost: **низкая** (< 1)
- Estimated I/O Cost: **низкая**

### Автоматическое сравнение через скрипт:

```sql
-- Сравнение стоимости запросов
DECLARE @CostWithoutIndex FLOAT;
DECLARE @CostWithIndex FLOAT;

-- Без индекса
SET SHOWPLAN_ALL ON;
GO
SELECT COUNT(*) FROM Deals WHERE property_id = 1;
GO
SET SHOWPLAN_ALL OFF;
GO
-- Запишите значение EstimatedTotalSubtreeCost

-- С индексом
SET SHOWPLAN_ALL ON;
GO
SELECT COUNT(*) FROM Deals WHERE property_id = 1;
GO
SET SHOWPLAN_ALL OFF;
GO
-- Сравните значения
```

---

## Полезные команды для анализа

### Просмотр всех индексов таблицы:

```sql
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Deals')
ORDER BY i.name, ic.key_ordinal;
```

### Просмотр статистики использования индексов:

```sql
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks AS Seeks,
    s.user_scans AS Scans,
    s.user_lookups AS Lookups,
    s.user_updates AS Updates
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE OBJECT_NAME(s.object_id) = 'Deals'
ORDER BY s.user_seeks + s.user_scans DESC;
```

### Просмотр фрагментации индексов:

```sql
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS Fragmentation,
    ips.page_count AS PageCount
FROM sys.dm_db_index_physical_stats(
    DB_ID(), 
    OBJECT_ID('Deals'), 
    NULL, 
    NULL, 
    'DETAILED'
) ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
ORDER BY ips.avg_fragmentation_in_percent DESC;
```

---

## Рекомендации

1. **Всегда смотрите план выполнения** перед оптимизацией запросов
2. **Сравнивайте планы** до и после создания индексов
3. **Обращайте внимание на предупреждения** (желтые значки в SSMS)
4. **Используйте реальный план выполнения** (Actual Execution Plan) для точных метрик
5. **Обновляйте статистику** после создания индексов: `UPDATE STATISTICS Deals;`

---

## Дополнительные ресурсы

- [Microsoft Docs: Execution Plans](https://docs.microsoft.com/en-us/sql/relational-databases/performance/execution-plans)
- [SQL Server Execution Plan Analysis](https://www.sqlshack.com/execution-plan-analysis-in-sql-server/)

