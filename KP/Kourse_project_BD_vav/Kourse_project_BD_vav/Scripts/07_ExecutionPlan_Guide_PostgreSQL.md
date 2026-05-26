# Анализ плана выполнения (PostgreSQL)

## Цель
- Зафиксировать время и план выполнения запросов по таблице `deals` до и после индексации.

## Что запускать
- `05_GenerateTestData_Deals_PostgreSQL.sql` — генерация 100000 строк.
- `06_PerformanceTest_Deals_PostgreSQL.sql` — прогоны `EXPLAIN (ANALYZE, BUFFERS)`.

## Как читать вывод EXPLAIN ANALYZE
- `Execution Time` — итоговое время выполнения.
- `Seq Scan` — полный скан таблицы (обычно хуже на больших объемах).
- `Index Scan` / `Bitmap Index Scan` — использование индекса.
- `Rows Removed by Filter` — сколько строк отсеяли фильтры.
- `Buffers` — работа с буферами (косвенно показывает I/O нагрузку).

## Что должно измениться после индексов
- По фильтрам `client_id`, `realtor_id`, `deal_date` и `(deal_status, deal_date)`:
  - вместо `Seq Scan` должен появиться `Index Scan`/`Bitmap Index Scan`;
  - `Execution Time` должен снизиться.

## Шаблон отчета в пояснительную записку
1. Объем данных: `100000` строк в `deals`.
2. Запрос: `<текст запроса>`.
3. До индекса: `<Execution Time>`, план: `<Seq Scan/...>`.
4. После индекса: `<Execution Time>`, план: `<Index Scan/...>`.
5. Вывод: ускорение `<X>` раз, индекс `<имя>` признан эффективным.
