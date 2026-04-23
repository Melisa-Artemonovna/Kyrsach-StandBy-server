--10
CREATE TABLE c_paa_table (id NUMBER, text VARCHAR2(20));
INSERT INTO c_paa_table VALUES (1, 'Common User Insert');
COMMIT;

SELECT * FROM C_PAA_table;

--11
SELECT object_name, object_type FROM user_objects;