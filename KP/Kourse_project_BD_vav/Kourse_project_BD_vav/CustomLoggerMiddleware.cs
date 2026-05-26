namespace Kourse_project_BD_vav.Middleware
{
    public class CustomLoggerMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<CustomLoggerMiddleware> _logger;

        public CustomLoggerMiddleware(RequestDelegate next, ILogger<CustomLoggerMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var path = context.Request.Path;
            var method = context.Request.Method;

            _logger.LogDebug($"Начало обработки запроса: {method} {path}");

            try
            {
                await _next(context);
                _logger.LogDebug($"Запрос успешно обработан: {method} {path} - {context.Response.StatusCode}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Ошибка при обработке запроса: {method} {path}");
                throw;
            }
        }
    }

    public static class CustomLoggerMiddlewareExtensions
    {
        public static IApplicationBuilder UseCustomLogger(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<CustomLoggerMiddleware>();
        }
    }
}