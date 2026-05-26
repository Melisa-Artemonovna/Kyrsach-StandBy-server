using Kourse_project_BD_vav.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kourse_project_BD_vav.Controllers
{
    [Authorize(Roles = "Admin")]
    public class SyncMvcController : Controller
    {
        private readonly ISyncService _syncService;

        public SyncMvcController(ISyncService syncService)
        {
            _syncService = syncService;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var status = await _syncService.GetSyncStatusAsync();
            return View(status);
        }

        [HttpPost]
        public async Task<IActionResult> FullSync()
        {
            try
            {
                var result = await _syncService.FullSyncAsync();

                if (result.Success)
                {
                    TempData["SyncMessage"] = result.Message;
                }
                else
                {
                    TempData["SyncError"] = result.Message;
                }

                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["SyncError"] = $"Ошибка: {ex.Message}";
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        public async Task<IActionResult> IncrementalSync()
        {
            try
            {
                var result = await _syncService.IncrementalSyncAsync();

                if (result.Success)
                {
                    TempData["SyncMessage"] = result.Message;
                }
                else
                {
                    TempData["SyncError"] = result.Message;
                }

                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["SyncError"] = $"Ошибка: {ex.Message}";
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        public async Task<IActionResult> StartAutoSync(int intervalMinutes = 5)
        {
            try
            {
                await _syncService.StartAutoSyncAsync(intervalMinutes);
                TempData["SyncMessage"] = $"Автосинхронизация запущена (интервал: {intervalMinutes} мин)";
            }
            catch (Exception ex)
            {
                TempData["SyncError"] = $"Ошибка: {ex.Message}";
            }

            return RedirectToAction("Index");
        }

        [HttpPost]
        public async Task<IActionResult> StopAutoSync()
        {
            try
            {
                await _syncService.StopAutoSyncAsync();
                TempData["SyncMessage"] = "Автосинхронизация остановлена";
            }
            catch (Exception ex)
            {
                TempData["SyncError"] = $"Ошибка: {ex.Message}";
            }

            return RedirectToAction("Index");
        }
    }
}