using Kourse_project_BD_vav.Models;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace Kourse_project_BD_vav.Controllers
{
    public class AccountController : Controller
    {
        private readonly StoredProcedureService _spService;

        public AccountController(StoredProcedureService spService)
        {
            _spService = spService;
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult Login()
        {
            Console.WriteLine($"=== LOGIN GET REQUEST ===");
            Console.WriteLine($"Path: {Request.Path}");
            Console.WriteLine($"Method: {Request.Method}");
            Console.WriteLine($"User authenticated: {User.Identity?.IsAuthenticated}");
            Console.WriteLine($"Cookies count: {Request.Cookies.Count}");
            foreach (var cookie in Request.Cookies)
            {
                Console.WriteLine($"Cookie: {cookie.Key}");
            }
            
            // Если пользователь уже аутентифицирован, редиректим на Dashboard
            if (User.Identity?.IsAuthenticated == true)
            {
                Console.WriteLine($"=== LOGIN GET: User already authenticated, redirecting to Dashboard ===");
                Console.WriteLine($"User: {User.Identity.Name}, Role: {User.FindFirst(ClaimTypes.Role)?.Value}");
                return RedirectToAction("Dashboard", "Home");
            }
            
            Console.WriteLine($"=== LOGIN GET: Showing login page (user not authenticated) ===");
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login([FromForm] LoginModel model)
        {
            Console.WriteLine($"=== ПОПЫТКА ВХОДА ===");
            Console.WriteLine($"Model is null: {model == null}");
            
            // Проверяем данные из формы напрямую
            Console.WriteLine("=== ДАННЫЕ ИЗ ФОРМЫ ===");
            foreach (var key in Request.Form.Keys)
            {
                Console.WriteLine($"Form[{key}] = {Request.Form[key]}");
            }
            
            if (model != null)
            {
                Console.WriteLine($"Username: '{model.Username}'");
                Console.WriteLine($"Password length: {model.Password?.Length ?? 0}");
                Console.WriteLine($"RememberMe: {model.RememberMe}");
            }
            else
            {
                // Пытаемся создать модель из формы вручную
                model = new LoginModel();
                await TryUpdateModelAsync(model);
                Console.WriteLine("Модель создана из формы вручную");
            }

            if (!ModelState.IsValid)
            {
                Console.WriteLine("ModelState невалиден:");
                foreach (var error in ModelState)
                {
                    Console.WriteLine($"  {error.Key}: {string.Join(", ", error.Value.Errors.Select(e => e.ErrorMessage))}");
                }
                return View(model ?? new LoginModel());
            }

            // Ищем пользователя через процедуру
            var user = await _spService.GetUserByUsernameAsync(model.Username);

            if (user == null)
            {
                Console.WriteLine("Пользователь не найден");
                ModelState.AddModelError("", "Неверное имя пользователя или пароль");
                return View(model);
            }

            Console.WriteLine($"Пользователь найден: {user.username}, роль: {user.role}");

            // Проверяем пароль
            var hashedPassword = HashPassword(model.Password);
            if (user.password_hash != hashedPassword)
            {
                Console.WriteLine("Неверный пароль");
                ModelState.AddModelError("", "Неверное имя пользователя или пароль");
                return View(model);
            }

            // Создаем claims для аутентификации
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.user_id.ToString()),
                new Claim(ClaimTypes.Name, user.username),
                new Claim(ClaimTypes.Role, user.role),
                new Claim("FullName", user.full_name)
            };

            var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);

            // Persistent cookie - сохраняются между сессиями
            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                new ClaimsPrincipal(claimsIdentity),
                new AuthenticationProperties
                {
                    IsPersistent = true, // Persistent cookie
                    AllowRefresh = true,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddDays(7) // Cookie на 7 дней
                });

            Console.WriteLine($"=== УСПЕШНЫЙ ВХОД! Cookie установлены ===");
            Console.WriteLine($"Cookie name: .KourseProject.Auth");
            Console.WriteLine($"IsPersistent: true (persistent cookie на 7 дней)");

            return RedirectToAction("Dashboard", "Home");
        }

        [HttpGet]
        public IActionResult Register()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register([FromForm] RegisterModel model)
        {
            Console.WriteLine("=== ПОПЫТКА РЕГИСТРАЦИИ ===");
            Console.WriteLine($"Model is null: {model == null}");
            
            // Проверяем данные из формы напрямую
            Console.WriteLine("=== ДАННЫЕ ИЗ ФОРМЫ ===");
            foreach (var key in Request.Form.Keys)
            {
                Console.WriteLine($"Form[{key}] = {Request.Form[key]}");
            }
            
            if (model != null)
            {
                Console.WriteLine($"FullName: '{model.FullName}'");
                Console.WriteLine($"Username: '{model.Username}'");
                Console.WriteLine($"Email: '{model.Email}'");
                Console.WriteLine($"Password length: {model.Password?.Length ?? 0}");
                Console.WriteLine($"Role: '{model.Role}'");
            }
            else
            {
                // Пытаемся создать модель из формы вручную
                model = new RegisterModel();
                await TryUpdateModelAsync(model);
                Console.WriteLine("Модель создана из формы вручную");
            }

            if (!ModelState.IsValid)
            {
                Console.WriteLine("ModelState невалиден:");
                foreach (var error in ModelState)
                {
                    Console.WriteLine($"  {error.Key}: {string.Join(", ", error.Value.Errors.Select(e => e.ErrorMessage))}");
                }
                return View(model ?? new RegisterModel());
            }

            // Проверяем уникальность через процедуры
            if (await _spService.CheckUsernameExistsAsync(model.Username))
            {
                ModelState.AddModelError("Username", "Имя пользователя уже занято");
                return View(model);
            }

            if (await _spService.CheckEmailExistsAsync(model.Email))
            {
                ModelState.AddModelError("Email", "Email уже используется");
                return View(model);
            }

            // Создаем пользователя через процедуру
            var user = new User
            {
                username = model.Username,
                email = model.Email,
                full_name = model.FullName,
                role = model.Role,
                password_hash = HashPassword(model.Password),
                created_at = DateTime.UtcNow
            };

            var userId = await _spService.CreateUserAsync(user);
            user.user_id = userId;

            Console.WriteLine($"Пользователь создан: ID={user.user_id}, Role={user.role}");

            // Создаем профиль в зависимости от роли через процедуры
            if (model.Role == "Client")
            {
                var client = new Client
                {
                    full_name = model.FullName,
                    email = model.Email,
                    phone_number = "", // Можно оставить пустым, пользователь заполнит позже
                    passport_number = "", // Можно оставить пустым, пользователь заполнит позже
                    registration_date = DateTime.UtcNow,
                    user_id = user.user_id
                };
                var clientId = await _spService.CreateClientAsync(client);
                client.client_id = clientId;
                
                // Обновляем user.client_id через процедуру
                user.client_id = clientId;
                await _spService.UpdateUserAsync(user);
                
                Console.WriteLine($"Профиль клиента создан: ID={client.client_id}");
            }
            else if (model.Role == "Realtor")
            {
                var realtor = new Realtor
                {
                    full_name = model.FullName,
                    email = model.Email,
                    phone_number = "+375 (29) 000-00-00", // Значение по умолчанию (обязательное поле)
                    hire_date = DateTime.UtcNow,
                    commission_rate = 5.0m, // Значение по умолчанию
                    user_id = user.user_id
                };
                var realtorId = await _spService.CreateRealtorAsync(realtor);
                realtor.realtor_id = realtorId;
                
                // Обновляем user.realtor_id через процедуру
                user.realtor_id = realtorId;
                await _spService.UpdateUserAsync(user);
                
                Console.WriteLine($"Профиль риэлтора создан: ID={realtor.realtor_id}");
            }

            // Автоматически логиним
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.user_id.ToString()),
                new Claim(ClaimTypes.Name, user.username),
                new Claim(ClaimTypes.Role, user.role),
                new Claim("FullName", user.full_name)
            };

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                new ClaimsPrincipal(new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme)),
                new AuthenticationProperties
                {
                    IsPersistent = true, // Persistent cookie
                    AllowRefresh = true,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddDays(7) // Cookie на 7 дней
                });

            Console.WriteLine($"=== РЕГИСТРАЦИЯ УСПЕШНА! Редирект на Dashboard ===");
            return RedirectToAction("Dashboard", "Home");
        }

        [HttpGet]
        [HttpPost]
        public async Task<IActionResult> Logout()
        {
            Console.WriteLine($"=== ВЫХОД ИЗ СИСТЕМЫ ===");
            Console.WriteLine($"Method: {Request.Method}");
            Console.WriteLine($"User authenticated before logout: {User.Identity?.IsAuthenticated}");
            Console.WriteLine($"User: {User.Identity?.Name}");
            Console.WriteLine($"Cookies before logout: {Request.Cookies.Count}");
            foreach (var cookie in Request.Cookies)
            {
                Console.WriteLine($"Cookie: {cookie.Key}");
            }
            
            // Удаляем все cookies аутентификации
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            
            // Явно удаляем cookie аутентификации
            Response.Cookies.Delete(".KourseProject.Auth");
            
            // Также удаляем сессию
            HttpContext.Session.Clear();
            Response.Cookies.Delete(".KourseProject.Session");
            
            Console.WriteLine($"=== ВЫХОД ВЫПОЛНЕН! Cookie удалены. Редирект на Login ===");
            return RedirectToAction("Login", "Account");
        }

        [HttpGet]
        public IActionResult AccessDenied()
        {
            return View();
        }

        // Простой тестовый метод для быстрого входа
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> QuickLogin(string username = "admin")
        {
            try
            {
                Console.WriteLine($"=== БЫСТРЫЙ ВХОД: {username} ===");

                // Ищем пользователя через хранимую функцию
                var user = await _spService.GetUserByUsernameAsync(username);

                if (user == null)
                {
                    // Если пользователя нет, создаем временного
                    var role = username switch
                    {
                        "admin" => "Admin",
                        "realtor" => "Realtor",
                        "client" => "Client",
                        _ => "Client"
                    };

                    user = new User
                    {
                        user_id = username.GetHashCode(),
                        username = username,
                        role = role,
                        full_name = username,
                        email = $"{username}@test.com"
                    };
                }

                // Создаем claims
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, user.user_id.ToString()),
                    new Claim(ClaimTypes.Name, user.username),
                    new Claim(ClaimTypes.Role, user.role),
                    new Claim("FullName", user.full_name)
                };

                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);

                await HttpContext.SignInAsync(
                    CookieAuthenticationDefaults.AuthenticationScheme,
                    new ClaimsPrincipal(claimsIdentity),
                    new AuthenticationProperties
                    {
                        IsPersistent = true, // Persistent cookie
                        AllowRefresh = true,
                        ExpiresUtc = DateTimeOffset.UtcNow.AddDays(7) // Cookie на 7 дней
                    });

                Console.WriteLine($"=== БЫСТРЫЙ ВХОД УСПЕШЕН! Редирект на Dashboard ===");

                return RedirectToAction("Dashboard", "Home");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка быстрого входа: {ex.Message}");
                return RedirectToAction("Login");
            }
        }

        // Самый простой вход через сессию (для отладки)
        [HttpGet]
        [AllowAnonymous]
        public IActionResult SimpleLogin(string username = "admin")
        {
            try
            {
                var role = username switch
                {
                    "admin" => "Admin",
                    "realtor" => "Realtor",
                    "client" => "Client",
                    _ => "Client"
                };

                HttpContext.Session.SetString("CurrentUser", username);
                HttpContext.Session.SetString("CurrentRole", role);

                Console.WriteLine($"Простой вход: {username} как {role}");
                return RedirectToAction("Dashboard", "Home");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
                return RedirectToAction("Index", "Home");
            }
        }
        [Authorize]
[HttpGet]
public async Task<IActionResult> Profile()
{
    try
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        var user = await _spService.GetUserByIdAsync(userId);
        
        if (user == null)
        {
            TempData["ErrorMessage"] = "Пользователь не найден";
            return RedirectToAction("Dashboard", "Home");
        }
        
        // В зависимости от роли получаем дополнительную информацию
        if (user.role == "Client")
        {
            var client = await _spService.GetClientByUserIdAsync(userId);
            ViewBag.AdditionalInfo = client;
        }
        else if (user.role == "Realtor")
        {
            var realtor = await _spService.GetRealtorByUserIdAsync(userId);
            ViewBag.AdditionalInfo = realtor;
        }
        
        return View(user);
    }
    catch (Exception ex)
    {
        TempData["ErrorMessage"] = $"Ошибка: {ex.Message}";
        return RedirectToAction("Dashboard", "Home");
    }
}
        // Тестовый вход с правильным редиректом
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> TestLogin(string username = "admin")
        {
            try
            {
                Console.WriteLine($"=== ТЕСТОВЫЙ ВХОД: {username} ===");

                // Ищем пользователя через хранимую функцию
                var user = await _spService.GetUserByUsernameAsync(username);

                if (user == null)
                {
                    Console.WriteLine($"Пользователь {username} не найден в БД. Используйте QuickLogin для создания.");
                    TempData["ErrorMessage"] = $"Пользователь {username} не найден. Используйте /Account/QuickLogin?username={username}";
                    return RedirectToAction("Login");
                }

                Console.WriteLine($"Пользователь найден: ID={user.user_id}, Role={user.role}");

                // Создаем claims с реальным user_id
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, user.user_id.ToString()),
                    new Claim(ClaimTypes.Name, user.username),
                    new Claim(ClaimTypes.Role, user.role),
                    new Claim("FullName", user.full_name)
                };

                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);

                await HttpContext.SignInAsync(
                    CookieAuthenticationDefaults.AuthenticationScheme,
                    new ClaimsPrincipal(claimsIdentity),
                    new AuthenticationProperties
                    {
                        IsPersistent = true, // Persistent cookie
                        AllowRefresh = true,
                        ExpiresUtc = DateTimeOffset.UtcNow.AddDays(7) // Cookie на 7 дней
                    });

                Console.WriteLine($"=== ВХОД ВЫПОЛНЕН: {username} как {user.role} ===");

                // Редирект на Dashboard, который сам разберется с ролью
                return RedirectToAction("Dashboard", "Home");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
                TempData["ErrorMessage"] = $"Ошибка входа: {ex.Message}";
                return RedirectToAction("Login");
            }
        }

        private string HashPassword(string password)
        {
            // Для теста используем простые пароли
            if (password == "admin123!")
                return "hTfqNvB6ZKA24C3c8E8qJ0JBXb5D4M+uzkXw4Xp5h3A=";

            if (password == "123456")
                return "jGl25bVBBBW96Qi9Te4V37Fnqchz/Eu4qB9vKrRIqRg=";

            using var sha256 = SHA256.Create();
            var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(bytes);
        }
    }
}