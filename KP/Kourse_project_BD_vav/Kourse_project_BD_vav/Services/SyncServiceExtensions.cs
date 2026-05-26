using Kourse_project_BD_vav.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace Kourse_project_BD_vav.Services
{
    public static class SyncServiceExtensions
    {
        public static IServiceCollection AddSyncService(this IServiceCollection services)
        {
            services.AddSingleton<ISyncService, SyncService>();
            services.AddHostedService(provider => provider.GetRequiredService<ISyncService>() as SyncService);
            return services;
        }
    }
}