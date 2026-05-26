using Kourse_project_BD_vav.Data;
using Kourse_project_BD_vav.Hubs;
using Kourse_project_BD_vav.Interfaces;
using Kourse_project_BD_vav.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore.Metadata;

namespace Kourse_project_BD_vav.Services
{
    public class SyncService : ISyncService, IHostedService
    {
        private const int DefaultCommandTimeoutSeconds = 30;
        private const int FullSyncCommandTimeoutSeconds = 300;
        private const int DefaultBatchSize = 250;

        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<SyncService> _logger;
        private readonly IHubContext<SyncHub> _hub;

        private bool _autoSyncRunning;
        private DateTime? _nextAutoSync;
        private int _autoSyncIntervalMinutes = 5;
        private CancellationTokenSource? _autoSyncCts;
        private Task? _autoSyncTask;

        public SyncService(IServiceScopeFactory scopeFactory, ILogger<SyncService> logger, IHubContext<SyncHub> hub = null)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _hub = hub;
        }

        #region IHostedService

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("SyncService started");
            _autoSyncCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            _autoSyncTask = Task.Run(() => AutoSyncLoopAsync(_autoSyncCts.Token), _autoSyncCts.Token);
            return Task.CompletedTask;
        }

        public async Task StopAsync(CancellationToken cancellationToken)
        {
            _autoSyncRunning = false;
            if (_autoSyncCts != null)
            {
                _autoSyncCts.Cancel();
            }

            if (_autoSyncTask != null)
            {
                try
                {
                    await _autoSyncTask;
                }
                catch (OperationCanceledException)
                {
                    // expected on shutdown
                }
            }
        }

        #endregion

        #region ISyncService

        public async Task<SyncResult> FullSyncAsync()
        {
            using var scope = _scopeFactory.CreateScope();
            var mssql = scope.ServiceProvider.GetRequiredService<MssqlDbContext>();
            var pg = scope.ServiceProvider.GetRequiredService<PgDbContext>();

            int totalSynced = 0;

            try
            {
                var mssqlConnected = await TestConnection(mssql);
                var pgConnected = await TestConnection(pg);

                if (!mssqlConnected || !pgConnected)
                {
                    return new SyncResult
                    {
                        Success = false,
                        RecordsSynced = 0,
                        Message = $"Двусторонняя синхронизация недоступна. MSSQL: {(mssqlConnected ? "ONLINE" : "OFFLINE")}, PostgreSQL: {(pgConnected ? "ONLINE" : "OFFLINE")}"
                    };
                }

                mssql.Database.SetCommandTimeout(FullSyncCommandTimeoutSeconds);
                pg.Database.SetCommandTimeout(FullSyncCommandTimeoutSeconds);

                // Двусторонняя синхронизация (без удаления), чтобы обе БД могли быть источником изменений.
                // Порядок важен из-за внешних ключей.
                totalSynced += await SyncTableBidirectional<User, int>(mssql, pg, u => u.user_id);
                totalSynced += await SyncTableBidirectional<Client, int>(mssql, pg, c => c.client_id);
                totalSynced += await SyncTableBidirectional<Realtor, int>(mssql, pg, r => r.realtor_id);
                totalSynced += await SyncTableBidirectional<Property, int>(mssql, pg, p => p.property_id);
                totalSynced += await SyncTableBidirectional<PropertyReservation, int>(mssql, pg, pr => pr.reservation_id);
                totalSynced += await SyncTableBidirectional<Contract, int>(mssql, pg, c => c.contract_id);
                totalSynced += await SyncTableBidirectional<Deal, int>(mssql, pg, d => d.deal_id);

                return new SyncResult
                {
                    Success = true,
                    RecordsSynced = totalSynced,
                    Message = "Двусторонняя синхронизация выполнена успешно"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Ошибка при синхронизации данных");
                return new SyncResult { Success = false, Message = ex.Message };
            }
            finally
            {
                mssql.Database.SetCommandTimeout(DefaultCommandTimeoutSeconds);
                pg.Database.SetCommandTimeout(DefaultCommandTimeoutSeconds);
            }
        }

        public Task<SyncResult> IncrementalSyncAsync() => FullSyncAsync();

        public async Task<SyncStatus> GetSyncStatusAsync()
        {
            using var scope = _scopeFactory.CreateScope();
            var mssql = scope.ServiceProvider.GetRequiredService<MssqlDbContext>();
            var pg = scope.ServiceProvider.GetRequiredService<PgDbContext>();

            var status = new SyncStatus
            {
                MssqlConnected = await TestConnection(mssql),
                PgConnected = await TestConnection(pg),
                AutoSyncEnabled = _autoSyncRunning,
                NextAutoSync = _nextAutoSync,
                Tables = new List<TableStatus>()
            };

            // Для standby-режима считаем каждую БД независимо:
            // если MSSQL недоступен, статус всё равно должен открываться.
            async Task<int> SafeCount(Func<Task<int>> getter, string source, string table)
            {
                try
                {
                    return await getter();
                }
                catch (Exception ex)
                {
                    _logger?.LogWarning("Не удалось получить count из {Source} для {Table}: {Message}", source, table, ex.Message);
                    return 0;
                }
            }

            status.Tables.Add(new TableStatus
            {
                Name = "Users",
                MssqlCount = status.MssqlConnected ? await SafeCount(() => mssql.Users.CountAsync(), "MSSQL", "Users") : 0,
                PgCount = status.PgConnected ? await SafeCount(() => pg.Users.CountAsync(), "PostgreSQL", "Users") : 0
            });
            status.Tables.Add(new TableStatus
            {
                Name = "Clients",
                MssqlCount = status.MssqlConnected ? await SafeCount(() => mssql.Clients.CountAsync(), "MSSQL", "Clients") : 0,
                PgCount = status.PgConnected ? await SafeCount(() => pg.Clients.CountAsync(), "PostgreSQL", "Clients") : 0
            });
            status.Tables.Add(new TableStatus
            {
                Name = "Realtors",
                MssqlCount = status.MssqlConnected ? await SafeCount(() => mssql.Realtors.CountAsync(), "MSSQL", "Realtors") : 0,
                PgCount = status.PgConnected ? await SafeCount(() => pg.Realtors.CountAsync(), "PostgreSQL", "Realtors") : 0
            });
            status.Tables.Add(new TableStatus
            {
                Name = "Properties",
                MssqlCount = status.MssqlConnected ? await SafeCount(() => mssql.Properties.CountAsync(), "MSSQL", "Properties") : 0,
                PgCount = status.PgConnected ? await SafeCount(() => pg.Properties.CountAsync(), "PostgreSQL", "Properties") : 0
            });
            status.Tables.Add(new TableStatus
            {
                Name = "Deals",
                MssqlCount = status.MssqlConnected ? await SafeCount(() => mssql.Deals.CountAsync(), "MSSQL", "Deals") : 0,
                PgCount = status.PgConnected ? await SafeCount(() => pg.Deals.CountAsync(), "PostgreSQL", "Deals") : 0
            });
            status.Tables.Add(new TableStatus
            {
                Name = "Contracts",
                MssqlCount = status.MssqlConnected ? await SafeCount(() => mssql.Contracts.CountAsync(), "MSSQL", "Contracts") : 0,
                PgCount = status.PgConnected ? await SafeCount(() => pg.Contracts.CountAsync(), "PostgreSQL", "Contracts") : 0
            });
            status.Tables.Add(new TableStatus
            {
                Name = "PropertyReservations",
                MssqlCount = status.MssqlConnected ? await SafeCount(() => mssql.PropertyReservations.CountAsync(), "MSSQL", "PropertyReservations") : 0,
                PgCount = status.PgConnected ? await SafeCount(() => pg.PropertyReservations.CountAsync(), "PostgreSQL", "PropertyReservations") : 0
            });

            // Так как PostgreSQL является primary, итог считаем по нему
            status.TotalRecordsSynced = status.Tables.Sum(t => t.PgCount);
            status.SystemHealth = new SystemHealth { Status = "Healthy", CheckedAt = DateTime.UtcNow };

            return status;
        }

        public async Task<bool> CheckDatabaseConnectivityAsync()
        {
            using var scope = _scopeFactory.CreateScope();
            var mssql = scope.ServiceProvider.GetRequiredService<MssqlDbContext>();
            var pg = scope.ServiceProvider.GetRequiredService<PgDbContext>();
            return await TestConnection(mssql) && await TestConnection(pg);
        }

        public Task StartAutoSyncAsync(int intervalMinutes = 5)
        {
            _autoSyncIntervalMinutes = intervalMinutes <= 0 ? 5 : intervalMinutes;
            _autoSyncRunning = true;
            _nextAutoSync = DateTime.UtcNow.AddMinutes(_autoSyncIntervalMinutes);
            return Task.CompletedTask;
        }

        public Task StopAutoSyncAsync()
        {
            _autoSyncRunning = false;
            _nextAutoSync = null;
            return Task.CompletedTask;
        }

        public Task<bool> IsAutoSyncRunningAsync() => Task.FromResult(_autoSyncRunning);

        #endregion

        #region Helpers

        private async Task<int> SyncTable<TEntity, TKey>(
            DbContext sourceContext,
            DbContext targetContext,
            Expression<Func<TEntity, TKey>> keySelector) where TEntity : class
        {
            var sourceDbSet = sourceContext.Set<TEntity>();
            var targetDbSet = targetContext.Set<TEntity>();
            var keyCompiled = keySelector.Compile();

            // 1. Получаем актуальные данные из source базы (primary PostgreSQL)
            var sourceList = await sourceDbSet.AsNoTracking().ToListAsync();
            var sourceKeys = sourceList.Select(keyCompiled).ToHashSet();

            // 2. УДАЛЕНИЕ: Находим записи в target (standby), которых больше нет в source
            // Для таблиц с зависимостями (Property) сначала удаляем связанные записи
            var targetList = await targetDbSet.ToListAsync();
            int deletedCount = 0;
            
            // Если это Property, сначала удаляем связанные Deals и PropertyReservations
            if (typeof(TEntity) == typeof(Property))
            {
                var propertiesToDelete = targetList.Where(t => !sourceKeys.Contains(keyCompiled(t))).ToList();
                foreach (var propertyToDelete in propertiesToDelete)
                {
                    var propertyId = keyCompiled(propertyToDelete);
                    try
                    {
                        // Преобразуем ключ в int
                        int propertyIdInt = Convert.ToInt32(propertyId);
                        
                        // Удаляем связанные Deals
                        var dealsToDelete = await targetContext.Set<Deal>()
                            .Where(d => d.property_id == propertyIdInt)
                            .ToListAsync();
                        if (dealsToDelete.Any())
                        {
                            targetContext.Set<Deal>().RemoveRange(dealsToDelete);
                            await targetContext.SaveChangesAsync();
                        }

                        // Удаляем связанные PropertyReservations
                        var reservationsToDelete = await targetContext.Set<PropertyReservation>()
                            .Where(pr => pr.property_id == propertyIdInt)
                            .ToListAsync();
                        if (reservationsToDelete.Any())
                        {
                            targetContext.Set<PropertyReservation>().RemoveRange(reservationsToDelete);
                            await targetContext.SaveChangesAsync();
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning($"Ошибка при удалении связанных записей для Property {propertyId}: {ex.Message}");
                    }
                }
            }

            // Теперь удаляем основные записи
            foreach (var targetItem in targetList)
            {
                if (!sourceKeys.Contains(keyCompiled(targetItem)))
                {
                    targetDbSet.Remove(targetItem);
                    deletedCount++;
                }
            }
            if (deletedCount > 0)
            {
                try
                {
                    await targetContext.SaveChangesAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Ошибка при удалении записей из таблицы {typeof(TEntity).Name}");
                    // Продолжаем выполнение, даже если удаление не удалось
                }
            }

            // 3. ДОБАВЛЕНИЕ/ОБНОВЛЕНИЕ:
            int syncedCount = 0;
            var currentTargetKeys = (await targetDbSet.AsNoTracking()
                .Select(keySelector)
                .ToListAsync()).ToHashSet();

            foreach (var item in sourceList)
            {
                var key = keyCompiled(item);
                if (!currentTargetKeys.Contains(key))
                {
                    NormalizeDateTimesToUtc(item);
                    await targetDbSet.AddAsync(item);
                    syncedCount++;
                }
                // Здесь можно добавить Update логику, если данные в source изменились
            }

            try
            {
                await targetContext.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Ошибка при сохранении записей в таблицу {typeof(TEntity).Name}");
                throw;
            }
            
            _logger.LogInformation($"Таблица {typeof(TEntity).Name}: добавлено {syncedCount}, удалено {deletedCount}");

            return syncedCount;
        }

        private async Task<int> SyncTableBidirectional<TEntity, TKey>(
            DbContext leftContext,
            DbContext rightContext,
            Expression<Func<TEntity, TKey>> keySelector) where TEntity : class
        {
            var leftSet = leftContext.Set<TEntity>();
            var rightSet = rightContext.Set<TEntity>();
            var keyCompiled = keySelector.Compile();

            var leftList = await leftSet.AsNoTracking().ToListAsync();
            var rightList = await rightSet.AsNoTracking().ToListAsync();

            var leftKeys = leftList.Select(keyCompiled).ToHashSet();
            var rightKeys = rightList.Select(keyCompiled).ToHashSet();

            var leftToRight = leftList.Where(item => !rightKeys.Contains(keyCompiled(item))).ToList();
            var rightToLeft = rightList.Where(item => !leftKeys.Contains(keyCompiled(item))).ToList();

            int synced = 0;
            synced += await AddMissingInBatchesAsync(rightContext, rightSet, leftToRight, typeof(TEntity));
            synced += await AddMissingInBatchesAsync(leftContext, leftSet, rightToLeft, typeof(TEntity));

            _logger.LogInformation("Таблица {Table}: двусторонне добавлено {Synced}", typeof(TEntity).Name, synced);
            return synced;
        }

        private async Task<int> AddMissingInBatchesAsync<TEntity>(
            DbContext targetContext,
            DbSet<TEntity> targetSet,
            List<TEntity> missingItems,
            Type entityType) where TEntity : class
        {
            if (missingItems.Count == 0)
            {
                return 0;
            }

            int added = 0;
            for (int i = 0; i < missingItems.Count; i += DefaultBatchSize)
            {
                var batch = missingItems.Skip(i).Take(DefaultBatchSize).ToList();
                foreach (var item in batch)
                {
                    NormalizeDateTimesToUtc(item);
                }

                await targetSet.AddRangeAsync(batch);
                await SaveContextForEntityAsync(targetContext, entityType);
                added += batch.Count;

                // Сбрасываем трекинг, иначе при больших объемах память растет лавинообразно.
                targetContext.ChangeTracker.Clear();
            }

            return added;
        }

        private void NormalizeDateTimesToUtc(object entity)
        {
            foreach (var prop in entity.GetType().GetProperties())
            {
                if (prop.PropertyType == typeof(DateTime) || prop.PropertyType == typeof(DateTime?))
                {
                    var value = prop.GetValue(entity);
                    if (value is DateTime dt)
                    {
                        if (dt.Kind == DateTimeKind.Unspecified)
                            prop.SetValue(entity, DateTime.SpecifyKind(dt, DateTimeKind.Utc));
                        else if (dt.Kind == DateTimeKind.Local)
                            prop.SetValue(entity, dt.ToUniversalTime());
                    }
                }
            }
        }

        private async Task SaveContextForEntityAsync(DbContext context, Type entityType)
        {
            var hasAdds = context.ChangeTracker.Entries()
                .Any(e => entityType.IsAssignableFrom(e.Entity.GetType()) && e.State == EntityState.Added);

            if (!hasAdds)
            {
                await context.SaveChangesAsync();
                return;
            }

            if (context is MssqlDbContext)
            {
                var entityModel = context.Model.FindEntityType(entityType);
                var tableName = entityModel?.GetTableName() ?? entityType.Name;
                var schema = entityModel?.GetSchema();
                var fullTableName = string.IsNullOrWhiteSpace(schema)
                    ? $"[{tableName}]"
                    : $"[{schema}].[{tableName}]";

                await context.Database.OpenConnectionAsync();
                await using var tx = await context.Database.BeginTransactionAsync();
                try
                {
                    await context.Database.ExecuteSqlRawAsync($"SET IDENTITY_INSERT {fullTableName} ON");
                    await context.SaveChangesAsync();
                    await context.Database.ExecuteSqlRawAsync($"SET IDENTITY_INSERT {fullTableName} OFF");
                    await tx.CommitAsync();
                }
                finally
                {
                    await context.Database.CloseConnectionAsync();
                }
            }
            else
            {
                await context.SaveChangesAsync();
            }
        }

        private async Task AutoSyncLoopAsync(CancellationToken token)
        {
            while (!token.IsCancellationRequested)
            {
                try
                {
                    if (_autoSyncRunning && _nextAutoSync.HasValue && DateTime.UtcNow >= _nextAutoSync.Value)
                    {
                        await IncrementalSyncAsync();
                        _nextAutoSync = DateTime.UtcNow.AddMinutes(_autoSyncIntervalMinutes);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Ошибка автосинхронизации");
                }

                await Task.Delay(TimeSpan.FromSeconds(10), token);
            }
        }

        private async Task<bool> TestConnection(DbContext ctx)
        {
            try
            {
                return await ctx.Database.CanConnectAsync();
            }
            catch
            {
                return false;
            }
        }

        #endregion
    }
}