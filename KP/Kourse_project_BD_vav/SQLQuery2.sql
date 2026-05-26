

-- =====================================================
-- Проверка наличия таблиц
-- =====================================================
SELECT 
    TABLE_NAME,
    (SELECT COUNT(*) FROM sys.tables t WHERE t.name = TABLE_NAME) as table_exists
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- =====================================================
-- Комментарии к таблицам (через sp_addextendedproperty)
-- =====================================================

EXEC sp_addextendedproperty 
    @name = N'MS_Description', @value = N'Таблица резервирований объектов недвижимости для просмотра',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'PropertyReservations';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', @value = N'Уникальный идентификатор резервирования',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'PropertyReservations',
    @level2type = N'COLUMN', @level2name = N'reservation_id';

-- =====================================================
-- Выборка данных
-- =====================================================
-- SELECT * FROM Users;
-- SELECT * FROM Clients;
