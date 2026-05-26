// SyncHub.cs
using Kourse_project_BD_vav.Interfaces;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace Kourse_project_BD_vav.Hubs
{
    public class SyncHub : Hub
    {
        public async Task SendProgress(SyncProgress progress)
        {
            await Clients.All.SendAsync("UpdateProgress", progress);
        }

        public async Task SendSyncResult(SyncResult result)
        {
            await Clients.All.SendAsync("SyncCompleted", result);
        }
    }
}