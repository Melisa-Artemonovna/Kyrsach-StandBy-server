using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Kourse_project_BD_vav.Controllers
{
    [Route("[controller]")]
    public class TestController : Controller
    {
        [HttpGet("check-admin")]
        [AllowAnonymous]
        public IActionResult CheckAdmin()
        {
            return Ok(new
            {
                Message = "Тестовый доступ",
                IsAuthenticated = User.Identity?.IsAuthenticated,
                UserName = User.Identity?.Name,
                Claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList(),
                IsInRoleAdmin = User.IsInRole("Admin"),
                IsInRoleRealtor = User.IsInRole("Realtor"),
                IsInRoleClient = User.IsInRole("Client")
            });
        }

        [HttpGet("admin-only")]
        [Authorize(Roles = "Admin")]
        public IActionResult AdminOnly()
        {
            return Ok(new { Message = "Вы вошли как администратор!", User = User.Identity?.Name });
        }

        [HttpGet("create-test-data")]
        [AllowAnonymous]
        public IActionResult CreateTestData()
        {
            return Ok(new
            {
                Message = "Используйте /Account/TestLogin?username=admin для входа",
                QuickLinks = new[]
                {
                    "/Account/TestLogin?username=admin",
                    "/Account/TestLogin?username=realtor",
                    "/Account/TestLogin?username=client",
                    "/Home/Dashboard",
                    "/Test/check-admin"
                }
            });
        }
    }
}