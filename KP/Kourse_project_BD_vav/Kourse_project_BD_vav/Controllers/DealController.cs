using Kourse_project_BD_vav.Models;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.Security.Claims;

namespace Kourse_project_BD_vav.Controllers
{
    [Authorize(Roles = "Admin,Realtor,Client")]
    public class DealController : Controller
    {
        private readonly StoredProcedureService _spService;

        public DealController(StoredProcedureService spService)
        {
            _spService = spService;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            // Используем процедуру вместо прямого запроса
            var user = await _spService.GetUserByIdAsync(userId);

            // Если пользователь - клиент, редиректим на MyDeals
            if (user?.role == "Client")
            {
                return RedirectToAction("MyDeals");
            }

            List<Deal> deals;

            if (user?.role == "Realtor")
            {
                // Используем процедуру вместо прямого запроса
                var realtor = await _spService.GetRealtorByUserIdAsync(userId);
                Console.WriteLine($"=== Deal/Index для риэлтора ===");
                Console.WriteLine($"User ID: {userId}");
                Console.WriteLine($"Realtor found: {realtor != null}");
                if (realtor != null)
                {
                    Console.WriteLine($"Realtor ID: {realtor.realtor_id}");
                    // Используем процедуру вместо прямого запроса
                    deals = await _spService.GetDealsByRealtorIdAsync(realtor.realtor_id);
                    Console.WriteLine($"Найдено сделок: {deals.Count}");

                    // Статистика по периодам (неделя, месяц) через процедуру
                    var weekStart = DateTime.Now.AddDays(-7);
                    var currentMonthStart = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
                    
                    var (weekCount, weekAmount) = await _spService.GetRealtorDealStatsAsync(realtor.realtor_id, weekStart, DateTime.Now);
                    var (monthCount, monthAmount) = await _spService.GetRealtorDealStatsAsync(realtor.realtor_id, currentMonthStart, DateTime.Now);

                    ViewBag.PeriodStats = new
                    {
                        WeekDealsCount = weekCount,
                        WeekDealsAmount = weekAmount,
                        MonthDealsCount = monthCount,
                        MonthDealsAmount = monthAmount
                    };
                }
                else
                {
                    Console.WriteLine("Риэлтор не найден!");
                    Console.WriteLine($"Для user_id={userId} нет записи в таблице Realtors");
                    TempData["ErrorMessage"] = "Профиль риэлтора не найден. Обратитесь к администратору для создания профиля.";
                    deals = new List<Deal>();
                    ViewBag.PeriodStats = new
                    {
                        WeekDealsCount = 0,
                        WeekDealsAmount = 0m,
                        MonthDealsCount = 0,
                        MonthDealsAmount = 0m
                    };
                }
            }
            else // Admin
            {
                // Используем процедуру вместо прямого запроса
                deals = await _spService.GetAllDealsAsync();
            }

            // Загружаем связанные данные (Client, Property) для всех сделок
            if (deals != null && deals.Any())
            {
                var clientIds = deals.Where(d => d.client_id > 0).Select(d => d.client_id).Distinct().ToList();
                var propertyIds = deals.Where(d => d.property_id > 0).Select(d => d.property_id).Distinct().ToList();

                var clients = new Dictionary<int, Client>();
                foreach (var clientId in clientIds)
                {
                    var client = await _spService.GetClientByIdAsync(clientId);
                    if (client != null)
                    {
                        clients[clientId] = client;
                    }
                }

                var properties = new Dictionary<int, Property>();
                foreach (var propertyId in propertyIds)
                {
                    var property = await _spService.GetPropertyByIdAsync(propertyId);
                    if (property != null)
                    {
                        properties[propertyId] = property;
                    }
                }

                foreach (var deal in deals)
                {
                    if (deal.client_id > 0 && clients.ContainsKey(deal.client_id))
                    {
                        deal.client = clients[deal.client_id];
                    }
                    if (deal.property_id > 0 && properties.ContainsKey(deal.property_id))
                    {
                        deal.property = properties[deal.property_id];
                    }
                }
            }

            return View(deals);
        }

        [HttpGet]
        [Authorize(Roles = "Client")]
        public async Task<IActionResult> MyDeals()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            // Используем процедуру вместо прямого запроса
            var user = await _spService.GetUserByIdAsync(userId);

            if (user?.role != "Client")
            {
                return RedirectToAction("Index");
            }

            // Используем процедуру вместо прямого запроса
            var client = await _spService.GetClientByUserIdAsync(userId);
            if (client == null)
            {
                return View(new List<Deal>());
            }

            // Используем процедуру вместо прямого запроса
            var deals = await _spService.GetDealsByClientIdAsync(client.client_id);

            return View(deals);
        }

        [HttpGet]
        [Authorize(Roles = "Admin,Realtor")]
        public async Task<IActionResult> Create()
        {
            try
            {
                // Используем процедуры для получения данных формы
                var allProperties = await _spService.GetAllPropertiesAsync();
                var properties = allProperties.Where(p => p.is_available).OrderBy(p => p.address).ToList();

                var clients = await _spService.GetAllClientsAsync();
                clients = clients.OrderBy(c => c.full_name).ToList();

                var realtors = await _spService.GetAllRealtorsAsync();
                realtors = realtors.OrderBy(r => r.full_name).ToList();

                ViewBag.Properties = new SelectList(properties, "property_id", "address");
                ViewBag.Clients = new SelectList(clients, "client_id", "full_name");
                ViewBag.Realtors = new SelectList(realtors, "realtor_id", "full_name");

                // Если риэлтор, автоматически назначаем его
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                // Используем процедуру вместо прямого запроса
                var user = await _spService.GetUserByIdAsync(userId);

                if (user?.role == "Realtor")
                {
                    // Используем процедуру вместо прямого запроса
                    var realtor = await _spService.GetRealtorByUserIdAsync(userId);
                    if (realtor != null)
                    {
                        ViewBag.CurrentRealtorId = realtor.realtor_id;
                    }
                }

                // Создаем новую сделку с дефолтными значениями
                return View(new Deal
                {
                    deal_date = DateTime.UtcNow,
                    deal_type = "Продажа",
                    deal_status = "В обработке",
                    deal_price = 1000000
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка в Create (GET): {ex.Message}");
                TempData["ErrorMessage"] = "Ошибка при загрузке формы";
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        [Authorize(Roles = "Admin,Realtor")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Deal deal)
        {
            try
            {
                Console.WriteLine("=== ПОПЫТКА СОЗДАНИЯ СДЕЛКИ ===");

                // Проверяем обязательные поля
                if (deal.property_id <= 0)
                {
                    TempData["ErrorMessage"] = "Выберите объект недвижимости";
                    return RedirectToAction("Create");
                }

                if (deal.client_id <= 0)
                {
                    TempData["ErrorMessage"] = "Выберите клиента";
                    return RedirectToAction("Create");
                }

                if (string.IsNullOrEmpty(deal.deal_type))
                {
                    TempData["ErrorMessage"] = "Выберите тип сделки";
                    return RedirectToAction("Create");
                }

                if (deal.deal_price <= 0)
                {
                    TempData["ErrorMessage"] = "Введите корректную сумму";
                    return RedirectToAction("Create");
                }

                // Получаем текущего пользователя
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                // Используем процедуру вместо прямого запроса
                var user = await _spService.GetUserByIdAsync(userId);

                // Если риэлтор, назначаем его автоматически
                if (user?.role == "Realtor")
                {
                    // Используем процедуру вместо прямого запроса
                    var realtor = await _spService.GetRealtorByUserIdAsync(userId);
                    if (realtor == null)
                    {
                        Console.WriteLine("ОШИБКА: Риэлтор не найден для пользователя! Создаем профиль автоматически...");
                        
                        // Создаем профиль риэлтора автоматически через процедуру
                        var newRealtor = new Realtor
                        {
                            full_name = user.full_name,
                            email = user.email,
                            phone_number = "+375 (29) 000-00-00",
                            hire_date = DateTime.UtcNow,
                            commission_rate = 5.0m,
                            user_id = user.user_id
                        };
                        
                        var realtorId = await _spService.CreateRealtorAsync(newRealtor);
                        newRealtor.realtor_id = realtorId;
                        
                        // Обновляем user.realtor_id через процедуру
                        user.realtor_id = realtorId;
                        await _spService.UpdateUserAsync(user);
                        
                        realtor = newRealtor;
                        Console.WriteLine($"Профиль риэлтора автоматически создан: ID={realtor.realtor_id}");
                    }
                    
                    deal.realtor_id = realtor.realtor_id;
                    Console.WriteLine($"=== СОЗДАНИЕ СДЕЛКИ РИЭЛТОРОМ ===");
                    Console.WriteLine($"Realtor ID: {realtor.realtor_id}");
                    Console.WriteLine($"Deal Realtor ID установлен: {deal.realtor_id}");
                }

                // Устанавливаем дату если не задана
                if (deal.deal_date == DateTime.MinValue)
                {
                    deal.deal_date = DateTime.UtcNow;
                }

                // Устанавливаем статус по умолчанию
                if (string.IsNullOrEmpty(deal.deal_status))
                {
                    deal.deal_status = "В обработке";
                }

                Console.WriteLine($"=== ПОПЫТКА СОЗДАНИЯ СДЕЛКИ ===");
                Console.WriteLine($"Property ID: {deal.property_id}");
                Console.WriteLine($"Client ID: {deal.client_id}");
                Console.WriteLine($"Realtor ID: {deal.realtor_id}");
                Console.WriteLine($"Deal Type: {deal.deal_type}");
                Console.WriteLine($"Deal Price: {deal.deal_price}");

                // Используем процедуру для создания сделки
                var dealId = await _spService.CreateDealAsync(deal);
                deal.deal_id = dealId;

                Console.WriteLine($"Сделка создана! ID: {deal.deal_id}, Realtor ID: {deal.realtor_id}");
                TempData["SuccessMessage"] = $"Сделка успешно создана! ID: {deal.deal_id}";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка при создании сделки: {ex.Message}");
                TempData["ErrorMessage"] = $"Ошибка: {ex.Message}";
                return RedirectToAction("Create");
            }
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                Console.WriteLine($"=== DELETE DEAL START ===");
                Console.WriteLine($"Request method: {Request.Method}");
                Console.WriteLine($"Request path: {Request.Path}");
                Console.WriteLine($"Has AntiForgeryToken: {Request.Form.ContainsKey("__RequestVerificationToken")}");
                Console.WriteLine($"Deleting deal ID: {id}");
                Console.WriteLine($"User authenticated: {User.Identity?.IsAuthenticated}");
                Console.WriteLine($"User role: {User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value}");
                Console.WriteLine($"User ID: {User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value}");

                // Используем процедуру вместо прямого запроса
                var deal = await _spService.GetDealByIdAsync(id);
                if (deal == null)
                {
                    TempData["ErrorMessage"] = "Сделка не найдена";
                    Console.WriteLine($"Deal with ID {id} not found");
                    return RedirectToAction("Index");
                }

                // Используем процедуру для удаления
                Console.WriteLine($"Calling DeleteDealAsync for ID: {id}");
                await _spService.DeleteDealAsync(id);
                Console.WriteLine($"DeleteDealAsync completed for ID: {id}");

                TempData["SuccessMessage"] = "Сделка удалена";
                Console.WriteLine($"Deal {id} deleted successfully");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"=== ERROR DELETING DEAL ===");
                Console.WriteLine($"Error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
                    Console.WriteLine($"Inner stack trace: {ex.InnerException.StackTrace}");
                }
                TempData["ErrorMessage"] = $"Ошибка при удалении: {ex.Message}";
            }
            finally
            {
                Console.WriteLine($"=== DELETE DEAL FINALLY ===");
                Console.WriteLine($"User still authenticated: {User.Identity?.IsAuthenticated}");
                Console.WriteLine($"User role: {User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value}");
                Console.WriteLine($"User ID: {User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value}");
            }
            
            Console.WriteLine($"Redirecting to Index. User still authenticated: {User.Identity?.IsAuthenticated}");
            
            // Используем обычный RedirectToAction - он должен работать правильно
            return RedirectToAction("Index");
        }
    }
}