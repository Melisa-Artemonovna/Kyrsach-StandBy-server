-- Настройка прав доступа к процедурам для ролей в MSSQL
-- Выполните после создания всех процедур

-- =============================================
-- ПРАВА ДЛЯ ADMIN_ROLE (полный доступ ко всем процедурам)
-- =============================================

-- Users
GRANT EXECUTE ON sp_GetUserById TO db_admin_role;
GRANT EXECUTE ON sp_GetUserByUsername TO db_admin_role;
GRANT EXECUTE ON sp_GetAllUsers TO db_admin_role;
GRANT EXECUTE ON sp_CreateUser TO db_admin_role;
GRANT EXECUTE ON sp_UpdateUser TO db_admin_role;

-- Clients
GRANT EXECUTE ON sp_GetAllClients TO db_admin_role;
GRANT EXECUTE ON sp_GetClientById TO db_admin_role;
GRANT EXECUTE ON sp_GetClientByUserId TO db_admin_role;
GRANT EXECUTE ON sp_CreateClient TO db_admin_role;
GRANT EXECUTE ON sp_UpdateClient TO db_admin_role;
GRANT EXECUTE ON sp_DeleteClient TO db_admin_role;

-- Realtors
GRANT EXECUTE ON sp_GetAllRealtors TO db_admin_role;
GRANT EXECUTE ON sp_GetRealtorById TO db_admin_role;
GRANT EXECUTE ON sp_GetRealtorByUserId TO db_admin_role;
GRANT EXECUTE ON sp_CreateRealtor TO db_admin_role;
GRANT EXECUTE ON sp_UpdateRealtor TO db_admin_role;
GRANT EXECUTE ON sp_DeleteRealtor TO db_admin_role;

-- Properties
GRANT EXECUTE ON sp_GetAllProperties TO db_admin_role;
GRANT EXECUTE ON sp_GetPropertyById TO db_admin_role;
GRANT EXECUTE ON sp_GetPropertiesByRealtorId TO db_admin_role;
GRANT EXECUTE ON sp_CreateProperty TO db_admin_role;
GRANT EXECUTE ON sp_UpdateProperty TO db_admin_role;
GRANT EXECUTE ON sp_DeleteProperty TO db_admin_role;

-- Deals
GRANT EXECUTE ON sp_GetAllDeals TO db_admin_role;
GRANT EXECUTE ON sp_GetDealById TO db_admin_role;
GRANT EXECUTE ON sp_GetDealsByRealtorId TO db_admin_role;
GRANT EXECUTE ON sp_GetDealsByClientId TO db_admin_role;
GRANT EXECUTE ON sp_GetRealtorDealStats TO db_admin_role;
GRANT EXECUTE ON sp_CreateDeal TO db_admin_role;
GRANT EXECUTE ON sp_UpdateDeal TO db_admin_role;
GRANT EXECUTE ON sp_DeleteDeal TO db_admin_role;

-- PropertyReservations
GRANT EXECUTE ON sp_GetAllPropertyReservations TO db_admin_role;
GRANT EXECUTE ON sp_GetPropertyReservationById TO db_admin_role;
GRANT EXECUTE ON sp_GetPropertyReservationsByRealtorId TO db_admin_role;
GRANT EXECUTE ON sp_GetPropertyReservationsByClientId TO db_admin_role;
GRANT EXECUTE ON sp_CheckActiveReservation TO db_admin_role;
GRANT EXECUTE ON sp_CreatePropertyReservation TO db_admin_role;
GRANT EXECUTE ON sp_UpdatePropertyReservation TO db_admin_role;
GRANT EXECUTE ON sp_DeletePropertyReservation TO db_admin_role;

-- Contracts
GRANT EXECUTE ON sp_GetAllContracts TO db_admin_role;
GRANT EXECUTE ON sp_GetContractById TO db_admin_role;
GRANT EXECUTE ON sp_GetContractsByDealId TO db_admin_role;
GRANT EXECUTE ON sp_CreateContract TO db_admin_role;
GRANT EXECUTE ON sp_UpdateContract TO db_admin_role;
GRANT EXECUTE ON sp_DeleteContract TO db_admin_role;

-- =============================================
-- ПРАВА ДЛЯ REALTOR_ROLE
-- =============================================

-- Users (только свой профиль)
GRANT EXECUTE ON sp_GetUserById TO db_realtor_role;
GRANT EXECUTE ON sp_GetUserByUsername TO db_realtor_role;

-- Clients (чтение и создание)
GRANT EXECUTE ON sp_GetAllClients TO db_realtor_role;
GRANT EXECUTE ON sp_GetClientById TO db_realtor_role;
GRANT EXECUTE ON sp_CreateClient TO db_realtor_role;
GRANT EXECUTE ON sp_UpdateClient TO db_realtor_role;

-- Realtors (только свой профиль)
GRANT EXECUTE ON sp_GetRealtorById TO db_realtor_role;
GRANT EXECUTE ON sp_GetRealtorByUserId TO db_realtor_role;
GRANT EXECUTE ON sp_UpdateRealtor TO db_realtor_role;

-- Properties (свои объекты)
GRANT EXECUTE ON sp_GetAllProperties TO db_realtor_role;
GRANT EXECUTE ON sp_GetPropertyById TO db_realtor_role;
GRANT EXECUTE ON sp_GetPropertiesByRealtorId TO db_realtor_role;
GRANT EXECUTE ON sp_CreateProperty TO db_realtor_role;
GRANT EXECUTE ON sp_UpdateProperty TO db_realtor_role;

-- Deals (свои сделки)
GRANT EXECUTE ON sp_GetDealsByRealtorId TO db_realtor_role;
GRANT EXECUTE ON sp_GetDealById TO db_realtor_role;
GRANT EXECUTE ON sp_GetRealtorDealStats TO db_realtor_role;
GRANT EXECUTE ON sp_CreateDeal TO db_realtor_role;
GRANT EXECUTE ON sp_UpdateDeal TO db_realtor_role;

-- PropertyReservations (свои резервирования)
GRANT EXECUTE ON sp_GetPropertyReservationsByRealtorId TO db_realtor_role;
GRANT EXECUTE ON sp_GetPropertyReservationById TO db_realtor_role;
GRANT EXECUTE ON sp_UpdatePropertyReservation TO db_realtor_role;

-- Contracts (контракты по своим сделкам)
GRANT EXECUTE ON sp_GetContractById TO db_realtor_role;
GRANT EXECUTE ON sp_GetContractsByDealId TO db_realtor_role;
GRANT EXECUTE ON sp_CreateContract TO db_realtor_role;
GRANT EXECUTE ON sp_UpdateContract TO db_realtor_role;

-- =============================================
-- ПРАВА ДЛЯ CLIENT_ROLE
-- =============================================

-- Users (только свой профиль)
GRANT EXECUTE ON sp_GetUserById TO db_client_role;
GRANT EXECUTE ON sp_GetUserByUsername TO db_client_role;

-- Clients (только свой профиль)
GRANT EXECUTE ON sp_GetClientById TO db_client_role;
GRANT EXECUTE ON sp_GetClientByUserId TO db_client_role;
GRANT EXECUTE ON sp_UpdateClient TO db_client_role;

-- Properties (только чтение)
GRANT EXECUTE ON sp_GetAllProperties TO db_client_role;
GRANT EXECUTE ON sp_GetPropertyById TO db_client_role;

-- Deals (только свои сделки)
GRANT EXECUTE ON sp_GetDealsByClientId TO db_client_role;
GRANT EXECUTE ON sp_GetDealById TO db_client_role;

-- PropertyReservations (только свои резервирования)
GRANT EXECUTE ON sp_GetPropertyReservationsByClientId TO db_client_role;
GRANT EXECUTE ON sp_GetPropertyReservationById TO db_client_role;
GRANT EXECUTE ON sp_CheckActiveReservation TO db_client_role;
GRANT EXECUTE ON sp_CreatePropertyReservation TO db_client_role;

-- Contracts (контракты по своим сделкам)
GRANT EXECUTE ON sp_GetContractById TO db_client_role;
GRANT EXECUTE ON sp_GetContractsByDealId TO db_client_role;

PRINT 'Права доступа к процедурам настроены';
GO

