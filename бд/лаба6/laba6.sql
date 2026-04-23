--docker exec -it oracle-xe bash

--sqlplus / as sysdba



SHOW PARAMETER SPFILE;


CREATE PFILE='/tmp/PAA_PFILE.ORA' FROM SPFILE;

--docker exec -it oracle-xe bash
--cat /tmp/PAA_PFILE.ORA
--sed -i 's/*.open_cursors=.*/*.open_cursors=400/' /tmp/PAA_PFILE.ORA
--sqlplus / as sysdba

shutdown immediate;
CREATE SPFILE FROM PFILE='/tmp/PAA_PFILE.ORA';
STARTUP;
--консоль до сюда

-- Проверка:
SHOW PARAMETER open_cursors;

ALTER SYSTEM SET open_cursors=300 SCOPE=BOTH;

SHOW PARAMETER control_files;

ALTER DATABASE BACKUP CONTROLFILE TO TRACE;

SELECT * FROM v$pwfile_users;

--host ls -l /opt/oracle/dbs/orapwXE

SELECT name, value FROM v$diag_info;


ALTER SYSTEM SWITCH LOGFILE;


--host tail -n 100 /opt/oracle/diag/rdbms/xe/XE/alert/log.xml
--host cat /opt/oracle/diag/rdbms/xe/XE/trace/XE_ora_442.trc