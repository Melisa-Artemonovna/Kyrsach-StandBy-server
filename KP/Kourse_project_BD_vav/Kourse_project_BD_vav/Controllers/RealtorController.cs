using Kourse_project_BD_vav.Models;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Linq;

namespace Kourse_project_BD_vav.Controllers
{
    [Authorize(Roles = "Admin")]
    public class RealtorController : Controller
    {
        private readonly StoredProcedureService _spService;

        public RealtorController(StoredProcedureService spService)
        {
            _spService = spService;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            Console.WriteLine($"=== REALTOR INDEX ===");
            Console.WriteLine($"User authenticated: {User.Identity?.IsAuthenticated}");
            Console.WriteLine($"User role: {User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value}");
            Console.WriteLine($"User ID: {User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value}");
            Console.WriteLine($"Request cookies count: {Request.Cookies.Count}");
            foreach (var cookie in Request.Cookies)
            {
                Console.WriteLine($"Cookie in request: {cookie.Key}");
            }
            
            var realtors = await _spService.GetAllRealtorsAsync();
            Console.WriteLine($"Loaded {realtors.Count} realtors");
            return View(realtors);
        }

        [HttpGet]
        public IActionResult Create()
        {
            Console.WriteLine($"=== CREATE GET - REALTOR ===");
            Console.WriteLine($"User authenticated: {User.Identity?.IsAuthenticated}");
            return View(new Realtor
            {
                hire_date = DateTime.Now,
                commission_rate = 5.0m
            });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Realtor realtor)
        {
            try
            {
                Console.WriteLine($"=== CREATE POST - REALTOR ===");
                Console.WriteLine($"User authenticated: {User.Identity?.IsAuthenticated}");
                Console.WriteLine($"User role: {User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value}");
                Console.WriteLine($"User ID: {User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value}");
                Console.WriteLine($"Realtor name: {realtor?.full_name}");
                Console.WriteLine($"Realtor email: {realtor?.email}");
                
                // Парсим значения из формы вручную, если они не были правильно извлечены
                if (Request.Form.ContainsKey("hire_date"))
                {
                    if (DateTime.TryParse(Request.Form["hire_date"], out var hireDate))
                    {
                        realtor.hire_date = hireDate;
                        Console.WriteLine($"Parsed hire_date from form: {hireDate}");
                    }
                }
                
                if (Request.Form.ContainsKey("commission_rate"))
                {
                    // Используем инвариантную культуру для парсинга decimal
                    if (decimal.TryParse(Request.Form["commission_rate"], System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var commissionRate))
                    {
                        realtor.commission_rate = commissionRate;
                        Console.WriteLine($"Parsed commission_rate from form: {commissionRate}");
                    }
                    else
                    {
                        Console.WriteLine($"Failed to parse commission_rate: {Request.Form["commission_rate"]}");
                        ModelState.AddModelError("commission_rate", "Неверный формат комиссии. Используйте точку как разделитель (например: 5.0)");
                    }
                }

                if (!ModelState.IsValid)
                {
                    Console.WriteLine("ModelState невалиден:");
                    foreach (var error in ModelState.Values.SelectMany(v => v.Errors))
                    {
                        Console.WriteLine($"Error: {error.ErrorMessage}");
                    }
                    return View(realtor);
                }

                // Устанавливаем значения по умолчанию, если не указаны
                if (realtor.hire_date == default(DateTime))
                {
                    realtor.hire_date = DateTime.Now;
                }
                if (realtor.commission_rate == default(decimal))
                {
                    realtor.commission_rate = 5.0m;
                }

                // Используем процедуру для создания
                var realtorId = await _spService.CreateRealtorAsync(realtor);
                realtor.realtor_id = realtorId;

                Console.WriteLine($"Realtor created successfully with ID: {realtorId}");
                TempData["SuccessMessage"] = $"Риэлтор '{realtor.full_name}' успешно добавлен!";
                
                Console.WriteLine($"Redirecting to Index. User still authenticated: {User.Identity?.IsAuthenticated}");
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"=== ERROR CREATING REALTOR ===");
                Console.WriteLine($"Error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
                }
                TempData["ErrorMessage"] = $"Ошибка при создании риэлтора: {ex.Message}";
                return View(realtor);
            }
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            Console.WriteLine($"=== EDIT GET - REALTOR ID: {id} ===");
            Console.WriteLine($"User authenticated: {User.Identity?.IsAuthenticated}");
            
            var realtor = await _spService.GetRealtorByIdAsync(id);
            if (realtor == null)
            {
                Console.WriteLine($"Realtor with ID {id} not found");
                return NotFound();
            }
            return View(realtor);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, [FromForm] Realtor realtor)
        {
            Console.WriteLine($"=== EDIT POST ===");
            Console.WriteLine($"Route ID: {id}");
            Console.WriteLine($"Model ID: {realtor?.realtor_id}");
            Console.WriteLine($"Name: {realtor?.full_name}");

            // Если модель null, создаем новую из формы
            if (realtor == null)
            {
                Console.WriteLine("Model is null, creating from form...");
                realtor = new Realtor();
                await TryUpdateModelAsync(realtor);
                Console.WriteLine($"After TryUpdateModel: ID={realtor.realtor_id}, Name={realtor.full_name}");
            }
            
            // Парсим значения из формы вручную, если они не были правильно извлечены
            if (Request.Form.ContainsKey("hire_date"))
            {
                if (DateTime.TryParse(Request.Form["hire_date"], out var hireDate))
                {
                    realtor.hire_date = hireDate;
                    Console.WriteLine($"Parsed hire_date from form: {hireDate}");
                }
            }
            
            if (Request.Form.ContainsKey("commission_rate"))
            {
                if (decimal.TryParse(Request.Form["commission_rate"], out var commissionRate))
                {
                    realtor.commission_rate = commissionRate;
                    Console.WriteLine($"Parsed commission_rate from form: {commissionRate}");
                }
            }

            if (id != realtor.realtor_id)
            {
                Console.WriteLine($"ID mismatch! Route: {id}, Model: {realtor.realtor_id}");

                // Пробуем исправить ID
                realtor.realtor_id = id;
                Console.WriteLine($"Fixed ID to: {realtor.realtor_id}");
            }

            // Находим существующего риэлтора через процедуру
            var existingRealtor = await _spService.GetRealtorByIdAsync(id);
            if (existingRealtor == null)
            {
                Console.WriteLine("Realtor not found in DB!");
                TempData["ErrorMessage"] = "Риэлтор не найден";
                return RedirectToAction(nameof(Index));
            }

            Console.WriteLine($"Before update: {existingRealtor.full_name}");
            Console.WriteLine($"Form hire_date: {realtor.hire_date}");
            Console.WriteLine($"Form commission_rate: {realtor.commission_rate}");

            // Обновляем данные
            existingRealtor.full_name = realtor.full_name;
            existingRealtor.phone_number = realtor.phone_number;
            existingRealtor.email = realtor.email;
            
            // Правильно обрабатываем дату найма
            if (realtor.hire_date != default(DateTime))
            {
                existingRealtor.hire_date = realtor.hire_date;
            }
            // Если дата не передана, оставляем существующую
            
            // Правильно обрабатываем комиссию
            if (realtor.commission_rate != default(decimal))
            {
                existingRealtor.commission_rate = realtor.commission_rate;
            }
            // Если комиссия не передана, оставляем существующую

            Console.WriteLine($"After update: {existingRealtor.full_name}");
            Console.WriteLine($"Final hire_date: {existingRealtor.hire_date}");
            Console.WriteLine($"Final commission_rate: {existingRealtor.commission_rate}");

            try
            {
                // Сохраняем изменения через процедуру
                await _spService.UpdateRealtorAsync(existingRealtor);
                Console.WriteLine("Realtor updated via stored procedure");

                TempData["SuccessMessage"] = $"Данные риэлтора '{existingRealtor.full_name}' успешно обновлены!";

                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
                TempData["ErrorMessage"] = $"Ошибка: {ex.Message}";
                return View(realtor);
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                Console.WriteLine($"=== DELETE REALTOR START ===");
                Console.WriteLine($"Request method: {Request.Method}");
                Console.WriteLine($"Request path: {Request.Path}");
                Console.WriteLine($"Has AntiForgeryToken: {Request.Form.ContainsKey("__RequestVerificationToken")}");
                Console.WriteLine($"Deleting realtor ID: {id}");
                Console.WriteLine($"User authenticated: {User.Identity?.IsAuthenticated}");
                Console.WriteLine($"User role: {User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value}");
                Console.WriteLine($"User ID: {User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value}");

                var realtor = await _spService.GetRealtorByIdAsync(id);
                if (realtor != null)
                {
                    Console.WriteLine($"Found realtor: {realtor.full_name}, ID: {realtor.realtor_id}");
                    await _spService.DeleteRealtorAsync(id);
                    Console.WriteLine($"DeleteRealtorAsync completed for ID: {id}");
                    TempData["SuccessMessage"] = $"Риэлтор '{realtor.full_name}' успешно удален!";
                    Console.WriteLine($"Realtor {realtor.full_name} deleted successfully");
                }
                else
                {
                    TempData["ErrorMessage"] = "Риэлтор не найден";
                    Console.WriteLine($"Realtor with ID {id} not found");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"=== ERROR DELETING REALTOR ===");
                Console.WriteLine($"Error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
                    Console.WriteLine($"Inner stack trace: {ex.InnerException.StackTrace}");
                }
                TempData["ErrorMessage"] = $"Не удалось удалить риэлтора: {ex.Message}";
            }
            finally
            {
                Console.WriteLine($"=== DELETE REALTOR FINALLY ===");
                Console.WriteLine($"User still authenticated: {User.Identity?.IsAuthenticated}");
                Console.WriteLine($"User role: {User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value}");
                Console.WriteLine($"User ID: {User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value}");
            }
            
            Console.WriteLine($"Redirecting to Index. User still authenticated: {User.Identity?.IsAuthenticated}");
            
            // Используем обычный RedirectToAction - он должен работать правильно
            return RedirectToAction(nameof(Index));
        }
    }
}