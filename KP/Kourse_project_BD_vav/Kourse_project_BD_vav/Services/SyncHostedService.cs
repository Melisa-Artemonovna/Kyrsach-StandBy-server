using Microsoft.Extensions.Hosting;
using Kourse_project_BD_vav.Interfaces;
using System.Threading;
using System.Threading.Tasks;

namespace Kourse_project_BD_vav.Services
{
    public class SyncHostedService : IHostedService
    {
        private readonly ISyncService _syncService;

        public SyncHostedService(ISyncService syncService)
        {
            _syncService = syncService;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            return _syncService.StartAutoSyncAsync();
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            return _syncService.StopAutoSyncAsync();
        }
    }
}
