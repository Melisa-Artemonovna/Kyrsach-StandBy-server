using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Kourse_project_BD_vav.Interfaces
{
    public interface ISyncService
    {
        Task<SyncResult> FullSyncAsync();
        Task<SyncResult> IncrementalSyncAsync();
        Task<SyncStatus> GetSyncStatusAsync();
        Task<bool> CheckDatabaseConnectivityAsync();
        Task StartAutoSyncAsync(int intervalMinutes = 5);
        Task StopAutoSyncAsync();
        Task<bool> IsAutoSyncRunningAsync();
    }

    public class SyncResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public int TotalRecordsSynced { get; set; }
        public int RecordsSynced { get; set; }  // <- добавляем это
        public int TablesSynced { get; set; }
        public TimeSpan Duration { get; set; }
        public string? ErrorMessage { get; set; }
        public DateTime StartedAt { get; set; } = DateTime.UtcNow;
        public DateTime? CompletedAt { get; set; }
        public List<TableSyncResult> Tables { get; set; } = new List<TableSyncResult>();
    }

    public class TableSyncResult
    {
        public string TableName { get; set; } = string.Empty;
        public bool IsSuccess { get; set; }
        public int RecordsSynced { get; set; }
        public string? Error { get; set; }
        public TimeSpan Duration { get; set; }
        public DateTime SyncedAt { get; set; }
    }

    public class SyncStatus
    {
        public bool MssqlConnected { get; set; }
        public bool PgConnected { get; set; }
        public DateTime? LastSync { get; set; }
        public int TotalRecordsSynced { get; set; }
        public List<TableStatus> Tables { get; set; } = new List<TableStatus>();
        public TimeSpan ReplicationLag { get; set; } // Добавил
        public bool AutoSyncEnabled { get; set; }
        public DateTime? NextAutoSync { get; set; }
        public SystemHealth SystemHealth { get; set; } = new SystemHealth(); // Добавил
    }

    public class TableStatus
    {
        public string Name { get; set; } = string.Empty;
        public int MssqlCount { get; set; }
        public int PgCount { get; set; }
        public bool IsSynced => MssqlCount == PgCount;
        public int Difference => Math.Abs(MssqlCount - PgCount);
        public DateTime? LastSyncedAt { get; set; } // Добавил
        public string StatusColor => IsSynced ? "success" : Difference > 10 ? "danger" : "warning";
    }

    // Добавил класс SystemHealth
    public class SystemHealth
    {
        public string Status { get; set; } = "Unknown";
        public List<HealthCheck> Checks { get; set; } = new List<HealthCheck>();
        public DateTime CheckedAt { get; set; } = DateTime.UtcNow;
    }

    public class HealthCheck
    {
        public string Component { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public TimeSpan Duration { get; set; }
    }

    public class SyncProgress
    {
        public string CurrentTable { get; set; } = string.Empty;
        public int CurrentTableNumber { get; set; }
        public int TotalTables { get; set; }
        public int RecordsProcessed { get; set; }
        public int TotalRecords { get; set; }
        public double Percentage { get; set; }
        public string StatusMessage { get; set; } = string.Empty;
        public bool IsRunning { get; set; }
        public DateTime StartedAt { get; set; }
        public DateTime? EstimatedCompletion { get; set; }
    }
}