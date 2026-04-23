--5-----------------
CREATE TABLE PAA_table (
    id NUMBER PRIMARY KEY,
    info VARCHAR2(100)
);

INSERT INTO PAA_table VALUES (1, 'Тест PAA 1');
INSERT INTO PAA_table VALUES (2, 'Тест PAA 2');
COMMIT;

SELECT * FROM PAA_table;

--11
SELECT object_name, object_type FROM user_objects;