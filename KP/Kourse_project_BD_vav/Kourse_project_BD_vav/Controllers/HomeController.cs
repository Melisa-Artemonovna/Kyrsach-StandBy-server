using Kourse_project_BD_vav.Interfaces;
using Kourse_project_BD_vav.Models;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using System.Security.Claims;

namespace Kourse_project_BD_vav.Controllers
{
    public class HomeController : Controller
    {
        private readonly ISyncService _syncService;
        private readonly StoredProcedureService _spService;

        public HomeController(ISyncService syncService, StoredProcedureService spService)
        {
            _syncService = syncService;
            _spService = spService;
        }

        [AllowAnonymous]
        public IActionResult Index()
        {
            return View();
        }

        [Authorize]
        public async Task<IActionResult> Dashboard()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            // Используем процедуру вместо прямого запроса
            var user = await _spService.GetUserByIdAsync(userId);
            
            // Сначала берем роль из Claims, если нет - из базы данных, иначе по умолчанию
            var userRole = User.FindFirst(ClaimTypes.Role)?.Value 
                ?? user?.role 
                ?? "Client";

            ViewBag.UserRole = userRole;
            ViewBag.UserName = user?.full_name ?? User.Identity?.Name ?? "Пользователь";

            Console.WriteLine($"=== Dashboard ===");
            Console.WriteLine($"User ID: {userId}");
            Console.WriteLine($"User Role from Claims: {User.FindFirst(ClaimTypes.Role)?.Value}");
            Console.WriteLine($"User Role from DB: {user?.role}");
            Console.WriteLine($"Final User Role: {userRole}");
            Console.WriteLine($"Username: {ViewBag.UserName}");

            if (userRole == "Admin")
            {
                // Админ статистика через процедуры
                var allClients = await _spService.GetAllClientsAsync();
                var allRealtors = await _spService.GetAllRealtorsAsync();
                var allProperties = await _spService.GetAllPropertiesAsync();
                var allDeals = await _spService.GetAllDealsAsync();
                
                ViewBag.Stats = new
                {
                    TotalClients = allClients.Count,
                    TotalRealtors = allRealtors.Count,
                    TotalProperties = allProperties.Count,
                    ActiveDeals = allDeals.Count(d => d.deal_date >= DateTime.Now.AddMonths(-1))
                };

                Console.WriteLine($"Admin stats loaded");
            }
            else if (userRole == "Realtor")
            {
                // Риэлтор статистика через процедуры
                var realtor = await _spService.GetRealtorByUserIdAsync(userId);

                if (realtor == null)
                {
                    Console.WriteLine($"Риэлтор не найден для user_id: {userId}, создаем профиль автоматически...");
                    
                    // Получаем данные пользователя через процедуру
                    var realtorUser = await _spService.GetUserByIdAsync(userId);
                    if (realtorUser != null)
                    {
                        // Создаем профиль риэлтора автоматически через процедуру
                        var newRealtor = new Realtor
                        {
                            full_name = realtorUser.full_name,
                            email = realtorUser.email,
                            phone_number = "+375 (29) 000-00-00",
                            hire_date = DateTime.Now,
                            commission_rate = 5.0m,
                            user_id = realtorUser.user_id
                        };
                        
                        var realtorId = await _spService.CreateRealtorAsync(newRealtor);
                        newRealtor.realtor_id = realtorId;
                        
                        // Обновляем realtorUser.realtor_id через процедуру
                        realtorUser.realtor_id = realtorId;
                        await _spService.UpdateUserAsync(realtorUser);
                        
                        realtor = newRealtor;
                        Console.WriteLine($"Профиль риэлтора автоматически создан: ID={realtor.realtor_id}");
                    }
                }

                if (realtor != null)
                {
                    ViewBag.Realtor = realtor;
                    
                    // Получаем данные через процедуры
                    var myProperties = await _spService.GetPropertiesByRealtorIdAsync(realtor.realtor_id);
                    var myDeals = await _spService.GetDealsByRealtorIdAsync(realtor.realtor_id);
                    
                    ViewBag.Stats = new
                    {
                        MyProperties = myProperties.Count,
                        MyDeals = myDeals.Count,
                        ActiveProperties = myProperties.Count(p => p.is_available)
                    };

                    Console.WriteLine($"Realtor stats loaded: {realtor.full_name}");
                }
            }
            else // Client
            {
                // Клиент статистика - ВАЖНО: загружаем сделки клиента через процедуры
                var client = await _spService.GetClientByUserIdAsync(userId);

                Console.WriteLine($"Client found: {client != null}");

                if (client == null && user != null)
                {
                    Console.WriteLine($"Клиент не найден для user_id: {userId}, создаем профиль автоматически...");
                    
                    // Создаем профиль клиента автоматически через процедуру
                    var newClient = new Client
                    {
                        full_name = user.full_name,
                        email = user.email,
                        phone_number = "",
                        passport_number = "",
                        registration_date = DateTime.Now,
                        user_id = user.user_id
                    };
                    
                    var clientId = await _spService.CreateClientAsync(newClient);
                    newClient.client_id = clientId;
                    
                    // Обновляем user.client_id через процедуру
                    user.client_id = clientId;
                    await _spService.UpdateUserAsync(user);
                    
                    client = newClient;
                    Console.WriteLine($"Профиль клиента автоматически создан: ID={client.client_id}");
                }

                if (client != null)
                {
                    ViewBag.Client = client;

                    // Загружаем сделки клиента через процедуру
                    var allMyDeals = await _spService.GetDealsByClientIdAsync(client.client_id);
                    var myDeals = allMyDeals.OrderByDescending(d => d.deal_date).Take(5).ToList();

                    ViewBag.MyDeals = myDeals;

                    // Статистика клиента через процедуры
                    // Считаем все сделки, независимо от статуса (или только завершенные, если статус указан)
                    var completedDeals = allMyDeals.Where(d => string.IsNullOrEmpty(d.deal_status) || d.deal_status == "Завершена" || d.deal_status == "Completed").ToList();
                    // Если нет завершенных сделок, считаем все сделки
                    var dealsForTotal = completedDeals.Any() ? completedDeals : allMyDeals;
                    var activeDeals = allMyDeals.Where(d => !string.IsNullOrEmpty(d.deal_status) && d.deal_status != "Завершена" && d.deal_status != "Completed").ToList();
                    
                    ViewBag.Stats = new
                    {
                        MyDeals = allMyDeals.Count,
                        TotalSpent = dealsForTotal.Sum(d => d.deal_price),
                        ActiveDeals = activeDeals.Count
                    };

                    Console.WriteLine($"Client {client.full_name} has {myDeals.Count} deals");
                }
                else
                {
                    // Если клиент не найден в базе
                    ViewBag.Client = new Client
                    {
                        full_name = user?.full_name ?? User.Identity?.Name ?? "Клиент",
                        phone_number = "Не указан",
                        email = user?.email ?? "",
                        registration_date = DateTime.Now
                    };
                    ViewBag.MyDeals = new List<Deal>();
                    ViewBag.Stats = new
                    {
                        MyDeals = 0,
                        TotalSpent = 0,
                        ActiveDeals = 0
                    };

                    Console.WriteLine($"Client not found, using temporary data");
                }
            }

            // Для админа показываем статус синхронизации
            SyncStatus syncStatusModel = null;
            if (userRole == "Admin")
            {
                syncStatusModel = await _syncService.GetSyncStatusAsync();
            }

            return View(syncStatusModel ?? new SyncStatus());
        }

        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> AdminDashboard()
        {
            Console.WriteLine("=== ВХОД В АДМИН ПАНЕЛЬ ===");
            Console.WriteLine($"User: {User.Identity?.Name}");
            Console.WriteLine($"IsAuthenticated: {User.Identity?.IsAuthenticated}");

            try
            {
                var allUsers = await _spService.GetAllUsersAsync();
                var allClients = await _spService.GetAllClientsAsync();
                var allRealtors = await _spService.GetAllRealtorsAsync();
                var allProperties = await _spService.GetAllPropertiesAsync();
                var allDeals = await _spService.GetAllDealsAsync();

                var stats = new
                {
                    TotalUsers = allUsers.Count,
                    TotalClients = allClients.Count,
                    TotalRealtors = allRealtors.Count,
                    TotalProperties = allProperties.Count,
                    ActiveProperties = allProperties.Count(p => p.is_available),
                    TotalDeals = allDeals.Count,
                    ActiveDeals = allDeals.Count(d => d.deal_date >= DateTime.Now.AddMonths(-1))
                };

                var recentUsers = allUsers
                    .OrderByDescending(u => u.created_at)
                    .Take(5)
                    .ToList();

                // Получаем статус синхронизации
                var syncStatus = await _syncService.GetSyncStatusAsync();

                ViewBag.User = new
                {
                    Username = User.Identity?.Name ?? "Admin",
                    Role = "Admin",
                    FullName = User.Claims.FirstOrDefault(c => c.Type == "FullName")?.Value ?? "Администратор"
                };

                ViewBag.Stats = stats;
                ViewBag.RecentUsers = recentUsers;
                ViewBag.SyncStatus = syncStatus;

                return View("AdminDashboard");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"AdminDashboard Error: {ex.Message}");
                ViewBag.Error = ex.Message;
                return View("AdminDashboard");
            }
        }

        [Authorize(Roles = "Realtor")]
        public async Task<IActionResult> RealtorDashboard()
        {
            try
            {
                var username = User.Identity?.Name ?? "realtor";
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                var realtor = await _spService.GetRealtorByUserIdAsync(userId);

                if (realtor == null)
                {
                    Console.WriteLine($"Риэлтор не найден для user_id: {userId}, создаем профиль автоматически...");
                    
                    var user = await _spService.GetUserByIdAsync(userId);
                    if (user == null)
                    {
                        ViewBag.Error = "Пользователь не найден.";
                        return View("RealtorDashboard");
                    }
                    
                    // Создаем профиль риэлтора автоматически
                    realtor = new Realtor
                    {
                        full_name = user.full_name,
                        email = user.email,
                        phone_number = "+375 (29) 000-00-00", // Значение по умолчанию
                        hire_date = DateTime.Now,
                        commission_rate = 5.0m, // Значение по умолчанию
                        user_id = user.user_id
                    };
                    
                    var realtorId = await _spService.CreateRealtorAsync(realtor);
                    realtor.realtor_id = realtorId;
                    
                    // Обновляем user.realtor_id через процедуру
                    user.realtor_id = realtor.realtor_id;
                    await _spService.UpdateUserAsync(user);
                    
                    Console.WriteLine($"Профиль риэлтора автоматически создан: ID={realtor.realtor_id}");
                }

                Console.WriteLine($"Риэлтор найден: ID={realtor.realtor_id}, Name={realtor.full_name}");

                var myProperties = (await _spService.GetPropertiesByRealtorIdAsync(realtor.realtor_id))
                    .Where(p => p.is_available)
                    .OrderByDescending(p => p.price)
                    .Take(5)
                    .ToList();

                Console.WriteLine($"Найдено объектов: {myProperties.Count}");

                var allRealtorDeals = await _spService.GetDealsByRealtorIdAsync(realtor.realtor_id);
                var myDeals = allRealtorDeals
                    .OrderByDescending(d => d.deal_date)
                    .Take(3)
                    .ToList();

                Console.WriteLine($"Найдено сделок: {myDeals.Count}");

                // Получаем статистику по месяцам за последние 12 месяцев
                var now = DateTime.Now;
                var monthlyStats = new List<dynamic>();
                
                for (int i = 11; i >= 0; i--)
                {
                    var monthStart = new DateTime(now.Year, now.Month, 1).AddMonths(-i);
                    var monthEnd = monthStart.AddMonths(1).AddDays(-1);
                    var monthName = monthStart.ToString("MMMM yyyy", new System.Globalization.CultureInfo("ru-RU"));
                    
                    var (dealsCount, dealsTotalPrice) = await _spService.GetRealtorDealStatsAsync(
                        realtor.realtor_id,
                        monthStart,
                        monthEnd);

                    monthlyStats.Add(new
                    {
                        MonthName = monthName,
                        MonthStart = monthStart,
                        MonthEnd = monthEnd,
                        DealsCount = dealsCount,
                        DealsTotalPrice = dealsTotalPrice
                    });
                }

                var totalDeals = allRealtorDeals.Count;
                var totalDealsPrice = allRealtorDeals.Sum(d => d.deal_price);

                // Статистика по периодам (неделя, месяц)
                var weekStart = DateTime.Now.AddDays(-7);
                var currentMonthStart = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
                
                var dealsThisWeek = allRealtorDeals
                    .Where(d => d.deal_date >= weekStart)
                    .ToList();
                
                var dealsThisMonth = allRealtorDeals
                    .Where(d => d.deal_date >= currentMonthStart)
                    .ToList();

                var periodStats = new
                {
                    WeekDealsCount = dealsThisWeek.Count,
                    WeekDealsAmount = dealsThisWeek.Sum(d => d.deal_price),
                    MonthDealsCount = dealsThisMonth.Count,
                    MonthDealsAmount = dealsThisMonth.Sum(d => d.deal_price)
                };

                ViewBag.User = new
                {
                    Username = username,
                    Role = "Realtor",
                    FullName = realtor.full_name
                };

                ViewBag.Realtor = realtor;
                ViewBag.MyProperties = myProperties;
                ViewBag.MyDeals = myDeals;
                ViewBag.MonthlyStats = monthlyStats;
                ViewBag.PeriodStats = periodStats;
                ViewBag.Stats = new
                {
                    MyProperties = myProperties.Count,
                    MyDeals = totalDeals,
                    ActiveProperties = myProperties.Count,
                    TotalDealsPrice = totalDealsPrice
                };

                return View("RealtorDashboard");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"RealtorDashboard Error: {ex.Message}");
                ViewBag.Error = ex.Message;
                return View("RealtorDashboard");
            }
        }

        [Authorize(Roles = "Client")]
        public async Task<IActionResult> ClientDashboard()
        {
            try
            {
                var username = User.Identity?.Name ?? "client";
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                var client = await _spService.GetClientByUserIdAsync(userId);

                if (client == null)
                {
                    client = new Client
                    {
                        full_name = "Петр Клиентов",
                        phone_number = "+7 (999) 987-65-43",
                        email = "client@test.com",
                        passport_number = "1234 567890",
                        registration_date = DateTime.Now.AddMonths(-3)
                    };
                }

                var availableProperties = (await _spService.GetAllPropertiesAsync())
                    .Where(p => p.is_available)
                    .OrderByDescending(p => p.price)
                    .Take(6)
                    .ToList();

                var myDeals = (await _spService.GetDealsByClientIdAsync(client.client_id))
                    .OrderByDescending(d => d.deal_date)
                    .Take(2)
                    .ToList();

                ViewBag.User = new
                {
                    Username = username,
                    Role = "Client",
                    FullName = client.full_name
                };

                ViewBag.Client = client;
                ViewBag.AvailableProperties = availableProperties;
                ViewBag.MyDeals = myDeals;

                return View("ClientDashboard");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"ClientDashboard Error: {ex.Message}");
                ViewBag.Error = ex.Message;
                return View("ClientDashboard");
            }
        }

        [AllowAnonymous]
        public IActionResult BrowseProperties(string? search = null)
        {
            return RedirectToAction("Index", "Property", new { search });
        }

        [AllowAnonymous]
        public IActionResult About()
        {
            return View();
        }

        [AllowAnonymous]
        public IActionResult Contact()
        {
            return View();
        }

        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Sync()
        {
            try
            {
                var status = await _syncService.GetSyncStatusAsync();
                return View(status);
            }
            catch (Exception ex)
            {
                ViewBag.Error = ex.Message;
                return View(new SyncStatus());
            }
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> PerformSync()
        {
            try
            {
                var result = await _syncService.FullSyncAsync();

                TempData["SyncResult"] = JsonConvert.SerializeObject(result);
                TempData["SyncMessage"] = result.Success ? "✅ Синхронизация выполнена успешно!" : "❌ Ошибка синхронизации!";

                return RedirectToAction("Sync");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"PerformSync Error: {ex.Message}");
                TempData["ErrorMessage"] = $"Ошибка синхронизации: {ex.Message}";
                return RedirectToAction("Sync");
            }
        }

        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetSyncData()
        {
            try
            {
                var status = await _syncService.GetSyncStatusAsync();
                var syncHistory = status.Tables
                    .Take(10)
                    .Select(t => new
                    {
                        Date = DateTime.UtcNow,
                        Table = t.Name,
                        Status = t.IsSynced ? "success" : "warning",
                        Records = t.PgCount
                    })
                    .ToList();

                return Json(new
                {
                    success = true,
                    syncHistory
                });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, error = ex.Message });
            }
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult TestAdminView()
        {
            ViewBag.User = new
            {
                Username = "testadmin",
                Role = "Admin",
                FullName = "Тестовый Админ"
            };

            ViewBag.Stats = new
            {
                TotalUsers = 10,
                TotalClients = 5,
                TotalRealtors = 3,
                TotalProperties = 8,
                ActiveDeals = 3
            };

            return View("AdminDashboard");
        }

        // -----------------------------
        // Экспорт/Импорт Deals
        // -----------------------------

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> ExportDeals()
        {
            var logger = HttpContext.RequestServices.GetRequiredService<ILogger<HomeController>>();
            
            try
            {
                logger.LogInformation("[EXPORT] Начало экспорта Deals из PostgreSQL");
                Console.WriteLine($"[EXPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Начало экспорта Deals из PostgreSQL");

                // Используем процедуру для получения всех сделок
                var deals = await _spService.GetAllDealsAsync();
                
                logger.LogInformation($"[EXPORT] Получено {deals.Count} сделок из базы данных");
                Console.WriteLine($"[EXPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Получено {deals.Count} сделок из базы данных");

                if (deals == null || deals.Count == 0)
                {
                    logger.LogWarning("[EXPORT] Таблица Deals пуста");
                    Console.WriteLine($"[EXPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] WARNING: Таблица Deals пуста");
                }

                var json = System.Text.Json.JsonSerializer.Serialize(deals, new System.Text.Json.JsonSerializerOptions
                {
                    WriteIndented = true,
                    Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                });

                var fileName = $"deals_export_{DateTime.Now:yyyyMMdd_HHmmss}.json";
                var bytes = System.Text.Encoding.UTF8.GetBytes(json);

                logger.LogInformation($"[EXPORT] Файл {fileName} успешно создан, размер: {bytes.Length} байт");
                Console.WriteLine($"[EXPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Файл {fileName} успешно создан, размер: {bytes.Length} байт");

                return File(bytes, "application/json", fileName);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "[EXPORT ERROR] Ошибка при экспорте Deals: {Message}", ex.Message);
                Console.WriteLine($"[EXPORT ERROR] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Ошибка при экспорте Deals");
                Console.WriteLine($"[EXPORT ERROR] Сообщение: {ex.Message}");
                Console.WriteLine($"[EXPORT ERROR] StackTrace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"[EXPORT ERROR] InnerException: {ex.InnerException.Message}");
                }

                TempData["ExportError"] = $"Ошибка экспорта: {ex.Message}";
                return RedirectToAction("Dashboard");
            }
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> ImportDeals(IFormFile file)
        {
            var logger = HttpContext.RequestServices.GetRequiredService<ILogger<HomeController>>();
            
            try
            {
                logger.LogInformation("[IMPORT] Начало импорта Deals в PostgreSQL");
                Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Начало импорта Deals в PostgreSQL");

                if (file == null || file.Length == 0)
                {
                    var errorMsg = "Файл не выбран или пуст";
                    logger.LogWarning($"[IMPORT] {errorMsg}");
                    Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] WARNING: {errorMsg}");
                    return Json(new { success = false, message = errorMsg });
                }

                logger.LogInformation($"[IMPORT] Получен файл: {file.FileName}, размер: {file.Length} байт");
                Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Получен файл: {file.FileName}, размер: {file.Length} байт");

                if (!file.FileName.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
                {
                    var errorMsg = "Неверный формат файла. Требуется JSON";
                    logger.LogWarning($"[IMPORT] {errorMsg}");
                    Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] WARNING: {errorMsg}");
                    return Json(new { success = false, message = errorMsg });
                }

                using var stream = new System.IO.StreamReader(file.OpenReadStream());
                var json = await stream.ReadToEndAsync();
                
                logger.LogInformation($"[IMPORT] Файл прочитан, размер JSON: {json.Length} символов");
                Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Файл прочитан, размер JSON: {json.Length} символов");

                List<Deal> deals;
                try
                {
                    deals = System.Text.Json.JsonSerializer.Deserialize<List<Deal>>(json);
                    logger.LogInformation($"[IMPORT] JSON успешно десериализован");
                    Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] JSON успешно десериализован");
                }
                catch (System.Text.Json.JsonException jsonEx)
                {
                    var errorMsg = $"Ошибка парсинга JSON: {jsonEx.Message}";
                    logger.LogError(jsonEx, $"[IMPORT ERROR] {errorMsg}");
                    Console.WriteLine($"[IMPORT ERROR] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {errorMsg}");
                    Console.WriteLine($"[IMPORT ERROR] StackTrace: {jsonEx.StackTrace}");
                    return Json(new { success = false, message = errorMsg });
                }

                if (deals == null || deals.Count == 0)
                {
                    var errorMsg = "Файл не содержит данных";
                    logger.LogWarning($"[IMPORT] {errorMsg}");
                    Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] WARNING: {errorMsg}");
                    return Json(new { success = false, message = errorMsg });
                }

                logger.LogInformation($"[IMPORT] Найдено {deals.Count} сделок для импорта");
                Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Найдено {deals.Count} сделок для импорта");

                // Получаем все существующие сделки через процедуру и удаляем их
                logger.LogInformation("[IMPORT] Получение существующих сделок для удаления...");
                Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Получение существующих сделок для удаления...");
                
                var existingDeals = await _spService.GetAllDealsAsync();
                logger.LogInformation($"[IMPORT] Найдено {existingDeals.Count} существующих сделок");
                Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Найдено {existingDeals.Count} существующих сделок");

                int deletedCount = 0;
                foreach (var deal in existingDeals)
                {
                    try
                    {
                        await _spService.DeleteDealAsync(deal.deal_id);
                        deletedCount++;
                    }
                    catch (Exception deleteEx)
                    {
                        logger.LogError(deleteEx, $"[IMPORT ERROR] Ошибка при удалении сделки ID={deal.deal_id}: {deleteEx.Message}");
                        Console.WriteLine($"[IMPORT ERROR] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Ошибка при удалении сделки ID={deal.deal_id}: {deleteEx.Message}");
                    }
                }

                logger.LogInformation($"[IMPORT] Удалено {deletedCount} существующих сделок");
                Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Удалено {deletedCount} существующих сделок");

                // Добавляем новые сделки через процедуры
                logger.LogInformation("[IMPORT] Начало добавления новых сделок...");
                Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Начало добавления новых сделок...");
                
                int importedCount = 0;
                int errorCount = 0;
                
                foreach (var deal in deals)
                {
                    try
                    {
                        // Валидация данных
                        if (deal.property_id <= 0 || deal.client_id <= 0)
                        {
                            logger.LogWarning($"[IMPORT] Пропущена сделка с невалидными данными: property_id={deal.property_id}, client_id={deal.client_id}");
                            Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] WARNING: Пропущена сделка с невалидными данными: property_id={deal.property_id}, client_id={deal.client_id}");
                            errorCount++;
                            continue;
                        }

                        await _spService.CreateDealAsync(deal);
                        importedCount++;
                    }
                    catch (Exception createEx)
                    {
                        errorCount++;
                        logger.LogError(createEx, $"[IMPORT ERROR] Ошибка при создании сделки: {createEx.Message}");
                        Console.WriteLine($"[IMPORT ERROR] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Ошибка при создании сделки");
                        Console.WriteLine($"[IMPORT ERROR] Deal data: property_id={deal.property_id}, client_id={deal.client_id}, realtor_id={deal.realtor_id}");
                        Console.WriteLine($"[IMPORT ERROR] Message: {createEx.Message}");
                        Console.WriteLine($"[IMPORT ERROR] StackTrace: {createEx.StackTrace}");
                        if (createEx.InnerException != null)
                        {
                            Console.WriteLine($"[IMPORT ERROR] InnerException: {createEx.InnerException.Message}");
                        }
                    }
                }

                logger.LogInformation($"[IMPORT] Импорт завершен: успешно {importedCount}, ошибок {errorCount}");
                Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Импорт завершен: успешно {importedCount}, ошибок {errorCount}");

                if (errorCount > 0)
                {
                    var warningMsg = $"Импортировано {importedCount} сделок, {errorCount} ошибок";
                    logger.LogWarning($"[IMPORT] {warningMsg}");
                    Console.WriteLine($"[IMPORT] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] WARNING: {warningMsg}");
                    return Json(new { success = true, message = warningMsg, imported = importedCount, errors = errorCount });
                }

                var successMsg = $"Успешно импортировано {importedCount} сделок";
                logger.LogInformation($"[IMPORT SUCCESS] {successMsg}");
                Console.WriteLine($"[IMPORT SUCCESS] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {successMsg}");
                
                return Json(new { success = true, message = successMsg, imported = importedCount });
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "[IMPORT ERROR] Критическая ошибка при импорте Deals: {Message}", ex.Message);
                Console.WriteLine($"[IMPORT ERROR] [{DateTime.Now:yyyy-MM-dd HH:mm:ss}] Критическая ошибка при импорте Deals");
                Console.WriteLine($"[IMPORT ERROR] Сообщение: {ex.Message}");
                Console.WriteLine($"[IMPORT ERROR] StackTrace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"[IMPORT ERROR] InnerException: {ex.InnerException.Message}");
                    Console.WriteLine($"[IMPORT ERROR] InnerException StackTrace: {ex.InnerException.StackTrace}");
                }

                return Json(new { success = false, message = $"Ошибка импорта: {ex.Message}" });
            }
        }
    }
}