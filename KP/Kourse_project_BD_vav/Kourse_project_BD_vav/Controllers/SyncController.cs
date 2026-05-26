using Kourse_project_BD_vav.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace Kourse_project_BD_vav.Controllers
{
    [Authorize(Roles = "Admin")]
    public class SyncController : Controller
    {
        private readonly ISyncService _syncService;

        public SyncController(ISyncService syncService)
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
        public async Task<IActionResult> Sync()
        {
            var result = await _syncService.FullSyncAsync();

            if (result.Success)
            {
                TempData["Message"] = $"✅ {result.Message}";
                TempData["MessageType"] = "success";
            }
            else
            {
                TempData["Message"] = $"❌ {result.Message}";
                TempData["MessageType"] = "danger";
            }

            return RedirectToAction(nameof(Index));
        }

        [HttpGet]
        public async Task<IActionResult> Status()
        {
            var status = await _syncService.GetSyncStatusAsync();
            return Json(new
            {
                status.MssqlConnected,
                status.PgConnected,
                status.LastSync,
                status.TotalRecordsSynced,
                Tables = status.Tables
            });
        }
    }
}