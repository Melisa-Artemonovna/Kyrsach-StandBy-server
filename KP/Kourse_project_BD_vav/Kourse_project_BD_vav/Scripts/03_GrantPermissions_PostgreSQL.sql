-- Настройка прав доступа к процедурам для ролей в PostgreSQL
-- Выполните после создания всех процедур

-- =============================================
-- ПРАВА ДЛЯ ADMIN_ROLE (полный доступ ко всем процедурам)
-- =============================================

-- Users
GRANT EXECUTE ON FUNCTION sp_getuserbyid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getuserbyusername(VARCHAR) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getallusers() TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_createuser(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TIMESTAMP WITH TIME ZONE) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_updateuser(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO db_admin_role;

-- Clients
GRANT EXECUTE ON FUNCTION sp_getallclients() TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getclientbyid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getclientbyuserid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_createclient(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_updateclient(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_deleteclient(INTEGER) TO db_admin_role;

-- Realtors
GRANT EXECUTE ON FUNCTION sp_getallrealtors() TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getrealtorbyid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getrealtorbyuserid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_createrealtor(VARCHAR, VARCHAR, VARCHAR, INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_updaterealtor(INTEGER, VARCHAR, VARCHAR, VARCHAR, TIMESTAMP WITH TIME ZONE, NUMERIC) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_deleterealtor(INTEGER) TO db_admin_role;

-- Properties
GRANT EXECUTE ON FUNCTION sp_getallproperties() TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getpropertybyid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getpropertiesbyrealtorid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_createproperty(VARCHAR, VARCHAR, NUMERIC, NUMERIC, TEXT, INTEGER, BOOLEAN, INTEGER, INTEGER, INTEGER, VARCHAR, TEXT) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_updateproperty(INTEGER, VARCHAR, VARCHAR, NUMERIC, NUMERIC, TEXT, INTEGER, BOOLEAN, INTEGER, INTEGER, INTEGER, VARCHAR, TEXT) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_deleteproperty(INTEGER) TO db_admin_role;

-- Deals
GRANT EXECUTE ON FUNCTION sp_getalldeals() TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getdealbyid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getdealsbyrealtorid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getdealsbyclientid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getrealtordealstats(INTEGER, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_createdeal(INTEGER, INTEGER, INTEGER, VARCHAR, NUMERIC, TIMESTAMP WITH TIME ZONE) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_updatedeal(INTEGER, INTEGER, INTEGER, INTEGER, VARCHAR, NUMERIC, TIMESTAMP WITH TIME ZONE) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_deletedeal(INTEGER) TO db_admin_role;

-- PropertyReservations
GRANT EXECUTE ON FUNCTION sp_getallpropertyreservations() TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getpropertyreservationbyid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getpropertyreservationsbyrealtorid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getpropertyreservationsbyclientid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_checkactivereservation(INTEGER, INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_createpropertyreservation(INTEGER, INTEGER, INTEGER, TIMESTAMP, TIMESTAMP, VARCHAR) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_updatepropertyreservation(INTEGER, VARCHAR, TIMESTAMP) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_deletepropertyreservation(INTEGER) TO db_admin_role;

-- Contracts
GRANT EXECUTE ON FUNCTION sp_getallcontracts() TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getcontractbyid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_getcontractsbydealid(INTEGER) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_createcontract(INTEGER, TIMESTAMP WITH TIME ZONE, VARCHAR, TEXT) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_updatecontract(INTEGER, TIMESTAMP WITH TIME ZONE, VARCHAR, TEXT) TO db_admin_role;
GRANT EXECUTE ON FUNCTION sp_deletecontract(INTEGER) TO db_admin_role;

-- =============================================
-- ПРАВА ДЛЯ REALTOR_ROLE
-- =============================================

-- Users (только свой профиль)
GRANT EXECUTE ON FUNCTION sp_getuserbyid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_getuserbyusername(VARCHAR) TO db_realtor_role;

-- Clients (чтение и создание)
GRANT EXECUTE ON FUNCTION sp_getallclients() TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_getclientbyid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_createclient(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_updateclient(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO db_realtor_role;

-- Realtors (только свой профиль)
GRANT EXECUTE ON FUNCTION sp_getrealtorbyid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_getrealtorbyuserid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_updaterealtor(INTEGER, VARCHAR, VARCHAR, VARCHAR) TO db_realtor_role;

-- Properties (свои объекты)
GRANT EXECUTE ON FUNCTION sp_getallproperties() TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_getpropertybyid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_getpropertiesbyrealtorid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_createproperty(VARCHAR, VARCHAR, NUMERIC, NUMERIC, TEXT, INTEGER, BOOLEAN, INTEGER, INTEGER, INTEGER, VARCHAR, TEXT) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_updateproperty(INTEGER, VARCHAR, VARCHAR, NUMERIC, NUMERIC, TEXT, INTEGER, BOOLEAN, INTEGER, INTEGER, INTEGER, VARCHAR, TEXT) TO db_realtor_role;

-- Deals (свои сделки)
GRANT EXECUTE ON FUNCTION sp_getdealsbyrealtorid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_getdealbyid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_getrealtordealstats(INTEGER, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_createdeal(INTEGER, INTEGER, INTEGER, VARCHAR, NUMERIC, TIMESTAMP WITH TIME ZONE) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_updatedeal(INTEGER, INTEGER, INTEGER, INTEGER, VARCHAR, NUMERIC, TIMESTAMP WITH TIME ZONE) TO db_realtor_role;

-- PropertyReservations (свои резервирования)
GRANT EXECUTE ON FUNCTION sp_getpropertyreservationsbyrealtorid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_getpropertyreservationbyid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_updatepropertyreservation(INTEGER, VARCHAR, TIMESTAMP) TO db_realtor_role;

-- Contracts (контракты по своим сделкам)
GRANT EXECUTE ON FUNCTION sp_getcontractbyid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_getcontractsbydealid(INTEGER) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_createcontract(INTEGER, TIMESTAMP WITH TIME ZONE, VARCHAR, TEXT) TO db_realtor_role;
GRANT EXECUTE ON FUNCTION sp_updatecontract(INTEGER, TIMESTAMP WITH TIME ZONE, VARCHAR, TEXT) TO db_realtor_role;

-- =============================================
-- ПРАВА ДЛЯ CLIENT_ROLE
-- =============================================

-- Users (только свой профиль)
GRANT EXECUTE ON FUNCTION sp_getuserbyid(INTEGER) TO db_client_role;
GRANT EXECUTE ON FUNCTION sp_getuserbyusername(VARCHAR) TO db_client_role;

-- Clients (только свой профиль)
GRANT EXECUTE ON FUNCTION sp_getclientbyid(INTEGER) TO db_client_role;
GRANT EXECUTE ON FUNCTION sp_getclientbyuserid(INTEGER) TO db_client_role;
GRANT EXECUTE ON FUNCTION sp_updateclient(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO db_client_role;

-- Properties (только чтение)
GRANT EXECUTE ON FUNCTION sp_getallproperties() TO db_client_role;
GRANT EXECUTE ON FUNCTION sp_getpropertybyid(INTEGER) TO db_client_role;

-- Deals (только свои сделки)
GRANT EXECUTE ON FUNCTION sp_getdealsbyclientid(INTEGER) TO db_client_role;
GRANT EXECUTE ON FUNCTION sp_getdealbyid(INTEGER) TO db_client_role;

-- PropertyReservations (только свои резервирования)
GRANT EXECUTE ON FUNCTION sp_getpropertyreservationsbyclientid(INTEGER) TO db_client_role;
GRANT EXECUTE ON FUNCTION sp_getpropertyreservationbyid(INTEGER) TO db_client_role;
GRANT EXECUTE ON FUNCTION sp_checkactivereservation(INTEGER, INTEGER) TO db_client_role;
GRANT EXECUTE ON FUNCTION sp_createpropertyreservation(INTEGER, INTEGER, INTEGER, TIMESTAMP, TIMESTAMP, VARCHAR) TO db_client_role;

-- Contracts (контракты по своим сделкам)
GRANT EXECUTE ON FUNCTION sp_getcontractbyid(INTEGER) TO db_client_role;
GRANT EXECUTE ON FUNCTION sp_getcontractsbydealid(INTEGER) TO db_client_role;

SELECT 'Права доступа к процедурам настроены' AS status;

