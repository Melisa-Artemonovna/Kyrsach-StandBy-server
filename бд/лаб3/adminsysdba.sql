-- Проверка текущего контейнера (должен быть CDB$ROOT)
SHOW CON_NAME;

--1-------------------------------------------
SELECT name, open_mode, restricted FROM v$pdbs;
-----------------------------------------------
--в cmd
--docker ps 
--docker exec -it oracle-xe bash
--dbca -silent -createPluggableDatabase -sourceDB ORA12W -pdbName PAA_PDB -createPDBFrom DEFAULT -pdbAdminPassword "Pa$$w0rd123"

--3-----
SELECT name, open_mode FROM v$pdbs;
-----


--7
ALTER SESSION SET CONTAINER = CDB$ROOT;


CREATE USER C##PAA IDENTIFIED BY "12345" CONTAINER=ALL;

GRANT CREATE SESSION TO C##PAA CONTAINER=ALL;

--8
GRANT CREATE TABLE TO C##PAA CONTAINER=ALL;

ALTER USER C##PAA DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS CONTAINER=ALL;
----


--12
-- 1. Создаем общего пользователя
CREATE USER C##YYY IDENTIFIED BY password CONTAINER=ALL;

-- 2. Даем права на подключение
GRANT CREATE SESSION TO C##YYY CONTAINER=ALL;

-- 3. Разрешаем переключаться на PDB (PAA_PDB)
GRANT SET CONTAINER TO C##YYY CONTAINER=ALL;

-- 4. Даем права на создание таблиц (для выполнения задания)
GRANT CREATE TABLE, UNLIMITED TABLESPACE TO C##YYY CONTAINER=ALL;



SELECT 
    username, 
    machine, 
    program, 
    con_id 
FROM v$session 
WHERE username = 'C##YYY';


SELECT 
    s.username, 
    s.machine, 
    s.program, 
    p.name AS database_name,
    s.type
FROM v$session s
LEFT JOIN v$pdbs p ON s.con_id = p.con_id
WHERE s.username IN ('U1_PAA_PDB', 'C##PAA', 'C##YYY')
ORDER BY s.machine;



SELECT name AS file_path FROM v$datafile WHERE con_id > 2;



ALTER SESSION SET CONTAINER = CDB$ROOT;

ALTER PLUGGABLE DATABASE PAA_PDB CLOSE IMMEDIATE;
DROP PLUGGABLE DATABASE PAA_PDB INCLUDING DATAFILES;

DROP USER C##PAA CASCADE;

