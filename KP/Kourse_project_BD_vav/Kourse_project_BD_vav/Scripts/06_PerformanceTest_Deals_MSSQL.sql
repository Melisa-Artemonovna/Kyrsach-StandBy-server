-- Тестирование производительности поиска

-- Удаляем индексы
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Deals_property_id' AND object_id = OBJECT_ID('Deals'))
    DROP INDEX IX_Deals_property_id ON Deals;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Deals_client_id' AND object_id = OBJECT_ID('Deals'))
    DROP INDEX IX_Deals_client_id ON Deals;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Deals_realtor_id' AND object_id = OBJECT_ID('Deals'))
    DROP INDEX IX_Deals_realtor_id ON Deals;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Deals_deal_date' AND object_id = OBJECT_ID('Deals'))
    DROP INDEX IX_Deals_deal_date ON Deals;

DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

-- Тест 1: Без индексов
DECLARE @test_id INT, @start DATETIME, @dur1 INT, @dur2 INT;

SELECT TOP 1 @test_id = property_id FROM Deals ORDER BY NEWID();
SET @start = GETDATE();
SELECT COUNT(*) FROM Deals WHERE property_id = @test_id;
SET @dur1 = DATEDIFF(MILLISECOND, @start, GETDATE());

SELECT TOP 1 @test_id = client_id FROM Deals ORDER BY NEWID();
SET @start = GETDATE();
SELECT COUNT(*) FROM Deals WHERE client_id = @test_id;
SET @dur2 = DATEDIFF(MILLISECOND, @start, GETDATE());

-- Создаем индексы
CREATE INDEX IX_Deals_property_id ON Deals(property_id);
CREATE INDEX IX_Deals_client_id ON Deals(client_id);
CREATE INDEX IX_Deals_realtor_id ON Deals(realtor_id);
CREATE INDEX IX_Deals_deal_date ON Deals(deal_date);

UPDATE STATISTICS Deals;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

-- Тест 2: С индексами
SELECT TOP 1 @test_id = property_id FROM Deals ORDER BY NEWID();
SET @start = GETDATE();
SELECT COUNT(*) FROM Deals WHERE property_id = @test_id;
SET @dur2 = DATEDIFF(MILLISECOND, @start, GETDATE());

SELECT TOP 1 @test_id = client_id FROM Deals ORDER BY NEWID();
SET @start = GETDATE();
SELECT COUNT(*) FROM Deals WHERE client_id = @test_id;
SET @dur2 = DATEDIFF(MILLISECOND, @start, GETDATE());

-- Результаты
PRINT 'property_id: ' + CAST(@dur1 AS VARCHAR) + ' мс без индекса, ' + CAST(@dur2 AS VARCHAR) + ' мс с индексом';