-- Создание ролей в PostgreSQL
-- Выполните этот скрипт от имени суперпользователя (postgres)

-- Создаем роли, если их нет
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_admin_role') THEN
        CREATE ROLE db_admin_role;
        RAISE NOTICE 'Роль db_admin_role создана';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_realtor_role') THEN
        CREATE ROLE db_realtor_role;
        RAISE NOTICE 'Роль db_realtor_role создана';
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_client_role') THEN
        CREATE ROLE db_client_role;
        RAISE NOTICE 'Роль db_client_role создана';
    END IF;
END
$$;

-- Отключаем прямое чтение таблиц для всех ролей
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM db_admin_role;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM db_realtor_role;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM db_client_role;

-- Разрешаем выполнение процедур (будет настроено после создания процедур)
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO db_admin_role;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO db_realtor_role;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO db_client_role;

-- Применяем к будущим таблицам
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM db_admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM db_realtor_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM db_client_role;

SELECT 'Роли созданы. Прямой доступ к таблицам запрещен.' AS status;

