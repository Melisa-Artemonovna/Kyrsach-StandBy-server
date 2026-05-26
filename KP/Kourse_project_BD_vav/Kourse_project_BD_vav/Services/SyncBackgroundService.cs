using Kourse_project_BD_vav.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Kourse_project_BD_vav.Services
{
    public class SyncBackgroundService : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<SyncBackgroundService> _logger;
        private readonly TimeSpan _syncInterval = TimeSpan.FromMinutes(5);
        private bool _isRunning = false;

        public SyncBackgroundService(
            IServiceScopeFactory scopeFactory,
            ILogger<SyncBackgroundService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        public bool IsRunning => _isRunning;

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🚀 Фоновая служба синхронизации запущена. Интервал: {Interval} минут",
                _syncInterval.TotalMinutes);

            _isRunning = true;

            // Первая синхронизация при старте с задержкой
            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = _scopeFactory.CreateScope();
                    var syncService = scope.ServiceProvider.GetRequiredService<ISyncService>();

                    _logger.LogInformation("🔄 Запуск автоматической синхронизации");

                    // Получаем статус системы
                    var status = await syncService.GetSyncStatusAsync();

                    if (status.MssqlConnected && status.PgConnected)
                    {
                        // Проверяем, есть ли несинхронизированные таблицы
                        var outOfSyncTables = status.Tables.Where(t => !t.IsSynced).ToList();

                        if (outOfSyncTables.Any())
                        {
                            _logger.LogInformation("Найдено {Count} несинхронизированных таблиц", outOfSyncTables.Count);
                            await syncService.IncrementalSyncAsync();
                        }
                        else
                        {
                            _logger.LogDebug("Все таблицы синхронизированы");
                        }
                    }
                    else
                    {
                        _logger.LogWarning("Проблемы с подключением к БД, пропускаем синхронизацию");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Ошибка в фоновой синхронизации");
                }

                // Ждем до следующей проверки
                await Task.Delay(_syncInterval, stoppingToken);
            }

            _isRunning = false;
            _logger.LogInformation("🛑 Фоновая служба синхронизации остановлена");
        }
    }
}