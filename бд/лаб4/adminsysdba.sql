--sys
SELECT tablespace_name, status, contents FROM dba_tablespaces;



CREATE TABLESPACE PAA_QDATA 
DATAFILE 'PAA_qdata.dbf' SIZE 10M 
OFFLINE;


ALTER TABLESPACE PAA_QDATA ONLINE;


ALTER USER PAA QUOTA 5M ON PAA_QDATA;

-- PAA
CREATE TABLE PAA_T1 (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50)
) TABLESPACE PAA_QDATA;

-- Добавление 3 строк
INSERT INTO PAA_T1 VALUES (1, 'Row 1');
INSERT INTO PAA_T1 VALUES (2, 'Row 2');
INSERT INTO PAA_T1 VALUES (3, 'Row 3');
COMMIT;

select * from PAA_T1

--sys
SELECT segment_name, segment_type, bytes 
FROM dba_segments 
WHERE tablespace_name = 'PAA_QDATA';

--PAA
DROP TABLE PAA_T1;

-- sys
SELECT segment_name, segment_type FROM dba_segments WHERE tablespace_name = 'PAA_QDATA';

-- PAA
SELECT object_name, original_name, type, droptime FROM user_recyclebin;


FLASHBACK TABLE PAA_T1 TO BEFORE DROP;


BEGIN
    FOR i IN 4..10003 LOOP
        INSERT INTO PAA_T1 (id, name) VALUES (i, 'Name ' || i);
    END LOOP;
    COMMIT;
END;
/

--sys
SELECT extent_id, bytes, blocks 
FROM dba_extents 
WHERE segment_name = 'PAA_T1' AND owner = 'PAA';

-- Итоговое кол-во и размер:
SELECT COUNT(*) as extent_count, SUM(blocks) as total_blocks, SUM(bytes) as total_bytes
FROM dba_extents 
WHERE segment_name = 'PAA_T1' AND owner = 'PAA';



SELECT owner, segment_name, extent_id, bytes 
FROM dba_extents;

--PAA
SELECT ROWID, id, name FROM PAA_T1 WHERE id <= 5;


SELECT ORA_ROWSCN, id, name FROM PAA_T1;



CREATE TABLE PAA_T2 ROWDEPENDENCIES 
tablespace PAA_QDATA
AS SELECT * FROM PAA_T1;


UPDATE PAA_T2 SET name = 'Changed 1' WHERE id = 1;
UPDATE PAA_T2 SET name = 'Changed 2' WHERE id = 2;
COMMIT;

-- Проверка 
SELECT ORA_ROWSCN, id FROM PAA_T2 WHERE id <=5;


-- Сначала закройте сессии, если они используют это пространство sys
DROP TABLESPACE PAA_QDATA INCLUDING CONTENTS AND DATAFILES;