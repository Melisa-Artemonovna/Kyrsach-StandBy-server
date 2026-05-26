using Kourse_project_BD_vav.Interfaces;
using Kourse_project_BD_vav.Data;
using Kourse_project_BD_vav.Models;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Threading.Tasks;

namespace Kourse_project_BD_vav.Controllers
{
    [Authorize(Roles = "Admin")]
    public class SyncPageController : Controller
    {
        private readonly ISyncService _syncService;
        private readonly StoredProcedureService _spService;

        public SyncPageController(ISyncService syncService, StoredProcedureService spService)
        {
            _syncService = syncService;
            _spService = spService;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var status = await _syncService.GetSyncStatusAsync();
            return View("~/Views/Sync/Index.cshtml", status);
        }

        // -----------------------------
        // Полная синхронизация
        // -----------------------------
        [HttpPost]
        public async Task<IActionResult> FullSync()
        {
            var result = await _syncService.FullSyncAsync();
            return View("~/Views/Home/SyncResult.cshtml", result);
        }

        [HttpPost]
        public async Task<IActionResult> IncrementalSync()
        {
            var result = await _syncService.IncrementalSyncAsync();
            return View("~/Views/Home/SyncResult.cshtml", result);
        }


        // -----------------------------
        // Автосинхронизация
        // -----------------------------
        [HttpPost]
        public async Task<IActionResult> StartAutoSync([FromForm] int intervalMinutes = 5)
        {
            await _syncService.StartAutoSyncAsync(intervalMinutes);
            TempData["SyncMessage"] = $"Автосинхронизация запущена (интервал: {intervalMinutes} минут)";
            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        public async Task<IActionResult> StopAutoSync()
        {
            await _syncService.StopAutoSyncAsync();
            TempData["SyncMessage"] = "Автосинхронизация остановлена";
            return RedirectToAction(nameof(Index));
        }

        [HttpGet("status")]
        public async Task<IActionResult> GetStatusJson()
        {
            var status = await _syncService.GetSyncStatusAsync();
            return Json(new
            {
                status.MssqlConnected,
                status.PgConnected,
                status.LastSync,
                status.TotalRecordsSynced,
                ReplicationLag = status.ReplicationLag.ToString(@"hh\:mm\:ss"),
                status.AutoSyncEnabled,
                status.NextAutoSync,
                Tables = status.Tables
            });
        }

        // -----------------------------
        // Экспорт/Импорт Deals
        // -----------------------------

        [HttpGet]
        public async Task<IActionResult> ExportDeals()
        {
            try
            {
                // Используем процедуру для получения всех сделок
                var deals = await _spService.GetAllDealsAsync();

                var json = JsonSerializer.Serialize(deals, new JsonSerializerOptions
                {
                    WriteIndented = true,
                    Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                });

                var fileName = $"deals_export_{DateTime.Now:yyyyMMdd_HHmmss}.json";
                var bytes = System.Text.Encoding.UTF8.GetBytes(json);

                return File(bytes, "application/json", fileName);
            }
            catch (Exception ex)
            {
                TempData["SyncError"] = $"Ошибка экспорта: {ex.Message}";
                return RedirectToAction(nameof(Index));
            }
        }

        [HttpPost]
        public async Task<IActionResult> ImportDeals(IFormFile file)
        {
            try
            {
                if (file == null || file.Length == 0)
                {
                    TempData["SyncError"] = "Файл не выбран или пуст";
                    return RedirectToAction(nameof(Index));
                }

                if (!file.FileName.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
                {
                    TempData["SyncError"] = "Неверный формат файла. Требуется JSON";
                    return RedirectToAction(nameof(Index));
                }

                using var stream = new System.IO.StreamReader(file.OpenReadStream());
                var json = await stream.ReadToEndAsync();
                var deals = JsonSerializer.Deserialize<List<Deal>>(json);

                if (deals == null || deals.Count == 0)
                {
                    TempData["SyncError"] = "Файл не содержит данных";
                    return RedirectToAction(nameof(Index));
                }

                // Получаем все существующие сделки через процедуру и удаляем их
                var existingDeals = await _spService.GetAllDealsAsync();
                foreach (var deal in existingDeals)
                {
                    await _spService.DeleteDealAsync(deal.deal_id);
                }

                // Добавляем новые сделки через процедуры
                foreach (var deal in deals)
                {
                    await _spService.CreateDealAsync(deal);
                }

                TempData["SyncMessage"] = $"Успешно импортировано {deals.Count} сделок";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["SyncError"] = $"Ошибка импорта: {ex.Message}";
                return RedirectToAction(nameof(Index));
            }
        }
    }
}
