-- Тест производительности запросов к deals в PostgreSQL
-- Сценарий:
-- 1) Прогон EXPLAIN ANALYZE без индексов
-- 2) Создание индексов
-- 3) Повторный прогон EXPLAIN ANALYZE

-- ========= ЭТАП 1: удалить индексы (если есть) =========
DROP INDEX IF EXISTS ix_deals_property_id_perf;
DROP INDEX IF EXISTS ix_deals_client_id_perf;
DROP INDEX IF EXISTS ix_deals_realtor_id_perf;
DROP INDEX IF EXISTS ix_deals_deal_date_perf;
DROP INDEX IF EXISTS ix_deals_status_date_perf;

-- ANALYZE можно выполнять в транзакции; VACUUM — нет.
ANALYZE deals;

-- ========= ЭТАП 2: тесты БЕЗ индексов =========
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM deals WHERE client_id = 10;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM deals WHERE realtor_id = 10;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM deals WHERE deal_date >= CURRENT_DATE - INTERVAL '30 days';

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM deals WHERE deal_status = 'Завершена' AND deal_date >= CURRENT_DATE - INTERVAL '1 year';

-- ========= ЭТАП 3: создать индексы =========
CREATE INDEX IF NOT EXISTS ix_deals_property_id_perf ON deals(property_id);
CREATE INDEX IF NOT EXISTS ix_deals_client_id_perf ON deals(client_id);
CREATE INDEX IF NOT EXISTS ix_deals_realtor_id_perf ON deals(realtor_id);
CREATE INDEX IF NOT EXISTS ix_deals_deal_date_perf ON deals(deal_date);
CREATE INDEX IF NOT EXISTS ix_deals_status_date_perf ON deals(deal_status, deal_date);

ANALYZE deals;

-- ========= ЭТАП 4: тесты С индексами =========
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM deals WHERE client_id = 10;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM deals WHERE realtor_id = 10;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM deals WHERE deal_date >= CURRENT_DATE - INTERVAL '30 days';

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM deals WHERE deal_status = 'Завершена' AND deal_date >= CURRENT_DATE - INTERVAL '1 year';
