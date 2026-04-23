-- 4
CREATE TABLESPACE PAA_TS 
DATAFILE 'paa_ts_01.dbf' SIZE 100M AUTOEXTEND ON NEXT 10M;


CREATE PROFILE PAA_PROFILE LIMIT 
  FAILED_LOGIN_ATTEMPTS 3 
  PASSWORD_LIFE_TIME UNLIMITED;


CREATE ROLE PAA_ROLE;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO PAA_ROLE;


CREATE USER U1_PAA_PDB IDENTIFIED BY "Pa$$123" 
  DEFAULT TABLESPACE PAA_TS 
  PROFILE PAA_PROFILE 
  QUOTA UNLIMITED ON PAA_TS;

GRANT PAA_ROLE TO U1_PAA_PDB;
-----------



---6
SELECT tablespace_name, contents, status FROM dba_tablespaces;

SELECT file_name, tablespace_name FROM dba_data_files;

SELECT file_name, tablespace_name FROM dba_temp_files;

SELECT role FROM dba_roles WHERE role LIKE '%PAA%';

SELECT privilege FROM role_sys_privs WHERE role = 'PAA_ROLE';

SELECT DISTINCT profile FROM dba_profiles WHERE profile LIKE '%PAA%';

SELECT username, account_status, profile FROM dba_users WHERE username LIKE '%PAA%';

SELECT granted_role FROM dba_role_privs WHERE grantee = 'U1_PAA_PDB';


