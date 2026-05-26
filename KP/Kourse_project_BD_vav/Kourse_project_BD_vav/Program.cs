using Kourse_project_BD_vav.Data;
using Kourse_project_BD_vav.Hubs;
using Kourse_project_BD_vav.Interfaces;
using Kourse_project_BD_vav.Models;
using Kourse_project_BD_vav.Services;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Настройка подробного логирования
builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole(options =>
{
    options.IncludeScopes = true;
    options.TimestampFormat = "HH:mm:ss ";
});
builder.Logging.AddDebug();
builder.Logging.SetMinimumLevel(LogLevel.Debug);

Console.WriteLine("🚀 Запуск приложения...");

// ------------------ Сервисы ------------------
builder.Services.AddControllersWithViews()
    .AddSessionStateTempDataProvider();

builder.Services.AddRazorPages()
    .AddSessionStateTempDataProvider();

builder.Services.AddSignalR();

// Сессии
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.Name = ".KourseProject.Session";
});

// ------------------ SyncService ------------------
builder.Services.AddSingleton<SyncService>();
builder.Services.AddSingleton<ISyncService>(sp => sp.GetRequiredService<SyncService>());
builder.Services.AddHostedService(sp => sp.GetRequiredService<SyncService>()!);

// ------------------ StoredProcedureService ------------------
builder.Services.AddScoped<StoredProcedureService>();

// ------------------ Базы данных ------------------
builder.Services.AddDbContext<MssqlDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("MssqlConnection")));

builder.Services.AddDbContext<PgDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("PgConnection")));

// ------------------ Аутентификация ------------------
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
        options.AccessDeniedPath = "/Account/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromDays(7); // Cookie на 7 дней
        options.SlidingExpiration = true; // Включаем скользящее истечение
        options.Cookie.HttpOnly = true;
        options.Cookie.Name = ".KourseProject.Auth"; // Уникальное имя для cookie
        options.Cookie.IsEssential = true; // Важно для работы
        // Используем None для разработки, чтобы cookie работали на HTTP
        options.Cookie.SecurePolicy = builder.Environment.IsDevelopment() 
            ? Microsoft.AspNetCore.Http.CookieSecurePolicy.None 
            : Microsoft.AspNetCore.Http.CookieSecurePolicy.Always;
        options.Cookie.SameSite = Microsoft.AspNetCore.Http.SameSiteMode.Lax; // Lax для лучшей совместимости
        // Persistent cookies - сохраняются на 7 дней
        
        // Сохраняем cookie при редиректе
        options.Events.OnSigningIn = context =>
        {
            Console.WriteLine($"=== SIGNING IN: Setting cookie ===");
            Console.WriteLine($"IsPersistent: {context.Properties.IsPersistent}");
            Console.WriteLine($"ExpiresUtc: {context.Properties.ExpiresUtc}");
            return Task.CompletedTask;
        };
        
        // Удаляем cookie при выходе
        options.Events.OnSigningOut = context =>
        {
            Console.WriteLine($"=== SIGNING OUT: Removing cookie ===");
            Console.WriteLine($"Path: {context.Request.Path}");
            return Task.CompletedTask;
        };
        
        // Проверяем, что cookie не потеряны
        options.Events.OnValidatePrincipal = context =>
        {
            var isAuthenticated = context.Principal?.Identity?.IsAuthenticated ?? false;
            Console.WriteLine($"=== VALIDATE PRINCIPAL: Authenticated={isAuthenticated}, Path={context.Request.Path} ===");
            if (!isAuthenticated)
            {
                Console.WriteLine($"=== VALIDATE PRINCIPAL: User not authenticated, checking cookies ===");
                foreach (var cookie in context.Request.Cookies)
                {
                    Console.WriteLine($"Cookie: {cookie.Key} = {cookie.Value?.Substring(0, Math.Min(50, cookie.Value?.Length ?? 0))}...");
                }
            }
            return Task.CompletedTask;
        };
        
        // Логируем, когда cookie не найдены и происходит редирект на логин
        options.Events.OnRedirectToLogin = context =>
        {
            var user = context.HttpContext.User;
            var isAuthenticated = user?.Identity?.IsAuthenticated ?? false;
            
            Console.WriteLine($"=== REDIRECT TO LOGIN TRIGGERED: Path={context.Request.Path}, Method={context.Request.Method} ===");
            Console.WriteLine($"Cookies in request: {context.Request.Cookies.Count}");
            foreach (var cookie in context.Request.Cookies)
            {
                Console.WriteLine($"Cookie: {cookie.Key}");
            }
            Console.WriteLine($"User authenticated before redirect: {isAuthenticated}");
            Console.WriteLine($"Redirect URI: {context.RedirectUri}");
            
            // НЕ редиректим на логин, если пользователь уже аутентифицирован (это может быть баг)
            if (isAuthenticated)
            {
                Console.WriteLine($"=== BUG: User is authenticated but being redirected to login! Cancelling redirect. ===");
                context.Response.StatusCode = 200;
                return Task.CompletedTask;
            }
            
            // Не редиректим на логин, если это AJAX запрос или POST запрос
            if (context.Request.Path.StartsWithSegments("/api") || 
                context.Request.Method == "POST")
            {
                context.Response.StatusCode = 401;
                return Task.CompletedTask;
            }
            context.Response.Redirect(context.RedirectUri);
            return Task.CompletedTask;
        };
    });

// ------------------ Авторизация ------------------
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("RealtorOrAdmin", policy => policy.RequireRole("Realtor", "Admin"));
    options.AddPolicy("ClientOrHigher", policy => policy.RequireRole("Client", "Realtor", "Admin"));
});

// ------------------ Создаем приложение ------------------
var app = builder.Build();

// ------------------ Middleware ------------------
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}
else
{
    app.UseDeveloperExceptionPage();
}

// ВАЖНО: порядок middleware критичен!
app.UseStaticFiles();
// НЕ используем UseHttpsRedirection вообще, чтобы cookie работали на HTTP
// if (!app.Environment.IsDevelopment())
// {
//     app.UseHttpsRedirection();
// }
app.UseRouting();

// Middleware для логирования всех запросов
app.Use(async (context, next) =>
{
    Console.WriteLine($"=== REQUEST: {context.Request.Method} {context.Request.Path} ===");
    Console.WriteLine($"User authenticated: {context.User?.Identity?.IsAuthenticated ?? false}");
    Console.WriteLine($"Cookies: {context.Request.Cookies.Count}");
    
    if (context.Request.Path.StartsWithSegments("/Property") ||
        context.Request.Path.StartsWithSegments("/Account") ||
        context.Request.Path.StartsWithSegments("/Client") ||
        context.Request.Path.StartsWithSegments("/Realtor") ||
        context.Request.Path.StartsWithSegments("/Deal"))
    {
        context.Response.Headers["Cache-Control"] = "no-cache, no-store, must-revalidate";
        context.Response.Headers["Pragma"] = "no-cache";
        context.Response.Headers["Expires"] = "0";
    }
    await next();
});

// ВАЖНО: Session должен быть ПЕРЕД Authentication
app.UseSession();
app.UseAuthentication();
app.UseAuthorization();

// ------------------ МАРШРУТЫ ------------------
Console.WriteLine("🛣️ Настройка маршрутов...");

// СПЕЦИФИЧНЫЕ МАРШРУТЫ (должны быть ПЕРЕД общими)

// Маршрут для сделок клиента
app.MapControllerRoute(
    name: "deal-mydeals",
    pattern: "Deal/MyDeals",
    defaults: new { controller = "Deal", action = "MyDeals" });

// Маршрут для деталей сделки
app.MapControllerRoute(
    name: "deal-details",
    pattern: "Deal/Details/{id}",
    defaults: new { controller = "Deal", action = "Details" });

// Маршрут для создания сделки
app.MapControllerRoute(
    name: "deal-create",
    pattern: "Deal/Create",
    defaults: new { controller = "Deal", action = "Create" });

// Маршрут для деталей объекта недвижимости
app.MapControllerRoute(
    name: "property-details",
    pattern: "Property/Details/{id}",
    defaults: new { controller = "Property", action = "Details" });

// Маршрут для быстрого резервирования
app.MapControllerRoute(
    name: "property-reservation-quick",
    pattern: "PropertyReservation/QuickReserve/{id}",
    defaults: new { controller = "PropertyReservation", action = "QuickReserve" });

// Маршрут для создания объекта недвижимости
app.MapControllerRoute(
    name: "property-create",
    pattern: "Property/Create",
    defaults: new { controller = "Property", action = "Create" });

// Маршрут для профиля пользователя
app.MapControllerRoute(
    name: "account-profile",
    pattern: "Account/Profile",
    defaults: new { controller = "Account", action = "Profile" });

// Маршрут для редактирования профиля
app.MapControllerRoute(
    name: "account-edit",
    pattern: "Account/Edit/{id?}",
    defaults: new { controller = "Account", action = "Edit" });

// ОБЩИЕ МАРШРУТЫ ДЛЯ КОНТРОЛЛЕРОВ
app.MapControllerRoute(
    name: "property",
    pattern: "Property/{action=Index}/{id?}",
    defaults: new { controller = "Property" });

app.MapControllerRoute(
    name: "deal",
    pattern: "Deal/{action=Index}/{id?}",
    defaults: new { controller = "Deal" });

app.MapControllerRoute(
    name: "account",
    pattern: "Account/{action=Login}/{id?}",
    defaults: new { controller = "Account" });

app.MapControllerRoute(
    name: "client",
    pattern: "Client/{action=Index}/{id?}",
    defaults: new { controller = "Client" });

app.MapControllerRoute(
    name: "realtor",
    pattern: "Realtor/{action=Index}/{id?}",
    defaults: new { controller = "Realtor" });

app.MapControllerRoute(
    name: "sync",
    pattern: "Sync/{action=Index}/{id?}",
    defaults: new { controller = "Sync" });

app.MapControllerRoute(
    name: "home",
    pattern: "Home/{action=Index}/{id?}",
    defaults: new { controller = "Home" });

app.MapControllerRoute(
    name: "propertyreservation",
    pattern: "PropertyReservation/{action=Index}/{id?}",
    defaults: new { controller = "PropertyReservation" });

// SignalR Hub
app.MapHub<SyncHub>("/syncHub");

// ОБЩИЙ маршрут (должен быть ПОСЛЕДНИМ!)
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

// Fallback route
app.MapFallbackToController("Index", "Home");

Console.WriteLine("✅ Маршруты настроены");

// ------------------ Инициализация баз данных ------------------
Console.WriteLine("🔄 Начало инициализации базы данных...");
using (var scope = app.Services.CreateScope())
{
    try
    {
        var mssqlContext = scope.ServiceProvider.GetRequiredService<MssqlDbContext>();
        var pgContext = scope.ServiceProvider.GetRequiredService<PgDbContext>();

        Console.WriteLine("🔍 Проверка MSSQL базы...");
        await mssqlContext.Database.EnsureCreatedAsync();
        Console.WriteLine("✅ MSSQL база создана/проверена");

        Console.WriteLine("🔍 Проверка PostgreSQL базы...");
        await pgContext.Database.EnsureCreatedAsync();
        Console.WriteLine("✅ PostgreSQL база создана/проверена");

        // Создаем таблицу PropertyReservations в PostgreSQL, если её нет
        Console.WriteLine("🔍 Проверка таблицы PropertyReservations в PostgreSQL...");
        try
        {
            await pgContext.Database.ExecuteSqlRawAsync(@"
                CREATE TABLE IF NOT EXISTS propertyreservations (
                    reservation_id SERIAL PRIMARY KEY,
                    property_id INTEGER NOT NULL,
                    client_id INTEGER NOT NULL,
                    realtor_id INTEGER NOT NULL,
                    status VARCHAR(20) DEFAULT 'Active',
                    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    expiry_date TIMESTAMP NOT NULL,
                    
                    CONSTRAINT fk_reservations_property FOREIGN KEY (property_id) REFERENCES properties(property_id),
                    CONSTRAINT fk_reservations_client FOREIGN KEY (client_id) REFERENCES clients(client_id),
                    CONSTRAINT fk_reservations_realtor FOREIGN KEY (realtor_id) REFERENCES realtors(realtor_id)
                );
                
                CREATE INDEX IF NOT EXISTS ix_propertyreservations_property_id ON propertyreservations(property_id);
                CREATE INDEX IF NOT EXISTS ix_propertyreservations_client_id ON propertyreservations(client_id);
                CREATE INDEX IF NOT EXISTS ix_propertyreservations_realtor_id ON propertyreservations(realtor_id);
                CREATE INDEX IF NOT EXISTS ix_propertyreservations_status ON propertyreservations(status);
            ");
            Console.WriteLine("✅ Таблица PropertyReservations создана/проверена в PostgreSQL");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"⚠️ Ошибка при создании таблицы PropertyReservations в PostgreSQL: {ex.Message}");
            // Продолжаем выполнение, возможно таблица уже существует
        }

        // PostgreSQL является основной БД, поэтому расширяем схему в primary
        Console.WriteLine("🔍 Проверка структуры таблицы Properties в PostgreSQL...");
        await pgContext.Database.ExecuteSqlRawAsync(@"
            ALTER TABLE IF EXISTS properties
                ADD COLUMN IF NOT EXISTS is_available BOOLEAN NOT NULL DEFAULT TRUE;
            ALTER TABLE IF EXISTS properties
                ADD COLUMN IF NOT EXISTS rooms INTEGER NULL;
            ALTER TABLE IF EXISTS properties
                ADD COLUMN IF NOT EXISTS floor INTEGER NULL;
            ALTER TABLE IF EXISTS properties
                ADD COLUMN IF NOT EXISTS total_floors INTEGER NULL;
            ALTER TABLE IF EXISTS properties
                ADD COLUMN IF NOT EXISTS main_image_url VARCHAR(500) NULL;
            ALTER TABLE IF EXISTS properties
                ADD COLUMN IF NOT EXISTS image_urls TEXT NULL;
        ");
        Console.WriteLine("✅ Структура таблицы Properties проверена в PostgreSQL");

        // Создаем тестовых пользователей если их нет
        if (!await pgContext.Users.AnyAsync())
        {
            Console.WriteLine("🔄 Создание тестовых пользователей...");

            var passwordHash = "hTfqNvB6ZKA24C3c8E8qJ0JBXb5D4M+uzkXw4Xp5h3A=";

            var users = new List<Kourse_project_BD_vav.Models.User>
            {
                new() {
                    username = "admin",
                    email = "admin@test.com",
                    full_name = "Администратор",
                    role = "Admin",
                    password_hash = passwordHash,
                    created_at = DateTime.Now
                },
                new() {
                    username = "realtor",
                    email = "realtor@test.com",
                    full_name = "Иванов Иван",
                    role = "Realtor",
                    password_hash = passwordHash,
                    created_at = DateTime.Now
                },
                new() {
                    username = "client",
                    email = "client@test.com",
                    full_name = "Петров Петр",
                    role = "Client",
                    password_hash = passwordHash,
                    created_at = DateTime.Now
                }
            };
            pgContext.Users.AddRange(users);
            await pgContext.SaveChangesAsync();
            Console.WriteLine("✅ Пользователи созданы");
        }

        // Создаем тестовых клиентов если их нет
        if (!await pgContext.Clients.AnyAsync())
        {
            Console.WriteLine("🔄 Создание тестовых клиентов...");
            var clientUser = await pgContext.Users.FirstAsync(u => u.username == "client");

            var clients = new List<Kourse_project_BD_vav.Models.Client>
            {
                new()
                {
                    full_name = "Петров Петр Петрович",
                    phone_number = "+7 (999) 111-22-33",
                    email = "petrov@example.com",
                    passport_number = "1234 567890",
                    registration_date = DateTime.Now.AddMonths(-3),
                    user_id = clientUser.user_id
                }
            };
            pgContext.Clients.AddRange(clients);
            await pgContext.SaveChangesAsync();
            Console.WriteLine("✅ Клиенты созданы");
        }

        // Создаем тестовых риэлторов если их нет
        if (!await pgContext.Realtors.AnyAsync())
        {
            Console.WriteLine("🔄 Создание тестовых риэлторов...");
            var realtorUser = await pgContext.Users.FirstAsync(u => u.username == "realtor");

            var realtors = new List<Kourse_project_BD_vav.Models.Realtor>
            {
                new()
                {
                    full_name = "Иванов Иван Иванович",
                    phone_number = "+7 (999) 123-45-67",
                    email = "ivanov@example.com",
                    hire_date = DateTime.Now.AddMonths(-6),
                    commission_rate = 5.5m,
                    user_id = realtorUser.user_id
                }
            };
            pgContext.Realtors.AddRange(realtors);
            await pgContext.SaveChangesAsync();
            Console.WriteLine("✅ Риэлторы созданы");
        }

        // Создаем тестовые объекты недвижимости если их нет
        if (!await pgContext.Properties.AnyAsync())
        {
            Console.WriteLine("🔄 Создание тестовых объектов недвижимости...");
            var realtor = await pgContext.Realtors.FirstAsync();

            var properties = new List<Kourse_project_BD_vav.Models.Property>
            {
                new()
                {
                    address = "Москва, ул. Тверская, д. 10",
                    property_type = "Квартира",
                    area = 75.5m,
                    price = 25000000,
                    description = "Просторная 3-комнатная квартира в центре Москвы",
                    realtor_id = realtor.realtor_id,
                    is_available = true,
                    rooms = 3,
                    floor = 5,
                    total_floors = 12,
                    main_image_url = "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800",
                    image_urls = "[\"https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800\", \"https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=800\"]"
                },
                new()
                {
                    address = "Санкт-Петербург, Невский пр., д. 25",
                    property_type = "Квартира",
                    area = 45.2m,
                    price = 15000000,
                    description = "Светлая 2-комнатная квартира с ремонтом",
                    realtor_id = realtor.realtor_id,
                    is_available = true,
                    rooms = 2,
                    floor = 3,
                    total_floors = 9,
                    main_image_url = "https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=800",
                    image_urls = "[\"https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800\"]"
                }

            };
            pgContext.Properties.AddRange(properties);
            await pgContext.SaveChangesAsync();
            Console.WriteLine("✅ Объекты недвижимости созданы");
        }
        // Создаем тестовую сделку если ее нет
        if (!await pgContext.Deals.AnyAsync())
        {
            Console.WriteLine("🔄 Создание тестовой сделки...");

            // Получаем или создаем риэлтора
            var realtor = await pgContext.Realtors.FirstOrDefaultAsync();
            if (realtor == null)
            {
                realtor = new Kourse_project_BD_vav.Models.Realtor
                {
                    full_name = "Милочкин Илья Игоревич",
                    phone_number = "+7 (999) 111-22-33",
                    email = "realtor@example.com",
                    hire_date = DateTime.Now.AddYears(-1),
                    commission_rate = 5.0m,
                    user_id = (await pgContext.Users.FirstAsync(u => u.username == "realtor")).user_id
                };
                pgContext.Realtors.Add(realtor);
                await pgContext.SaveChangesAsync();
                Console.WriteLine("✅ Риэлтор создан");
            }

            // Получаем или создаем клиента
            var client = await pgContext.Clients.FirstOrDefaultAsync();
            if (client == null)
            {
                client = new Kourse_project_BD_vav.Models.Client
                {
                    full_name = "Петров Петр Петрович",
                    phone_number = "+7 (999) 123-45-67",
                    email = "client@example.com",
                    passport_number = "1234 567890",
                    registration_date = DateTime.Now.AddMonths(-3),
                    user_id = (await pgContext.Users.FirstAsync(u => u.username == "client")).user_id
                };
                pgContext.Clients.Add(client);
                await pgContext.SaveChangesAsync();
                Console.WriteLine("✅ Клиент создан");
            }

            // Получаем или создаем объект недвижимости
            var property = await pgContext.Properties.FirstOrDefaultAsync();
            if (property == null)
            {
                property = new Kourse_project_BD_vav.Models.Property
                {
                    address = "г. Москва, ул. Ленина, д. 5, кв. 12",
                    property_type = "Квартира",
                    area = 75.5m,
                    price = 5000000,
                    description = "3-комнатная квартира с ремонтом",
                    realtor_id = realtor.realtor_id,
                    is_available = true,
                    rooms = 3,
                    floor = 5,
                    total_floors = 12
                };
                pgContext.Properties.Add(property);
                await pgContext.SaveChangesAsync();
                Console.WriteLine("✅ Объект недвижимости создан");
            }

            // Создаем сделку
            var deal = new Kourse_project_BD_vav.Models.Deal
            {
                property_id = property.property_id,
                client_id = client.client_id,
                realtor_id = realtor.realtor_id,
                deal_type = "Продажа",
                deal_status = "Завершена",
                deal_date = new DateTime(2025, 11, 17),
                deal_price = 5000000
            };

            pgContext.Deals.Add(deal);
            await pgContext.SaveChangesAsync();
            Console.WriteLine("✅ Тестовая сделка создана");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"❌ ОШИБКА при инициализации БД: {ex.Message}");
        if (ex.InnerException != null)
        {
            Console.WriteLine($"🔍 Внутренняя ошибка: {ex.InnerException.Message}");
        }
    }
}

Console.WriteLine("🚀 Запуск приложения...");
await app.RunAsync();