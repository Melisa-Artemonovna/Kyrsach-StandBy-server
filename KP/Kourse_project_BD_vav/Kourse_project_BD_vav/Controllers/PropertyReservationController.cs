using Kourse_project_BD_vav.Models;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Kourse_project_BD_vav.Controllers
{
    [Authorize]
    public class PropertyReservationController : Controller
    {
        private readonly StoredProcedureService _spService;
        private readonly ILogger<PropertyReservationController> _logger;

        public PropertyReservationController(
            StoredProcedureService spService,
            ILogger<PropertyReservationController> logger)
        {
            _spService = spService;
            _logger = logger;
        }

        // GET: PropertyReservation
        public async Task<IActionResult> Index()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            List<PropertyReservation> reservations;

            if (User.IsInRole("Admin"))
            {
                // Админ видит все резервирования через процедуру
                reservations = await _spService.GetAllPropertyReservationsAsync();
            }
            else if (User.IsInRole("Realtor"))
            {
                // Риэлтор видит резервирования по своим объектам
                _logger.LogInformation($"=== ПОЛУЧЕНИЕ РЕЗЕРВИРОВАНИЙ ДЛЯ РИЭЛТОРА ===");
                _logger.LogInformation($"User ID: {userId}");
                
                // Используем процедуру вместо прямого запроса
                var realtor = await _spService.GetRealtorByUserIdAsync(userId);

                if (realtor == null)
                {
                    _logger.LogWarning($"Риэлтор не найден для user_id: {userId}, создаем профиль автоматически...");
                    
                    // Получаем данные пользователя через процедуру
                    var user = await _spService.GetUserByIdAsync(userId);
                    if (user == null)
                    {
                        TempData["ErrorMessage"] = "Пользователь не найден.";
                        return View(new List<PropertyReservation>());
                    }
                    
                    // Создаем профиль риэлтора автоматически через процедуру
                    var newRealtor = new Realtor
                    {
                        full_name = user.full_name,
                        email = user.email,
                        phone_number = "+375 (29) 000-00-00",
                        hire_date = DateTime.Now,
                        commission_rate = 5.0m,
                        user_id = user.user_id
                    };
                    
                    var realtorId = await _spService.CreateRealtorAsync(newRealtor);
                    newRealtor.realtor_id = realtorId;
                    
                    // Обновляем user.realtor_id через процедуру
                    user.realtor_id = realtorId;
                    await _spService.UpdateUserAsync(user);
                    
                    realtor = newRealtor;
                    _logger.LogInformation($"Профиль риэлтора автоматически создан: ID={realtor.realtor_id}");
                }

                _logger.LogInformation($"Риэлтор найден: ID={realtor.realtor_id}, Name={realtor.full_name}");

                // Используем процедуру вместо прямого запроса
                reservations = await _spService.GetPropertyReservationsByRealtorIdAsync(realtor.realtor_id);
                
                _logger.LogInformation($"Найдено резервирований: {reservations.Count}");
            }
            else
            {
                // Клиент видит только свои резервирования
                // Используем процедуру вместо прямого запроса
                var client = await _spService.GetClientByUserIdAsync(userId);

                if (client == null)
                {
                    TempData["ErrorMessage"] = "Профиль клиента не найден. Обратитесь к администратору.";
                    return View(new List<PropertyReservation>());
                }

                // Используем процедуру вместо прямого запроса
                reservations = await _spService.GetPropertyReservationsByClientIdAsync(client.client_id);
            }

            // Загружаем связанные данные (Client и Property) для каждого резервирования
            if (reservations != null && reservations.Any())
            {
                // Получаем уникальные ID клиентов и объектов
                var clientIds = reservations.Where(r => r.client_id > 0).Select(r => r.client_id).Distinct().ToList();
                var propertyIds = reservations.Where(r => r.property_id > 0).Select(r => r.property_id).Distinct().ToList();

                // Загружаем всех клиентов одним запросом
                var clients = new Dictionary<int, Client>();
                foreach (var clientId in clientIds)
                {
                    var client = await _spService.GetClientByIdAsync(clientId);
                    if (client != null)
                    {
                        clients[clientId] = client;
                    }
                }

                // Загружаем все объекты одним запросом
                var properties = new Dictionary<int, Property>();
                foreach (var propertyId in propertyIds)
                {
                    var property = await _spService.GetPropertyByIdAsync(propertyId);
                    if (property != null)
                    {
                        properties[propertyId] = property;
                    }
                }

                // Присваиваем навигационные свойства каждому резервированию
                foreach (var reservation in reservations)
                {
                    if (reservation.client_id > 0 && clients.ContainsKey(reservation.client_id))
                    {
                        reservation.Client = clients[reservation.client_id];
                    }
                    if (reservation.property_id > 0 && properties.ContainsKey(reservation.property_id))
                    {
                        reservation.Property = properties[reservation.property_id];
                    }
                }
            }

            return View(reservations);
        }

        // GET: PropertyReservation/Create/5
        public async Task<IActionResult> Create(int id)
        {
            // Используем процедуру вместо прямого запроса
            var property = await _spService.GetPropertyByIdAsync(id);
            if (property == null)
            {
                return NotFound();
            }

            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            // Используем процедуру вместо прямого запроса
            var client = await _spService.GetClientByUserIdAsync(userId);

            if (client == null)
            {
                TempData["ErrorMessage"] = "Только клиенты могут бронировать просмотры";
                return RedirectToAction("Details", "Property", new { id });
            }

            // Получаем риэлтора объекта
            if (!property.realtor_id.HasValue)
            {
                TempData["ErrorMessage"] = "У этого объекта не назначен риэлтор. Невозможно записаться на просмотр.";
                return RedirectToAction("Details", "Property", new { id });
            }

            // Используем процедуру вместо прямого запроса
            var realtor = await _spService.GetRealtorByIdAsync(property.realtor_id.Value);

            if (realtor == null)
            {
                TempData["ErrorMessage"] = "Риэлтор не найден. Обратитесь к администратору.";
                return RedirectToAction("Details", "Property", new { id });
            }

            var reservation = new PropertyReservation
            {
                property_id = id,
                client_id = client.client_id,
                realtor_id = realtor.realtor_id,
                reservation_date = DateTime.Now,
                expiry_date = DateTime.Now.AddDays(7) // По умолчанию на 7 дней
            };

            ViewBag.Property = property;
            ViewBag.Realtor = realtor;

            return View(reservation);
        }

        // POST: PropertyReservation/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(PropertyReservation reservation)
        {
            // Проверяем, что у объекта есть риэлтор
            var property = await _spService.GetPropertyByIdAsync(reservation.property_id);
            if (property == null)
            {
                TempData["ErrorMessage"] = "Объект не найден";
                return RedirectToAction("Index", "Property");
            }

            if (!property.realtor_id.HasValue)
            {
                TempData["ErrorMessage"] = "У этого объекта не назначен риэлтор. Невозможно записаться на просмотр.";
                return RedirectToAction("Details", "Property", new { id = reservation.property_id });
            }

            // Устанавливаем realtor_id из объекта
            reservation.realtor_id = property.realtor_id.Value;

            if (ModelState.IsValid)
            {
                try
                {
                    reservation.reservation_date = DateTime.Now;
                    reservation.status = "Active";

                    var reservationId = await _spService.CreatePropertyReservationAsync(reservation);
                    reservation.reservation_id = reservationId;

                    TempData["SuccessMessage"] = "Просмотр успешно забронирован!";
                    return RedirectToAction("Index");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Ошибка при создании резервирования");
                    ModelState.AddModelError("", "Произошла ошибка при создании резервирования");
                }
            }

            // Если что-то пошло не так, загружаем данные заново
            ViewBag.Property = property;
            ViewBag.Realtor = await _spService.GetRealtorByIdAsync(property.realtor_id.Value);
            return View(reservation);
        }

        // GET: PropertyReservation/Edit/5
        public async Task<IActionResult> Edit(int id)
        {
            var reservation = await _spService.GetPropertyReservationByIdAsync(id);

            if (reservation == null)
            {
                return NotFound();
            }

            reservation.Property = await _spService.GetPropertyByIdAsync(reservation.property_id);

            // Проверяем права доступа
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (User.IsInRole("Client"))
            {
                var client = await _spService.GetClientByUserIdAsync(userId);

                if (client == null || reservation.client_id != client.client_id)
                {
                    return Forbid();
                }
            }

            return View(reservation);
        }

        // POST: PropertyReservation/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, PropertyReservation reservation)
        {
            if (id != reservation.reservation_id)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                try
                {
                    var existingReservation = await _spService.GetPropertyReservationByIdAsync(id);
                    if (existingReservation == null)
                    {
                        return NotFound();
                    }

                    // Обновляем только разрешенные поля
                    existingReservation.expiry_date = reservation.expiry_date;
                    existingReservation.status = reservation.status;

                    await _spService.UpdatePropertyReservationAsync(existingReservation);

                    TempData["SuccessMessage"] = "Резервирование успешно обновлено!";
                    return RedirectToAction("Index");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Ошибка при обновлении резервирования");
                    ModelState.AddModelError("", "Произошла ошибка при обновлении");
                }
            }
            return View(reservation);
        }

        // POST: PropertyReservation/Delete/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            // Используем процедуру вместо прямого запроса
            var reservation = await _spService.GetPropertyReservationByIdAsync(id);
            if (reservation == null)
            {
                return NotFound();
            }

            // Проверяем права доступа
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (User.IsInRole("Client"))
            {
                // Используем процедуру вместо прямого запроса
                var client = await _spService.GetClientByUserIdAsync(userId);

                if (client == null || reservation.client_id != client.client_id)
                {
                    return Forbid();
                }
            }

            // Используем процедуру для удаления
            await _spService.DeletePropertyReservationAsync(id);

            TempData["SuccessMessage"] = "Резервирование успешно отменено!";
            return RedirectToAction("Index");
        }

        // POST: PropertyReservation/Complete/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Complete(int id)
        {
            // Используем процедуру вместо прямого запроса
            var reservation = await _spService.GetPropertyReservationByIdAsync(id);
            if (reservation == null)
            {
                return NotFound();
            }

            // Используем процедуру для обновления
            reservation.status = "Completed";
            await _spService.UpdatePropertyReservationAsync(reservation);

            TempData["SuccessMessage"] = "Резервирование отмечено как завершенное!";
            return RedirectToAction("Index");
        }

        // POST: PropertyReservation/QuickReserve/5 - быстрое резервирование для клиента
        [HttpPost]
        [Authorize(Roles = "Client")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> QuickReserve(int id)
        {
            _logger.LogInformation($"=== ПОПЫТКА БЫСТРОГО РЕЗЕРВИРОВАНИЯ ===");
            _logger.LogInformation($"Property ID: {id}");
            _logger.LogInformation($"User ID: {User.FindFirst(ClaimTypes.NameIdentifier)?.Value}");
            _logger.LogInformation($"User Role: {User.FindFirst(ClaimTypes.Role)?.Value}");
            _logger.LogInformation($"IsAuthenticated: {User.Identity?.IsAuthenticated}");
            _logger.LogInformation($"Request Path: {Request.Path}");
            _logger.LogInformation($"Request Method: {Request.Method}");
            
            try
            {
                // Используем процедуру вместо прямого запроса
                var property = await _spService.GetPropertyByIdAsync(id);
                if (property == null)
                {
                    _logger.LogWarning($"Объект с ID {id} не найден");
                    TempData["ErrorMessage"] = "Объект не найден";
                    return RedirectToAction("Details", "Property", new { id });
                }
                
                _logger.LogInformation($"Объект найден: {property.address}");

                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                // Используем процедуру вместо прямого запроса
                var client = await _spService.GetClientByUserIdAsync(userId);

                if (client == null)
                {
                    TempData["ErrorMessage"] = "Профиль клиента не найден. Обратитесь к администратору.";
                    return RedirectToAction("Details", "Property", new { id });
                }

                // Проверяем, что у объекта есть риэлтор
                if (!property.realtor_id.HasValue)
                {
                    TempData["ErrorMessage"] = "У этого объекта не назначен риэлтор. Невозможно зарезервировать.";
                    return RedirectToAction("Details", "Property", new { id });
                }

                // Проверяем, нет ли уже активного резервирования через процедуру
                var hasActiveReservation = await _spService.CheckActiveReservationAsync(id, client.client_id);

                if (hasActiveReservation)
                {
                    TempData["SuccessMessage"] = "Вы уже зарезервировали этот объект!";
                    return RedirectToAction("Details", "Property", new { id });
                }

                // Создаем резервирование
                var reservation = new PropertyReservation
                {
                    property_id = id,
                    client_id = client.client_id,
                    realtor_id = property.realtor_id.Value,
                    reservation_date = DateTime.Now,
                    expiry_date = DateTime.Now.AddDays(7),
                    status = "Active"
                };

                _logger.LogInformation($"Создание резервирования: Property={id}, Client={client.client_id}, Realtor={property.realtor_id.Value}");

                try
                {
                    // Используем процедуру для создания резервирования
                    var reservationId = await _spService.CreatePropertyReservationAsync(reservation);
                    reservation.reservation_id = reservationId;

                    _logger.LogInformation($"Резервирование успешно создано! ID: {reservation.reservation_id}");
                    TempData["SuccessMessage"] = "Вы успешно зарезервировали объект!";
                    return RedirectToAction("Details", "Property", new { id });
                }
                catch (Exception dbEx)
                {
                    _logger.LogError(dbEx, "Ошибка БД при создании резервирования");
                    if (dbEx.InnerException != null)
                    {
                        _logger.LogError(dbEx.InnerException, $"Внутренняя ошибка БД: {dbEx.InnerException.Message}");
                    }
                    TempData["ErrorMessage"] = "Ошибка базы данных. Убедитесь, что таблица PropertyReservations создана. Обратитесь к администратору.";
                    return RedirectToAction("Details", "Property", new { id });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Ошибка при создании резервирования");
                _logger.LogError($"Детали ошибки: {ex.Message}");
                _logger.LogError($"Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    _logger.LogError($"Внутренняя ошибка: {ex.InnerException.Message}");
                }
                TempData["ErrorMessage"] = $"Произошла ошибка при записи на просмотр: {ex.Message}";
                return RedirectToAction("Details", "Property", new { id });
            }
        }
    }
}