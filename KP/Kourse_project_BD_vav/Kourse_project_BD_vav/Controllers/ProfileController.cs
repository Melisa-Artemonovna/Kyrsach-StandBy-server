using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Kourse_project_BD_vav.Controllers
{
    [Authorize]
    public class ProfileController : Controller
    {
        private readonly StoredProcedureService _spService;

        public ProfileController(StoredProcedureService spService)
        {
            _spService = spService;
        }

        [Route("Profile")]
        public async Task<IActionResult> Index()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            var user = await _spService.GetUserByIdAsync(userId);

            if (user == null)
            {
                return NotFound();
            }

            ViewBag.User = user;

            return View();
        }
    }
}