using Kourse_project_BD_vav.Models;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kourse_project_BD_vav.Controllers
{
    [Authorize(Roles = "Admin,Realtor")]
    public class ClientController : Controller
    {
        private readonly StoredProcedureService _spService;

        public ClientController(StoredProcedureService spService)
        {
            _spService = spService;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            Console.WriteLine($"=== CLIENT INDEX ===");
            Console.WriteLine($"User authenticated: {User.Identity?.IsAuthenticated}");
            Console.WriteLine($"User role: {User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value}");
            Console.WriteLine($"User ID: {User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value}");
            Console.WriteLine($"Request cookies count: {Request.Cookies.Count}");
            foreach (var cookie in Request.Cookies)
            {
                Console.WriteLine($"Cookie in request: {cookie.Key}");
            }
            
            // Используем процедуру вместо прямого запроса
            var clients = await _spService.GetAllClientsAsync();
            Console.WriteLine($"Loaded {clients.Count} clients");
            return View(clients);
        }

        [HttpGet]
        public IActionResult Create()
        {
            return View(new Client
            {
                registration_date = DateTime.Now
            });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Client client)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    if (client.registration_date == default(DateTime))
                    {
                        client.registration_date = DateTime.Now;
                    }

                    // Используем процедуру вместо прямого добавления
                    var clientId = await _spService.CreateClientAsync(client);
                    client.client_id = clientId;

                    TempData["SuccessMessage"] = $"Клиент '{client.full_name}' успешно добавлен!";
                    return RedirectToAction(nameof(Index));
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error creating client: {ex.Message}");
                    TempData["ErrorMessage"] = $"Ошибка при создании клиента: {ex.Message}";
                }
            }

            return View(client);
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            Console.WriteLine($"=== EDIT GET - Client ID: {id} ===");

            // Используем процедуру вместо прямого запроса
            var client = await _spService.GetClientByIdAsync(id);
            if (client == null)
            {
                Console.WriteLine($"Client with ID {id} not found!");
                TempData["ErrorMessage"] = "Клиент не найден";
                return RedirectToAction(nameof(Index));
            }

            // Отладочная информация
            Console.WriteLine($"Client found: ID={client.client_id}, Name={client.full_name}");
            Console.WriteLine($"Email={client.email}, Phone={client.phone_number}");
            Console.WriteLine($"Passport={client.passport_number}, RegDate={client.registration_date}");

            // Логируем все поля
            var properties = typeof(Client).GetProperties();
            foreach (var prop in properties)
            {
                Console.WriteLine($"{prop.Name}: {prop.GetValue(client)}");
            }

            return View(client);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, [FromForm] Client client)
        {
            Console.WriteLine($"=== EDIT POST ===");
            Console.WriteLine($"Route ID: {id}");
            Console.WriteLine($"Model client_id: {client?.client_id}");
            Console.WriteLine($"Model full_name: {client?.full_name}");

            // ДЕБАГ: выводим все значения из формы
            foreach (var key in Request.Form.Keys)
            {
                Console.WriteLine($"Form[{key}] = {Request.Form[key]}");
            }

            // Если модель null, создаем из формы
            if (client == null)
            {
                Console.WriteLine("Client model is null, creating from form...");
                client = new Client();
                await TryUpdateModelAsync(client);
                Console.WriteLine($"After TryUpdateModel: ID={client.client_id}, Name={client.full_name}");
            }

            // Важно: устанавливаем ID из маршрута
            client.client_id = id;
            Console.WriteLine($"Set client_id to {id}");

            if (!ModelState.IsValid)
            {
                Console.WriteLine("ModelState невалиден:");
                foreach (var error in ModelState.Values.SelectMany(v => v.Errors))
                {
                    Console.WriteLine($"Error: {error.ErrorMessage}");
                }
                return View(client);
            }

            try
            {
                // Проверяем существование через процедуру
                var existingClient = await _spService.GetClientByIdAsync(id);
                if (existingClient == null)
                {
                    TempData["ErrorMessage"] = "Клиент не найден";
                    return RedirectToAction(nameof(Index));
                }

                Console.WriteLine($"Before update: {existingClient.full_name}");

                // Используем процедуру для обновления
                await _spService.UpdateClientAsync(client);
                Console.WriteLine($"After update: {client.full_name}");

                TempData["SuccessMessage"] = $"Данные клиента '{client.full_name}' успешно обновлены!";

                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
                TempData["ErrorMessage"] = $"Ошибка: {ex.Message}";
                return View(client);
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                Console.WriteLine($"=== DELETE CLIENT START ===");
                Console.WriteLine($"Request method: {Request.Method}");
                Console.WriteLine($"Request path: {Request.Path}");
                Console.WriteLine($"Has AntiForgeryToken: {Request.Form.ContainsKey("__RequestVerificationToken")}");
                Console.WriteLine($"Deleting client ID: {id}");
                Console.WriteLine($"User authenticated: {User.Identity?.IsAuthenticated}");
                Console.WriteLine($"User role: {User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value}");
                Console.WriteLine($"User ID: {User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value}");

                // Проверяем существование через процедуру
                var client = await _spService.GetClientByIdAsync(id);
                if (client != null)
                {
                    // Используем процедуру для удаления
                    await _spService.DeleteClientAsync(id);
                    TempData["SuccessMessage"] = $"Клиент '{client.full_name}' успешно удален!";
                    Console.WriteLine($"Client {client.full_name} deleted successfully");
                }
                else
                {
                    TempData["ErrorMessage"] = "Клиент не найден";
                    Console.WriteLine($"Client with ID {id} not found");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"=== ERROR DELETING CLIENT ===");
                Console.WriteLine($"Error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
                }
                TempData["ErrorMessage"] = $"Не удалось удалить клиента: {ex.Message}";
            }

            Console.WriteLine($"Redirecting to Index. User still authenticated: {User.Identity?.IsAuthenticated}");
            
            // Используем обычный RedirectToAction - он должен работать правильно
            return RedirectToAction(nameof(Index));
        }

        private async Task<bool> ClientExists(int id)
        {
            // Используем процедуру вместо прямого запроса
            var client = await _spService.GetClientByIdAsync(id);
            return client != null;
        }
    }
}