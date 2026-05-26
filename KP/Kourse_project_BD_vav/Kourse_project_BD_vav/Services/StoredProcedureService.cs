using Kourse_project_BD_vav.Data;
using Kourse_project_BD_vav.Models;
using Microsoft.EntityFrameworkCore;
using System.Data;
using Microsoft.Data.SqlClient;
using Npgsql;

namespace Kourse_project_BD_vav.Services
{
    public class StoredProcedureService
    {
        private readonly MssqlDbContext _mssqlContext;
        private readonly PgDbContext _pgContext;
        private readonly ILogger<StoredProcedureService> _logger;

        public StoredProcedureService(
            MssqlDbContext mssqlContext,
            PgDbContext pgContext,
            ILogger<StoredProcedureService> logger)
        {
            _mssqlContext = mssqlContext;
            _pgContext = pgContext;
            _logger = logger;
        }

        private static DateTime EnsureUtc(DateTime value)
        {
            return value.Kind switch
            {
                DateTimeKind.Utc => value,
                DateTimeKind.Local => value.ToUniversalTime(),
                _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
            };
        }

        // Вспомогательный метод для выполнения MSSQL процедур, возвращающих результат
        private async Task<T?> ExecuteMssqlProcedureSingleAsync<T>(
            string procedureName,
            Func<System.Data.Common.DbDataReader, T> mapper,
            params (string name, object value)[] parameters) where T : class
        {
            var connection = _mssqlContext.Database.GetDbConnection();
            await connection.OpenAsync();
            try
            {
                using var command = connection.CreateCommand();
                var paramList = string.Join(", ", parameters.Select((p, i) => $"@{p.name}"));
                command.CommandText = $"EXEC {procedureName} {paramList}";
                
                foreach (var (name, value) in parameters)
                {
                    var param = command.CreateParameter();
                    param.ParameterName = $"@{name}";
                    param.Value = value ?? DBNull.Value;
                    command.Parameters.Add(param);
                }
                
                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    return mapper(reader);
                }
                return null;
            }
            finally
            {
                await connection.CloseAsync();
            }
        }

        // Вспомогательный метод для выполнения MSSQL процедур, возвращающих список
        private async Task<List<T>> ExecuteMssqlProcedureListAsync<T>(
            string procedureName,
            Func<System.Data.Common.DbDataReader, T> mapper,
            params (string name, object value)[] parameters) where T : class
        {
            var connection = _mssqlContext.Database.GetDbConnection();
            await connection.OpenAsync();
            try
            {
                using var command = connection.CreateCommand();
                var paramList = parameters.Length > 0 
                    ? string.Join(", ", parameters.Select(p => $"@{p.name}"))
                    : "";
                command.CommandText = paramList.Length > 0 
                    ? $"EXEC {procedureName} {paramList}"
                    : $"EXEC {procedureName}";
                
                foreach (var (name, value) in parameters)
                {
                    var param = command.CreateParameter();
                    param.ParameterName = $"@{name}";
                    param.Value = value ?? DBNull.Value;
                    command.Parameters.Add(param);
                }
                
                using var reader = await command.ExecuteReaderAsync();
                var results = new List<T>();
                while (await reader.ReadAsync())
                {
                    results.Add(mapper(reader));
                }
                return results;
            }
            finally
            {
                await connection.CloseAsync();
            }
        }

        // =============================================
        // USERS
        // =============================================

        public async Task<User?> GetUserByIdAsync(int userId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Users
                        .FromSqlRaw("SELECT * FROM sp_getuserbyid({0})", userId)
                        .AsNoTracking()
                        .FirstOrDefaultAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetUserByIdAsync, fallback на MSSQL");
                    return await GetUserByIdAsync(userId, false);
                }
            }
            else
            {
                // Для MSSQL используем прямой ADO.NET доступ, так как EXEC не композируется с LINQ
                var connection = _mssqlContext.Database.GetDbConnection();
                await connection.OpenAsync();
                try
                {
                    using var command = connection.CreateCommand();
                    command.CommandText = "EXEC sp_GetUserById @user_id";
                    var param = command.CreateParameter();
                    param.ParameterName = "@user_id";
                    param.Value = userId;
                    command.Parameters.Add(param);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        return new User
                        {
                            user_id = reader.GetInt32(0),
                            username = reader.GetString(1),
                            password_hash = reader.GetString(2),
                            email = reader.GetString(3),
                            full_name = reader.GetString(4),
                            role = reader.GetString(5),
                            created_at = reader.GetDateTime(6),
                            client_id = reader.IsDBNull(7) ? null : reader.GetInt32(7),
                            realtor_id = reader.IsDBNull(8) ? null : reader.GetInt32(8)
                        };
                    }
                    return null;
                }
                finally
                {
                    await connection.CloseAsync();
                }
            }
        }

        public async Task<User?> GetUserByUsernameAsync(string username, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Users
                        .FromSqlRaw("SELECT * FROM sp_getuserbyusername({0})", username)
                        .AsNoTracking()
                        .FirstOrDefaultAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetUserByUsernameAsync, fallback на MSSQL");
                    return await GetUserByUsernameAsync(username, false);
                }
            }
            else
            {
                // Для MSSQL используем прямой ADO.NET доступ
                var connection = _mssqlContext.Database.GetDbConnection();
                await connection.OpenAsync();
                try
                {
                    using var command = connection.CreateCommand();
                    command.CommandText = "EXEC sp_GetUserByUsername @username";
                    var param = command.CreateParameter();
                    param.ParameterName = "@username";
                    param.Value = username;
                    command.Parameters.Add(param);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        return new User
                        {
                            user_id = reader.GetInt32(0),
                            username = reader.GetString(1),
                            password_hash = reader.GetString(2),
                            email = reader.GetString(3),
                            full_name = reader.GetString(4),
                            role = reader.GetString(5),
                            created_at = reader.GetDateTime(6),
                            client_id = reader.IsDBNull(7) ? null : reader.GetInt32(7),
                            realtor_id = reader.IsDBNull(8) ? null : reader.GetInt32(8)
                        };
                    }
                    return null;
                }
                finally
                {
                    await connection.CloseAsync();
                }
            }
        }

        public async Task<List<User>> GetAllUsersAsync(bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Users
                        .FromSqlRaw("SELECT * FROM sp_getallusers()")
                        .AsNoTracking()
                        .ToListAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetAllUsersAsync, fallback на MSSQL");
                    return await GetAllUsersAsync(false);
                }
            }
            else
            {
                // Для MSSQL используем прямой ADO.NET доступ
                var connection = _mssqlContext.Database.GetDbConnection();
                await connection.OpenAsync();
                try
                {
                    using var command = connection.CreateCommand();
                    command.CommandText = "EXEC sp_GetAllUsers";
                    
                    using var reader = await command.ExecuteReaderAsync();
                    var users = new List<User>();
                    while (await reader.ReadAsync())
                    {
                        users.Add(new User
                        {
                            user_id = reader.GetInt32(0),
                            username = reader.GetString(1),
                            password_hash = reader.GetString(2),
                            email = reader.GetString(3),
                            full_name = reader.GetString(4),
                            role = reader.GetString(5),
                            created_at = reader.GetDateTime(6),
                            client_id = reader.IsDBNull(7) ? null : reader.GetInt32(7),
                            realtor_id = reader.IsDBNull(8) ? null : reader.GetInt32(8)
                        });
                    }
                    return users;
                }
                finally
                {
                    await connection.CloseAsync();
                }
            }
        }

        public async Task<int> CreateUserAsync(User user, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    await _pgContext.Database.ExecuteSqlRawAsync(
                        "SELECT setval(pg_get_serial_sequence('users', 'user_id'), COALESCE((SELECT MAX(user_id) FROM users), 1), true)");

                    await _pgContext.Database.ExecuteSqlRawAsync(
                        "SELECT sp_createuser({0}, {1}, {2}, {3}, {4}, {5})",
                        user.username, user.password_hash, user.email, user.full_name, user.role, user.created_at);
                    
                    // Получаем созданного пользователя по username для получения ID
                    var createdUser = await GetUserByUsernameAsync(user.username, true);
                    return createdUser?.user_id ?? 0;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в CreateUserAsync, fallback на MSSQL");
                    return await CreateUserAsync(user, false);
                }
            }
            else
            {
                var userIdParam = new SqlParameter("@user_id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_CreateUser @username={0}, @password_hash={1}, @email={2}, @full_name={3}, @role={4}, @created_at={5}, @user_id={6} OUTPUT",
                    user.username, user.password_hash, user.email, user.full_name, user.role, user.created_at, userIdParam);
                return (int)userIdParam.Value;
            }
        }

        public async Task UpdateUserAsync(User user, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    await _pgContext.Database.ExecuteSqlRawAsync(
                        "SELECT sp_updateuser({0}, {1}, {2}, {3}, {4})",
                        user.user_id, user.username, user.email, user.full_name, user.role);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в UpdateUserAsync, fallback на MSSQL");
                    await UpdateUserAsync(user, false);
                }
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_UpdateUser @user_id={0}, @username={1}, @email={2}, @full_name={3}, @role={4}",
                    user.user_id, user.username, user.email, user.full_name, user.role);
            }
        }

        // Проверить существование username
        public async Task<bool> CheckUsernameExistsAsync(string username, bool usePostgres = true)
        {
            var user = await GetUserByUsernameAsync(username, usePostgres);
            return user != null;
        }

        // Проверить существование email
        public async Task<bool> CheckEmailExistsAsync(string email, bool usePostgres = true)
        {
            if (usePostgres)
            {
                var connection = _pgContext.Database.GetDbConnection();
                try
                {
                    await connection.OpenAsync();
                    using var command = connection.CreateCommand();
                    command.CommandText = "SELECT EXISTS(SELECT 1 FROM users WHERE email = @email)";
                    var param = command.CreateParameter();
                    param.ParameterName = "@email";
                    param.Value = email;
                    command.Parameters.Add(param);
                    var result = await command.ExecuteScalarAsync();
                    return result != null && (bool)result;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в CheckEmailExistsAsync, fallback на MSSQL");
                    return await CheckEmailExistsAsync(email, usePostgres: false);
                }
                finally
                {
                    await connection.CloseAsync();
                }
            }
            else
            {
                var connection = _mssqlContext.Database.GetDbConnection();
                await connection.OpenAsync();
                try
                {
                    using var command = connection.CreateCommand();
                    command.CommandText = "SELECT CASE WHEN EXISTS(SELECT 1 FROM Users WHERE email = @email) THEN 1 ELSE 0 END";
                    var param = command.CreateParameter();
                    param.ParameterName = "@email";
                    param.Value = email;
                    command.Parameters.Add(param);
                    var result = await command.ExecuteScalarAsync();
                    return result != null && Convert.ToInt32(result) == 1;
                }
                finally
                {
                    await connection.CloseAsync();
                }
            }
        }

        // =============================================
        // CLIENTS
        // =============================================

        public async Task<List<Client>> GetAllClientsAsync(bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Clients
                        .FromSqlRaw("SELECT * FROM sp_getallclients()")
                        .AsNoTracking()
                        .ToListAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetAllClientsAsync, fallback на MSSQL");
                    return await GetAllClientsAsync(false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetAllClients", reader => new Client
                {
                    client_id = reader.GetInt32(0),
                    full_name = reader.GetString(1),
                    phone_number = reader.IsDBNull(2) ? "" : reader.GetString(2),
                    email = reader.IsDBNull(3) ? "" : reader.GetString(3),
                    passport_number = reader.IsDBNull(4) ? "" : reader.GetString(4),
                    registration_date = reader.GetDateTime(5),
                    user_id = reader.IsDBNull(6) ? null : reader.GetInt32(6)
                });
            }
        }

        public async Task<Client?> GetClientByIdAsync(int clientId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Clients
                        .FromSqlRaw("SELECT * FROM sp_getclientbyid({0})", clientId)
                        .AsNoTracking()
                        .FirstOrDefaultAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetClientByIdAsync, fallback на MSSQL");
                    return await GetClientByIdAsync(clientId, false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureSingleAsync("sp_GetClientById", reader => new Client
                {
                    client_id = reader.GetInt32(0),
                    full_name = reader.GetString(1),
                    phone_number = reader.IsDBNull(2) ? "" : reader.GetString(2),
                    email = reader.IsDBNull(3) ? "" : reader.GetString(3),
                    passport_number = reader.IsDBNull(4) ? "" : reader.GetString(4),
                    registration_date = reader.GetDateTime(5),
                    user_id = reader.IsDBNull(6) ? null : reader.GetInt32(6)
                }, ("client_id", clientId));
            }
        }

        public async Task<Client?> GetClientByUserIdAsync(int userId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Clients
                        .FromSqlRaw("SELECT * FROM sp_getclientbyuserid({0})", userId)
                        .AsNoTracking()
                        .FirstOrDefaultAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetClientByUserIdAsync, fallback на MSSQL");
                    return await GetClientByUserIdAsync(userId, false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureSingleAsync("sp_GetClientByUserId", reader => new Client
                {
                    client_id = reader.GetInt32(0),
                    full_name = reader.GetString(1),
                    phone_number = reader.IsDBNull(2) ? "" : reader.GetString(2),
                    email = reader.IsDBNull(3) ? "" : reader.GetString(3),
                    passport_number = reader.IsDBNull(4) ? "" : reader.GetString(4),
                    registration_date = reader.GetDateTime(5),
                    user_id = reader.IsDBNull(6) ? null : reader.GetInt32(6)
                }, ("user_id", userId));
            }
        }

        public async Task<int> CreateClientAsync(Client client, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    await _pgContext.Database.ExecuteSqlRawAsync(
                        "SELECT setval(pg_get_serial_sequence('clients', 'client_id'), COALESCE((SELECT MAX(client_id) FROM clients), 1), true)");

                    await _pgContext.Database.ExecuteSqlRawAsync(
                        "SELECT sp_createclient({0}, {1}, {2}, {3}, {4})",
                        client.full_name, client.phone_number, client.email, client.passport_number, client.user_id);
                    
                    // Получаем созданного клиента по user_id для получения ID
                    var createdClient = await GetClientByUserIdAsync(client.user_id ?? 0, true);
                    return createdClient?.client_id ?? 0;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в CreateClientAsync, fallback на MSSQL");
                    return await CreateClientAsync(client, false);
                }
            }
            else
            {
                var clientIdParam = new SqlParameter("@client_id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_CreateClient @full_name={0}, @phone_number={1}, @email={2}, @passport_number={3}, @user_id={4}, @client_id={5} OUTPUT",
                    client.full_name, client.phone_number, client.email, client.passport_number, client.user_id, clientIdParam);
                return (int)clientIdParam.Value;
            }
        }

        public async Task UpdateClientAsync(Client client, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_updateclient({0}, {1}, {2}, {3}, {4})",
                    client.client_id, client.full_name, client.phone_number, client.email, client.passport_number);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_UpdateClient @client_id={0}, @full_name={1}, @phone_number={2}, @email={3}, @passport_number={4}",
                    client.client_id, client.full_name, client.phone_number, client.email, client.passport_number);
            }
        }

        public async Task DeleteClientAsync(int clientId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync("SELECT sp_deleteclient({0})", clientId);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync("EXEC sp_DeleteClient @client_id={0}", clientId);
            }
        }

        // =============================================
        // REALTORS
        // =============================================

        public async Task<List<Realtor>> GetAllRealtorsAsync(bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Realtors
                        .FromSqlRaw("SELECT * FROM sp_getallrealtors()")
                        .AsNoTracking()
                        .ToListAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetAllRealtorsAsync, fallback на MSSQL");
                    return await GetAllRealtorsAsync(false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetAllRealtors", reader => new Realtor
                {
                    realtor_id = reader.GetInt32(0),
                    full_name = reader.GetString(1),
                    phone_number = reader.GetString(2),
                    email = reader.GetString(3),
                    hire_date = reader.GetDateTime(4),
                    commission_rate = reader.GetDecimal(5),
                    user_id = reader.IsDBNull(6) ? null : reader.GetInt32(6)
                });
            }
        }

        public async Task<Realtor?> GetRealtorByIdAsync(int realtorId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.Realtors
                    .FromSqlRaw("SELECT * FROM sp_getrealtorbyid({0})", realtorId)
                    .AsNoTracking()
                    .FirstOrDefaultAsync();
            }
            else
            {
                return await ExecuteMssqlProcedureSingleAsync("sp_GetRealtorById", reader => new Realtor
                {
                    realtor_id = reader.GetInt32(0),
                    full_name = reader.GetString(1),
                    phone_number = reader.GetString(2),
                    email = reader.GetString(3),
                    hire_date = reader.GetDateTime(4),
                    commission_rate = reader.GetDecimal(5),
                    user_id = reader.IsDBNull(6) ? null : reader.GetInt32(6)
                }, ("realtor_id", realtorId));
            }
        }

        public async Task<Realtor?> GetRealtorByUserIdAsync(int userId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Realtors
                        .FromSqlRaw("SELECT * FROM sp_getrealtorbyuserid({0})", userId)
                        .AsNoTracking()
                        .FirstOrDefaultAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetRealtorByUserIdAsync, fallback на MSSQL");
                    return await GetRealtorByUserIdAsync(userId, false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureSingleAsync("sp_GetRealtorByUserId", reader => new Realtor
                {
                    realtor_id = reader.GetInt32(0),
                    full_name = reader.GetString(1),
                    phone_number = reader.GetString(2),
                    email = reader.GetString(3),
                    hire_date = reader.GetDateTime(4),
                    commission_rate = reader.GetDecimal(5),
                    user_id = reader.IsDBNull(6) ? null : reader.GetInt32(6)
                }, ("user_id", userId));
            }
        }

        public async Task<int> CreateRealtorAsync(Realtor realtor, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    await _pgContext.Database.ExecuteSqlRawAsync(
                        "SELECT setval(pg_get_serial_sequence('realtors', 'realtor_id'), COALESCE((SELECT MAX(realtor_id) FROM realtors), 1), true)");

                    // PostgreSQL процедура принимает только 4 параметра и устанавливает значения по умолчанию
                    await _pgContext.Database.ExecuteSqlRawAsync(
                        "SELECT sp_createrealtor({0}, {1}, {2}, {3})",
                        realtor.full_name, realtor.phone_number, realtor.email, 
                        realtor.user_id ?? (object)DBNull.Value);
                    
                    // Получаем созданного риэлтора по user_id для получения ID
                    var createdRealtor = await GetRealtorByUserIdAsync(realtor.user_id ?? 0, true);
                    return createdRealtor?.realtor_id ?? 0;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в CreateRealtorAsync, fallback на MSSQL");
                    return await CreateRealtorAsync(realtor, false);
                }
            }
            else
            {
                var realtorIdParam = new SqlParameter("@realtor_id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                
                // Используем SqlParameter для правильной передачи NULL значений
                var userIdParam = new SqlParameter("@user_id", SqlDbType.Int) 
                { 
                    Value = realtor.user_id ?? (object)DBNull.Value 
                };
                var hireDateParam = new SqlParameter("@hire_date", SqlDbType.DateTime) 
                { 
                    Value = realtor.hire_date != default(DateTime) ? (object)realtor.hire_date : (object)DBNull.Value 
                };
                var commissionRateParam = new SqlParameter("@commission_rate", SqlDbType.Decimal) 
                { 
                    Value = realtor.commission_rate != default(decimal) ? (object)realtor.commission_rate : (object)DBNull.Value 
                };
                
                // MSSQL процедура теперь принимает hire_date и commission_rate как опциональные
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_CreateRealtor @full_name={0}, @phone_number={1}, @email={2}, @user_id={3}, @hire_date={4}, @commission_rate={5}, @realtor_id={6} OUTPUT",
                    realtor.full_name, realtor.phone_number, realtor.email, 
                    userIdParam, hireDateParam, commissionRateParam, realtorIdParam);
                return (int)realtorIdParam.Value;
            }
        }

        public async Task UpdateRealtorAsync(Realtor realtor, bool usePostgres = true)
        {
            // Используем существующие значения, если новые не переданы
            var existingRealtor = await GetRealtorByIdAsync(realtor.realtor_id, usePostgres);
            if (existingRealtor == null)
            {
                throw new InvalidOperationException($"Realtor with ID {realtor.realtor_id} not found");
            }

            // Используем переданные значения или существующие
            var hireDate = realtor.hire_date != default(DateTime) ? realtor.hire_date : existingRealtor.hire_date;
            var commissionRate = realtor.commission_rate != default(decimal) ? realtor.commission_rate : existingRealtor.commission_rate;

            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_updaterealtor({0}, {1}, {2}, {3}, {4}, {5})",
                    realtor.realtor_id, realtor.full_name, realtor.phone_number, realtor.email,
                    hireDate, commissionRate);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_UpdateRealtor @realtor_id={0}, @full_name={1}, @phone_number={2}, @email={3}, @hire_date={4}, @commission_rate={5}",
                    realtor.realtor_id, realtor.full_name, realtor.phone_number, realtor.email,
                    hireDate, commissionRate);
            }
        }

        public async Task DeleteRealtorAsync(int realtorId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync("SELECT sp_deleterealtor({0})", realtorId);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync("EXEC sp_DeleteRealtor @realtor_id={0}", realtorId);
            }
        }

        // =============================================
        // PROPERTIES
        // =============================================

        // Вспомогательный метод для маппинга Property из DataReader
        private Property MapPropertyFromReader(System.Data.Common.DbDataReader reader)
        {
            return new Property
            {
                property_id = reader.GetInt32(reader.GetOrdinal("property_id")),
                address = reader.GetString(reader.GetOrdinal("address")),
                property_type = reader.IsDBNull(reader.GetOrdinal("property_type")) ? null : reader.GetString(reader.GetOrdinal("property_type")),
                area = reader.IsDBNull(reader.GetOrdinal("area")) ? 0 : reader.GetDecimal(reader.GetOrdinal("area")),
                price = reader.IsDBNull(reader.GetOrdinal("price")) ? 0 : reader.GetDecimal(reader.GetOrdinal("price")),
                description = reader.IsDBNull(reader.GetOrdinal("description")) ? null : reader.GetString(reader.GetOrdinal("description")),
                realtor_id = reader.IsDBNull(reader.GetOrdinal("realtor_id")) ? null : reader.GetInt32(reader.GetOrdinal("realtor_id")),
                is_available = reader.IsDBNull(reader.GetOrdinal("is_available")) ? true : reader.GetBoolean(reader.GetOrdinal("is_available")),
                main_image_url = reader.IsDBNull(reader.GetOrdinal("main_image_url")) ? null : reader.GetString(reader.GetOrdinal("main_image_url")),
                image_urls = reader.IsDBNull(reader.GetOrdinal("image_urls")) ? null : reader.GetString(reader.GetOrdinal("image_urls")),
                rooms = reader.IsDBNull(reader.GetOrdinal("rooms")) ? null : reader.GetInt32(reader.GetOrdinal("rooms")),
                floor = reader.IsDBNull(reader.GetOrdinal("floor")) ? null : reader.GetInt32(reader.GetOrdinal("floor")),
                total_floors = reader.IsDBNull(reader.GetOrdinal("total_floors")) ? null : reader.GetInt32(reader.GetOrdinal("total_floors"))
            };
        }

        public async Task<List<Property>> GetAllPropertiesAsync(bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Properties
                        .FromSqlRaw("SELECT * FROM sp_getallproperties()")
                        .AsNoTracking()
                        .ToListAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetAllPropertiesAsync, fallback на MSSQL");
                    return await GetAllPropertiesAsync(false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetAllProperties", MapPropertyFromReader);
            }
        }

        public async Task<Property?> GetPropertyByIdAsync(int propertyId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Properties
                        .FromSqlRaw("SELECT * FROM sp_getpropertybyid({0})", propertyId)
                        .AsNoTracking()
                        .FirstOrDefaultAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetPropertyByIdAsync, fallback на MSSQL");
                    return await GetPropertyByIdAsync(propertyId, false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureSingleAsync("sp_GetPropertyById", MapPropertyFromReader, ("property_id", propertyId));
            }
        }

        public async Task<List<Property>> GetPropertiesByRealtorIdAsync(int realtorId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.Properties
                    .FromSqlRaw("SELECT * FROM sp_getpropertiesbyrealtorid({0})", realtorId)
                    .AsNoTracking()
                    .ToListAsync();
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetPropertiesByRealtorId", MapPropertyFromReader, ("realtor_id", realtorId));
            }
        }

        public async Task<int> CreatePropertyAsync(Property property, bool usePostgres = true)
        {
            if (usePostgres)
            {
                // Если в таблице есть записи с явными ID, последовательность может отстать.
                // Синхронизируем sequence перед вставкой, чтобы избежать PK_properties (23505).
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT setval(pg_get_serial_sequence('properties', 'property_id'), COALESCE((SELECT MAX(property_id) FROM properties), 1), true)");

                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_createproperty({0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11})",
                    property.address, property.property_type, property.area, property.price, property.description ?? "",
                    property.realtor_id, property.is_available, property.rooms, property.floor, property.total_floors,
                    property.main_image_url ?? "", property.image_urls ?? "");
                
                // Получаем созданный объект по адресу и риэлтору для получения ID
                var properties = await GetPropertiesByRealtorIdAsync(property.realtor_id ?? 0, true);
                return properties.FirstOrDefault(p => p.address == property.address)?.property_id ?? 0;
            }
            else
            {
                var propertyIdParam = new SqlParameter("@property_id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_CreateProperty @address={0}, @property_type={1}, @area={2}, @price={3}, @description={4}, @realtor_id={5}, @is_available={6}, @rooms={7}, @floor={8}, @total_floors={9}, @main_image_url={10}, @image_urls={11}, @property_id={12} OUTPUT",
                    property.address, property.property_type, property.area, property.price, property.description ?? "",
                    property.realtor_id, property.is_available, property.rooms, property.floor, property.total_floors,
                    property.main_image_url ?? "", property.image_urls ?? "", propertyIdParam);
                return (int)propertyIdParam.Value;
            }
        }

        public async Task UpdatePropertyAsync(Property property, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_updateproperty({0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12})",
                    property.property_id, property.address, property.property_type, property.area, property.price,
                    property.description ?? "", property.realtor_id, property.is_available, property.rooms,
                    property.floor, property.total_floors, property.main_image_url ?? "", property.image_urls ?? "");
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_UpdateProperty @property_id={0}, @address={1}, @property_type={2}, @area={3}, @price={4}, @description={5}, @realtor_id={6}, @is_available={7}, @rooms={8}, @floor={9}, @total_floors={10}, @main_image_url={11}, @image_urls={12}",
                    property.property_id, property.address, property.property_type, property.area, property.price,
                    property.description ?? "", property.realtor_id, property.is_available, property.rooms,
                    property.floor, property.total_floors, property.main_image_url ?? "", property.image_urls ?? "");
            }
        }

        public async Task DeletePropertyAsync(int propertyId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync("SELECT sp_deleteproperty({0})", propertyId);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync("EXEC sp_DeleteProperty @property_id={0}", propertyId);
            }
        }

        // =============================================
        // DEALS
        // =============================================

        // Вспомогательный метод для маппинга Deal из DataReader
        private Deal MapDealFromReader(System.Data.Common.DbDataReader reader)
        {
            return new Deal
            {
                deal_id = reader.GetInt32(reader.GetOrdinal("deal_id")),
                property_id = reader.GetInt32(reader.GetOrdinal("property_id")),
                client_id = reader.GetInt32(reader.GetOrdinal("client_id")),
                realtor_id = reader.IsDBNull(reader.GetOrdinal("realtor_id")) ? null : reader.GetInt32(reader.GetOrdinal("realtor_id")),
                deal_type = reader.IsDBNull(reader.GetOrdinal("deal_type")) ? null : reader.GetString(reader.GetOrdinal("deal_type")),
                deal_status = reader.IsDBNull(reader.GetOrdinal("deal_status")) ? null : reader.GetString(reader.GetOrdinal("deal_status")),
                deal_date = reader.GetDateTime(reader.GetOrdinal("deal_date")),
                deal_price = reader.GetDecimal(reader.GetOrdinal("deal_price"))
            };
        }

        public async Task<List<Deal>> GetAllDealsAsync(bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Deals
                        .FromSqlRaw("SELECT * FROM sp_getalldeals()")
                        .AsNoTracking()
                        .ToListAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetAllDealsAsync, fallback на MSSQL");
                    return await GetAllDealsAsync(false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetAllDeals", MapDealFromReader);
            }
        }

        public async Task<Deal?> GetDealByIdAsync(int dealId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.Deals
                    .FromSqlRaw("SELECT * FROM sp_getdealbyid({0})", dealId)
                    .AsNoTracking()
                    .FirstOrDefaultAsync();
            }
            else
            {
                return await ExecuteMssqlProcedureSingleAsync("sp_GetDealById", MapDealFromReader, ("deal_id", dealId));
            }
        }

        public async Task<List<Deal>> GetDealsByRealtorIdAsync(int realtorId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Deals
                        .FromSqlRaw("SELECT * FROM sp_getdealsbyrealtorid({0})", realtorId)
                        .AsNoTracking()
                        .ToListAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetDealsByRealtorIdAsync, fallback на MSSQL");
                    return await GetDealsByRealtorIdAsync(realtorId, false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetDealsByRealtorId", MapDealFromReader, ("realtor_id", realtorId));
            }
        }

        public async Task<List<Deal>> GetDealsByClientIdAsync(int clientId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                try
                {
                    return await _pgContext.Deals
                        .FromSqlRaw("SELECT * FROM sp_getdealsbyclientid({0})", clientId)
                        .AsNoTracking()
                        .ToListAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL недоступен в GetDealsByClientIdAsync, fallback на MSSQL");
                    return await GetDealsByClientIdAsync(clientId, false);
                }
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetDealsByClientId", MapDealFromReader, ("client_id", clientId));
            }
        }

        public async Task<(int count, decimal amount)> GetRealtorDealStatsAsync(int realtorId, DateTime startDate, DateTime endDate, bool usePostgres = true)
        {
            if (usePostgres)
            {
                // Для PostgreSQL функция возвращает TABLE
                var connection = _pgContext.Database.GetDbConnection();
                await connection.OpenAsync();
                try
                {
                    using var command = connection.CreateCommand();
                    command.CommandText = "SELECT * FROM sp_getrealtordealstats($1, $2, $3)";
                    var param1 = command.CreateParameter();
                    param1.ParameterName = "p1";
                    param1.Value = realtorId;
                    command.Parameters.Add(param1);
                    var param2 = command.CreateParameter();
                    param2.ParameterName = "p2";
                    param2.Value = startDate;
                    command.Parameters.Add(param2);
                    var param3 = command.CreateParameter();
                    param3.ParameterName = "p3";
                    param3.Value = endDate;
                    command.Parameters.Add(param3);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        var count = reader.GetInt64(0);
                        var amount = reader.GetDecimal(1);
                        return ((int)count, amount);
                    }
                    return (0, 0);
                }
                finally
                {
                    await connection.CloseAsync();
                }
            }
            else
            {
                var realtorIdParam = new SqlParameter("@realtor_id", realtorId);
                var startDateParam = new SqlParameter("@start_date", startDate);
                var endDateParam = new SqlParameter("@end_date", endDate);
                var dealCountParam = new SqlParameter("@deal_count", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var dealAmountParam = new SqlParameter("@deal_amount", SqlDbType.Decimal) { Direction = ParameterDirection.Output };
                
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_GetRealtorDealStats @realtor_id={0}, @start_date={1}, @end_date={2}, @deal_count={3} OUTPUT, @deal_amount={4} OUTPUT",
                    realtorIdParam, startDateParam, endDateParam, dealCountParam, dealAmountParam);
                
                return ((int)dealCountParam.Value, (decimal)dealAmountParam.Value);
            }
        }

        public async Task<int> CreateDealAsync(Deal deal, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT setval(pg_get_serial_sequence('deals', 'deal_id'), COALESCE((SELECT MAX(deal_id) FROM deals), 1), true)");

                var dealDateUtc = EnsureUtc(deal.deal_date);
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_createdeal({0}, {1}, {2}, {3}, {4}, {5})",
                    deal.property_id, deal.client_id, deal.realtor_id, deal.deal_type, deal.deal_price, dealDateUtc);
                
                // Получаем созданную сделку по параметрам для получения ID
                var deals = await GetDealsByRealtorIdAsync(deal.realtor_id ?? 0, true);
                return deals.FirstOrDefault(d => d.property_id == deal.property_id && d.client_id == deal.client_id && 
                    d.deal_date == dealDateUtc)?.deal_id ?? 0;
            }
            else
            {
                var dealIdParam = new SqlParameter("@deal_id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_CreateDeal @property_id={0}, @client_id={1}, @realtor_id={2}, @deal_type={3}, @deal_price={4}, @deal_date={5}, @deal_id={6} OUTPUT",
                    deal.property_id, deal.client_id, deal.realtor_id, deal.deal_type, deal.deal_price, deal.deal_date, dealIdParam);
                return (int)dealIdParam.Value;
            }
        }

        public async Task UpdateDealAsync(Deal deal, bool usePostgres = true)
        {
            if (usePostgres)
            {
                var dealDateUtc = EnsureUtc(deal.deal_date);
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_updatedeal({0}, {1}, {2}, {3}, {4}, {5}, {6})",
                    deal.deal_id, deal.property_id, deal.client_id, deal.realtor_id, deal.deal_type, deal.deal_price, dealDateUtc);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_UpdateDeal @deal_id={0}, @property_id={1}, @client_id={2}, @realtor_id={3}, @deal_type={4}, @deal_price={5}, @deal_date={6}",
                    deal.deal_id, deal.property_id, deal.client_id, deal.realtor_id, deal.deal_type, deal.deal_price, deal.deal_date);
            }
        }

        public async Task DeleteDealAsync(int dealId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync("SELECT sp_deletedeal({0})", dealId);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync("EXEC sp_DeleteDeal @deal_id={0}", dealId);
            }
        }

        // =============================================
        // PROPERTY RESERVATIONS
        // =============================================

        public async Task<List<PropertyReservation>> GetAllPropertyReservationsAsync(bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.PropertyReservations
                    .FromSqlRaw("SELECT * FROM sp_getallpropertyreservations()")
                    .AsNoTracking()
                    .ToListAsync();
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetAllPropertyReservations", reader => new PropertyReservation
                {
                    reservation_id = reader.GetInt32(0),
                    property_id = reader.GetInt32(1),
                    client_id = reader.GetInt32(2),
                    realtor_id = reader.GetInt32(3),
                    status = reader.IsDBNull(4) ? "Active" : reader.GetString(4),
                    reservation_date = reader.GetDateTime(5),
                    expiry_date = reader.GetDateTime(6)
                });
            }
        }

        public async Task<PropertyReservation?> GetPropertyReservationByIdAsync(int reservationId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.PropertyReservations
                    .FromSqlRaw("SELECT * FROM sp_getpropertyreservationbyid({0})", reservationId)
                    .AsNoTracking()
                    .FirstOrDefaultAsync();
            }
            else
            {
                return await ExecuteMssqlProcedureSingleAsync("sp_GetPropertyReservationById", reader => new PropertyReservation
                {
                    reservation_id = reader.GetInt32(0),
                    property_id = reader.GetInt32(1),
                    client_id = reader.GetInt32(2),
                    realtor_id = reader.GetInt32(3),
                    status = reader.IsDBNull(4) ? "Active" : reader.GetString(4),
                    reservation_date = reader.GetDateTime(5),
                    expiry_date = reader.GetDateTime(6)
                }, ("reservation_id", reservationId));
            }
        }

        public async Task<List<PropertyReservation>> GetPropertyReservationsByRealtorIdAsync(int realtorId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.PropertyReservations
                    .FromSqlRaw("SELECT * FROM sp_getpropertyreservationsbyrealtorid({0})", realtorId)
                    .AsNoTracking()
                    .ToListAsync();
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetPropertyReservationsByRealtorId", reader => new PropertyReservation
                {
                    reservation_id = reader.GetInt32(0),
                    property_id = reader.GetInt32(1),
                    client_id = reader.GetInt32(2),
                    realtor_id = reader.GetInt32(3),
                    status = reader.IsDBNull(4) ? "Active" : reader.GetString(4),
                    reservation_date = reader.GetDateTime(5),
                    expiry_date = reader.GetDateTime(6)
                }, ("realtor_id", realtorId));
            }
        }

        public async Task<List<PropertyReservation>> GetPropertyReservationsByClientIdAsync(int clientId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.PropertyReservations
                    .FromSqlRaw("SELECT * FROM sp_getpropertyreservationsbyclientid({0})", clientId)
                    .AsNoTracking()
                    .ToListAsync();
            }
            else
            {
                return await ExecuteMssqlProcedureListAsync("sp_GetPropertyReservationsByClientId", reader => new PropertyReservation
                {
                    reservation_id = reader.GetInt32(0),
                    property_id = reader.GetInt32(1),
                    client_id = reader.GetInt32(2),
                    realtor_id = reader.GetInt32(3),
                    status = reader.IsDBNull(4) ? "Active" : reader.GetString(4),
                    reservation_date = reader.GetDateTime(5),
                    expiry_date = reader.GetDateTime(6)
                }, ("client_id", clientId));
            }
        }

        public async Task<bool> CheckActiveReservationAsync(int propertyId, int clientId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                // Для PostgreSQL используем прямой SQL запрос через ADO.NET
                var connection = _pgContext.Database.GetDbConnection();
                await connection.OpenAsync();
                try
                {
                    using var command = connection.CreateCommand();
                    command.CommandText = "SELECT sp_checkactivereservation($1, $2)";
                    var param1 = command.CreateParameter();
                    param1.ParameterName = "p1";
                    param1.Value = propertyId;
                    command.Parameters.Add(param1);
                    var param2 = command.CreateParameter();
                    param2.ParameterName = "p2";
                    param2.Value = clientId;
                    command.Parameters.Add(param2);
                    
                    var result = await command.ExecuteScalarAsync();
                    return result != null && (bool)result;
                }
                finally
                {
                    await connection.CloseAsync();
                }
            }
            else
            {
                var existsParam = new SqlParameter("@exists", SqlDbType.Bit) { Direction = ParameterDirection.Output };
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_CheckActiveReservation @property_id={0}, @client_id={1}, @exists={2} OUTPUT",
                    propertyId, clientId, existsParam);
                return (bool)existsParam.Value;
            }
        }

        public async Task<int> CreatePropertyReservationAsync(PropertyReservation reservation, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_createpropertyreservation({0}, {1}, {2}, {3}, {4}, {5})",
                    reservation.property_id, reservation.client_id, reservation.realtor_id,
                    reservation.reservation_date, reservation.expiry_date, reservation.status);
                
                // Получаем созданное резервирование по параметрам для получения ID
                var reservations = await GetPropertyReservationsByClientIdAsync(reservation.client_id, true);
                return reservations.FirstOrDefault(r => r.property_id == reservation.property_id && 
                    r.reservation_date == reservation.reservation_date)?.reservation_id ?? 0;
            }
            else
            {
                var reservationIdParam = new SqlParameter("@reservation_id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_CreatePropertyReservation @property_id={0}, @client_id={1}, @realtor_id={2}, @reservation_date={3}, @expiry_date={4}, @status={5}, @reservation_id={6} OUTPUT",
                    reservation.property_id, reservation.client_id, reservation.realtor_id,
                    reservation.reservation_date, reservation.expiry_date, reservation.status, reservationIdParam);
                return (int)reservationIdParam.Value;
            }
        }

        public async Task UpdatePropertyReservationAsync(PropertyReservation reservation, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_updatepropertyreservation({0}, {1}, {2})",
                    reservation.reservation_id, reservation.status, reservation.expiry_date);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_UpdatePropertyReservation @reservation_id={0}, @status={1}, @expiry_date={2}",
                    reservation.reservation_id, reservation.status, reservation.expiry_date);
            }
        }

        public async Task DeletePropertyReservationAsync(int reservationId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync("SELECT sp_deletepropertyreservation({0})", reservationId);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync("EXEC sp_DeletePropertyReservation @reservation_id={0}", reservationId);
            }
        }

        // =============================================
        // CONTRACTS
        // =============================================

        public async Task<List<Contract>> GetAllContractsAsync(bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.Contracts
                    .FromSqlRaw("SELECT * FROM sp_getallcontracts()")
                    .AsNoTracking()
                    .ToListAsync();
            }
            else
            {
                return await _mssqlContext.Contracts
                    .FromSqlRaw("EXEC sp_GetAllContracts")
                    .AsNoTracking()
                    .ToListAsync();
            }
        }

        public async Task<Contract?> GetContractByIdAsync(int contractId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.Contracts
                    .FromSqlRaw("SELECT * FROM sp_getcontractbyid({0})", contractId)
                    .AsNoTracking()
                    .FirstOrDefaultAsync();
            }
            else
            {
                var contractIdParam = new SqlParameter("@contract_id", contractId);
                return await _mssqlContext.Contracts
                    .FromSqlRaw("EXEC sp_GetContractById @contract_id", contractIdParam)
                    .AsNoTracking()
                    .FirstOrDefaultAsync();
            }
        }

        public async Task<List<Contract>> GetContractsByDealIdAsync(int dealId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                return await _pgContext.Contracts
                    .FromSqlRaw("SELECT * FROM sp_getcontractsbydealid({0})", dealId)
                    .AsNoTracking()
                    .ToListAsync();
            }
            else
            {
                var dealIdParam = new SqlParameter("@deal_id", dealId);
                return await _mssqlContext.Contracts
                    .FromSqlRaw("EXEC sp_GetContractsByDealId @deal_id", dealIdParam)
                    .AsNoTracking()
                    .ToListAsync();
            }
        }

        public async Task<int> CreateContractAsync(Contract contract, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_createcontract({0}, {1}, {2}, {3})",
                    contract.deal_id, contract.contract_date, contract.contract_file, contract.notes ?? "");
                
                // Получаем созданный контракт по deal_id для получения ID
                var contracts = await GetContractsByDealIdAsync(contract.deal_id, true);
                return contracts.FirstOrDefault(c => c.contract_date == contract.contract_date)?.contract_id ?? 0;
            }
            else
            {
                var contractIdParam = new SqlParameter("@contract_id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_CreateContract @deal_id={0}, @contract_date={1}, @contract_file={2}, @notes={3}, @contract_id={4} OUTPUT",
                    contract.deal_id, contract.contract_date, contract.contract_file, contract.notes ?? "", contractIdParam);
                return (int)contractIdParam.Value;
            }
        }

        public async Task UpdateContractAsync(Contract contract, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync(
                    "SELECT sp_updatecontract({0}, {1}, {2}, {3})",
                    contract.contract_id, contract.contract_date, contract.contract_file, contract.notes ?? "");
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync(
                    "EXEC sp_UpdateContract @contract_id={0}, @contract_date={1}, @contract_file={2}, @notes={3}",
                    contract.contract_id, contract.contract_date, contract.contract_file, contract.notes ?? "");
            }
        }

        public async Task DeleteContractAsync(int contractId, bool usePostgres = true)
        {
            if (usePostgres)
            {
                await _pgContext.Database.ExecuteSqlRawAsync("SELECT sp_deletecontract({0})", contractId);
            }
            else
            {
                await _mssqlContext.Database.ExecuteSqlRawAsync("EXEC sp_DeleteContract @contract_id={0}", contractId);
            }
        }
    }

    // Вспомогательный класс для результатов статистики
    public class DealStatsResult
    {
        public int deal_count { get; set; }
        public decimal deal_amount { get; set; }
    }
}
