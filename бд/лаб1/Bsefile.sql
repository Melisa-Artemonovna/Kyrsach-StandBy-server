-- 10. Создание таблицы XXX_t
CREATE TABLE XXX_t (
    id NUMBER(3) CONSTRAINT pk_xxx_t PRIMARY KEY,
    name VARCHAR2(50)
);


-- 12. Добавление 3 строк (INSERT) и фиксация транзакции (COMMIT)
INSERT INTO XXX_t (id, name) VALUES (1, 'Первая строка');
INSERT INTO XXX_t (id, name) VALUES (2, 'Вторая строка');
INSERT INTO XXX_t (id, name) VALUES (3, 'Третья строка');
COMMIT;

-- 13. Изменение 2 строк (UPDATE) и фиксация транзакции (COMMIT)
UPDATE XXX_t 
SET name = 'Обновленная строка' 
WHERE id IN (1, 2);
COMMIT;


-- 14. Выборка данных (SELECT)
SELECT * FROM XXX_t WHERE id >= 2;

-- Применение агрегатных функций (подсчет количества и максимальный ID)
SELECT COUNT(*) AS total_rows, MAX(id) AS max_id FROM XXX_t;


-- 15. Удаление 1 строки (DELETE) и отмена транзакции (ROLLBACK)
DELETE FROM XXX_t WHERE id = 3;
-- Строка удалена, но теперь мы отменяем это действие:
ROLLBACK;
-- Проверка, что 3-я строка осталась в таблице:
SELECT * FROM XXX_t;


-- 16. Создание подчиненной таблицы (XXX_t_child) и добавление данных
CREATE TABLE XXX_t_child (
    child_id NUMBER(3) CONSTRAINT pk_xxx_t_child PRIMARY KEY,
    parent_id NUMBER(3),
    description VARCHAR2(50),
    CONSTRAINT fk_xxx_parent FOREIGN KEY (parent_id) REFERENCES XXX_t(id)
);

INSERT INTO XXX_t_child (child_id, parent_id, description) VALUES (101, 1, 'Деталь для первой строки');
INSERT INTO XXX_t_child (child_id, parent_id, description) VALUES (102, 2, 'Деталь для второй строки');
INSERT INTO XXX_t_child (child_id, parent_id, description) VALUES (103, 1, 'Вторая деталь для 1 строки');
COMMIT;


-- 17. Выборка из обеих таблиц (JOIN)
-- Внутреннее соединение (INNER JOIN)
SELECT p.id, p.name, c.child_id, c.description
FROM XXX_t p
INNER JOIN XXX_t_child c ON p.id = c.parent_id;

-- Левое соединение (LEFT JOIN) - покажет все строки из XXX_t, даже если у них нет дочерних записей (например, id = 3)
SELECT p.id, p.name, c.child_id, c.description
FROM XXX_t p
LEFT JOIN XXX_t_child c ON p.id = c.parent_id;


-- 18. Удаление таблиц (DROP)
-- DROP TABLE XXX_t_child;
-- DROP TABLE XXX_t;