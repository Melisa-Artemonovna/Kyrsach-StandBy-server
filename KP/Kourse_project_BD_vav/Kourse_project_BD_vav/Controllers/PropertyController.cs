using Kourse_project_BD_vav.Models;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Text.Json;

namespace Kourse_project_BD_vav.Controllers
{
    public class PropertyController : Controller
    {
        private readonly StoredProcedureService _spService;
        private readonly ILogger<PropertyController> _logger;

        public PropertyController(
            StoredProcedureService spService,
            ILogger<PropertyController> logger)
        {
            _spService = spService;
            _logger = logger;
        }

        // GET: /Property
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> Index()
        {
            try
            {
                _logger.LogInformation("Запрос списка объектов недвижимости");
                // Используем процедуру вместо прямого запроса
                var properties = await _spService.GetAllPropertiesAsync();
                _logger.LogInformation($"Найдено {properties.Count} объектов");
                return View(properties);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Ошибка при получении списка объектов");
                return View(new List<Property>());
            }
        }

        // GET: /Property/Details/5
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> Details(int id)
        {
            try
            {
                _logger.LogInformation($"Запрос деталей объекта ID={id}");
                // Используем процедуру вместо прямого запроса
                var property = await _spService.GetPropertyByIdAsync(id);

                if (property == null)
                {
                    _logger.LogWarning($"Объект с ID={id} не найден");
                    TempData["ErrorMessage"] = "Объект не найден";
                    return RedirectToAction("Index");
                }

                _logger.LogInformation($"Найден объект: {property.address}");
                return View(property);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Ошибка при получении объекта ID={id}");
                TempData["ErrorMessage"] = "Ошибка при загрузке объекта";
                return RedirectToAction("Index");
            }
        }

        // GET: /Property/Create
        [HttpGet]
        [Authorize(Roles = "Admin,Realtor")]
        public IActionResult Create()
        {
            _logger.LogInformation("Открытие формы создания объекта");
            return View();
        }

        // POST: /Property/Create
        [HttpPost]
        [Authorize(Roles = "Admin,Realtor")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Property property)
        {
            try
            {
                _logger.LogInformation("Начало обработки формы создания объекта");
                _logger.LogInformation($"Данные: Address={property.address}, Price={property.price}, Type={property.property_type}");

                // Простая валидация
                if (string.IsNullOrEmpty(property.address))
                {
                    TempData["ErrorMessage"] = "Адрес обязателен";
                    return View(property);
                }

                if (string.IsNullOrEmpty(property.property_type))
                {
                    TempData["ErrorMessage"] = "Тип недвижимости обязателен";
                    return View(property);
                }

                if (property.price <= 0)
                {
                    TempData["ErrorMessage"] = "Цена должна быть больше 0";
                    return View(property);
                }

                // Устанавливаем значения по умолчанию
                property.is_available = true;
                property.description ??= "";

                // Если риэлтор не указан и текущий пользователь - риэлтор
                if (!property.realtor_id.HasValue && User.IsInRole("Realtor"))
                {
                    var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                    // Используем процедуру вместо прямого запроса
                    var realtor = await _spService.GetRealtorByUserIdAsync(userId);
                    property.realtor_id = realtor?.realtor_id;
                }

                // Используем процедуру вместо прямого добавления
                var propertyId = await _spService.CreatePropertyAsync(property);
                property.property_id = propertyId;

                _logger.LogInformation($"Новый объект создан с ID={property.property_id}");
                TempData["SuccessMessage"] = "Объект успешно добавлен!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Ошибка при создании объекта");
                TempData["ErrorMessage"] = $"Ошибка при сохранении: {ex.Message}";
                return View(property);
            }
        }

        // GET: /Property/Edit/5
        [HttpGet]
        [Authorize(Roles = "Admin,Realtor")]
        public async Task<IActionResult> Edit(int id)
        {
            try
            {
                _logger.LogInformation($"Запрос редактирования объекта ID={id}");
                // Используем процедуру вместо прямого запроса
                var property = await _spService.GetPropertyByIdAsync(id);
                if (property == null)
                {
                    _logger.LogWarning($"Объект для редактирования с ID={id} не найден");
                    TempData["ErrorMessage"] = "Объект не найден";
                    return RedirectToAction("Index");
                }

                _logger.LogInformation($"Объект для редактирования найден: {property.address}");
                return View(property);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Ошибка при загрузке для редактирования объекта ID={id}");
                TempData["ErrorMessage"] = "Ошибка при загрузке объекта";
                return RedirectToAction("Index");
            }
        }

        // POST: /Property/Edit
        [HttpPost]
        [Authorize(Roles = "Admin,Realtor")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(Property property)
        {
            try
            {
                _logger.LogInformation($"Edit POST: ID={property.property_id}, Address={property.address}");

                // Убираем валидацию для чекбокса
                ModelState.Remove("is_available");

                // Проверяем существование через процедуру
                var existing = await _spService.GetPropertyByIdAsync(property.property_id);
                if (existing == null)
                {
                    _logger.LogWarning($"Объект с ID={property.property_id} не найден");
                    TempData["ErrorMessage"] = "Объект не найден";
                    return RedirectToAction("Index");
                }

                // Используем процедуру для обновления
                await _spService.UpdatePropertyAsync(property);

                _logger.LogInformation($"Объект ID={property.property_id} успешно обновлен");
                TempData["SuccessMessage"] = "Объект успешно обновлен!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Ошибка при редактировании объекта ID={property?.property_id}");
                TempData["ErrorMessage"] = $"Ошибка при обновлении: {ex.Message}";
                return View(property);
            }
        }
        // POST: /Property/Delete/5
        [HttpPost]
        [Authorize(Roles = "Admin,Realtor")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                _logger.LogInformation($"Попытка удаления объекта ID={id}");

                // Проверяем существование через процедуру
                var property = await _spService.GetPropertyByIdAsync(id);
                if (property == null)
                {
                    _logger.LogWarning($"Объект для удаления с ID={id} не найден");
                    TempData["ErrorMessage"] = "Объект не найден!";
                    return RedirectToAction("Index");
                }

                // Используем процедуру для удаления
                await _spService.DeletePropertyAsync(id);

                _logger.LogInformation($"Объект ID={id} успешно удален");
                TempData["SuccessMessage"] = "Объект успешно удален!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"ОШИБКА при удалении объекта ID={id}");
                TempData["ErrorMessage"] = $"Не удалось удалить объект: {ex.Message}";
                return RedirectToAction("Index");
            }
        }
    }
}